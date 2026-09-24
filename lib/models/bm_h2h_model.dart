import 'bm_match_model.dart';

/// BMH2HMatch - H2H historyencounterssinglematch (H2H Tab usage)
/// API：GET /api/livespeed/football/match/analysis -> data.history.vs
class BMH2HMatch {
 /// matchID (String type)
 final String matchId;

 /// league name (String? type)
 final String? leagueName;

 /// match timesecondlevel timestamp (int? type)
 final int? matchTime;

 /// home teamname (String? type)
 final String? homeTeamName;

 /// away teamname (String? type)
 final String? awayTeamName;

 /// home teamteam ID (int? type, forcheckwhetheryescurrenthome team: homeTeamId == currentHomeTeamId)
 final int? homeTeamId;

 /// away teamteam ID (int? type, forcheckwhetheryescurrenthome team: awayTeamId == currentHomeTeamId)
 final int? awayTeamId;

 /// home teamlogo URL (String? type)
 final String? homeTeamLogo;

 /// away teamlogo URL (String? type)
 final String? awayTeamLogo;

 /// league/cup Logo (String? type, HankLive TopRow left sideicon)
 final String? leagueLogo;

 /// home team 90 minutetimescore (int? type, notincludesextra time/penalty, corresponding Hank homeNormalScore)
 final int? homeNormalScore;

 /// away team 90 minutetimescore (int? type, corresponding Hank awayNormalScore)
 final int? awayNormalScore;

 /// home teamscore (int? type, includesextra time/penaltytotal score)
 final int? homeScore;

 /// away teamscore (int? type)
 final int? awayScore;

 /// halfcourthome teamscore (int? type, can be empty)
 final int? homeHalfScore;

 /// halfcourtaway teamscore (int? type, can be empty)
 final int? awayHalfScore;

 /// matchstate (int? type, 8=FT wait, reference BMMatchStatus id)
 final int? statusId;

 BMH2HMatch({
 required this.matchId,
 this.leagueName,
 this.matchTime,
 this.homeTeamName,
 this.awayTeamName,
 this.homeTeamId,
 this.awayTeamId,
 this.homeTeamLogo,
 this.awayTeamLogo,
 this.leagueLogo,
 this.homeNormalScore,
 this.awayNormalScore,
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
    final hnt = json['home_normal_score'] ?? json['homeNormalScore'] ?? json['home_regular_score'] ?? json['homeRegularScore'] ?? ht;
    final ant = json['away_normal_score'] ?? json['awayNormalScore'] ?? json['away_regular_score'] ?? json['awayRegularScore'] ?? at;
    final hh = json['home_half_score'] ?? json['homeHalfScore'];
    final aa = json['away_half_score'] ?? json['awayHalfScore'];
    final mt = json['match_time'] ?? json['matchTime'] ?? json['time'];
    final hid = json['home_team_id'] ?? json['homeTeamId'] ?? json['homeId'];
    final aid = json['away_team_id'] ?? json['awayTeamId'] ?? json['awayId'];
    final ll = json['league_logo'] ?? json['leagueLogo'] ?? json['competition_logo'] ?? json['competitionLogo'];
    return BMH2HMatch(
      matchId: mid,
      leagueName: json['league_name'] ?? json['leagueName'] ?? json['competition_name'] ?? json['competitionName'],
      leagueLogo: ll is String && ll.isNotEmpty ? ll : null,
      matchTime: (mt is num) ? mt.toInt() : int.tryParse(mt?.toString() ?? ''),
      homeTeamName: json['home_team_name'] ?? json['homeTeamName'] ?? json['homeName'],
      awayTeamName: json['away_team_name'] ?? json['awayTeamName'] ?? json['awayName'],
      homeTeamId: (hid is num) ? hid.toInt() : int.tryParse(hid?.toString() ?? ''),
      awayTeamId: (aid is num) ? aid.toInt() : int.tryParse(aid?.toString() ?? ''),
      homeTeamLogo: json['home_team_logo'] ?? json['homeTeamLogo'] ?? json['homeLogo'],
      awayTeamLogo: json['away_team_logo'] ?? json['awayTeamLogo'] ?? json['awayLogo'],
      homeNormalScore: (hnt is num) ? hnt.toInt() : int.tryParse(hnt?.toString() ?? ''),
      awayNormalScore: (ant is num) ? ant.toInt() : int.tryParse(ant?.toString() ?? ''),
      homeScore: (ht is num) ? ht.toInt() : int.tryParse(ht?.toString() ?? ''),
      awayScore: (at is num) ? at.toInt() : int.tryParse(at?.toString() ?? ''),
      homeHalfScore: (hh is num) ? hh.toInt() : int.tryParse(hh?.toString() ?? ''),
      awayHalfScore: (aa is num) ? aa.toInt() : int.tryParse(aa?.toString() ?? ''),
      statusId: (json['status'] is num) ? (json['status'] as num).toInt(): null,
);
 }
}

/// BMH2HMatch displayandconvertexpanded
extension BMH2HMatchDisplayX on BMH2HMatch {
 /// stateID -> BMMatchStatus enum (same BMFootball : 1NS 2-7in progress 8FT othersTBD)
 BMMatchStatus get resolvedStatus {
 if (statusId == 8) return BMMatchStatus.ended;
 if (statusId == 1) return BMMatchStatus.upcoming;
 if (statusId != null && statusId! >= 2 && statusId! <= 7) return BMMatchStatus.live;
 return BMMatchStatus.tbd;
 }

