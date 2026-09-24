import 'package:flutter/foundation.dart';

import '../network/bm_network_manager.dart';
import '../models/bm_match_api_model.dart';
import '../models/bm_basketball_match_model.dart';
import '../models/bm_match_model.dart';
import '../models/bm_competition_model.dart';
import '../models/bm_competition_season_model.dart';
import '../models/bm_player_ability_model.dart';
import '../models/bm_player_rank_model.dart';
import '../theme/bm_colors.dart';

/// BMMatchApiService - matchlistAPIservice
/// purposescope: homefocus competition / competitionlistpage / leaguelist relatedAPI
class BMMatchApiService {
 /// singletoninstance (BMMatchApiService type)
 static final BMMatchApiService _instance = BMMatchApiService._internal();

 /// factory constructor, returnssingleton
 factory BMMatchApiService() {
 return _instance;
 }

 /// privateconstructor
 BMMatchApiService._internal();

 /// footballmatchAPIpath
 static const String _footballApiPath = '/api/livespeed/football/matches';

 /// basketballmatchAPIpath
 static const String _basketballApiPath = '/api/livespeed/basketball/matches';

 /// footballleaguelistAPIpath
 static const String _footballCompetitionPath =
 '/api/livespeed/football/competition/list';

 /// footballleagueseasonlistAPIpath
 static const String _footballSeasonListPath =
 '/api/livespeed/football/competition/season-list';

 /// footballleagueplayerrankingboardAPIpath
 static const String _footballPlayerRankPath =
 '/api/livespeed/football/competition/player-rank';

 /// footballplayerdetail(includesabilitypower)APIpath
 static const String _footballPlayerInfoPath = '/api/livespeed/football/info';

