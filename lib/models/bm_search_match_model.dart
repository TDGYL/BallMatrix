/// BMSearchMatch - post topicrelated match of search resultsmodel
/// purposescope: post topicpage (BMPostTopicPage) related match entry + matchsearchpage (BMPostTopicMatchSearchPage)
/// data source:
/// - GET /api/livespeed/index/search (data.matches array element)
/// - GET /api/livespeed/index/search/match/hot (data array element)
/// field 100% alignment hanklive HankSearchMatch (snake_case JSON -> camelCase model)
class BMSearchMatch {
 /// matchID (int? type, related matchargument match_id)
 final int? matchId;

 /// match timestamp (int? type, secondlevel)
 final int? matchTime;

 /// league namename (String? type)
 final String? competitionName;

 /// home teamID (int? type)
 final int? homeTeamId;

 /// home teamname (String? type)
 final String? homeTeamName;

 /// home team Logo URL (String? type)
 final String? homeTeamLogo;

 /// home teamscore (int? type)
 final int? homeTeamScore;

 /// away teamID (int? type)
 final int? awayTeamId;

 /// away teamname (String? type)
 final String? awayTeamName;

 /// away team Logo URL (String? type)
 final String? awayTeamLogo;

 /// away teamscore (int? type)
 final int? awayTeamScore;

 /// sport typeID (int? type, 1=football 2=basketball, forfilter)
 final int? categoryId;

 /// constructor
 BMSearchMatch({
 this.matchId,
 this.matchTime,
 this.competitionName,
 this.homeTeamId,
 this.homeTeamName,
 this.homeTeamLogo,
 this.homeTeamScore,
 this.awayTeamId,
 this.awayTeamName,
 this.awayTeamLogo,
 this.awayTeamScore,
 this.categoryId,
 });

 /// from JSON Map build model (snake_case -> camelCase, MJExtension stylemapping)
 /// [json] - API response of singleitemsmatch Map (Map<String, dynamic> type)
 /// returns: BMSearchMatch
 factory BMSearchMatch.fromJson(Map<String, dynamic> json) {
 return BMSearchMatch(
 matchId: _toInt(json['match_id']),
      matchTime: _toInt(json['match_time']),
      competitionName: _toStr(json['competition_name']),
      homeTeamId: _toInt(json['home_team_id']),
      homeTeamName: _toStr(json['home_team_name']),
      homeTeamLogo: _toStr(json['home_team_logo']),
      homeTeamScore: _toInt(json['home_team_score']),
      awayTeamId: _toInt(json['away_team_id']),
      awayTeamName: _toStr(json['away_team_name']),
      awayTeamLogo: _toStr(json['away_team_logo']),
      awayTeamScore: _toInt(json['away_team_score']),
      categoryId: _toInt(json['category']),
);
 }

 /// security int convert (num/String -> int?)
 static int? _toInt(dynamic v) {
 if (v == null) return null;
 if (v is num) return v.toInt();
 if (v is String) return int.tryParse(v);
 return null;
 }

 /// security String convert (dynamic -> String?)
 static String? _toStr(dynamic v) {
 if (v == null) return null;
 if (v is String) return v.isEmpty ? null: v;
 return v.toString();
 }
}

/// BMSearchResult - searchAPImergeresultmodel
/// data source: GET /api/livespeed/index/search returns data object
/// purposescope: matchsearchpagebykeysearchwhenparse matches group
class BMSearchResult {
 /// matchsearch resultslist (List<BMSearchMatch> type)
 final List<BMSearchMatch> matches;

 /// constructor
 BMSearchResult({this.matches = const []});

 /// from JSON Map build model (onlyparsepost topicneeds of matches group)
 /// [json] - API response of data Map (Map<String, dynamic> type)
 /// returns: BMSearchResult
 factory BMSearchResult.fromJson(Map<String, dynamic> json) {
 final rawMatches = json['matches'];
    final List<BMSearchMatch> list = [];
    if (rawMatches is List) {
      for (final e in rawMatches) {
        if (e is Map<String, dynamic>) list.add(BMSearchMatch.fromJson(e));
      }
    }
    return BMSearchResult(matches: list);
  }
}
