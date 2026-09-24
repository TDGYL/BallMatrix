import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bm_player_ability_model.dart';

/// BMPlayerAbilityGenerator - 球员六维战力随机数生成器 (纯函数工具类)
/// 规则 (需求 2026-09-23):
///   1. ATT/TEC/STA/DEF/POW/SPD 六项每项均取 1~100 随机数
///   2. 随机数带积分排序规则: 球员A积27分 > 球员B积19分
///      => 球员A六项数据的"综合值"(六项总和) 必须强于球员B
///   3. 同积分的球员不做强弱约束 (只约束"不同积分"之间的强弱关系)
/// 实现思路 (总积分锚定法):
///   - 积分越高 => 六项"总和锚点"越大 (严格随积分单调递增, 每差1分总分至少差6)
///   - 总和确定后, 六项在 1~100 内随机扰动分配 (保证每项仍是随机数)
///   - 总和锚点: base = 100 + score*5 (score=19 -> 195, score=27 -> 235)
///     每差 1 分总分差 5, 单项扰动幅度不跨过该间隔 => 综合强弱严格保证
/// 作用范围: 工具页「生成战力报告」获取随机六项数据 (替代原球员详情接口)
class BMPlayerAbilityGenerator {
  /// 私有构造 (纯静态工具类, 禁止实例化)
  BMPlayerAbilityGenerator._();

  /// 随机数种子 (Random 类型, 顶层复用保证序列随机)
  static final Random _random = Random();

  /// 单项随机数下限 (int 类型, 需求: 1-100 之间)
  static const int _minValue = 1;

  /// 单项随机数上限 (int 类型, 需求: 1-100 之间)
  static const int _maxValue = 100;

  /// 六项维度总数 (int 类型, ATT/TEC/STA/DEF/POW/SPD)
  static const int _dimensionCount = 6;

  /// 总分锚点基础偏移 (int 类型, 保证低积分球员总和也在合理区间)
  static const int _baseSum = 100;

  /// 按积分生成六项战力随机数
  /// [playerId] - 球员唯一ID (int 类型, 仅用于构建模型)
  /// [playerName] - 球员名 (String 类型, 仅用于构建模型)
  /// [score] - 球员积分 (int 类型, 例: 27分/19分, 值越大六项综合越强)
  /// 返回: BMPlayerAbilityModel (六项均为 1~100 随机数, 综合强度与积分严格正相关)
  static BMPlayerAbilityModel generate({
    required int playerId,
    required String playerName,
    required int score,
  }) {
    // 1. 总分锚点: score 每差 1 分, 六项总和至少差 5 (2*_jitter=4 < 5, 强弱严格)
    final targetSum = (_baseSum + score * 5).clamp(
      _dimensionCount * _minValue,
      _dimensionCount * _maxValue,
    );
    // 2. 六项在 1~100 内随机分配该总和 (先均分, 再随机迁移制造扰动)
    final values = _distributeRandom(targetSum);
    return BMPlayerAbilityModel(
      playerId: playerId,
      playerName: playerName,
      att: values[0],
      tec: values[1],
      sta: values[2],
      def: values[3],
      pow: values[4],
      spd: values[5],
    );
  }

  /// 将目标总和随机分配到 6 项, 每项 1~100
  /// [targetSum] - 六项总和目标值 (int 类型, 6~600)
  /// 返回: List int 六项随机值 (总和精确等于 targetSum, 每项 1~100)
  static List<int> _distributeRandom(int targetSum) {
    // 2a. 均分基础: 商 + 余数前几项 +1
    final base = targetSum ~/ _dimensionCount;
    final rem = targetSum % _dimensionCount;
    final values = List<int>.generate(
      _dimensionCount,
      (i) => base + (i < rem ? 1 : 0),
    );
    // 2b. 随机扰动: 两两之间随机转移 (保持总和不变, 制造六项强弱差异)
    for (int round = 0; round < 8; round++) {
      final i = _random.nextInt(_dimensionCount);
      final j = _random.nextInt(_dimensionCount);
      if (i == j) continue;
      // 可转移量: i 不能低于 1, j 不能高于 100
      final maxGive = values[i] - _minValue;
      final maxTake = _maxValue - values[j];
      final cap = maxGive < maxTake ? maxGive : maxTake;
      if (cap <= 0) continue;
      final move = _random.nextInt(cap + 1);
      values[i] -= move;
      values[j] += move;
    }
    return values;
  }
}

