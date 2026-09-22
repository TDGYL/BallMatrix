import 'package:flutter/foundation.dart';

/// BMCompetitionModel - 足球联赛(赛事)数据模型
/// 来源接口: GET /api/livespeed/football/competition/list -> data 数组项
/// 作用范围: 首页过滤器 / 工具页联赛筛选 / 球员申请擅长联赛 等全项目所有联赛选择UI
class BMCompetitionModel {
  /// 联赛唯一ID (int 类型, 后端主键, 用于请求 matches 时 competition_ids 过滤)
  final int id;

  /// 联赛显示名称 (String 类型, 中文友好名称, 例: 英超/世欧预/西甲)
  final String name;

  /// 联赛缩写首字母 (String 类型, 例: 英超=EPL / 世欧预=O, 左侧小图标文字用)
  final String cap;

  /// 是否主流联赛标记 (int 类型, 1=主流置顶/靠前显示, 0=次级联赛, 排序时可降序)
  final int main;

  const BMCompetitionModel({
    required this.id,
    required this.name,
    required this.cap,
    required this.main,
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
  /// 非空对象一律 toString(), null 返回 null
  static String? _safeString(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final s = v.trim();
      return s.isEmpty ? null : s;
    }
    return v.toString();
  }

  /// 从后端 Map<String, dynamic> 创建模型实例
  /// 单条解析失败返回 null, 调用方建议使用 for + try-catch 避免整批丢弃
  static BMCompetitionModel? fromMap(Map<String, dynamic> map) {
    try {
      final id = _safeInt(map['id']);
      final name = _safeString(map['name']);
      final cap = _safeString(map['cap']);
      final main = _safeInt(map['main']);
      if (id == null || name == null) return null;
      // cap 兜底: 取name第1个字符大写 (中文取首字, 英文取首字母)
      final capFallback = name.isEmpty ? '·' : name.substring(0, 1).toUpperCase();
      return BMCompetitionModel(
        id: id,
        name: name,
        cap: cap ?? capFallback,
        main: main ?? 0,
      );
    } catch (e) {
      debugPrint('BMCompetitionModel.fromMap 解析异常: $e, map=$map');
      return null;
    }
  }
}
