import 'package:flutter/foundation.dart';

/// BMCompetitionSeasonModel - 足球联赛赛季数据模型
/// 来源接口: GET /api/livespeed/football/competition/season-list -> data 数组项
/// 参考: hanklive/lib/models/hank_season_info_model.dart 字段 1:1 对应
/// 作用范围: 工具页联赛下获取赛季 -> 用 season_id 请求球员/积分榜/赛程
class BMCompetitionSeasonModel {
  /// 赛季唯一ID (int 类型, 后端主键, 请求积分榜/赛程/球员榜时 season_id 入参必传)
  final int seasonId;

  /// 赛季年份名称 (String 类型, 例: "2024-2025" / "2026-2027", 用于UI显示当前赛季)
  final String year;

  /// 是否当前赛季标记 (int 类型, 1=正在进行的当前赛季 / 0=历史赛季, 参考 hanklive 优先选 isCurrent=1)
  final int isCurrent;

  const BMCompetitionSeasonModel({
    required this.seasonId,
    required this.year,
    required this.isCurrent,
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

  /// 从后端 Map<String, dynamic> 创建模型实例
  /// 单条解析失败返回 null, 调用方建议使用 for + try-catch 避免整批丢弃
  static BMCompetitionSeasonModel? fromMap(Map<String, dynamic> map) {
    try {
      final seasonId = _safeInt(map['season_id']);
      final year = _safeString(map['year']);
      final isCurrent = _safeInt(map['is_current']);
      if (seasonId == null) return null;
      return BMCompetitionSeasonModel(
        seasonId: seasonId,
        year: year ?? '',
        isCurrent: isCurrent ?? 0,
      );
    } catch (e) {
      debugPrint('BMCompetitionSeasonModel.fromMap 解析异常: $e, map=$map');
      return null;
    }
  }
}