 /// requestfootballmatchlist (POST)
 /// [tab] - Tabtype, 4=follow, 0=Allall, 1=in progress, 5=point/recommended, 2=match, 3=FT
 /// [page] - page number (starting from 1)
 /// [size] - per pagecount
 /// [timestamp] - datetimestamp (int type, secondlevel)
 /// [competitionIds] - leagueIDfilterlist, empty=no filter
 /// returns: BMMatchData?
 Future<BMMatchData?> fetchFootballMatches({
 int tab = 5,
 int page = 1,
 int size = 1,
 int? timestamp,
 List<int> competitionIds = const [],
 }) async {
 final data = <String, dynamic>{
 'tab': tab,
      'page': page,
      'size': size,
      'competition_ids': competitionIds,
    };
    if (timestamp != null) {
      data['timestamp'] = timestamp;
    }

    final response = await BMNetworkManager().postRequest(
      _footballApiPath,
      data: data,
    );

    if (response.isSuccess && response.data != null) {
      try {
        if (response.data is Map<String, dynamic>) {
          return BMMatchData.fromJson(response.data as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('BMMatchApiService footballdataparseexception: $e');
 }
 }

 return null;
 }

 /// requestbasketballmatchlist (POST)
 /// [tab] - Tabtype, samefootball
 /// [page] - page number (starting from 1)
 /// [size] - per pagecount
 /// [timestamp] - datetimestamp (int type, secondlevel)
 /// [competitionIds] - leagueIDfilterlist, empty=no filter
 /// returns: BMBasketballMatchData?
 Future<BMBasketballMatchData?> fetchBasketballMatches({
 int tab = 5,
 int page = 1,
 int size = 1,
 int? timestamp,
 List<int> competitionIds = const [],
 }) async {
 final data = <String, dynamic>{
 'tab': tab,
      'page': page,
      'size': size,
      'competition_ids': competitionIds,
    };
    if (timestamp != null) {
      data['timestamp'] = timestamp;
    }

    final response = await BMNetworkManager().postRequest(
      _basketballApiPath,
      data: data,
    );

    if (response.isSuccess && response.data != null) {
      try {
        if (response.data is Map<String, dynamic>) {
          return BMBasketballMatchData.fromJson(
            response.data as Map<String, dynamic>,
          );
        }
      } catch (e) {
        debugPrint('BMMatchApiService basketballdataparseexception: $e');
 }
 }

 return null;
 }

 /// takefootballallmatchlistandconvertasUImodel (tab=0, competitionlistpageusage)
 /// [timestamp] - datetimestamp (secondlevel, can be empty)
 /// [page] - page number, default1
 /// [size] - per pagecount, default10 (alignmenthanklive)
 /// [competitionIds] - leagueIDfilterlist, empty=no filter
 Future<List<BMMatchModel>> fetchFootballList({
 int? timestamp,
 int page = 1,
 int size = 10,
 List<int> competitionIds = const [],
 }) async {
 debugPrint(
 '🏟️ BMMatchApiService.fetchFootballList send: tab=0, page=$page, size=$size, ts=$timestamp',
    );
    final data = await fetchFootballMatches(
      tab: 0,
      page: page,
      size: size,
      timestamp: timestamp,
      competitionIds: competitionIds,
    );
    debugPrint(
      '🏟️  BMMatchApiService.fetchFootballList returns: data == null ? ${data == null}, results.length = ${data?.results.length ?? -1}',
    );
    if (data == null || data.results.isEmpty) return [];
    final List<BMMatchModel> list = [];
    for (final item in data.results) {
      try {
        list.add(_convertFootballMatch(item));
      } catch (e) {
        debugPrint('BMMatchApiService footballsingleconvertskipexception: $e');
      }
    }
    debugPrint(
      '🏟️ BMMatchApiService.fetchFootballList UImodelcount: ${list.length}',
);
 return list;
 }

 /// takebasketballallmatchlistandconvertasUImodel (tab=0, competitionlistpageusage)
 /// [timestamp] - datetimestamp (secondlevel, can be empty)
 /// [page] - page number, default1
 /// [size] - per pagecount, default10 (alignmenthanklive)
 /// [competitionIds] - leagueIDfilterlist, empty=no filter
 Future<List<BMMatchModel>> fetchBasketballList({
 int? timestamp,
 int page = 1,
 int size = 10,
 List<int> competitionIds = const [],
 }) async {
 debugPrint(
 '🏀 BMMatchApiService.fetchBasketballList send: tab=0, page=$page, size=$size, ts=$timestamp',
    );
    final data = await fetchBasketballMatches(
      tab: 0,
      page: page,
      size: size,
      timestamp: timestamp,
      competitionIds: competitionIds,
    );
    debugPrint(
      '🏀 BMMatchApiService.fetchBasketballList returns: data == null ? ${data == null}, results.length = ${data?.results.length ?? -1}',
    );
    if (data == null || data.results.isEmpty) return [];
    final List<BMMatchModel> list = [];
    for (final item in data.results) {
      try {
        list.add(_convertBasketballMatch(item));
      } catch (e) {
        debugPrint('BMMatchApiService basketballsingleconvertskipexception: $e');
      }
    }
    debugPrint(
      '🏀 BMMatchApiService.fetchBasketballList UImodelcount: ${list.length}',
);
 return list;
 }

 /// requestpointfootballmatchandconvertasUImodel (homeusage)
 /// returns: BMMatchModel? (singleitems, takeNo. oneitems)
 Future<BMMatchModel?> fetchFeaturedFootballMatch() async {
 final data = await fetchFootballMatches(tab: 5, page: 1, size: 1);
 if (data == null || data.results.isEmpty) return null;
 return _convertFootballMatch(data.results.first);
 }

 /// requestpointbasketballmatchandconvertasUImodel (homeusage)
 /// returns: BMMatchModel? (singleitems, takeNo. oneitems)
 Future<BMMatchModel?> fetchFeaturedBasketballMatch() async {
 final data = await fetchBasketballMatches(tab: 5, page: 1, size: 1);
 if (data == null || data.results.isEmpty) return null;
 return _convertBasketballMatch(data.results.first);
 }

 /// footballAPImodel -> UImodel convert (alignmenthanklive HankMatchApiService.convertToMatchModel)
 BMMatchModel _convertFootballMatch(BMMatchItem item) {
 final status = _footballStatusFromId(item.statusId);
 // score: alignmenthanklive, not started/TBDkeepnullnotfalse0, LIVE/FT 0-0alsoallownull
 final int? homeScore = item.homeNormalScore;
 final int? awayScore = item.awayNormalScore;
 // matchTime: LIVEstateprioritydisplayminutes, otherwise thenformatasHH:mm
 final String timeStr;
 if (status == BMMatchStatus.live && (item.minutes ?? '').isNotEmpty) {
      timeStr = item.minutes!;
    } else {
      timeStr = _formatMatchTime(item.matchTime);
    }
    String? half;
    if (item.homeHalfScore != null || item.awayHalfScore != null) {
      half = 'half ${item.homeHalfScore ?? 0}-${item.awayHalfScore ?? 0}';
    }
    return BMMatchModel(
      matchId: item.matchId?.toString() ?? '',
      leagueName: item.competitionName ?? '',
 leagueColor: BMColors.orange.toARGB32(),
 homeTeam: BMTeamModel(
 teamId: item.homeTeamId?.toString(),
 teamName: item.homeTeamName,
 teamShort: _extractShort(item.homeTeamName),
 logoUrl: item.homeTeamLogo,
),
 awayTeam: BMTeamModel(
 teamId: item.awayTeamId?.toString(),
 teamName: item.awayTeamName,
 teamShort: _extractShort(item.awayTeamName),
 logoUrl: item.awayTeamLogo,
),
 homeScore: homeScore,
 awayScore: awayScore,
 matchTime: timeStr,
 status: status,
 statusId: item.statusId,
 statusName: item.statusName,
 sportType: BMMatchSportType.football,
 liveMinute: status == BMMatchStatus.live ? item.minutes: null,
 halfTimeScore: half,
 goalEvents: const [],
 isFeatured: status == BMMatchStatus.live, // alignmenthanklive: LIVE=featuredlargecard
 isFollowed: item.subscribed ?? false,
 matchTag: item.stageName,
 round: item.stageName,
);
 }

 /// byOCaccumulatebasketballper-quarter score (splitcomma No.passsum)
 /// OC: NSArray *a=[str componentsSeparatedByString:@","]; for(NSString*s in a) count+=[s integerValue];
  int _sumBasketballScores(String? scoresStr) {
    if (scoresStr == null || scoresStr.isEmpty) return 0;
    final arr = scoresStr.split(',');
 int count = 0;
 for (final sub in arr) {
 final trimmed = sub.trim();
 if (trimmed.isEmpty) continue;
 count += int.tryParse(trimmed) ?? 0;
 }
 return count;
 }

 /// basketballAPImodel -> UImodel convert (alignmenthanklive)
 BMMatchModel _convertBasketballMatch(BMBasketballMatchItem item) {
 final status = _basketballStatusFromId(item.statusId);
 // byOC: comma No.minper-quarter scoreaccumulate
 final int homeScore = _sumBasketballScores(item.homeScores);
 final int awayScore = _sumBasketballScores(item.awayScores);
 final String timeStr = _formatMatchTime(item.matchTime);
 return BMMatchModel(
 matchId: item.id?.toString() ?? '',
      leagueName: item.competitionName ?? '',
 leagueColor: BMColors.orange.toARGB32(),
 homeTeam: BMTeamModel(
 teamId: item.homeTeamId?.toString(),
 teamName: item.homeTeamName,
 teamShort: _extractShort(item.homeTeamName),
 logoUrl: item.homeTeamLogo,
),
 awayTeam: BMTeamModel(
 teamId: item.awayTeamId?.toString(),
 teamName: item.awayTeamName,
 teamShort: _extractShort(item.awayTeamName),
 logoUrl: item.awayTeamLogo,
),
 homeScore: homeScore,
 awayScore: awayScore,
 matchTime: timeStr,
 status: status,
 statusId: item.statusId,
 statusName: item.statusName,
 sportType: BMMatchSportType.basketball,
 liveMinute: status == BMMatchStatus.live ? item.stageName: null,
 halfTimeScore: null,
 goalEvents: const [],
 isFeatured: status == BMMatchStatus.live,
 isFollowed: item.subscribed ?? false,
 matchTag: item.stageName,
 round: item.stageName,
);
 }

 /// footballstatemapping: statusId → BMMatchStatus
 /// 1=NS, 2|3|4|5|7=in progress, 8=FT, 0|9|10|11|12|13=TBD
 BMMatchStatus _footballStatusFromId(int? statusId) {
 switch (statusId) {
 case 1:
 return BMMatchStatus.upcoming;
 case 2:
 case 3:
 case 4:
 case 5:
 case 7:
 return BMMatchStatus.live;
 case 8:
 return BMMatchStatus.ended;
 case 0:
 case 9:
 case 10:
 case 11:
 case 12:
 case 13:
 return BMMatchStatus.tbd;
 default:
 return BMMatchStatus.tbd;
 }
 }

 /// basketballstatemapping: statusId → BMMatchStatus
 /// 1|13=NS, 2|3|4|5|6|7|8|9=in progress, 10|11=FT, 0|12|14|15=TBD
 BMMatchStatus _basketballStatusFromId(int? statusId) {
 switch (statusId) {
 case 1:
 case 13:
 return BMMatchStatus.upcoming;
 case 2:
 case 3:
 case 4:
 case 5:
 case 6:
 case 7:
 case 8:
 case 9:
 return BMMatchStatus.live;
 case 10:
 case 11:
 return BMMatchStatus.ended;
 case 0:
 case 12:
 case 14:
 case 15:
 return BMMatchStatus.tbd;
 default:
 return BMMatchStatus.tbd;
 }
 }

 /// formatmatch timestamp -> HH:mm
 String _formatMatchTime(int? timestamp) {
 if (timestamp == null || timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
 }

 /// taketeam nameabbreviation (3position)
 String _extractShort(String? name) {
 if (name == null || name.isEmpty) return '';
 if (name.length <= 3) return name.toUpperCase();
 return name.substring(0, 3).toUpperCase();
 }

 /// requestfootballleague(competition)list (GET noneinput)
 /// API: /api/livespeed/football/competition/list
 /// Dio rawresponse: {code:int, data:List<{id,name,cap,main}>, message:String?}
 /// ⚠️ key: BMNetworkManager._parseResponse (bm_network_manager.dart:149-153) alreadyautounwraponelayer
 /// => BMApiResponse.code = outer code
 /// => BMApiResponse.data = outer data (leaguearraythisheight!)
 /// => BMApiResponse.isSuccess = code == 0
 /// correctnotabilitytake response.data againwhen {code,data} Map parse, otherwise then data(yesList) is! Map -> return [] farempty
 /// parserule: isSuccess && data is List -> single for loop try-catch convert, 1itemsbaddataskiptheitemsnotimpactwhole
 /// returns: always non null, outputwrong/emptydatareturnsemptyarray[]
 Future<List<BMCompetitionModel>> fetchCompetitionList() async {
 debugPrint('🌐 BMMatchApiService requestfootballleaguelist GET $_footballCompetitionPath (alreadybynetworklayerautounwrap)');
    final response = await BMNetworkManager().getRequest(
      _footballCompetitionPath,
    );

    if (!response.isSuccess || response.data == null) {
      debugPrint(
        '❌ BMMatchApiService footballleaguelistrequest failure: '
        'isSuccess=${response.isSuccess}, code=${response.code}, msg=${response.message}',
);
 return const [];
 }

 try {
 // BMApiResponse.data alreadyyesouter {code,data:[...]} of data innerpartvalue = List<league> thisheight
 final data = response.data;
 if (data is! List) {
 debugPrint(
 '❌ BMMatchApiService footballleague response.data notyesList '
          '(checkBMNetworkManagerunwraplogic): actual type=${data.runtimeType}, data=$data',
        );
        return const [];
      }
      final List<BMCompetitionModel> result = [];
      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        try {
          if (item is Map<String, dynamic>) {
            final m = BMCompetitionModel.fromMap(item);
            if (m != null) {
              result.add(m);
              debugPrint('⚽️ leagueparsesuccess[${result.length}/${data.length}] '
                  'id=${m.id}, name=${m.name}, cap=${m.cap}, main=${m.main}');
            } else {
              debugPrint('⚠️ skip league item: id/name missing or null, item=$item');
            }
          } else {
            debugPrint('⚠️ skip league item: data not a Map<String,dynamic>, , '
                'type=${item.runtimeType}, item=$item');
          }
        } catch (e) {
          debugPrint('⚠️ skip league item parse exception: $e, item=$item');
 }
 }
 // sort: main=1 of homeleaguepinned, itsremainingbynameindex
 result.sort((a, b) {
 if (b.main != a.main) return b.main.compareTo(a.main);
 return a.name.compareTo(b.name);
 });
 debugPrint('✅ BMMatchApiService footballleaguelistparsedone: '
          'raw${data.length}items => success${result.length}items');
      return result;
    } catch (e) {
      debugPrint('❌ BMMatchApiService footballleaguelisttotal parse exception: $e');
 return const [];
 }
 }

 /// requestspecified league of seasonlist (GET)
 /// API: /api/livespeed/football/competition/season-list
 /// [competitionId] - leagueuniqueID (from BMCompetitionModel.id gettake)
 /// returns: always non null, outputwrong/emptydata returnsemptyarray[]; arrayalreadyby hanklive rule: isCurrent=1 of seasonpriority (nonecurrentseasonthenkeeporiginalorder)
 Future<List<BMCompetitionSeasonModel>> fetchSeasonList({
 required int competitionId,
 }) async {
 debugPrint(
 '🌐 BMMatchApiService requestleagueseasonlist GET $_footballSeasonListPath '
      'competitionId=$competitionId',
    );
    final params = <String, dynamic>{
      'competition_id': competitionId,
    };
    final response = await BMNetworkManager().getRequest(
      _footballSeasonListPath,
      queryParameters: params,
    );

    if (!response.isSuccess || response.data == null) {
      debugPrint(
        '❌ BMMatchApiService leagueseasonlistrequest failure: '
        'competitionId=$competitionId, isSuccess=${response.isSuccess}, '
        'code=${response.code}, msg=${response.message}',
);
 return const [];
 }

 try {
 // BMApiResponse.data alreadyby BMNetworkManager unwrap = outer data (seasonarraythisheight!)
 final data = response.data;
 if (data is! List) {
 debugPrint(
 '❌ BMMatchApiService leagueseason response.data notyesList: '
          'actual type=${data.runtimeType}, data=$data',
        );
        return const [];
      }
      final List<BMCompetitionSeasonModel> result = [];
      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        try {
          if (item is Map<String, dynamic>) {
            final m = BMCompetitionSeasonModel.fromMap(item);
            if (m != null) {
              result.add(m);
              debugPrint(
                '📅 seasonparsesuccess[${result.length}/${data.length}] '
                'seasonId=${m.seasonId}, year=${m.year}, isCurrent=${m.isCurrent}',
              );
            } else {
              debugPrint('⚠️ skip season item: season_id missing, item=$item');
            }
          } else {
            debugPrint('⚠️ skip season item: data not a Map<String,dynamic>, , '
                'type=${item.runtimeType}, item=$item');
          }
        } catch (e) {
          debugPrint('⚠️ skip season item parse exception: $e, item=$item');
 }
 }
 // ⭐️ reference hanklive: isCurrent=1 of seasonorderfirst
 result.sort((a, b) => b.isCurrent.compareTo(a.isCurrent));
 debugPrint('✅ BMMatchApiService leagueseasonlistparsedone: '
          'raw${data.length}items => success${result.length}items, seasonid=${result.isEmpty ? 0: result.first.seasonId}');
      return result;
    } catch (e) {
      debugPrint('❌ BMMatchApiService leagueseasonlisttotal parse exception: $e');
 return const [];
 }
 }

 /// requestspecified league+seasonlower of playerrankingboard (GET)
 /// API: /api/livespeed/football/competition/player-rank
 /// [competitionId] - leagueuniqueID (required)
 /// [seasonId] - season ID (int type, default 20261 = compatibleoldcall, toolpagechange aspassseasonlistitemsid)
 /// [key] - datadegree (String type, default k_goals = compatibleoldcall, toolpagechange as k_shots_on = center)
 /// ⚠️ BMNetworkManager._parseResponse alreadyautounwrap => BMApiResponse.data = outer data (playerarraythisheight!)
 /// returns: always non null, outputwrong/emptydata returnsemptyarray[]
 Future<List<BMPlayerRankModel>> fetchPlayerRank({
 required int competitionId,
 int seasonId = 20261,
 String key = 'k_goals',
  }) async {
    debugPrint(
      '🌐 BMMatchApiService requestleagueplayerranking GET $_footballPlayerRankPath '
      'competitionId=$competitionId, seasonId=$seasonId, key=$key',
    );
    final params = <String, dynamic>{
      'competition_id': competitionId,
      'season_id': seasonId,
      'key': key,
    };
    final response = await BMNetworkManager().getRequest(
      _footballPlayerRankPath,
      queryParameters: params,
    );

    if (!response.isSuccess || response.data == null) {
      debugPrint(
        '❌ BMMatchApiService leagueplayerrankingrequest failure: '
        'competitionId=$competitionId, seasonId=$seasonId, key=$key, '
        'isSuccess=${response.isSuccess}, code=${response.code}, msg=${response.message}',
      );
      return const [];
    }

    try {
      final data = response.data;
      if (data is! List) {
        debugPrint(
          '❌ BMMatchApiService leagueplayerranking response.data notyesList: '
          'actual type=${data.runtimeType}, data=$data',
        );
        return const [];
      }
      final List<BMPlayerRankModel> result = [];
      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        try {
          if (item is Map<String, dynamic>) {
            final m = BMPlayerRankModel.fromMap(item);
            if (m != null) {
              result.add(m);
              debugPrint(
                '🏆 playerrankingparsesuccess[${result.length}/${data.length}] '
                'pos=${m.position}, name=${m.playerName}, team=${m.teamName}, total=${m.total}',
              );
            } else {
              debugPrint('⚠️ skip player item: player_id/player_name/position/total missing, item=$item');
            }
          } else {
            debugPrint('⚠️ skip player item: data not a Map<String,dynamic>, , '
                'type=${item.runtimeType}, item=$item');
          }
        } catch (e) {
          debugPrint('⚠️ skip player ranking item parse exception: $e, item=$item');
 }
 }
 // by position indexsort (No. 1namefirst)
 result.sort((a, b) => a.position.compareTo(b.position));
 debugPrint('✅ BMMatchApiService leagueplayerrankingparsedone: '
          'raw${data.length}items => success${result.length}items');
      return result;
    } catch (e) {
      debugPrint('❌ BMMatchApiService leagueplayerrankingtotal parse exception: $e');
 return const [];
 }
 }

