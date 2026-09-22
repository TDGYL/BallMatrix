import 'package:flutter/foundation.dart';

import '../network/bm_network_manager.dart';
import '../models/bm_match_api_model.dart';
import '../models/bm_basketball_match_model.dart';
import '../models/bm_match_model.dart';
import '../models/bm_competition_model.dart';
import '../models/bm_competition_season_model.dart';
import '../models/bm_player_rank_model.dart';
import '../theme/bm_colors.dart';

/// BMMatchApiService - 比赛列表API服务
/// 作用范围: 首页焦点赛事 / 赛事列表页 / 联赛列表 相关接口
class BMMatchApiService {
  /// 单例实例 (BMMatchApiService 类型)
  static final BMMatchApiService _instance = BMMatchApiService._internal();

  /// 工厂构造函数, 返回单例
  factory BMMatchApiService() {
    return _instance;
  }

  /// 私有构造函数
  BMMatchApiService._internal();

  /// 足球比赛API路径
  static const String _footballApiPath = '/api/livespeed/football/matches';

  /// 篮球比赛API路径
  static const String _basketballApiPath = '/api/livespeed/basketball/matches';

  /// 足球联赛列表API路径
  static const String _footballCompetitionPath =
      '/api/livespeed/football/competition/list';

  /// 足球联赛赛季列表API路径
  static const String _footballSeasonListPath =
      '/api/livespeed/football/competition/season-list';

  /// 足球联赛球员排行榜API路径
  static const String _footballPlayerRankPath =
      '/api/livespeed/football/competition/player-rank';

