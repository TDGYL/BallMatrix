import 'bm_match_api_model.dart' show safeInt, safeString, safeBool, debugPrintSafe;

/// BMBasketballMatchData - 篮球比赛列表API响应数据体
/// 作用范围: /api/livespeed/basketball/matches 接口响应data字段
class BMBasketballMatchData {
  /// 数据总数 (int? 类型)
  final int? total;

  /// 请求时间戳 (int? 类型, 秒)
  final int? timestamp;

  /// 比赛项目列表 (List<BMBasketballMatchItem> 类型)
  final List<BMBasketballMatchItem> results;

  BMBasketballMatchData({this.total, this.timestamp, this.results = const []});

  /// 从 JSON 解析 (全安全提取, 不抛错)
  factory BMBasketballMatchData.fromJson(Map<String, dynamic> json) {
    final list = json['results'] is List ? json['results'] as List : null;
    final List<BMBasketballMatchItem> items = [];
    if (list != null) {
      for (final e in list) {
        try {
          if (e is Map<String, dynamic>) {
            items.add(BMBasketballMatchItem.fromJson(e));
          }
        } catch (ex) {
          debugPrintSafe('BMBasketballMatchData results单项解析跳过: $ex');
        }
      }
    }
    return BMBasketballMatchData(
      total: safeInt(json['total']),
      timestamp: safeInt(json['timestamp']),
      results: items,
    );
  }
}

/// BMBasketballMatchItem - 单场篮球比赛数据项
/// 作用范围: /api/livespeed/basketball/matches 接口 results 子项
class BMBasketballMatchItem {
  /// 比赛唯一ID (int? 类型)
  final int? id;

  /// 赛季ID (int? 类型)
  final int? seasonId;

  /// 联赛ID (int? 类型)
  final int? competitionId;

  /// 联赛LogoURL (String? 类型)
  final String? competitionLogo;

  /// 联赛名称 (String? 类型)
  final String? competitionName;

  /// 主队ID (int? 类型)
  final int? homeTeamId;

  /// 主队名称 (String? 类型)
  final String? homeTeamName;

  /// 主队LogoURL (String? 类型)
  final String? homeTeamLogo;

  /// 客队ID (int? 类型)
  final int? awayTeamId;

  /// 客队名称 (String? 类型)
  final String? awayTeamName;

  /// 客队LogoURL (String? 类型)
  final String? awayTeamLogo;

  /// 主队总比分 (String? 类型, 注意后端可能是string或int)
  final String? homeScores;

  /// 客队总比分 (String? 类型)
  final String? awayScores;

  /// 主队系列赛比分 (String? 类型)
  final String? seriesHomeScore;

  /// 客队系列赛比分 (String? 类型)
  final String? seriesAwayScore;

  /// 类型 (int? 类型)
  final int? kind;

  /// 节数 (int? 类型)
  final int? periodCount;

  /// 状态ID (int? 类型)
  final int? statusId;

  /// 状态名称 (String? 类型)
  final String? statusName;

  /// 开赛时间戳 (int? 类型, 秒)
  final int? matchTime;

  /// 是否中立场地 (int? 类型)
  final int? neutral;

  /// 是否关注 (bool? 类型)
  final bool? subscribed;

  /// 主队排名 (String? 类型)
  final String? homePosition;

  /// 客队排名 (String? 类型)
  final String? awayPosition;

  /// 剩余时间 (int? 类型, 秒)
  final int? remainTime;

  /// 阶段名称 (String? 类型)
  final String? stageName;

  /// 主队Q1比分 (String? 类型, 兼容嵌套)
  final String? homeQ1;

  /// 主队Q2比分 (String? 类型)
  final String? homeQ2;

  /// 主队Q3比分 (String? 类型)
  final String? homeQ3;

  /// 主队Q4比分 (String? 类型)
  final String? homeQ4;

  /// 客队Q1比分 (String? 类型)
  final String? awayQ1;

  /// 客队Q2比分 (String? 类型)
  final String? awayQ2;

  /// 客队Q3比分 (String? 类型)
  final String? awayQ3;

  /// 客队Q4比分 (String? 类型)
  final String? awayQ4;

  BMBasketballMatchItem({
    this.id,
    this.seasonId,
    this.competitionId,
    this.competitionLogo,
    this.competitionName,
    this.homeTeamId,
    this.homeTeamName,
    this.homeTeamLogo,
    this.awayTeamId,
    this.awayTeamName,
    this.awayTeamLogo,
    this.homeScores,
    this.awayScores,
    this.seriesHomeScore,
    this.seriesAwayScore,
    this.kind,
    this.periodCount,
    this.statusId,
    this.statusName,
    this.matchTime,
    this.neutral,
    this.subscribed,
    this.homePosition,
    this.awayPosition,
    this.remainTime,
    this.stageName,
    this.homeQ1,
    this.homeQ2,
    this.homeQ3,
    this.homeQ4,
    this.awayQ1,
    this.awayQ2,
    this.awayQ3,
    this.awayQ4,
  });

  /// 从 JSON 解析 (snake_case → camelCase, 全安全提取不抛错)
  factory BMBasketballMatchItem.fromJson(Map<String, dynamic> json) {
    return BMBasketballMatchItem(
      id: safeInt(json['id']) ?? safeInt(json['match_id']),
      seasonId: safeInt(json['season_id']),
      competitionId: safeInt(json['competition_id']),
      competitionLogo: safeString(json['competition_logo']),
      competitionName: safeString(json['competition_name']),
      homeTeamId: safeInt(json['home_team_id']),
      homeTeamName: safeString(json['home_team_name']),
      homeTeamLogo: safeString(json['home_team_logo']),
      awayTeamId: safeInt(json['away_team_id']),
      awayTeamName: safeString(json['away_team_name']),
      awayTeamLogo: safeString(json['away_team_logo']),
      homeScores: safeString(json['home_scores']) ??
          safeString(json['home_score']) ??
          safeString(json['home_normal_score']),
      awayScores: safeString(json['away_scores']) ??
          safeString(json['away_score']) ??
          safeString(json['away_normal_score']),
      seriesHomeScore: safeString(json['series_home_score']),
      seriesAwayScore: safeString(json['series_away_score']),
      kind: safeInt(json['kind']),
      periodCount: safeInt(json['period_count']),
      statusId: safeInt(json['status_id']),
      statusName: safeString(json['status_name']),
      matchTime: safeInt(json['match_time']),
      neutral: safeInt(json['neutral']),
      subscribed: safeBool(json['subscribed']),
      homePosition: safeString(json['home_position']),
      awayPosition: safeString(json['away_position']),
      remainTime: safeInt(json['remain_time']),
      stageName: safeString(json['stage_name']),
      homeQ1: safeString(json['home_q1']),
      homeQ2: safeString(json['home_q2']),
      homeQ3: safeString(json['home_q3']),
      homeQ4: safeString(json['home_q4']),
      awayQ1: safeString(json['away_q1']),
      awayQ2: safeString(json['away_q2']),
      awayQ3: safeString(json['away_q3']),
      awayQ4: safeString(json['away_q4']),
    );
  }
}