 /// requestsingleitemsplayer of detailinfo + abilitypowerdata (GET)
 /// API: /api/livespeed/football/info (reference hank_player_detail_page.dart line 62)
 /// [playerId] - playeruniqueID (required, fromplayerrankinglist playerId fieldgettake)
 /// Dio rawresponse: {code:int, data:Map{id,name_zh,...,ability:{att,tec,sta,def,pow,spd,...}}, message:String?}
 /// ⚠️ BMNetworkManager._parseResponse alreadyautounwrap => BMApiResponse.data = outer data (playerdetailMapthisheight!)
 /// returns: BMPlayerAbilityModel?, parsefailure/abilityasempty/illegal -> return null
 Future<BMPlayerAbilityModel?> fetchPlayerAbility({
 required int playerId,
 String? playerNameHint,
 }) async {
 debugPrint(
 '🌐 BMMatchApiService requestplayerdetail+abilitypower GET $_footballPlayerInfoPath '
      'id=$playerId, hintName=$playerNameHint',
    );
    final params = <String, dynamic>{
      'id': playerId,
    };
    final response = await BMNetworkManager().getRequest(
      _footballPlayerInfoPath,
      queryParameters: params,
    );

    if (!response.isSuccess || response.data == null) {
      debugPrint(
        '❌ BMMatchApiService playerdetailrequest failure: id=$playerId, '
        'isSuccess=${response.isSuccess}, code=${response.code}, msg=${response.message}',
);
 return null;
 }

 try {
 // BMApiResponse.data alreadyby BMNetworkManager unwrap = outer data (playerdetailMap!)
 final data = response.data;
 if (data is! Map<String, dynamic>) {
 debugPrint(
 '❌ BMMatchApiService playerdetail response.data not a Map: '
          'actual type=${data.runtimeType}, data=$data',
        );
        return null;
      }
      final model = BMPlayerAbilityModel.fromPlayerDataMap(
        data,
        playerId: playerId,
        playerName: playerNameHint,
      );
      if (model == null) {
        debugPrint('⚠️ BMMatchApiService player $playerId ability power model parse failure, data=$data');
        return null;
      }
      debugPrint(
        '✅ BMMatchApiService player$playerId abilitypowerparsesuccess: '
        'name=${model.playerName}, ATT=${model.att}, TEC=${model.tec}, '
        'STA=${model.sta}, DEF=${model.def}, POW=${model.pow}, SPD=${model.spd}',
      );
      return model;
    } catch (e) {
      debugPrint('❌ BMMatchApiService playerdetailtotal parse exception: $e');
      return null;
    }
  }
}