 /// timestamp -> MM-dd HH:mm string (for matchTime field, not yetpassthenemptystring)
 String get formattedMatchTime {
 if (matchTime == null || matchTime == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(matchTime! * 1000);
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$mm-$dd $hh:$mi';
 }

 /// HT scoreconcatstring (like "1-0", missinganyonethennull)
 String? get halfTimeScoreStr {
 if (homeHalfScore == null || awayHalfScore == null) return null;
 return '${homeHalfScore}-${awayHalfScore}';
 }

 /// convertas BMMatchModel (for push BMFootballDetailPage, detailpage initState willuse matchId re-request detail/process overridedata)
 BMMatchModel get toMatchModel {
 return BMMatchModel(
 matchId: matchId,
 // Hank alignmentfield: top level int homeTeamId / awayTeamId → passto BMMatchModel, solve H2H WDL returncheckissue
 homeTeamId: homeTeamId,
 awayTeamId: awayTeamId,
 homeTeamName: homeTeamName,
 awayTeamName: awayTeamName,
 homeTeamLogo: homeTeamLogo,
 awayTeamLogo: awayTeamLogo,
 homeScore: homeScore,
 awayScore: awayScore,
 // 4 sectionscore (Hank alignment /halfcourt/extra time/penalty)
 homeNormalScore: homeNormalScore,
 homeHalfScore: homeHalfScore,
 awayNormalScore: awayNormalScore,
 awayHalfScore: awayHalfScore,
 leagueName: leagueName ?? '',
      leagueColor: 0xFF12FF80,
      status: resolvedStatus,
      statusId: statusId,
      statusName: resolvedStatus == BMMatchStatus.ended
          ? 'FT'
          : resolvedStatus == BMMatchStatus.live
              ? 'in progress'
              : resolvedStatus == BMMatchStatus.upcoming
                  ? 'NS'
                  : 'TBD',
 // win WLresult (1=home win 2=D 3=away win Hank alignment)
 win: (homeScore != null && awayScore != null)
 ? (homeScore! > awayScore! ? 1: (homeScore! < awayScore! ? 3: 2))
: null,
 sportType: BMMatchSportType.football,
 matchTime: formattedMatchTime,
 halfTimeScore: halfTimeScoreStr,
 round: '',
 // compatibleoriginal of homeTeam / awayTeam structurefield (not yetpass teamId/teamLogo when H2H top fallback)
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
    );
  }
}