/// BMPlayerAbilityStore - 球员六维战力本地存储服务 (SharedPreferences 持久化)
/// 规则 (需求 2026-09-23):
///   1. 生成随机数之前先查本地缓存, 命中直接返回 (同一球员六项数据稳定不变)
///   2. 本地无缓存才生成随机数, 生成后立即写回本地
///   3. 存储粒度: 按 playerId 一人一条, key = bm_player_ability_{playerId}
/// 作用范围: 工具页「生成战力报告」随机数缓存读写
class BMPlayerAbilityStore {
  /// 私有构造 (纯静态工具类, 禁止实例化)
  BMPlayerAbilityStore._();

  /// 存储key前缀 (String 类型, 拼接 playerId 使用)
  static const String _keyPrefix = 'bm_player_ability_';

  /// 从本地读取球员六维战力
  /// [playerId] - 球员唯一ID (int 类型)
  /// [playerName] - 球员名 (String 类型, 本地缓存无名字时兜底)
  /// 返回: BMPlayerAbilityModel? (本地无缓存/解析失败返回 null)
  static Future<BMPlayerAbilityModel?> load({
    required int playerId,
    String? playerName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$playerId');
      if (raw == null || raw.isEmpty) return null;
      // JSON 反序列化 -> Map (与 save 的 jsonEncode 格式严格配对)
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final model = BMPlayerAbilityModel.fromPlayerDataMap(
        decoded,
        playerId: playerId,
        playerName: playerName,
      );
      if (model != null && _isValid(model)) {
        debugPrint('📦 BMPlayerAbilityStore 本地命中: playerId=$playerId, 六项=[${model.att},${model.tec},${model.sta},${model.def},${model.pow},${model.spd}]');
        return model;
      }
      return null;
    } catch (e) {
      debugPrint('❌ BMPlayerAbilityStore.load 异常: $e, playerId=$playerId');
      return null;
    }
  }

  /// 将球员六维战力写入本地
  /// [model] - 球员能力模型 (BMPlayerAbilityModel 类型, 必含六项 1~100 值)
  /// 返回: bool (写入成功 true, 失败 false)
  static Future<bool> save(BMPlayerAbilityModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // JSON 序列化存储 (与 load 的 jsonDecode 格式严格配对, 保证可还原)
      final jsonStr = jsonEncode(<String, dynamic>{
        'ability': {
          'att': model.att,
          'tec': model.tec,
          'sta': model.sta,
          'def': model.def,
          'pow': model.pow,
          'spd': model.spd,
        },
        'name': model.playerName,
      });
      final ok = await prefs.setString(
        '$_keyPrefix${model.playerId}',
        jsonStr,
      );
      debugPrint('💾 BMPlayerAbilityStore.save playerId=${model.playerId} 结果=$ok, 数据=$jsonStr');
      return ok;
    } catch (e) {
      debugPrint('❌ BMPlayerAbilityStore.save 异常: $e, playerId=${model.playerId}');
      return false;
    }
  }

  /// 模型合法性校验 (六项均在 1~100)
  /// [model] - 待校验模型 (BMPlayerAbilityModel 类型)
  /// 返回: bool (六项全部 1~100 返回 true)
  static bool _isValid(BMPlayerAbilityModel model) {
    final values = [model.att, model.tec, model.sta, model.def, model.pow, model.spd];
    return values.every((v) => v >= 1 && v <= 100);
  }
}
