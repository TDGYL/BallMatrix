import 'package:flutter/foundation.dart';

/// BMPlayerRankModel - 联赛球员排行榜数据模型
/// 来源接口: GET /api/livespeed/football/competition/player-rank -> data 数组项
/// 作用范围: 工具页联赛下方球员榜单展示 (射手榜/射正榜/助攻榜等)
class BMPlayerRankModel {
  /// 球员唯一ID (int 类型, 后端主键, 用于跳转到球员详情页)
  final int playerId;

  /// 排行项类型名称 (String 类型, 例: 进球/射正/助攻/黄牌, 由 key 参数决定显示)
  final String rankName;

  /// 排名位置 (int 类型, 从1开始, 第1名/第2名..., UI 前3名可展示金/银/铜色)
  final int position;

  /// 球员显示姓名 (String 类型, 中文全名, 例: 埃林·布朗特·哈兰德)
  final String playerName;

  /// 球员头像URL (String 类型, 远端资源链接, may be 空, UI 需提供默认占位头像)
  final String playerLogo;

  /// 所属球队名称 (String 类型, 中文友好名称, 例: 曼彻斯特城)
  final String teamName;

  /// 数据统计值 (int 类型, 对应 key 的累计总数, 例: k_shots_on=射正数36)
  final int total;

  const BMPlayerRankModel({
    required this.playerId,
    required this.rankName,
    required this.position,
    required this.playerName,
    required this.playerLogo,
    required this.teamName,
    required this.total,
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
  static BMPlayerRankModel? fromMap(Map<String, dynamic> map) {
    try {
      final playerId = _safeInt(map['player_id']);
      final rankName = _safeString(map['rank_name']);
      final position = _safeInt(map['position']);
      final playerName = _safeString(map['player_name']);
      final playerLogo = _safeString(map['player_logo']);
      final teamName = _safeString(map['team_name']);
      final total = _safeInt(map['total']);
      if (playerId == null ||
          playerName == null ||
          position == null ||
          total == null) {
        return null;
      }
      return BMPlayerRankModel(
        playerId: playerId,
        rankName: rankName ?? '数据',
        position: position,
        playerName: playerName,
        playerLogo: playerLogo ?? '',
        teamName: teamName ?? '',
        total: total,
      );
    } catch (e) {
      debugPrint('BMPlayerRankModel.fromMap 解析异常: $e, map=$map');
      return null;
    }
  }
}
