import '../network/bm_network_manager.dart';
import '../models/bm_post_api_model.dart';
import '../models/bm_topic_model.dart';
import '../models/bm_match_model.dart';

/// BMCommunityTab - 社区列表Tab类型枚举
/// 映射到API type参数: 推荐=1, 最新=2, 关注=3
enum BMCommunityTab {
  /// 推荐 type=1
  recommend(1),

  /// 最新 type=2
  recent(2),

  /// 关注 type=3
  follow(3);

  /// API映射的type值 (int 类型)
  final int value;
  const BMCommunityTab(this.value);
}

/// BMCommunityApiService - 社区话题列表API服务
/// 作用范围: 首页热门话题列表
class BMCommunityApiService {
  /// 单例实例 (BMCommunityApiService 类型)
  static final BMCommunityApiService _instance = BMCommunityApiService._internal();

  /// 工厂构造函数, 返回单例
  factory BMCommunityApiService() {
    return _instance;
  }

  /// 私有构造函数
  BMCommunityApiService._internal();

  /// API路径
  static const String _apiPath = '/api/livespeed/community/list';

  /// 请求社区话题列表 (GET)
  /// [tab] - Tab类型 (推荐/最新/关注)
  /// [page] - 页码 (从1开始)
  /// [size] - 每页数量
  /// [matchType] - 比赛类型, 1=足球, 2=篮球, 默认1
  /// 返回: BMPostData?
  Future<BMPostData?> fetchPostList({
    required BMCommunityTab tab,
    int page = 1,
    int size = 10,
    int matchType = 1,
  }) async {
    final params = <String, dynamic>{
      'type': tab.value,
      'page': page,
      'size': size,
      'match_type': matchType,
    };

    final response = await BMNetworkManager().getRequest(
      _apiPath,
      queryParameters: params,
    );

    if (response.isSuccess && response.data != null) {
      return BMPostData.fromJson(response.data as Map<String, dynamic>);
    }

    return null;
  }

  /// 请求话题并转换为UI模型 (首页热门话题用)
  /// [count] - 请求条数, 默认3
  /// [matchType] - 比赛类型, 默认1足球
  /// 返回: List<BMTopicModel>
  Future<List<BMTopicModel>> fetchTopicModels({
    int count = 3,
    int matchType = 1,
  }) async {
    final data = await fetchPostList(
      tab: BMCommunityTab.recent,
      page: 1,
      size: count,
      matchType: matchType,
    );
    if (data == null || data.results.isEmpty) return [];
    return data.results.map((item) => _convertToTopicModel(item)).toList();
  }

  /// API模型 -> UI模型 转换
  BMTopicModel _convertToTopicModel(BMPostItem item) {
    final hashtags = _parseHashtags(item.image);
    final content = item.content ?? '';

    BMMatchModel? embeddedMatch;
    if (item.match != null) {
      final m = item.match!;
      final sport = (m.matchType ?? 1) == 2 ? BMMatchSportType.basketball : BMMatchSportType.football;
      embeddedMatch = BMMatchModel(
        matchId: m.matchId?.toString() ?? '',
        leagueName: m.competitionName ?? '',
        leagueColor: 0xFF8B5CF6,
        homeTeam: BMTeamModel(
          teamId: m.homeTeamId?.toString() ?? '',
          teamName: m.homeTeamName ?? '',
          teamShort: _extractShort(m.homeTeamName),
          logoUrl: m.homeTeamLogo,
        ),
        awayTeam: BMTeamModel(
          teamId: m.awayTeamId?.toString() ?? '',
          teamName: m.awayTeamName ?? '',
          teamShort: _extractShort(m.awayTeamName),
          logoUrl: m.awayTeamLogo,
        ),
        homeScore: m.homeScore ?? 0,
        awayScore: m.awayScore ?? 0,
        matchTime: _formatMatchTime(m.startTime),
        status: _statusFromId(m.statusId, sport),
        statusId: m.statusId,
        statusName: m.statusName,
        sportType: sport,
        liveMinute: null,
        halfTimeScore: null,
        goalEvents: [],
        isFeatured: false,
        isFollowed: false,
        homeWinRate: 0,
        drawRate: 0,
        awayWinRate: 0,
        matchTag: m.competitionName,
      );
    }

    return BMTopicModel(
      topicId: item.id?.toString() ?? '',
      categoryTag: hashtags.isNotEmpty ? hashtags.first : '热门话题',
      categoryBgColor: 0xFFDC2626,
      categoryTextColor: 0xFFFFFFFF,
      prediction: hashtags.isNotEmpty ? hashtags.first : 'AI预测',
      predictionColor: 0xFFF97316,
      aiInsight: content.isNotEmpty ? content : '深度数据分析与洞察，提供独家视角。',
      predictionResult: _buildPredictionResult(item),
      confidence: 85,
      embeddedMatch: embeddedMatch,
    );
  }

  /// 构建预测结果字符串
  String _buildPredictionResult(BMPostItem item) {
    if (item.match != null) {
      final m = item.match!;
      if (m.homeScore != null && m.awayScore != null) {
        return '预测比分 ${m.homeScore}:${m.awayScore}';
      }
    }
    return '主胜概率 58%';
  }

  /// 解析话题标签
  List<String> _parseHashtags(String? rawImage) {
    if (rawImage == null || rawImage.isEmpty) return [];
    String raw = rawImage;
    if (raw.contains('com/')) {
      raw = raw.substring(raw.indexOf('com/') + 4);
    }
    return raw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// 格式化比赛时间戳 -> HH:mm
  String _formatMatchTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 从状态ID映射比赛状态 (按运动类型分规则)
  /// 足球: 1未开始, 2|3|4|5|7进行中, 8已结束, 0|9|10|11|12|13 TBD
  /// 篮球: 1|13未开始, 2|3|4|5|6|7|8|9进行中, 10|11已结束, 0|12|14|15 TBD
  BMMatchStatus _statusFromId(int? statusId, BMMatchSportType sport) {
    if (sport == BMMatchSportType.football) {
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
    } else {
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
  }

  /// 提取队名缩写
  String _extractShort(String? name) {
    if (name == null || name.isEmpty) return '';
    if (name.length <= 3) return name.toUpperCase();
    return name.substring(0, 3).toUpperCase();
  }
}