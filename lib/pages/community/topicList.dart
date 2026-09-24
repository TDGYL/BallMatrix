import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_topic_model.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_post_api_model.dart';
import '../../services/bm_community_api_service.dart';
import '../../widgets/home/bm_hot_topics_section.dart' show TopicPostCard;
import 'bm_post_topic_page.dart';

/// BMTopicListPage - 话题列表页 (首页第三段「查看全部」push 进来)
/// 功能: 真实GET接口(/api/livespeed/community/list, type='2') + 复用首页话题卡片 + 下拉刷新 + 上拉加载
class BMTopicListPage extends BMBasePage {
  const BMTopicListPage({
    super.key,
  });

  @override
  State<BMTopicListPage> createState() => _BMTopicListPageState();
}

class _BMTopicListPageState extends BMBasePageState<BMTopicListPage> {
  /// 话题列表数据 (List<BMTopicModel> 类型)
  List<BMTopicModel> _topicList = [];

  /// 下拉刷新或首次加载中 (bool 类型, 控制UI全屏Loading)
  bool _isRefreshing = true;

  /// 上拉加载更多中 (bool 类型, 控制底部footer Loading)
  bool _isLoadingMore = false;

  /// 请求重入锁 (bool 类型, 防止重复请求)
  bool _isFetching = false;

  /// 是否还有下一页 (bool 类型)
  bool _hasNoMore = false;

  /// 当前页码 (int 类型, 从1开始, 内部用int便于递增, 请求时转String)
  int _page = 1;

  /// 每页条数 (int 类型, 默认10, 请求时转String)
  final int _size = 10;

  /// 列表滚动控制器 (ScrollController 类型, 上拉加载监听)
  late final ScrollController _scrollController;

