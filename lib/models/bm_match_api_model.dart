/// securitytool: fromjsonstatevaluetakeint? (compatibleint/String/num/null, extract failure returns null)
int? safeInt(dynamic v) {
 if (v == null) return null;
 if (v is int) return v;
 if (v is num) return v.toInt();
 if (v is String) return int.tryParse(v);
 return null;
}

/// securitytool: fromjsonstatevaluetakeString? (compatibleString/num/null, extract failure returns null)
String? safeString(dynamic v) {
 if (v == null) return null;
 if (v is String) return v;
 return v.toString();
}

/// securitytool: fromjsonstatevaluetakebool? (compatiblebool/int/null, extract failure returns null)
bool? safeBool(dynamic v) {
 if (v == null) return null;
 if (v is bool) return v;
 if (v is int) return v != 0;
 if (v is String) {
 final s = v.toLowerCase().trim();
 if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
 }
 return null;
}

/// BMMatchData - footballmatchlistAPIresponsedatabody
/// purposescope: /api/livespeed/football/matches APIresponsedatafield
class BMMatchData {
 /// datatotal (int? type)
 final int? total;

 /// requesttimestamp (int? type, second)
 final int? timestamp;

 /// matchitem list (List<BMMatchItem> type)
 final List<BMMatchItem> results;

 BMMatchData({this.total, this.timestamp, this.results = const []});

 /// from JSON parse (fullfieldsecuritytake, no throw)
 factory BMMatchData.fromJson(Map<String, dynamic> json) {
 final list = json['results'] is List ? json['results'] as List : null;
    final List<BMMatchItem> items = [];
    if (list != null) {
      for (final e in list) {
        try {
          if (e is Map<String, dynamic>) {
            items.add(BMMatchItem.fromJson(e));
          }
        } catch (ex) {
          debugPrintSafe('BMMatchData resultssingleitemparseskip: $ex');
        }
      }
    }
    return BMMatchData(
      total: safeInt(json['total']),
      timestamp: safeInt(json['timestamp']),
 results: items,
);
 }
}

/// BMMatchItem - singlecourtfootballmatchdataitem
/// purposescope: /api/livespeed/football/matches API results sub item
class BMMatchItem {
 /// matchuniqueID (int? type)
 final int? matchId;

 /// season ID (int? type)
 final int? seasonId;

 /// leagueID (int? type)
 final int? competitionId;

 /// leagueLogoURL (String? type)
 final String? competitionLogo;

 /// league namename (String? type)
 final String? competitionName;

 /// leagueaccent color(home) (String? type, tensixmakecolorstringoptional)
 final String? competitionPrimaryColor;

 /// leagueaccent color(copy) (String? type)
 final String? competitionSecondaryColor;

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

 /// stateID (int? type: 0/1=NS, 2/3/4=in progress, 8=FT)
 final int? statusId;

 /// statename (String? type)
 final String? statusName;

 /// kickoff timestamp (int? type, second)
 final int? matchTime;

 /// whetherininstantlycourt (int? type)
 final int? neutral;

 /// home teamregular score (int? type)
 final int? homeNormalScore;

 /// home teamHT score (int? type)
 final int? homeHalfScore;

 /// home teamred card (int? type)
 final int? homeRed;

 /// home teamyellow card (int? type)
 final int? homeYellow;

 /// home teamcorner (int? type)
 final int? homeCorn;

 /// home teamextra timescore (int? type)
 final int? homeAddScore;

 /// home teampenaltyscore (int? type)
 final int? homePointScore;

 /// away teamregular score (int? type)
 final int? awayNormalScore;

 /// away teamHT score (int? type)
 final int? awayHalfScore;

 /// away teamred card (int? type)
 final int? awayRed;

 /// away teamyellow card (int? type)
 final int? awayYellow;

 /// away teamcorner (int? type)
 final int? awayCorn;

 /// away teamextra timescore (int? type)
 final int? awayAddScore;

 /// away teampenaltyscore (int? type)
 final int? awayPointScore;

 /// whetherhaslineup (int? type)
 final int? lineup;

 /// sectionID (int? type)
 final int? stageId;

 /// whetherfollow (bool? type)
 final bool? subscribed;

 /// home teamrank (String? type)
 final String? homePosition;

 /// away teamrank (String? type)
 final String? awayPosition;

 /// whetherhasextra time (bool? type)
 final bool? hasOt;

 /// whetherhaspenalty (bool? type)
 final bool? hasPenalty;

 /// WL (int? type: 1=home win, 2=D, 3=away win)
 final int? win;

 /// remark (String? type)
 final String? note;

 /// in progressminutecount (String? type, like "78'")
 final String? minutes;

 /// animationlive (int? type)
 final int? mlive;

 /// animationliveURL (String? type)
 final String? mliveUrl;

 /// viewlive (int? type)
 final int? liveVideo;

 /// whetherhastextchapter (int? type)
 final int? hasArticle;

