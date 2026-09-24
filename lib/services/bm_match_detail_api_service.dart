import '../network/bm_network_manager.dart';
import '../models/bm_process_model.dart';
import '../models/bm_odds_model.dart';
import '../models/bm_lineup_model.dart';
import '../models/bm_h2h_model.dart';
import '../models/bm_player_info_model.dart';
import '../models/bm_team_info_model.dart';
import '../models/bm_basketball_vote_model.dart';

/// BMMatchDetailApiService - footballmatchdetailAPIservice
/// APIpathplace 1:1 same hanklive HankMatchDetailApiService (height, noneneedmodifylaterside)
/// - GET /api/livespeed/football/match/detail: matchdetail + subscribestate
/// - GET /api/livespeed/football/match/process: match (eventincidents + statisticsstats)
/// - GET /api/livespeed/football/match/odds: indexlist (AH/1X2/O/U/Corners)
/// - GET /api/livespeed/football/match/odd-histories: indexhistory
/// - GET /api/livespeed/football/match/lineup: starterlineup
/// - GET /api/livespeed/football/match/analysis: H2H historyencounters(history.vs)
/// - GET /api/livespeed/football/match/player-info: playerinfo(taplineupavatarpop)
/// - GET /api/livespeed/football/team/data: teaminfo(taptopteamavatarpop)
/// - POST /api/livespeed/football/match/subscribe: subscribe
/// - POST /api/livespeed/football/match/unsubscribe: unsubscribe
class BMMatchDetailApiService {
 /// singletoninstance
 static final BMMatchDetailApiService _instance =
 BMMatchDetailApiService._internal();
 factory BMMatchDetailApiService() => _instance;
 BMMatchDetailApiService._internal();

 /// requestmatchdetailraw Map (subscribestatewaitfieldbypageparse)
 /// matchId: matchID (int, required)
 Future<Map<String, dynamic>?> fetchMatchDetail({required int matchId}) async {
 final resp = await BMNetworkManager().getRequest(
 '/api/livespeed/football/match/detail',
      queryParameters: {'match_id': matchId},
);
 if (resp.isSuccess && resp.data != null) {
 return resp.data as Map<String, dynamic>;
 }
 return null;
 }

 /// requestmatchdata (eventincidents + technical statsstats)
 /// GET /api/livespeed/football/match/process
 Future<BMProcessData?> fetchMatchProcess({required int matchId}) async {
 final resp = await BMNetworkManager().getRequest(
 '/api/livespeed/football/match/process',
      queryParameters: {'match_id': matchId},
);
 if (resp.isSuccess && resp.data != null) {
 return BMProcessData.fromJson(resp.data as Map<String, dynamic>);
 }
 return null;
 }

 /// request4kindhandicapodds (Asian handicap/1X2/size/corner)
 /// GET /api/livespeed/football/match/odds
 Future<BMOddsData?> fetchMatchOdds({required int matchId}) async {
 final resp = await BMNetworkManager().getRequest(
 '/api/livespeed/football/match/odds',
      queryParameters: {'match_id': matchId},
);
 if (resp.isSuccess && resp.data != null) {
 return BMOddsData.fromJson(resp.data as Map<String, dynamic>);
 }
 return null;
 }

 /// requestsomesomecourtmatch of indexhistory
 /// GET /api/livespeed/football/match/odd-histories?match_id=&company_id=
 Future<BMOddsHistoryData?> fetchOddsHistory({
 required int matchId,
 required String companyId,
 }) async {
 final resp = await BMNetworkManager().getRequest(
 '/api/livespeed/football/match/odd-histories',
      queryParameters: {'match_id': matchId, 'company_id': companyId},
    );
    if (resp.isSuccess && resp.data != null) {
      return BMOddsHistoryData.fromJson(resp.data as Map<String, dynamic>);
    }
    return null;
  }

  /// requeststarterlineup
  ///   GET /api/livespeed/football/match/lineup
  Future<BMLineupData?> fetchMatchLineup({required int matchId}) async {
    final resp = await BMNetworkManager().getRequest(
      '/api/livespeed/football/match/lineup',
      queryParameters: {'match_id': matchId},
);
 if (resp.isSuccess && resp.data != null) {
 return BMLineupData.fromJson(resp.data as Map<String, dynamic>);
 }
 return null;
 }

