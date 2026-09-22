import 'package:flutter/foundation.dart';

/// BMPlayerAbilityModel - 球员多维战力能力雷达数据模型
/// 来源接口: GET /api/livespeed/football/info?id={playerId} -> data["ability"] Map
/// 参考: MEPlayerVM.m:296-304 (ability Map取 6个维度 att/tec/sta/def/pow/spd)
/// 作用范围: 工具页点击「生成战力报告」后, 两名球员的6维能力雷达图对比绘制
class BMPlayerAbilityModel {
  /// 球员唯一ID (int 类型, 主键, 对应请求入参 id)
  final int playerId;

  /// 球员显示名称 (String 类型, 雷达图图例/对比展示用)
  final String playerName;

  /// ATT=进攻能力 (int 类型, 0-100 百分比, 雷达6边形顶点1)
  final int att;

  /// TEC=技术能力 (int 类型, 0-100 百分比, 雷达6边形顶点2)
  final int tec;

  /// STA=稳定/状态能力 (int 类型, 0-100 百分比, 雷达6边形顶点3)
  final int sta;

  /// DEF=防守能力 (int 类型, 0-100 百分比, 雷达6边形顶点4)
  final int def;

  /// POW=力量/身体素质 (int 类型, 0-100 百分比, 雷达6边形顶点5)
  final int pow;

  /// SPD=速度/爆发能力 (int 类型, 0-100 百分比, 雷达6边形顶点6)
  final int spd;

  const BMPlayerAbilityModel({
    required this.playerId,
    required this.playerName,
    required this.att,
    required this.tec,
    required this.sta,
    required this.def,
    required this.pow,
    required this.spd,
  });

  /// 从 Map 安全转换为 int?
  /// 兼容 int / num / String("123") 多种类型, 异常或 null 返回 null
  static int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }
    return null;
  }

  /// 从 Map 安全转换为 String?
  /// 非空对象一律 toString(), null 返回 null; 自动 trim 前后空白
  static String? _safeString(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final s = v.trim();
      return s.isEmpty ? null : s;
    }
    return v.toString();
  }

  /// 从 /football/info 接口返回的 data Map 创建能力模型
  /// 规则: 先取 data["ability"] 子 Map -> 提取 att/tec/sta/def/pow/spd 6项
  /// ⚠️ 每个 int 值 0-100(参考 MEPlayerVM attributeValueMap = MAX(0,MIN(100,num)));
  /// 如果 ability 子项缺失或非法 -> 对应值 0 兜底, 不丢整条
  /// [playerId] - 已知的球员ID (因为外层 data 才是球员详情, ability 子 Map 不含 playerId)
  /// [playerName] - 已知的球员姓名 (外层 data 或调用方传入)
  static BMPlayerAbilityModel? fromPlayerDataMap(
    Map<String, dynamic> data, {
    required int playerId,
    String? playerName,
  }) {
    try {
      // 1. 尝试从 data 外层取球员姓名(兼容 hanklive 字段名 name_zh / name / player_name)
      final fallbackName = playerName ??
          _safeString(data['name_zh']) ??
          _safeString(data['name']) ??
          _safeString(data['player_name']) ??
          '球员$playerId';

      // 2. ability 子 Map (参考 MEPlayerVM.m:296 NSDictionary *ability = dic[@"ability"])
      final ability = data['ability'];
      Map<String, dynamic> abilityMap = <String, dynamic>{};
      if (ability is Map<String, dynamic>) {
        abilityMap = ability;
      }

      // 3. 6维能力, 每项缺失/非法 -> 0 兜底, 且 clamp 0~100
      int clamp0100(int? v) {
        if (v == null) return 0;
        if (v < 0) return 0;
        if (v > 100) return 100;
        return v;
      }

      return BMPlayerAbilityModel(
        playerId: playerId,
        playerName: fallbackName,
        att: clamp0100(_safeInt(abilityMap['att'])),
        tec: clamp0100(_safeInt(abilityMap['tec'])),
        sta: clamp0100(_safeInt(abilityMap['sta'])),
        def: clamp0100(_safeInt(abilityMap['def'])),
        pow: clamp0100(_safeInt(abilityMap['pow'])),
        spd: clamp0100(_safeInt(abilityMap['spd'])),
      );
    } catch (e) {
      debugPrint('BMPlayerAbilityModel.fromPlayerDataMap 解析异常: $e, playerId=$playerId');
      return null;
    }
  }

  /// 获取6个维度值的顺序列表 (对应 MERadarChartView: ATT→TEC→STA→DEF→POW→SPD)
  /// 返回值已归一化 0.0~1.0 (value/100), 供雷达图半径比例使用
  List<double> get normalizedValues {
    return [
      att / 100.0,
      tec / 100.0,
      sta / 100.0,
      def / 100.0,
      pow / 100.0,
      spd / 100.0,
    ];
  }

  /// 6个维度显示标签顺序 (对应 iOS axisTitles 顺序, 1:1 对齐)
  static const List<String> dimensionLabels = [
    'ATT',
    'TEC',
    'STA',
    'DEF',
    'POW',
    'SPD',
  ];
}
