import '../network/bm_network_manager.dart';
import '../models/bm_process_model.dart';
import '../models/bm_odds_model.dart';
import '../models/bm_lineup_model.dart';
import '../models/bm_h2h_model.dart';
import '../models/bm_player_info_model.dart';
import '../models/bm_team_info_model.dart';

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
  static final BMMatchDetailApiService _instance = BMMatchDetailApiService._internal();
  factory BMMatchDetailApiService() => _instance;
  BMMatchDetailApiService._internal();

  /// 请求比赛详情原始 Map (订阅状态等字段由页面自解析)
  ///   matchId: 比赛ID (int, 必传)
  Future<Map<String, dynamic>?> fetchMatchDetail({required int matchId}) async {
    final resp = await BMNetworkManager().getRequest(
      '/api/livespeed/football/match/detail',
      queryParameters: {'match_id': matchId},
    );
    if (resp.isSuccess && resp.data != null) return resp.data as Map<String, dynamic>;
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
  Future<Map<String, List<BMH2HMatch>>> fetchH2HSplitedData({required int matchId}) async {
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
          result['home'] = parseList(history['home'] ?? history['home_team'] ?? history['homeRecent']);
          result['away'] = parseList(history['away'] ?? history['away_team'] ?? history['awayRecent']);
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
        if (obj['name'] != null || obj['team_id'] != null || obj['teamId'] != null) {
          // 平铺直接返回
          return BMTeamInfo.fromJson(obj);
        }
      }
    } catch (_) {}
    return null;
  }

  // ================ 篮球详情接口 ================

  /// 请求篮球比赛详情原始 Map
  ///   GET /api/v1/livespeed/match/detail?match_id=
  ///   matchId: 篮球比赛ID (int, 必传)
  Future<Map<String, dynamic>?> fetchBasketballDetail({required int matchId}) async {
    final resp = await BMNetworkManager().getRequest(
      '/api/v1/livespeed/match/detail',
      queryParameters: {'match_id': matchId},
    );
    if (resp.isSuccess && resp.data != null) return resp.data as Map<String, dynamic>;
    return null;
  }
}