 /// requestfootballmatch H2H historyencounters (split：teamencounters vs / home teamhistory / away teamhistory)
 /// GET /api/livespeed/football/match/analysis?match_id=
 /// returns Map: { 'vs': teamcorrectlist, 'home': home teamrecent match, 'away': away teamrecent match }
 Future<Map<String, List<BMH2HMatch>>> fetchH2HSplitedData({
 required int matchId,
 }) async {
 final result = <String, List<BMH2HMatch>>{
 'vs': <BMH2HMatch>[],
      'home': <BMH2HMatch>[],
      'away': <BMH2HMatch>[],
    };
    try {
      final resp = await BMNetworkManager().getRequest(
        '/api/livespeed/football/match/analysis',
        queryParameters: {'match_id': matchId},
      );
      if (resp.isSuccess && resp.data != null && resp.data is Map) {
        final Map<String, dynamic> data = resp.data as Map<String, dynamic>;
        final history = data['history'];
        if (history is Map<String, dynamic>) {
          List<BMH2HMatch> parseList(dynamic raw) {
            if (raw is! List) return const [];
            try {
              return raw
                  .whereType<Map<String, dynamic>>()
                  .map((e) => BMH2HMatch.fromJson(e))
                  .toList();
            } catch (_) {
              return const [];
            }
          }

          result['vs'] = parseList(history['vs'] ?? history['h2h']);
          result['home'] = parseList(
            history['home'] ?? history['home_team'] ?? history['homeRecent'],
          );
          result['away'] = parseList(
            history['away'] ?? history['away_team'] ?? history['awayRecent'],
);
 }
 }
 } catch (_) {}
 return result;
 }

 /// requestplayerdetail info(taplineupavatarpopSheetusage)
 /// GET /api/livespeed/football/match/player-info?player_id=&match_id=
 /// playerId: playerID (int required, lineupAPI player_id)
 /// matchId: matchID (int required, currentmatchID)
 Future<BMPlayerInfo?> fetchPlayerInfo({
 required int playerId,
 required int matchId,
 }) async {
 if (playerId <= 0) return null;
 try {
 final resp = await BMNetworkManager().getRequest(
 '/api/livespeed/football/match/player-info',
        queryParameters: {'player_id': playerId, 'match_id': matchId},
      );
      if (resp.isSuccess && resp.data != null && resp.data is Map) {
        final obj = resp.data as Map<String, dynamic>;
        final inner = obj['data'];
        if (inner is Map<String, dynamic>) {
          return BMPlayerInfo.fromJson(inner);
        }
        if (obj['player_id'] != null || obj['playerId'] != null) {
 return BMPlayerInfo.fromJson(obj);
 }
 }
 } catch (_) {}
 return null;
 }

 /// requestteamdetail info(taptopteamavatarpopSheetusage)
 /// GET /api/livespeed/football/team/data?team_id=
 /// teamId: teamID (int required)
 Future<BMTeamInfo?> fetchTeamData({required int teamId}) async {
 if (teamId <= 0) return null;
 try {
 final resp = await BMNetworkManager().getRequest(
 '/api/livespeed/football/team/data',
        queryParameters: {'team_id': teamId},
      );
      if (resp.isSuccess && resp.data != null && resp.data is Map) {
        final obj = resp.data as Map<String, dynamic>;
        final inner = obj['data'];
 if (inner is Map<String, dynamic>) {
 // typereturns {code/data/message} (userto of tagformat)
 return BMTeamInfo.fromJson(inner);
 }
 if (obj['name'] != null ||
            obj['team_id'] != null ||
            obj['teamId'] != null) {
 // Dreturns
 return BMTeamInfo.fromJson(obj);
 }
 }
 } catch (_) {}
 return null;
 }

 // ================ basketball detailAPI ================

 /// requestbasketballmatchvote info (live Tab voteratioexampledata source)
 /// GET api/livespeed/basketball/match/vote-info?match_id=
 /// matchId: basketball match ID (int, required)
 /// returns: data {home_votes, away_votes, vote_status}, failurereturns null
 Future<BMBasketballVoteInfo?> fetchBasketballVoteInfo({
 required int matchId,
 }) async {
 if (matchId == 0) return null;
 try {
 final resp = await BMNetworkManager().getRequest(
 '/api/livespeed/basketball/match/vote-info',
        queryParameters: {'match_id': matchId},
);
 if (resp.isSuccess && resp.data != null && resp.data is Map) {
 return BMBasketballVoteInfo.fromJson(resp.data as Map<String, dynamic>);
 }
 } catch (_) {}
 return null;
 }

