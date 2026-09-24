import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../viewmodels/home/bm_home_view_model.dart' show BMHomeViewModel, BMSportType;
import '../../services/bm_community_api_service.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_news_model.dart';
import '../../models/bm_topic_model.dart';
import '../../widgets/home/bm_home_header.dart';
import '../../widgets/home/bm_sport_switcher.dart';
import '../../widgets/home/bm_match_spotlight_card.dart';
import '../../widgets/home/bm_hot_news_section.dart';
import '../../widgets/home/bm_hot_topics_section.dart';
import '../match/matchList.dart';
import '../match/bm_football_detail_page.dart';
import '../match/bm_basketball_detail_page.dart';
import '../news/newsList.dart';
import '../news/bm_news_detail_page.dart';
import '../community/topicList.dart';
import '../community/bm_topic_detail_page.dart';

/// BMHomePage - 首页
/// 功能: 展示焦点赛事、热门资讯、热门话题
/// 架构: MVVM View层, 绑定 BMHomeViewModel
/// 修改点1: 焦点赛事卡片头部添加 View All 按钮, 跳转赛事列表页
/// 修改点2: 智能直达工具箱 → 热门资讯 (Banner列表, 一页1.5个)
/// 修改点3: 今日重点偏离模型简报 → 热门话题
class BMHomePage extends BMBasePage {
  /// 首页ViewModel (BMHomeViewModel 类型, 由父页面传入)
  final BMHomeViewModel viewModel;

  const BMHomePage({super.key, required this.viewModel});

  @override
  State<BMHomePage> createState() => _BMHomePageState();
}