  /// 请求足球比赛列表 (POST)
  /// [tab] - Tab类型, 4=关注, 0=All全部, 1=进行中, 5=焦点/推荐, 2=赛程, 3=已结束
  /// [page] - 页码 (从1开始)
  /// [size] - 每页数量
  /// [timestamp] - 日期时间戳 (int 类型, 秒级)
  /// [competitionIds] - 联赛ID过滤列表, 空=不过滤
  /// 返回: BMMatchData?
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
        debugPrint('BMMatchApiService 足球数据解析异常: $e');
      }
    }

    return null;
  }

  /// 请求篮球比赛列表 (POST)
  /// [tab] - Tab类型, 同足球
  /// [page] - 页码 (从1开始)
  /// [size] - 每页数量
  /// [timestamp] - 日期时间戳 (int 类型, 秒级)
  /// [competitionIds] - 联赛ID过滤列表, 空=不过滤
  /// 返回: BMBasketballMatchData?
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
        debugPrint('BMMatchApiService 篮球数据解析异常: $e');
      }
    }

    return null;
  }

  /// 拉取足球全部比赛列表并转为UI模型 (tab=0, 赛事列表页用)
  /// [timestamp] - 日期时间戳 (秒级, 可空)
  /// [page] - 页码, 默认1
  /// [size] - 每页条数, 默认10 (对齐hanklive)
  /// [competitionIds] - 联赛ID过滤列表, 空=不过滤
  Future<List<BMMatchModel>> fetchFootballList({
    int? timestamp,
    int page = 1,
    int size = 10,
    List<int> competitionIds = const [],
  }) async {
    debugPrint(
      '🏟️  BMMatchApiService.fetchFootballList 发起: tab=0, page=$page, size=$size, ts=$timestamp',
    );
    final data = await fetchFootballMatches(
      tab: 0,
      page: page,
      size: size,
      timestamp: timestamp,
      competitionIds: competitionIds,
    );
    debugPrint(
      '🏟️  BMMatchApiService.fetchFootballList 返回: data == null ? ${data == null}, results.length = ${data?.results.length ?? -1}',
    );
    if (data == null || data.results.isEmpty) return [];
    final List<BMMatchModel> list = [];
    for (final item in data.results) {
      try {
        list.add(_convertFootballMatch(item));
      } catch (e) {
        debugPrint('BMMatchApiService 足球单条转换跳过异常: $e');
      }
    }
    debugPrint(
      '🏟️  BMMatchApiService.fetchFootballList UI模型数: ${list.length}',
    );
    return list;
  }

  /// 拉取篮球全部比赛列表并转为UI模型 (tab=0, 赛事列表页用)
  /// [timestamp] - 日期时间戳 (秒级, 可空)
  /// [page] - 页码, 默认1
  /// [size] - 每页条数, 默认10 (对齐hanklive)
  /// [competitionIds] - 联赛ID过滤列表, 空=不过滤
  Future<List<BMMatchModel>> fetchBasketballList({
    int? timestamp,
    int page = 1,
    int size = 10,
    List<int> competitionIds = const [],
  }) async {
    debugPrint(
      '🏀 BMMatchApiService.fetchBasketballList 发起: tab=0, page=$page, size=$size, ts=$timestamp',
    );
    final data = await fetchBasketballMatches(
      tab: 0,
      page: page,
      size: size,
      timestamp: timestamp,
      competitionIds: competitionIds,
    );
    debugPrint(
      '🏀 BMMatchApiService.fetchBasketballList 返回: data == null ? ${data == null}, results.length = ${data?.results.length ?? -1}',
    );
    if (data == null || data.results.isEmpty) return [];
    final List<BMMatchModel> list = [];
    for (final item in data.results) {
      try {
        list.add(_convertBasketballMatch(item));
      } catch (e) {
        debugPrint('BMMatchApiService 篮球单条转换跳过异常: $e');
      }
    }
    debugPrint(
      '🏀 BMMatchApiService.fetchBasketballList UI模型数: ${list.length}',
    );
    return list;
  }

  /// 请求焦点足球比赛并转换为UI模型 (首页用)
  /// 返回: BMMatchModel? (单条, 取第一条)
  Future<BMMatchModel?> fetchFeaturedFootballMatch() async {
    final data = await fetchFootballMatches(tab: 5, page: 1, size: 1);
    if (data == null || data.results.isEmpty) return null;
    return _convertFootballMatch(data.results.first);
  }

  /// 请求焦点篮球比赛并转换为UI模型 (首页用)
  /// 返回: BMMatchModel? (单条, 取第一条)
  Future<BMMatchModel?> fetchFeaturedBasketballMatch() async {
    final data = await fetchBasketballMatches(tab: 5, page: 1, size: 1);
    if (data == null || data.results.isEmpty) return null;
    return _convertBasketballMatch(data.results.first);
  }

  /// 足球API模型 -> UI模型 转换 (对齐hanklive HankMatchApiService.convertToMatchModel)
  BMMatchModel _convertFootballMatch(BMMatchItem item) {
    final status = _footballStatusFromId(item.statusId);
    // 比分: 对齐hanklive, 未开赛/待定保持null不填假0, LIVE/已结束 0-0也允许null
    final int? homeScore = item.homeNormalScore;
    final int? awayScore = item.awayNormalScore;
    // matchTime: LIVE状态优先显示minutes, 否则格式化为HH:mm
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
      liveMinute: status == BMMatchStatus.live ? item.minutes : null,
      halfTimeScore: half,
      goalEvents: const [],
      isFeatured: status == BMMatchStatus.live, // 对齐hanklive: LIVE=featured大卡
      isFollowed: item.subscribed ?? false,
      matchTag: item.stageName,
      round: item.stageName,
    );
  }

  /// 按OC语法累加篮球各节比分 (split逗号遍历求和)
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

  /// 篮球API模型 -> UI模型 转换 (对齐hanklive)
  BMMatchModel _convertBasketballMatch(BMBasketballMatchItem item) {
    final status = _basketballStatusFromId(item.statusId);
    // 按OC语法: 逗号分隔各节比分累加
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
      liveMinute: status == BMMatchStatus.live ? item.stageName : null,
      halfTimeScore: null,
      goalEvents: const [],
      isFeatured: status == BMMatchStatus.live,
      isFollowed: item.subscribed ?? false,
      matchTag: item.stageName,
      round: item.stageName,
    );
  }

  /// 足球状态映射: statusId → BMMatchStatus
  /// 1=未开始, 2|3|4|5|7=进行中, 8=已结束, 0|9|10|11|12|13=TBD
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

  /// 篮球状态映射: statusId → BMMatchStatus
  /// 1|13=未开始, 2|3|4|5|6|7|8|9=进行中, 10|11=已结束, 0|12|14|15=TBD
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

  /// 格式化比赛时间戳 -> HH:mm
  String _formatMatchTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 提取队名缩写 (3位)
  String _extractShort(String? name) {
    if (name == null || name.isEmpty) return '';
    if (name.length <= 3) return name.toUpperCase();
    return name.substring(0, 3).toUpperCase();
  }

  /// 请求足球联赛(赛事)列表 (GET 无入参)
  /// 接口: /api/livespeed/football/competition/list
  /// Dio 原始响应: {code:int, data:List<{id,name,cap,main}>, message:String?}
  /// ⚠️ 关键: BMNetworkManager._parseResponse (bm_network_manager.dart:149-153) 已自动解包一层
  ///     => BMApiResponse.code = 外层 code
  ///     => BMApiResponse.data = 外层 data (联赛数组本身!)
  ///     => BMApiResponse.isSuccess = code == 0
  /// 绝对不能把 response.data 再当 {code,data} Map 解析, 否则 data(是List) is! Map -> return [] 永远空
  /// 解析规则: isSuccess && data is List -> 单条 for 循环 try-catch 转换, 1条坏数据跳过该条不影响整批
  /// 返回: 永远非 null, 出错/空数据返回空数组[]
  Future<List<BMCompetitionModel>> fetchCompetitionList() async {
    debugPrint('🌐 BMMatchApiService 请求足球联赛列表 GET $_footballCompetitionPath (已由网络层自动解包)');
    final response = await BMNetworkManager().getRequest(
      _footballCompetitionPath,
    );

    if (!response.isSuccess || response.data == null) {
      debugPrint(
        '❌ BMMatchApiService 足球联赛列表请求失败: '
        'isSuccess=${response.isSuccess}, code=${response.code}, msg=${response.message}',
      );
      return const [];
    }

    try {
      // BMApiResponse.data 已经是外层 {code,data:[...]} 的 data 内部值 = List<联赛> 本身
      final data = response.data;
      if (data is! List) {
        debugPrint(
          '❌ BMMatchApiService 足球联赛 response.data 不是List '
          '(请检查BMNetworkManager解包逻辑): 实际类型=${data.runtimeType}, data=$data',
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
              debugPrint('⚽️ 联赛解析成功[${result.length}/${data.length}] '
                  'id=${m.id}, name=${m.name}, cap=${m.cap}, main=${m.main}');
            } else {
              debugPrint('⚠️ 跳过第$i条联赛: id/name字段缺失或为null, item=$item');
            }
          } else {
            debugPrint('⚠️ 跳过第$i条联赛: 数据不是Map<String,dynamic>, '
                '类型=${item.runtimeType}, item=$item');
          }
        } catch (e) {
          debugPrint('⚠️ 跳过第$i条联赛解析异常: $e, item=$item');
        }
      }
      // 排序: main=1的主流联赛置顶, 其余按name升序
      result.sort((a, b) {
        if (b.main != a.main) return b.main.compareTo(a.main);
        return a.name.compareTo(b.name);
      });
      debugPrint('✅ BMMatchApiService 足球联赛列表解析完成: '
          '原始${data.length}条 => 成功${result.length}条');
      return result;
    } catch (e) {
      debugPrint('❌ BMMatchApiService 足球联赛列表总解析异常: $e');
      return const [];
    }
  }

  /// 请求指定联赛的赛季列表 (GET)
  /// 接口: /api/livespeed/football/competition/season-list
  /// [competitionId] - 联赛唯一ID (从 BMCompetitionModel.id 获取)
  /// 返回: 永远非 null, 出错/空数据 返回空数组[]; 数组已按 hanklive 规则: isCurrent=1 的赛季优先 (无当前赛季则保持原顺序)
  Future<List<BMCompetitionSeasonModel>> fetchSeasonList({
    required int competitionId,
  }) async {
    debugPrint(
      '🌐 BMMatchApiService 请求联赛赛季列表 GET $_footballSeasonListPath '
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
        '❌ BMMatchApiService 联赛赛季列表请求失败: '
        'competitionId=$competitionId, isSuccess=${response.isSuccess}, '
        'code=${response.code}, msg=${response.message}',
      );
      return const [];
    }

    try {
      // BMApiResponse.data 已由 BMNetworkManager 解包 = 外层 data (赛季数组本身!)
      final data = response.data;
      if (data is! List) {
        debugPrint(
          '❌ BMMatchApiService 联赛赛季 response.data 不是List: '
          '实际类型=${data.runtimeType}, data=$data',
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
                '📅 赛季解析成功[${result.length}/${data.length}] '
                'seasonId=${m.seasonId}, year=${m.year}, isCurrent=${m.isCurrent}',
              );
            } else {
              debugPrint('⚠️ 跳过第$i条赛季: season_id字段缺失, item=$item');
            }
          } else {
            debugPrint('⚠️ 跳过第$i条赛季: 数据不是Map<String,dynamic>, '
                '类型=${item.runtimeType}, item=$item');
          }
        } catch (e) {
          debugPrint('⚠️ 跳过第$i条赛季解析异常: $e, item=$item');
        }
      }
      // ⭐️ 参考 hanklive: isCurrent=1 的赛季排最前
      result.sort((a, b) => b.isCurrent.compareTo(a.isCurrent));
      debugPrint('✅ BMMatchApiService 联赛赛季列表解析完成: '
          '原始${data.length}条 => 成功${result.length}条, 首赛季id=${result.isEmpty ? 0 : result.first.seasonId}');
      return result;
    } catch (e) {
      debugPrint('❌ BMMatchApiService 联赛赛季列表总解析异常: $e');
      return const [];
    }
  }

  /// 请求指定联赛+赛季下的球员排行榜 (GET)
  /// 接口: /api/livespeed/football/competition/player-rank
  /// [competitionId] - 联赛唯一ID (必填)
  /// [seasonId] - 赛季ID (int 类型, 默认 20261 = 兼容旧调用, 工具页改为传赛季列表首个id)
  /// [key] - 数据维度键 (String 类型, 默认 k_goals = 兼容旧调用, 工具页改为 k_shots_on = 射正)
  /// ⚠️ BMNetworkManager._parseResponse 已自动解包 => BMApiResponse.data = 外层 data (球员数组本身!)
  /// 返回: 永远非 null, 出错/空数据 返回空数组[]
  Future<List<BMPlayerRankModel>> fetchPlayerRank({
    required int competitionId,
    int seasonId = 20261,
    String key = 'k_goals',
  }) async {
    debugPrint(
      '🌐 BMMatchApiService 请求联赛球员排行 GET $_footballPlayerRankPath '
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
        '❌ BMMatchApiService 联赛球员排行请求失败: '
        'competitionId=$competitionId, seasonId=$seasonId, key=$key, '
        'isSuccess=${response.isSuccess}, code=${response.code}, msg=${response.message}',
      );
      return const [];
    }

    try {
      final data = response.data;
      if (data is! List) {
        debugPrint(
          '❌ BMMatchApiService 联赛球员排行 response.data 不是List: '
          '实际类型=${data.runtimeType}, data=$data',
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
                '🏆 球员排行解析成功[${result.length}/${data.length}] '
                'pos=${m.position}, name=${m.playerName}, team=${m.teamName}, total=${m.total}',
              );
            } else {
              debugPrint('⚠️ 跳过第$i条球员排行: player_id/player_name/position/total字段缺失, item=$item');
            }
          } else {
            debugPrint('⚠️ 跳过第$i条球员排行: 数据不是Map<String,dynamic>, '
                '类型=${item.runtimeType}, item=$item');
          }
        } catch (e) {
          debugPrint('⚠️ 跳过第$i条球员排行解析异常: $e, item=$item');
        }
      }
      // 按 position 升序排序 (第1名在前)
      result.sort((a, b) => a.position.compareTo(b.position));
      debugPrint('✅ BMMatchApiService 联赛球员排行解析完成: '
          '原始${data.length}条 => 成功${result.length}条');
      return result;
    } catch (e) {
      debugPrint('❌ BMMatchApiService 联赛球员排行总解析异常: $e');
      return const [];
    }
  }
}
