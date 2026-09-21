/// BMMatchModel - 比赛数据模型
/// 作用范围: 首页焦点赛事卡片、赛事列表页、比赛详情页
/// 包含比赛的基本信息: 队伍名称、比分、联赛、状态等
class BMMatchModel {
  /// 比赛唯一标识 (String 类型, 范围: 全局唯一)
  final String matchId;

  /// 主队名称 (String 类型)
  final String homeTeamName;

  /// 客队名称 (String 类型)
  final String awayTeamName;

  /// 主队图标URL (String 类型, 可空)
  final String? homeTeamLogo;

  /// 客队图标URL (String 类型, 可空)
  final String? awayTeamLogo;

  /// 主队比分 (int 类型, 未开赛时为null)
  final int? homeScore;

  /// 客队比分 (int 类型, 未开赛时为null)
  final int? awayScore;

  /// 联赛名称 (String 类型)
  final String leagueName;

  /// 比赛轮次或描述 (String 类型)
  final String round;

  /// 比赛状态 (BMMatchStatus 枚举)
  final BMMatchStatus status;

  /// 比赛时间/分钟 (String 类型, 如 "68'" 或 "03:00")
  final String matchTime;

  /// AI胜率推算 (double 类型, 0-100)
  final double aiWinRate;

  /// 主队xG期望进球 (double 类型)
  final double homeXG;

  /// 客队xG期望进球 (double 类型)
  final double awayXG;

  /// 实时压制力百分比 (double 类型, 主队压制力)
  final double momentumPercent;

  /// 模型匹配度 (double 类型, 0-100)
  final double? modelMatchRate;

  /// 预测结果描述 (String 类型, 可空)
  final String? prediction;

  /// AI洞察文字 (String 类型, 可空)
  final String? aiInsight;

  /// 是否焦点对决 (bool 类型)
  final bool isFeatured;

  BMMatchModel({
    required this.matchId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.homeScore,
    this.awayScore,
    required this.leagueName,
    required this.round,
    required this.status,
    required this.matchTime,
    required this.aiWinRate,
    required this.homeXG,
    required this.awayXG,
    required this.momentumPercent,
    this.modelMatchRate,
    this.prediction,
    this.aiInsight,
    this.isFeatured = false,
  });

  /// 从Map映射构建模型 (模拟MJExtension映射)
  factory BMMatchModel.fromMap(Map<String, dynamic> map) {
    return BMMatchModel(
      matchId: map['matchId'] as String,
      homeTeamName: map['homeTeamName'] as String,
      awayTeamName: map['awayTeamName'] as String,
      homeTeamLogo: map['homeTeamLogo'] as String?,
      awayTeamLogo: map['awayTeamLogo'] as String?,
      homeScore: map['homeScore'] as int?,
      awayScore: map['awayScore'] as int?,
      leagueName: map['leagueName'] as String,
      round: map['round'] as String,
      status: BMMatchStatus.values[map['status'] as int? ?? 0],
      matchTime: map['matchTime'] as String,
      aiWinRate: (map['aiWinRate'] as num?)?.toDouble() ?? 0,
      homeXG: (map['homeXG'] as num?)?.toDouble() ?? 0,
      awayXG: (map['awayXG'] as num?)?.toDouble() ?? 0,
      momentumPercent: (map['momentumPercent'] as num?)?.toDouble() ?? 0,
      modelMatchRate: (map['modelMatchRate'] as num?)?.toDouble(),
      prediction: map['prediction'] as String?,
      aiInsight: map['aiInsight'] as String?,
      isFeatured: map['isFeatured'] as bool? ?? false,
    );
  }
}

/// BMMatchStatus - 比赛状态枚举
enum BMMatchStatus {
  /// 进行中
  live,
  /// 即将开赛
  upcoming,
  /// 已完场
  ended,
}