import 'bm_match_api_model.dart' show safeInt, safeString, safeBool, debugPrintSafe;

/// BMBasketballMatchData - basketballmatchlistAPIresponsedatabody
/// purposescope: /api/livespeed/basketball/matches APIresponsedatafield
class BMBasketballMatchData {
 /// datatotal (int? type)
 final int? total;

 /// requesttimestamp (int? type, second)
 final int? timestamp;

 /// matchitem list (List<BMBasketballMatchItem> type)
 final List<BMBasketballMatchItem> results;

 BMBasketballMatchData({this.total, this.timestamp, this.results = const []});

 /// from JSON parse (fullsecuritytake, no throw)
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
          debugPrintSafe('BMBasketballMatchData resultssingleitemparseskip: $ex');
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

/// BMBasketballMatchItem - singlecourtbasketballmatchdataitem
/// purposescope: /api/livespeed/basketball/matches API results sub item
class BMBasketballMatchItem {
 /// matchuniqueID (int? type)
 final int? id;

 /// season ID (int? type)
 final int? seasonId;

 /// leagueID (int? type)
 final int? competitionId;

 /// leagueLogoURL (String? type)
 final String? competitionLogo;

 /// league namename (String? type)
 final String? competitionName;

 /// home teamID (int? type)
 final int? homeTeamId;

 /// home teamname (String? type)
 final String? homeTeamName;

 /// home teamLogoURL (String? type)
 final String? homeTeamLogo;

 /// away teamID (int? type)
 final int? awayTeamId;

 /// away teamname (String? type)
 final String? awayTeamName;

 /// away teamLogoURL (String? type)
 final String? awayTeamLogo;

 /// home teamtotal score (String? type, notelatersidecanabilityyesstringorint)
 final String? homeScores;

 /// away teamtotal score (String? type)
 final String? awayScores;

 /// home teamsystemcolumnmatchscore (String? type)
 final String? seriesHomeScore;

 /// away teamsystemcolumnmatchscore (String? type)
 final String? seriesAwayScore;

 /// type (int? type)
 final int? kind;

 /// sectioncount (int? type)
 final int? periodCount;

 /// stateID (int? type)
 final int? statusId;

 /// statename (String? type)
 final String? statusName;

 /// kickoff timestamp (int? type, second)
 final int? matchTime;

 /// whetherininstantlycourt (int? type)
 final int? neutral;

 /// whetherfollow (bool? type)
 final bool? subscribed;

 /// home teamrank (String? type)
 final String? homePosition;

 /// away teamrank (String? type)
 final String? awayPosition;

 /// remainingtime (int? type, second)
 final int? remainTime;

 /// stage section name (String? type)
 final String? stageName;

 /// home teamQ1score (String? type, compatible)
 final String? homeQ1;

 /// home teamQ2score (String? type)
 final String? homeQ2;

 /// home teamQ3score (String? type)
 final String? homeQ3;

 /// home teamQ4score (String? type)
 final String? homeQ4;

 /// away teamQ1score (String? type)
 final String? awayQ1;

 /// away teamQ2score (String? type)
 final String? awayQ2;

 /// away teamQ3score (String? type)
 final String? awayQ3;

 /// away teamQ4score (String? type)
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

 /// from JSON parse (snake_case → camelCase, fullsecuritytakeno throw)
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
