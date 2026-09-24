import 'bm_match_model.dart';

/// BMHotMatchModel - hot matchesmodel
/// purposescope: mapping /api/livespeed/index/search/match/hot GET returns of hot matcheslist
/// fieldincludes: matchID、kickoff time、item split classes、league name、home/away teaminfo、currentscore
class BMHotMatchModel {
 /// matchuniqueID (int type)
 final int? matchId;

 /// kickoff time - UNIXsecondlevel timestamp (int type, second)
 final int? matchTime;

 /// item split classes (int type, 1=football 2=basketball)
 final int? category;

 /// league namename (String type, e.g.: WCBA / Premier League)
 final String? competitionName;

 /// home teamID (int type)
 final int? homeTeamId;

 /// home teamname (String type)
 final String? homeTeamName;

 /// home teamLogo URL (String type)
 final String? homeTeamLogo;

 /// home teamcurrentscore (int type, not started=0)
 final int? homeTeamScore;

 /// away teamID (int type)
 final int? awayTeamId;

 /// away teamname (String type)
 final String? awayTeamName;

 /// away teamLogo URL (String type)
 final String? awayTeamLogo;

 /// away teamcurrentscore (int type, not started=0)
 final int? awayTeamScore;

 BMHotMatchModel({
 this.matchId,
 this.matchTime,
 this.category,
 this.competitionName,
 this.homeTeamId,
 this.homeTeamName,
 this.homeTeamLogo,
 this.homeTeamScore,
 this.awayTeamId,
 this.awayTeamName,
 this.awayTeamLogo,
 this.awayTeamScore,
 });

 /// from JSON mappingbuild model (snake_case → camelCase)
 /// argument: [json] API response of singlematchraw Map
 /// returns: BMHotMatchModel instance
 factory BMHotMatchModel.fromJson(Map<String, dynamic> json) {
 return BMHotMatchModel(
 matchId: json['match_id'] as int?,
      matchTime: json['match_time'] as int?,
      category: json['category'] as int?,
      competitionName: json['competition_name'] as String?,
      homeTeamId: json['home_team_id'] as int?,
      homeTeamName: json['home_team_name'] as String?,
      homeTeamLogo: (json['home_team_logo'] is String)
          ? (json['home_team_logo'] as String).trim()
          : null,
      homeTeamScore: json['home_team_score'] as int?,
      awayTeamId: json['away_team_id'] as int?,
      awayTeamName: json['away_team_name'] as String?,
      awayTeamLogo: (json['away_team_logo'] is String)
          ? (json['away_team_logo'] as String).trim()
          : null,
      awayTeamScore: json['away_team_score'] as int?,
);
 }

 /// convertas JSON (camelCase → snake_case)
 /// returns: Map<String, dynamic>
 Map<String, dynamic> toJson() {
 return {
 'match_id': matchId,
      'match_time': matchTime,
      'category': category,
      'competition_name': competitionName,
      'home_team_id': homeTeamId,
      'home_team_name': homeTeamName,
      'home_team_logo': homeTeamLogo,
      'home_team_score': homeTeamScore,
      'away_team_id': awayTeamId,
      'away_team_name': awayTeamName,
      'away_team_logo': awayTeamLogo,
      'away_team_score': awayTeamScore,
 };
 }

 /// item split classestextdescription (String type: 'football'/'basketball'/'others')
  String get categoryLabel {
    switch (category) {
      case 1:
        return 'football';
      case 2:
        return 'basketball';
      default:
        return 'merge';
 }
 }

 /// formatkickoff timeas MM/DD HH:mm (emptytimestampreturns 'TBD')
  String get formattedMatchTime {
    if (matchTime == null || matchTime == 0) return 'TBD';
    final dt = DateTime.fromMillisecondsSinceEpoch(matchTime! * 1000);
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$mm/$dd $hh:$mi';
 }