  /// API 服务实例 (BMCommunityApiService 类型, 单例)
  final BMCommunityApiService _apiService = BMCommunityApiService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _fetchTopicList(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听: 触底100px内触发上拉加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isFetching && !_isRefreshing && !_hasNoMore) {
        _fetchTopicList(isRefresh: false);
      }
    }
  }

  /// 请求话题列表 (真实接口: type固定='2', GET /api/livespeed/community/list)
  /// [isRefresh] - true=重置page=1 / false=加载更多 page+1
  Future<void> _fetchTopicList({required bool isRefresh}) async {
    if (_isFetching) {
      debugPrint('🔒 BMTopicListPage 请求被挡(重入): isRefresh=$isRefresh');
      return;
    }
    if (!isRefresh && _hasNoMore) return;
    _isFetching = true;

    final int requestPageInt;
    if (isRefresh) {
      if (!mounted) {
        _isFetching = false;
        return;
      }
      setState(() {
        _isRefreshing = true;
        _page = 1;
        _hasNoMore = false;
      });
      requestPageInt = 1;
    } else {
      if (!mounted) {
        _isFetching = false;
        return;
      }
      setState(() {
        _isLoadingMore = true;
      });
      requestPageInt = _page + 1;
    }

    final String type = '2';
    final String requestPage = requestPageInt.toString();
    final String sizeStr = _size.toString();

    debugPrint(
      '🌐 BMTopicListPage 真实请求发起: type=$type, page=$requestPage, size=$sizeStr',
    );
    List<BMTopicModel> result = [];
    int? serverTotal;
    try {
      final data = await _apiService.fetchPostList(
        type: type,
        page: requestPage,
        size: sizeStr,
      );
      serverTotal = data?.total;
      if (data != null && data.results.isNotEmpty) {
        for (final item in data.results) {
          try {
            result.add(_convertToTopic(item));
          } catch (e) {
            debugPrint('BMTopicListPage 单条话题转换跳过: $e');
          }
        }
      }
      debugPrint(
        '✅ BMTopicListPage 真实请求成功: 本次返回 ${result.length} 条, 服务端总条数=$serverTotal',
      );
    } catch (e) {
      debugPrint(
        '❌ BMTopicListPage 请求异常(isRefresh=$isRefresh, page=$requestPage): $e',
      );
      result = [];
    } finally {
      _isFetching = false;
    }

    if (!mounted) return;
    setState(() {
      if (isRefresh) {
        _topicList = result;
        _page = 1;
        _isRefreshing = false;
      } else {
        _topicList.addAll(result);
        _page = requestPageInt;
        _isLoadingMore = false;
      }
      if (serverTotal != null) {
        _hasNoMore = _topicList.length >= serverTotal;
      } else {
        // 无 total 兜底: 返回条数 < 本次请求 size = 没有更多
        _hasNoMore = result.length < _size;
      }
    });
  }

  /// 话题转换逻辑（复刻 BMCommunityApiService._convertToTopicModel）
  /// 数据源对齐:
  ///   1. content -> 话题内容 (aiInsight)
  ///   2. image 逗号切割 + 过滤 com/ 前缀 -> 多个话题 (hashtags)
  ///   3. match 有数据 -> 内嵌比赛卡片 (embeddedMatch)
  BMTopicModel _convertToTopic(BMPostItem item) {
    final hashtags = _parseHashtags(_safeString(item.image));
    final content = _safeS(item.content, '深度数据分析与洞察，提供独家视角。');
    final BMPostMatch? m = item.match;
    final BMMatchModel? match = (m != null) ? _extractEmbeddedMatch(m) : null;

    String predResult;
    if (m != null && m.homeScore != null && m.awayScore != null) {
      predResult = '预测比分 ${m.homeScore}:${m.awayScore}';
    } else {
      predResult = '主胜概率 58%';
    }

    final BMPostAuthor? author = item.author;
    final String? authorName = author?.name;
    final String? authorAvatarUrl = author?.avatar;
    final int? createTs = item.createTime;
    final String? publishTimeDesc = _formatPublishTime(createTs);

    return BMTopicModel(
      topicId: _safeS(item.id?.toString(), ''),
      categoryTag: hashtags.isNotEmpty ? hashtags.first : '热门话题',
      categoryBgColor: 0xFFDC2626,
      categoryTextColor: 0xFFFFFFFF,
      prediction: hashtags.isNotEmpty ? hashtags.first : 'AI预测',
      predictionColor: 0xFFF97316,
      aiInsight: content,
      predictionResult: predResult,
      confidence: 85,
      embeddedMatch: match,
      hashtags: hashtags,
      likeCount: item.likeCount ?? 0,
      commentCount: item.commentCount ?? 0,
      isLiked: item.isLike ?? false,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      publishTimeDesc: publishTimeDesc,
    );
  }

  // 格式化发布时间为相对时间
  String? _formatPublishTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return null;
    final now = DateTime.now();
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${d.month}-${d.day}';
  }

  // 通用安全取值 helper
  String? _safeString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  String _safeS(dynamic v, String fallback) {
    if (v == null) return fallback;
    if (v is String) return v.isEmpty ? fallback : v;
    return v.toString();
  }

  /// 内嵌比赛从API模型 -> BMMatchModel (复用社区服务转换逻辑)
  BMMatchModel? _extractEmbeddedMatch(BMPostMatch m) {
    int? safeInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? safeStr(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    String safeS(dynamic v, String fallback) {
      if (v == null) return fallback;
      if (v is String) return v.isEmpty ? fallback : v;
      return v.toString();
    }

    final matchType = safeInt(m.matchType) ?? 1;
    final sport = matchType == 2
        ? BMMatchSportType.basketball
        : BMMatchSportType.football;
    final int? statusId = safeInt(m.statusId);
    final BMMatchStatus status = _statusFromId(statusId, sport);
    String matchTime = '';
    final int? startTs = safeInt(m.startTime);
    if (startTs != null && startTs > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(startTs * 1000);
      matchTime =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return BMMatchModel(
      matchId: safeS(m.matchId, safeS(m.competitionId, '')),
      leagueName: safeS(m.competitionName, ''),
      leagueColor: 0xFF8B5CF6,
      status: status,
      statusId: statusId,
      statusName: safeStr(m.statusName),
      sportType: sport,
      matchTime: matchTime,
      homeTeam: BMTeamModel(
        teamId: safeStr(m.homeTeamId),
        teamName: safeS(m.homeTeamName, ''),
        teamShort: _extractShort(safeStr(m.homeTeamName)),
        logoUrl: safeStr(m.homeTeamLogo),
      ),
      awayTeam: BMTeamModel(
        teamId: safeStr(m.awayTeamId),
        teamName: safeS(m.awayTeamName, ''),
        teamShort: _extractShort(safeStr(m.awayTeamName)),
        logoUrl: safeStr(m.awayTeamLogo),
      ),
      homeScore: safeInt(m.homeScore),
      awayScore: safeInt(m.awayScore),
      liveMinute: null,
      halfTimeScore: null,
      goalEvents: const [],
      isFeatured: false,
      isFollowed: false,
      homeWinRate: 0,
      drawRate: 0,
      awayWinRate: 0,
      matchTag: safeStr(m.competitionName),
    );
  }

  /// 从状态ID + 运动类型判断比赛状态
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
        default:
          return BMMatchStatus.tbd;
      }
    }
  }

  /// 队名取前3字母大写
  String _extractShort(String? name) {
    if (name == null || name.isEmpty) return '';
    if (name.length <= 3) return name.toUpperCase();
    return name.substring(0, 3).toUpperCase();
  }

  /// 解析话题标签 (image 逗号切割, 每个话题过滤 com/ 本身及之前的字符)
  /// [raw] - image 原始字符串 (String? 类型, 例 "xxx.com/话题A,话题B")
  /// 返回: List<String> 话题列表
  List<String> _parseHashtags(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .map((seg) {
          // 逐段过滤: 截掉 com/ 及其之前的字符
          final s = seg.trim();
          final idx = s.indexOf('com/');
          return idx >= 0 ? s.substring(idx + 4).trim() : s;
        })
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// 下拉刷新回调
  Future<void> _onRefresh() {
    return _fetchTopicList(isRefresh: true);
  }

  /// 跳转发布话题页 (右上角发布按钮)
  /// 发布成功 (pop true) 后刷新列表展示新话题
  Future<void> _gotoPostTopic() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BMPostTopicPage()),
    );
    if (ok == true) {
      _fetchTopicList(isRefresh: true);
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        _buildNavBar(context),
        Expanded(child: _buildTopicList()),
      ],
    );
  }

  /// 自定义导航栏 (返回 + 标题 + 发布按钮)
  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        border: Border(
          bottom: BorderSide(color: BMColors.pitch800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: BMColors.textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Expanded(
            child: Text(
              'Topic List',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _gotoPostTopic,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 60,
              height: 36,
              decoration: BoxDecoration(
                color: BMColors.bright.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BMColors.bright.withValues(alpha: 0.35)),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: BMColors.bright),
                  SizedBox(width: 3),
                  Text(
                    '发布',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BMColors.bright,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 话题列表区 (首屏Loading/空态/下拉刷新/上拉加载)
  Widget _buildTopicList() {
    if (_isRefreshing && _topicList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: BMColors.bright,
          strokeWidth: 2,
        ),
      );
    }
    if (_topicList.isEmpty) {
      return RefreshIndicator(
        color: BMColors.bright,
        backgroundColor: BMColors.pitch850,
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Center(
              child: Icon(
                Icons.bolt_outlined,
                size: 48,
                color: BMColors.textTertiary,
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                '暂无话题',
                style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: BMColors.bright,
      backgroundColor: BMColors.pitch850,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: _topicList.length + 1,
        itemBuilder: (ctx, index) {
          if (index == _topicList.length) return _buildFooter();
          final t = _topicList[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TopicPostCard(
              topic: t,
              onTap: () {},
              onMoreAction: (action, topicId) =>
                  _onMoreAction(action, t),
            ),
          );
        },
      ),
    );
  }

  /// 更多菜单点击处理 (举报/拉黑)
  /// [action] - 菜单动作 (String 类型, 'report'=举报 'block'=拉黑)
  /// [topic] - 当前话题模型 (BMTopicModel 类型, 用于取 postId 与本地删除)
  Future<void> _onMoreAction(String action, BMTopicModel topic) async {
    if (action != 'block') return; // 举报 toast 由卡片内部处理
    final int postId = int.tryParse(topic.topicId) ?? 0;
    if (postId == 0) return;

    // 拉黑前二次弹窗确认
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BMColors.pitch850,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.5)),
        ),
        title: const Text(
          '拉黑确认',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BMColors.textPrimary,
          ),
        ),
        content: const Text(
          '拉黑之后将不再看到此帖子',
          style: TextStyle(
            fontSize: 13,
            color: BMColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              '取消',
              style: TextStyle(fontSize: 14, color: BMColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '拉黑',
              style: TextStyle(fontSize: 14, color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // 拉黑: 调接口成功后本地删除该帖子
    final bool ok = await _apiService.blockPost(postId: postId, type: 1);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _topicList.removeWhere((t) => t.topicId == topic.topicId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '拉黑失败, 请稍后重试',
            style: TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: BMColors.pitch800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 底部加载指示器
  Widget _buildFooter() {
    if (_hasNoMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 24, height: 1, color: BMColors.pitch700),
            const SizedBox(width: 8),
            const Text(
              '—— 到底啦 ——',
              style: TextStyle(fontSize: 11, color: BMColors.textTertiary),
            ),
            const SizedBox(width: 8),
            Container(width: 24, height: 1, color: BMColors.pitch700),
          ],
        ),
      );
    }
    if (_isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: BMColors.bright,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text(
              '加载中...',
              style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
