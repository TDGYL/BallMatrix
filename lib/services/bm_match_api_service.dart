import 'package:flutter/foundation.dart';

import '../network/bm_network_manager.dart';
import '../models/bm_match_api_model.dart';
import '../models/bm_basketball_match_model.dart';
import '../models/bm_match_model.dart';
import '../theme/bm_colors.dart';

/// BMMatchApiService - 比赛列表API服务
/// 作用范围: 首页焦点赛事 / 赛事列表页 相关接口
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
    debugPrint('🏟️  BMMatchApiService.fetchFootballList 发起: tab=0, page=$page, size=$size, ts=$timestamp');
    final data = await fetchFootballMatches(
      tab: 0,
      page: page,
      size: size,
      timestamp: timestamp,
      competitionIds: competitionIds,
    );
    debugPrint('🏟️  BMMatchApiService.fetchFootballList 返回: data == null ? ${data == null}, results.length = ${data?.results.length ?? -1}');
    if (data == null || data.results.isEmpty) return [];
    final List<BMMatchModel> list = [];
    for (final item in data.results) {
      try {
        list.add(_convertFootballMatch(item));
      } catch (e) {
        debugPrint('BMMatchApiService 足球单条转换跳过异常: $e');
      }
    }
    debugPrint('🏟️  BMMatchApiService.fetchFootballList UI模型数: ${list.length}');
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
    debugPrint('🏀 BMMatchApiService.fetchBasketballList 发起: tab=0, page=$page, size=$size, ts=$timestamp');
    final data = await fetchBasketballMatches(
      tab: 0,
      page: page,
      size: size,
      timestamp: timestamp,
      competitionIds: competitionIds,
    );
    debugPrint('🏀 BMMatchApiService.fetchBasketballList 返回: data == null ? ${data == null}, results.length = ${data?.results.length ?? -1}');
    if (data == null || data.results.isEmpty) return [];
    final List<BMMatchModel> list = [];
    for (final item in data.results) {
      try {
        list.add(_convertBasketballMatch(item));
      } catch (e) {
        debugPrint('BMMatchApiService 篮球单条转换跳过异常: $e');
      }
    }
    debugPrint('🏀 BMMatchApiService.fetchBasketballList UI模型数: ${list.length}');
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

  /// 篮球API模型 -> UI模型 转换 (对齐hanklive)
  BMMatchModel _convertBasketballMatch(BMBasketballMatchItem item) {
    final status = _basketballStatusFromId(item.statusId);
    final int? homeScore = int.tryParse(item.homeScores ?? '');
    final int? awayScore = int.tryParse(item.awayScores ?? '');
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
}