 /// convertas BMMatchModel (for push match detail page, detailpage initState willre-request detail override)
 BMMatchModel get toMatchModel {
 final BMMatchStatus status;
 if (category == 1) {
 // footballstate: not started=1 in progress=2..7 FT=8
 final hasStarted = (homeTeamScore ?? 0) > 0 || (awayTeamScore ?? 0) > 0;
 if (!hasStarted) {
 status = BMMatchStatus.upcoming;
 } else if ((matchTime ?? 0) == 0) {
 status = BMMatchStatus.live;
 } else {
 status = BMMatchStatus.ended;
 }
 } else {
 // basketball: openmatchandhasscore=ended or live, otherwise thenupcoming
 final hasStarted = (homeTeamScore ?? 0) > 0 || (awayTeamScore ?? 0) > 0;
 if (!hasStarted) {
 status = BMMatchStatus.upcoming;
 } else if ((matchTime ?? 0) == 0) {
 status = BMMatchStatus.live;
 } else {
 status = BMMatchStatus.ended;
 }
 }
 return BMMatchModel(
 matchId: matchId?.toString() ?? '',
 // Hank alignment 52 fieldfill
 seasonId: null,
 competitionId: null,
 competitionLogo: null,
 competitionPrimaryColor: null,
 competitionSecondaryColor: null,
 // top level int teamId (alignment Hank home_team_id / away_team_id)
 homeTeamId: homeTeamId,
 homeTeamName: homeTeamName,
 homeTeamLogo: homeTeamLogo,
 awayTeamId: awayTeamId,
 awayTeamName: awayTeamName,
 awayTeamLogo: awayTeamLogo,
 statusId: (category == 1)
 ? (status == BMMatchStatus.upcoming
 ? 1
: status == BMMatchStatus.live
 ? 2
: status == BMMatchStatus.ended
 ? 8
: 0)
: (status == BMMatchStatus.upcoming
 ? 1
: status == BMMatchStatus.live
 ? 2
: 10),
 statusName: status == BMMatchStatus.ended
 ? 'FT'
          : status == BMMatchStatus.live
              ? 'in progress'
              : status == BMMatchStatus.upcoming
                  ? 'NS'
                  : 'TBD',
 // matchTimestamp: Hank match_time intsecond storerawvalue
 matchTimestamp: matchTime,
 neutral: null,
 // 4 sectionscore (BMHotMatchModel onlyhastotal, homeNormalScore fallback)
 homeNormalScore: homeTeamScore,
 homeHalfScore: null,
 homeRed: null,
 homeYellow: null,
 homeCorn: null,
 homeAddScore: null,
 homePointScore: null,
 awayNormalScore: awayTeamScore,
 awayHalfScore: null,
 awayRed: null,
 awayYellow: null,
 awayCorn: null,
 awayAddScore: null,
 awayPointScore: null,
 lineup: null,
 stageId: null,
 subscribed: null,
 homePosition: null,
 awayPosition: null,
 hasOt: null,
 hasPenalty: null,
 win: (homeTeamScore != null && awayTeamScore != null)
 ? (homeTeamScore! > awayTeamScore! ? 1: (homeTeamScore! < awayTeamScore! ? 3: 2))
: null,
 note: null,
 minutes: null,
 mlive: null,
 mliveUrl: null,
 liveVideo: null,
 hasArticle: null,
 stageName: null,
 groupNum: null,
 roundNum: null,
 schemeCount: null,
 countdown: null,
 isWorldCup: null,
 categoryId: category, // Hank category int, 1=football 2=basketball
 // ---- BM expandedfield ----
 homeTeam: (homeTeamId != null || (homeTeamName?.isNotEmpty ?? false))
 ? BMTeamModel(
 teamId: homeTeamId?.toString(),
 teamName: homeTeamName ?? '',
              logoUrl: homeTeamLogo,
            )
          : null,
      awayTeam: (awayTeamId != null || (awayTeamName?.isNotEmpty ?? false))
          ? BMTeamModel(
              teamId: awayTeamId?.toString(),
              teamName: awayTeamName ?? '',
              logoUrl: awayTeamLogo,
            )
          : null,
      homeScore: homeTeamScore,
      awayScore: awayTeamScore,
      leagueName: competitionName ?? '',
      leagueColor: category == 1 ? 0xFF12FF80 : 0xFFF97316,
      matchTag: null,
      round: '',
      status: status,
      sportType: category == 2
          ? BMMatchSportType.basketball
          : BMMatchSportType.football,
      matchTime: formattedMatchTime,
      liveMinute: null,
      halfTimeScore: null,
      goalEvents: const [],
      aiWinRate: 0,
      homeWinRate: 0,
      drawRate: 0,
      awayWinRate: 0,
      homeXG: 0,
      awayXG: 0,
      momentumPercent: 0,
      modelMatchRate: null,
      prediction: null,
      aiInsight: null,
      isFeatured: false,
      isFollowed: null,
    );
  }
}