 /// basketballmatchvote (live Tab votedo)
 /// POST api/livespeed/basketball/match/vote data: {match_id, team}
 /// matchId: basketball match ID (int, required)
 /// team: voteside (int, 1=home team 2=away team)
 /// returns: bool whethervotesuccess
 Future<bool> submitBasketballVote({
 required int matchId,
 required int team,
 }) async {
 if (matchId == 0 || (team != 1 && team != 2)) return false;
 try {
 final resp = await BMNetworkManager().postRequest(
 '/api/livespeed/basketball/match/vote',
        data: {'match_id': matchId, 'team': team},
);
 return resp.isSuccess;
 } catch (_) {
 return false;
 }
 }

 /// requestbasketballmatchdata (onetimerequestreturns stats + tlive, Tab shared)
 /// GET /api/livespeed/basketball/match/process?match_id=
 /// matchId: basketball match ID (int, required)
 /// returns: data Map (includes stats technical statsarray + tlive bysectionlivearray), failurereturns null
 Future<Map<String, dynamic>?> fetchBasketballProcess({
 required int matchId,
 }) async {
 try {
 final resp = await BMNetworkManager().getRequest(
 '/api/livespeed/basketball/match/process',
        queryParameters: {'match_id': matchId},
);
 if (resp.isSuccess && resp.data != null) {
 final obj = resp.data as Map<String, dynamic>;
 // compatible {code,data,message} : takeinnerlayer data
 final inner = obj['data'] is Map ? obj['data'] as Map<String, dynamic>: obj;
 return inner;
 }
 } catch (_) {}
 return null;
 }

 /// requestbasketballmatchdetailraw Map
 /// GET /api/livespeed/football/match/detail?match_id= (basketball detailsame football path, latersideshared)
 /// matchId: basketball match ID (int, required)
 /// returns: data Map (includes home_scores/away_scores minsectionscorecomma No.string / subscribed / odds etc)
 Future<Map<String, dynamic>?> fetchBasketballDetail({
 required int matchId,
 }) async {
 final resp = await BMNetworkManager().getRequest(
 '/api/livespeed/basketball/match/detail',
      queryParameters: {'match_id': matchId},
);
 if (resp.isSuccess && resp.data != null) {
 final obj = resp.data as Map<String, dynamic>;
 // compatible {code,data,message} : takeinnerlayer data
 final inner = obj['data'];
 if (inner is Map<String, dynamic>) return inner;
 return obj;
 }
 return null;
 }

 // ================ matchfollow/Take effectfollowAPI ================

 /// footballmatchfollow
 /// POST /api/livespeed/football/match/subscribe data: {match_id}
 /// [matchId] - footballmatchID (int type, required)
 /// returns: bool whetherfollowsuccess
 Future<bool> subscribeFootballMatch({required int matchId}) async {
 return _postSubscribe(
 '/api/livespeed/football/match/subscribe',
 matchId: matchId,
);
 }

 /// footballmatchTake effectfollow
 /// POST /api/livespeed/football/match/unsubscribe data: {match_id}
 /// [matchId] - footballmatchID (int type, required)
 /// returns: bool whetherTake effectfollowsuccess
 Future<bool> unsubscribeFootballMatch({required int matchId}) async {
 return _postSubscribe(
 '/api/livespeed/football/match/unsubscribe',
 matchId: matchId,
);
 }

 /// basketballmatchfollow
 /// POST /api/livespeed/basketball/match/subscribe data: {match_id}
 /// [matchId] - basketball match ID (int type, required)
 /// returns: bool whetherfollowsuccess
 Future<bool> subscribeBasketballMatch({required int matchId}) async {
 return _postSubscribe(
 '/api/livespeed/basketball/match/subscribe',
 matchId: matchId,
);
 }

 /// basketballmatchTake effectfollow
 /// POST /api/livespeed/basketball/match/unsubscribe data: {match_id}
 /// [matchId] - basketball match ID (int type, required)
 /// returns: bool whetherTake effectfollowsuccess
 Future<bool> unsubscribeBasketballMatch({required int matchId}) async {
 return _postSubscribe(
 '/api/livespeed/basketball/match/unsubscribe',
 matchId: matchId,
);
 }

 /// follow/Take effectfollowcommon POST request
 /// [url] - request (String type)
 /// [matchId] - matchID (int type, required)
 /// returns: bool requestwhethersuccess
 Future<bool> _postSubscribe(String url, {required int matchId}) async {
 if (matchId == 0) return false;
 try {
 final resp =
 await BMNetworkManager().postRequest(url, data: {'match_id': matchId});
      return resp.isSuccess;
    } catch (_) {
      return false;
    }
  }
}
