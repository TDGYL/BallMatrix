import 'bm_match_model.dart';

/// BMH2HMatch - H2H 历史交锋单条比赛 (H2H Tab 用)
/// API：GET /api/livespeed/football/match/analysis -> data.history.vs
class BMH2HMatch {
  /// 比赛ID (String 类型)
  final String matchId;

  /// 联赛名 (String? 类型)
  final String? leagueName;

  /// 比赛时间秒级时间戳 (int? 类型)
  final int? matchTime;

  /// 主队名 (String? 类型)
  final String? homeTeamName;

  /// 客队名 (String? 类型)
  final String? awayTeamName;

  /// 主队logo URL (String? 类型)
  final String? homeTeamLogo;

  /// 客队logo URL (String? 类型)
  final String? awayTeamLogo;

  /// 主队比分 (int? 类型, 含加时/点球总比分)
  final int? homeScore;

  /// 客队比分 (int? 类型)
  final int? awayScore;

  /// 半场主队比分 (int? 类型, 可空)
  final int? homeHalfScore;

  /// 半场客队比分 (int? 类型, 可空)
  final int? awayHalfScore;

  /// 比赛状态 (int? 类型, 8=已结束 等, 参考 BMMatchStatus id)
  final int? statusId;

  BMH2HMatch({
    required this.matchId,
    this.leagueName,
    this.matchTime,
    this.homeTeamName,
    this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.homeScore,
    this.awayScore,
    this.homeHalfScore,
    this.awayHalfScore,
    this.statusId,
  });

  factory BMH2HMatch.fromJson(Map<String, dynamic> json) {
    final mid = (json['match_id'] ?? json['matchId'] ?? '').toString();
    final ht = json['home_score'] ?? json['homeScore'];
    final at = json['away_score'] ?? json['awayScore'];
    final hh = json['home_half_score'] ?? json['homeHalfScore'];
    final aa = json['away_half_score'] ?? json['awayHalfScore'];
    final mt = json['match_time'] ?? json['matchTime'] ?? json['time'];
    return BMH2HMatch(
      matchId: mid,
      leagueName: json['league_name'] ?? json['leagueName'] ?? json['competition_name'] ?? json['competitionName'],
      matchTime: (mt is num) ? mt.toInt() : int.tryParse(mt?.toString() ?? ''),
      homeTeamName: json['home_team_name'] ?? json['homeTeamName'] ?? json['homeName'],
      awayTeamName: json['away_team_name'] ?? json['awayTeamName'] ?? json['awayName'],
      homeTeamLogo: json['home_team_logo'] ?? json['homeTeamLogo'] ?? json['homeLogo'],
      awayTeamLogo: json['away_team_logo'] ?? json['awayTeamLogo'] ?? json['awayLogo'],
      homeScore: (ht is num) ? ht.toInt() : int.tryParse(ht?.toString() ?? ''),
      awayScore: (at is num) ? at.toInt() : int.tryParse(at?.toString() ?? ''),
      homeHalfScore: (hh is num) ? hh.toInt() : int.tryParse(hh?.toString() ?? ''),
      awayHalfScore: (aa is num) ? aa.toInt() : int.tryParse(aa?.toString() ?? ''),
      statusId: (json['status'] is num) ? (json['status'] as num).toInt() : null,
    );
  }
}

/// BMH2HMatch 显示与转换扩展
extension BMH2HMatchDisplayX on BMH2HMatch {
  /// 状态ID -> BMMatchStatus 枚举 (同 BMFootball 约定: 1未开始 2-7进行中 8已结束 其他TBD)
  BMMatchStatus get resolvedStatus {
    if (statusId == 8) return BMMatchStatus.ended;
    if (statusId == 1) return BMMatchStatus.upcoming;
    if (statusId != null && statusId! >= 2 && statusId! <= 7) return BMMatchStatus.live;
    return BMMatchStatus.tbd;
  }

  /// 时间戳 -> MM-dd HH:mm 字符串 (用于 matchTime 字段, 未传则空串)
  String get formattedMatchTime {
    if (matchTime == null || matchTime == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(matchTime! * 1000);
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$mm-$dd $hh:$mi';
  }

  /// 半场比分拼接字符串 (如 "1-0", 缺任一则null)
  String? get halfTimeScoreStr {
    if (homeHalfScore == null || awayHalfScore == null) return null;
    return '${homeHalfScore}-${awayHalfScore}';
  }

  /// 转为 BMMatchModel (用于 push BMFootballDetailPage, 详情页 initState 会用 matchId 重新请求 detail/process 覆盖数据)
  BMMatchModel get toMatchModel {
    return BMMatchModel(
      matchId: matchId,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      homeTeamLogo: homeTeamLogo,
      awayTeamLogo: awayTeamLogo,
      homeScore: homeScore,
      awayScore: awayScore,
      leagueName: leagueName ?? '',
      leagueColor: 0xFF12FF80,
      status: resolvedStatus,
      statusId: statusId,
      statusName: resolvedStatus == BMMatchStatus.ended
          ? '完场'
          : resolvedStatus == BMMatchStatus.live
              ? '进行中'
              : resolvedStatus == BMMatchStatus.upcoming
                  ? '未开始'
                  : '待定',
      sportType: BMMatchSportType.football,
      matchTime: formattedMatchTime,
      halfTimeScore: halfTimeScoreStr,
      round: '',
    );
  }
}