class _BMHomePageState extends BMBasePageState<BMHomePage> {
  @override
  void initState() {
    super.initState();
    // 懒加载: 首次进入时加载数据
    widget.viewModel.loadData();
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        return RefreshIndicator(
          color: BMColors.bright,
          backgroundColor: BMColors.pitch850,
          onRefresh: () => widget.viewModel.refreshData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BMHomeHeader(
                  onSearchTap: () {},
                ),
                const SizedBox(height: 20),
                BMSportSwitcher(
                  currentSport: widget.viewModel.currentSport,
                  onSportChanged: (sport) => widget.viewModel.switchSport(sport),
                ),
                const SizedBox(height: 20),
                _buildFeaturedMatchSection(),
                const SizedBox(height: 20),
                _buildHotNewsSection(),
                const SizedBox(height: 20),
                _buildHotTopicsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建焦点赛事区域 (第一段)
  /// 区域头部包含标题和"查看全部"按钮, 点击跳转赛事列表页
  Widget _buildFeaturedMatchSection() {
    final bool loading = widget.viewModel.loadingMatch;
    final BMMatchModel? match = widget.viewModel.featuredMatch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.stadium, size: 16, color: BMColors.bright),
                const SizedBox(width: 6),
                const Text(
                  '焦点赛事',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                if (loading) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BMColors.bright,
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: loading ? null : _navigateToMatchList,
              child: Opacity(
                opacity: loading ? 0.4 : 1.0,
                child: const Row(
                  children: [
                    Text(
                      '查看全部',
                      style: TextStyle(fontSize: 12, color: BMColors.bright),
                    ),
                    Icon(Icons.chevron_right, size: 14, color: BMColors.bright),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        loading
            ? _buildMatchSkeleton()
            : (match != null
                ? BMMatchSpotlightCard(
                    match: match,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => widget.viewModel.currentSport ==
                                  BMSportType.football
                              ? BMFootballDetailPage(match: match)
                              : BMBasketballDetailPage(match: match),
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink()),
      ],
    );
  }

  /// 构建焦点赛事加载骨架屏
  Widget _buildMatchSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B3A2E),
            Color(0xFF0E2620),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: BMColors.pitch800,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Spacer(),
              Container(
                width: 70,
                height: 20,
                decoration: BoxDecoration(
                  color: BMColors.pitch800,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BMColors.pitch800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: BMColors.pitch800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Container(width: 26, height: 28, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 8),
                      Container(width: 10, height: 16, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Container(width: 26, height: 28, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BMColors.pitch800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: BMColors.pitch800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建热门资讯区域 (第二段, 修改点2)
  Widget _buildHotNewsSection() {
    final bool loading = widget.viewModel.loadingNews;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, size: 16, color: BMColors.bright),
                const SizedBox(width: 6),
                const Text(
                  '热门资讯',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                if (loading) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BMColors.bright,
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: loading ? null : _navigateToNewsList,
              child: Opacity(
                opacity: loading ? 0.4 : 1.0,
                child: const Row(
                  children: [
                    Text(
                      '查看全部',
                      style: TextStyle(fontSize: 12, color: BMColors.bright),
                    ),
                    Icon(Icons.chevron_right, size: 14, color: BMColors.bright),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        loading ? _buildNewsSkeleton() : _buildNewsContent(),
      ],
    );
  }

  Widget _buildNewsContent() {
    return BMHotNewsSection(
      newsList: widget.viewModel.newsList,
      onNewsTap: (BMNewsModel news) {
        final int? id = int.tryParse(news.newsId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BMNewsDetailPage(
              newsId: id ?? 0,
              newsTitle: news.title,
            ),
          ),
        );
      },
    );
  }

  /// 构建热门资讯加载骨架屏 (单页1.5个卡片)
  Widget _buildNewsSkeleton() {
    return SizedBox(
      height: 160,
      child: Row(
        children: [
          Expanded(flex: 6, child: _buildNewsCardSkeleton()),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: _buildNewsCardSkeleton()),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildNewsCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: BMColors.pitch800,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 160,
            height: 14,
            decoration: BoxDecoration(
              color: BMColors.pitch800,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 48, height: 10, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建热门话题区域 (第三段, 修改点3)
  Widget _buildHotTopicsSection() {
    final bool loading = widget.viewModel.loadingTopics;
    final List<BMTopicModel> topics = widget.viewModel.topicList;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, size: 16, color: BMColors.amber),
                const SizedBox(width: 6),
                const Text(
                  '热门话题',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                if (loading) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BMColors.amber,
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: loading ? null : _navigateToTopicList,
              child: Opacity(
                opacity: loading ? 0.4 : 1.0,
                child: const Row(
                  children: [
                    Text(
                      '查看全部',
                      style: TextStyle(fontSize: 12, color: BMColors.bright),
                    ),
                    Icon(Icons.chevron_right, size: 14, color: BMColors.bright),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (loading)
          _buildTopicsSkeleton()
        else
          BMHotTopicsSection(
            topicList: topics,
            onTopicTap: _onTopicTap,
            onMatchTap: _onTopicMatchTap,
            onBlockTopic: _onBlockTopic,
            onViewAll: _navigateToTopicList,
          ),
      ],
    );
  }

  Widget _buildTopicsSkeleton() {
    return Column(
      children: [
        _buildTopicCardSkeleton(),
        const SizedBox(height: 12),
        _buildTopicCardSkeleton(),
        const SizedBox(height: 12),
        _buildTopicCardSkeleton(),
      ],
    );
  }

  Widget _buildTopicCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: BMColors.pitch700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 12, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 4),
                    Container(width: 60, height: 10, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(5))),
                  ],
                ),
              ),
              Container(width: 26, height: 26, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(8))),
            ],
          ),
          const SizedBox(height: 10),
          Container(width: 100, height: 22, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 8),
          Container(width: double.infinity, height: 10, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 4),
          Container(width: double.infinity, height: 10, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Container(width: 160, height: 10, decoration: BoxDecoration(color: BMColors.pitch700, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 跳转到赛事列表页 (修改点1的跳转逻辑)
  void _navigateToMatchList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BMMatchListPage(
          sportType: widget.viewModel.currentSport,
        ),
      ),
    );
  }

  /// 跳转到资讯列表页 (第二段「查看全部」跳转)
  void _navigateToNewsList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BMNewsListPage(),
      ),
    );
  }

  /// 跳转到话题列表页 (第三段「查看全部」跳转, type=2 最新)
  void _navigateToTopicList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BMTopicListPage(),
      ),
    );
  }

  /// 首页热门话题卡片点击跳转话题详情页
  /// [topic] - 当前话题模型 (BMTopicModel 类型, topicId 即帖子ID)
  /// 返回 true 表示帖子被删除, 通知 ViewModel 本地移除
  Future<void> _onTopicTap(BMTopicModel topic) async {
    final int postId = int.tryParse(topic.topicId) ?? 0;
    if (postId == 0) return;
    final deleted = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BMTopicDetailPage(postId: postId),
      ),
    );
    if (deleted == true && mounted) {
      widget.viewModel.removeTopic(topic.topicId);
    }
  }

  /// 首页热门话题内嵌比赛卡跳转 (按球类型分流: basketball -> 篮球详情 / 其他 -> 足球详情)
  /// [topic] - 当前话题模型 (BMTopicModel 类型, 取 embeddedMatch)
  void _onTopicMatchTap(BMTopicModel topic) {
    final match = topic.embeddedMatch;
    if (match == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => match.sportType == BMMatchSportType.basketball
            ? BMBasketballDetailPage(match: match)
            : BMFootballDetailPage(match: match),
      ),
    );
  }

  /// 首页热门话题拉黑处理 (与话题列表页逻辑一致)
  /// [topic] - 当前话题模型 (BMTopicModel 类型)
  /// 链路: 二次确认弹窗 -> POST block_post -> 成功后 ViewModel 本地删除
  Future<void> _onBlockTopic(BMTopicModel topic) async {
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
          style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
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

    // 拉黑: 调接口成功后 ViewModel 本地删除该话题
    final bool ok =
        await BMCommunityApiService().blockPost(postId: postId, type: 1);
    if (!mounted) return;
    if (ok) {
      widget.viewModel.removeTopic(topic.topicId);
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
}