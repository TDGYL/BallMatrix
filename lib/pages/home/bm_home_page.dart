import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../viewmodels/home/bm_home_view_model.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_news_model.dart';
import '../../models/bm_topic_model.dart';
import '../../widgets/home/bm_home_header.dart';
import '../../widgets/home/bm_sport_switcher.dart';
import '../../widgets/home/bm_match_spotlight_card.dart';
import '../../widgets/home/bm_hot_news_section.dart';
import '../../widgets/home/bm_hot_topics_section.dart';
import '../match/bm_match_page.dart';

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
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部头部
              BMHomeHeader(
                onNotificationTap: () {},
              ),
              const SizedBox(height: 20),
              // 运动类型切换器
              BMSportSwitcher(
                currentSport: widget.viewModel.currentSport,
                onSportChanged: (sport) => widget.viewModel.switchSport(sport),
              ),
              const SizedBox(height: 20),
              // 第一段: 焦点赛事卡片 (修改点1: View All按钮)
              _buildFeaturedMatchSection(),
              const SizedBox(height: 20),
              // 第二段: 热门资讯 (修改点2: 替换智能直达工具箱)
              _buildHotNewsSection(),
              const SizedBox(height: 20),
              // 第三段: 热门话题 (修改点3: 替换今日重点偏离模型简报)
              _buildHotTopicsSection(),
            ],
          ),
        );
      },
    );
  }

  /// 构建焦点赛事区域 (第一段)
  /// 区域头部包含标题和"查看全部"按钮, 点击跳转赛事列表页
  Widget _buildFeaturedMatchSection() {
    final BMMatchModel? match = widget.viewModel.featuredMatch;
    if (match == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区域头部标题 + 查看全部 (与热门资讯样式一致)
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
              ],
            ),
            GestureDetector(
              onTap: _navigateToMatchList,
              child: Row(
                children: [
                  const Text(
                    '查看全部',
                    style: TextStyle(fontSize: 12, color: BMColors.bright),
                  ),
                  const Icon(Icons.chevron_right, size: 14, color: BMColors.bright),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BMMatchSpotlightCard(
          match: match,
          onTap: () {},
        ),
      ],
    );
  }

  /// 构建热门资讯区域 (第二段, 修改点2)
  Widget _buildHotNewsSection() {
    return BMHotNewsSection(
      newsList: widget.viewModel.newsList,
      onNewsTap: (BMNewsModel news) {},
    );
  }

  /// 构建热门话题区域 (第三段, 修改点3)
  Widget _buildHotTopicsSection() {
    return BMHotTopicsSection(
      topicList: widget.viewModel.topicList,
      onTopicTap: (BMTopicModel topic) {},
      onViewAll: _navigateToMatchList,
    );
  }

  /// 跳转到赛事列表页 (修改点1的跳转逻辑)
  void _navigateToMatchList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BMMatchPage(
          viewModel: widget.viewModel,
        ),
      ),
    );
  }
}