import '../network/bm_network_manager.dart';
import '../models/bm_process_model.dart';
import '../models/bm_odds_model.dart';
import '../models/bm_lineup_model.dart';
import '../models/bm_h2h_model.dart';
import '../models/bm_player_info_model.dart';
import '../models/bm_team_info_model.dart';
import '../models/bm_basketball_vote_model.dart';

/// BMMatchDetailApiService - 足球比赛详情API服务
/// 接口路径配置 1:1 同 hanklive HankMatchDetailApiService (替身, 无需修改后端)
///   - GET /api/livespeed/football/match/detail     : 比赛详情 + 订阅状态
///   - GET /api/livespeed/football/match/process    : 比赛进程 (事件incidents + 统计stats)
///   - GET /api/livespeed/football/match/odds       : 指数列表 (AH/1X2/O/U/Corners)
///   - GET /api/livespeed/football/match/odd-histories : 指数历史
///   - GET /api/livespeed/football/match/lineup     : 首发阵容
///   - GET /api/livespeed/football/match/analysis   : H2H 历史交锋(history.vs)
///   - GET /api/livespeed/football/match/player-info: 球员信息(点击阵容头像弹出)
///   - GET /api/livespeed/football/team/data      : 球队信息(点击顶部球队头像弹出)
///   - POST /api/livespeed/football/match/subscribe : 订阅
///   - POST /api/livespeed/football/match/unsubscribe : 取消订阅
class BMMatchDetailApiService {
  /// 单例实例
  static final BMMatchDetailApiService _instance =
      BMMatchDetailApiService._internal();
  factory BMMatchDetailApiService() => _instance;
  BMMatchDetailApiService._internal();

  /// 请求比赛详情原始 Map (订阅状态等字段由页面自解析)
  ///   matchId: 比赛ID (int, 必传)
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

  /// 请求比赛进程数据 (事件incidents + 技术统计stats)
  ///   GET /api/livespeed/football/match/process
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

  /// 请求4种盘口赔率 (亚盘/欧赔/大小/角球)
  ///   GET /api/livespeed/football/match/odds
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

  /// 请求某博彩公司某场比赛的指数历史
  ///   GET /api/livespeed/football/match/odd-histories?match_id=&company_id=
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

  /// 请求首发阵容
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

  /// 请求足球比赛 H2H 历史交锋 (拆分：两队直接交锋 vs / 主队历史 / 客队历史)
  ///   GET /api/livespeed/football/match/analysis?match_id=
  ///   返回 Map: { 'vs': 两队对战列表, 'home': 主队近期比赛, 'away': 客队近期比赛 }
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

  /// 请求球员详细信息(点击阵容头像弹Sheet用)
  ///   GET /api/livespeed/football/match/player-info?player_id=&match_id=
  ///   playerId: 球员ID (int 必传, 来自阵容API player_id)
  ///   matchId: 比赛ID (int 必传, 当前比赛ID)
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

  /// 请求球队详细信息(点击顶部球队头像弹Sheet用)
  ///   GET /api/livespeed/football/team/data?team_id=
  ///   teamId: 球队ID (int 必传)
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
          // 包装型返回 {code/data/message} (用户给的标准格式)
          return BMTeamInfo.fromJson(inner);
        }
        if (obj['name'] != null ||
            obj['team_id'] != null ||
            obj['teamId'] != null) {
          // 平铺直接返回
          return BMTeamInfo.fromJson(obj);
        }
      }
    } catch (_) {}
    return null;
  }

  // ================ 篮球详情接口 ================

  /// 请求篮球比赛投票信息 (实况 Tab 投票比例数据源)
  ///   GET api/livespeed/basketball/match/vote-info?match_id=
  ///   matchId: 篮球比赛ID (int, 必传)
  ///   返回: data {home_votes, away_votes, vote_status}, 失败返回 null
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

  /// 提交篮球比赛投票 (实况 Tab 投票动作)
  ///   POST api/livespeed/basketball/match/vote  data: {match_id, team}
  ///   matchId: 篮球比赛ID (int, 必传)
  ///   team: 投票侧 (int, 1=主队 2=客队)
  ///   返回: bool 是否投票成功
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

  /// 请求篮球比赛进程数据 (一次请求返回 stats + tlive, 两 Tab 共用)
  ///   GET /api/livespeed/basketball/match/process?match_id=
  ///   matchId: 篮球比赛ID (int, 必传)
  ///   返回: data Map (含 stats 技术统计数组 + tlive 按节实况数组), 失败返回 null
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
        // 兼容 {code,data,message} 包装: 取内层 data
        final inner = obj['data'] is Map ? obj['data'] as Map<String, dynamic> : obj;
        return inner;
      }
    } catch (_) {}
    return null;
  }

  /// 请求篮球比赛详情原始 Map
  ///   GET /api/livespeed/football/match/detail?match_id= (篮球详情同 football 路径, 后端共用)
  ///   matchId: 篮球比赛ID (int, 必传)
  ///   返回: data Map (含 home_scores/away_scores 分节比分逗号串 / subscribed / odds 等)
  Future<Map<String, dynamic>?> fetchBasketballDetail({
    required int matchId,
  }) async {
    final resp = await BMNetworkManager().getRequest(
      '/api/livespeed/basketball/match/detail',
      queryParameters: {'match_id': matchId},
    );
    if (resp.isSuccess && resp.data != null) {
      final obj = resp.data as Map<String, dynamic>;
      // 兼容 {code,data,message} 包装: 取内层 data
      final inner = obj['data'];
      if (inner is Map<String, dynamic>) return inner;
      return obj;
    }
    return null;
  }

  // ================ 比赛关注/取消关注接口 ================

  /// 足球比赛关注
  ///   POST /api/livespeed/football/match/subscribe  data: {match_id}
  /// [matchId] - 足球比赛ID (int 类型, 必传)
  /// 返回: bool 是否关注成功
  Future<bool> subscribeFootballMatch({required int matchId}) async {
    return _postSubscribe(
      '/api/livespeed/football/match/subscribe',
      matchId: matchId,
    );
  }

  /// 足球比赛取消关注
  ///   POST /api/livespeed/football/match/unsubscribe  data: {match_id}
  /// [matchId] - 足球比赛ID (int 类型, 必传)
  /// 返回: bool 是否取消关注成功
  Future<bool> unsubscribeFootballMatch({required int matchId}) async {
    return _postSubscribe(
      '/api/livespeed/football/match/unsubscribe',
      matchId: matchId,
    );
  }

  /// 篮球比赛关注
  ///   POST /api/livespeed/basketball/match/subscribe  data: {match_id}
  /// [matchId] - 篮球比赛ID (int 类型, 必传)
  /// 返回: bool 是否关注成功
  Future<bool> subscribeBasketballMatch({required int matchId}) async {
    return _postSubscribe(
      '/api/livespeed/basketball/match/subscribe',
      matchId: matchId,
    );
  }

  /// 篮球比赛取消关注
  ///   POST /api/livespeed/basketball/match/unsubscribe  data: {match_id}
  /// [matchId] - 篮球比赛ID (int 类型, 必传)
  /// 返回: bool 是否取消关注成功
  Future<bool> unsubscribeBasketballMatch({required int matchId}) async {
    return _postSubscribe(
      '/api/livespeed/basketball/match/unsubscribe',
      matchId: matchId,
    );
  }

  /// 关注/取消关注通用 POST 请求
  /// [url] - 请求地址 (String 类型)
  /// [matchId] - 比赛ID (int 类型, 必传)
  /// 返回: bool 请求是否成功
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