 /// stage section name (String? type)
 final String? stageName;

 /// smallgroupNo. (String? type)
 final String? groupNum;

 /// roundtimeNo. (int? type)
 final int? roundNum;

 /// solutioncount (int? type)
 final int? schemeCount;

 /// openmatchcountwhen (int? type, second)
 final int? countdown;

 /// whetherboundary (int? type)
 final int? isWorldCup;

 /// sportsplit classes (int? type)
 final int? categoryId;

 BMMatchItem({
 this.matchId,
 this.seasonId,
 this.competitionId,
 this.competitionLogo,
 this.competitionName,
 this.competitionPrimaryColor,
 this.competitionSecondaryColor,
 this.homeTeamId,
 this.homeTeamName,
 this.homeTeamLogo,
 this.awayTeamId,
 this.awayTeamName,
 this.awayTeamLogo,
 this.statusId,
 this.statusName,
 this.matchTime,
 this.neutral,
 this.homeNormalScore,
 this.homeHalfScore,
 this.homeRed,
 this.homeYellow,
 this.homeCorn,
 this.homeAddScore,
 this.homePointScore,
 this.awayNormalScore,
 this.awayHalfScore,
 this.awayRed,
 this.awayYellow,
 this.awayCorn,
 this.awayAddScore,
 this.awayPointScore,
 this.lineup,
 this.stageId,
 this.subscribed,
 this.homePosition,
 this.awayPosition,
 this.hasOt,
 this.hasPenalty,
 this.win,
 this.note,
 this.minutes,
 this.mlive,
 this.mliveUrl,
 this.liveVideo,
 this.hasArticle,
 this.stageName,
 this.groupNum,
 this.roundNum,
 this.schemeCount,
 this.countdown,
 this.isWorldCup,
 this.categoryId,
 });

 /// from JSON parse (snake_case → camelCase, fullsecuritytakeno throw)
 factory BMMatchItem.fromJson(Map<String, dynamic> json) {
 return BMMatchItem(
 matchId: safeInt(json['match_id']),
      seasonId: safeInt(json['season_id']),
      competitionId: safeInt(json['competition_id']),
      competitionLogo: safeString(json['competition_logo']),
      competitionName: safeString(json['competition_name']),
      competitionPrimaryColor: safeString(json['competition_primary_color']),
      competitionSecondaryColor: safeString(json['competition_secondary_color']),
      homeTeamId: safeInt(json['home_team_id']),
      homeTeamName: safeString(json['home_team_name']),
      homeTeamLogo: safeString(json['home_team_logo']),
      awayTeamId: safeInt(json['away_team_id']),
      awayTeamName: safeString(json['away_team_name']),
      awayTeamLogo: safeString(json['away_team_logo']),
      statusId: safeInt(json['status_id']),
      statusName: safeString(json['status_name']),
      matchTime: safeInt(json['match_time']),
      neutral: safeInt(json['neutral']),
      homeNormalScore: safeInt(json['home_normal_score']),
      homeHalfScore: safeInt(json['home_half_score']),
      homeRed: safeInt(json['home_red']),
      homeYellow: safeInt(json['home_yellow']),
      homeCorn: safeInt(json['home_corn']),
      homeAddScore: safeInt(json['home_add_score']),
      homePointScore: safeInt(json['home_point_score']),
      awayNormalScore: safeInt(json['away_normal_score']),
      awayHalfScore: safeInt(json['away_half_score']),
      awayRed: safeInt(json['away_red']),
      awayYellow: safeInt(json['away_yellow']),
      awayCorn: safeInt(json['away_corn']),
      awayAddScore: safeInt(json['away_add_score']),
      awayPointScore: safeInt(json['away_point_score']),
      lineup: safeInt(json['lineup']),
      stageId: safeInt(json['stage_id']),
      subscribed: safeBool(json['subscribed']),
      homePosition: safeString(json['home_position']),
      awayPosition: safeString(json['away_position']),
      hasOt: safeBool(json['has_ot']),
      hasPenalty: safeBool(json['has_penalty']),
      win: safeInt(json['win']),
      note: safeString(json['note']),
      minutes: safeString(json['minutes']),
      mlive: safeInt(json['mlive']),
      mliveUrl: safeString(json['mlive_url']),
      liveVideo: safeInt(json['live_video']),
      hasArticle: safeInt(json['has_article']),
      stageName: safeString(json['stage_name']),
      groupNum: safeString(json['group_num']),
      roundNum: safeInt(json['round_num']),
      schemeCount: safeInt(json['scheme_count']),
      countdown: safeInt(json['countdown']),
      isWorldCup: safeInt(json['is_world_cup']),
      categoryId: safeInt(json['category_id']) ?? safeInt(json['category']),
);
 }
}

/// debugPrintsecurity (foundationinputmissing, unified)
void debugPrintSafe(String msg) {
 // ignore: avoid_print
 print('[BallMatrix Safe] $msg');
}
