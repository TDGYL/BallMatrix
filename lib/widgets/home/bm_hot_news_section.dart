import 'package:flutter/material.dart';
import '../../models/bm_news_model.dart';
import '../../theme/bm_colors.dart';

/// BMHotNewsSection - 热门资讯Banner列表区域
/// 功能: 展示热门资讯Banner轮播, 一页可看到1.5个卡片
/// 修改点2: 替换原"智能直达工具箱"为"热门资讯"
/// 作用范围: 首页第二段
class BMHotNewsSection extends StatelessWidget {
  /// 热门资讯列表 (List<BMNewsModel> 类型)
  final List<BMNewsModel> newsList;

  /// 资讯点击回调 (ValueChanged<BMNewsModel> 类型, 可空)
  final ValueChanged<BMNewsModel>? onNewsTap;

  const BMHotNewsSection({
    super.key,
    required this.newsList,
    this.onNewsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 10),
        _buildBannerList(context),
      ],
    );
  }

  /// 构建区域标题
  Widget _buildSectionHeader() {
    return Row(
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
          ],
        ),
        const Text(
          '实时同步',
          style: TextStyle(fontSize: 11, color: BMColors.textSecondary),
        ),
      ],
    );
  }

  /// 构建Banner横向列表, 使用PageView实现一页看1.5个
  /// 原理: viewportFraction 设为 0.6667, 使每页显示约2/3宽度, 露出半张卡片
  Widget _buildBannerList(BuildContext context) {
    if (newsList.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.6667),
        itemCount: newsList.length,
        padEnds: false,
        itemBuilder: (context, index) {
          return _buildNewsCard(newsList[index]);
        },
      ),
    );
  }

  /// 构建单条资讯Banner卡片
  /// 参数: [news] 资讯数据
  Widget _buildNewsCard(BMNewsModel news) {
    return GestureDetector(
      onTap: () => onNewsTap?.call(news),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(news.tagColor).withValues(alpha: 0.15),
              BMColors.pitch850,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(news.tagColor).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardTopRow(news),
            const Spacer(),
            Text(
              news.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              news.summary,
              style: const TextStyle(fontSize: 11, color: BMColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            _buildCardBottomRow(news),
          ],
        ),
      ),
    );
  }

  /// 构建卡片顶部标签行
  /// 参数: [news] 资讯数据
  Widget _buildCardTopRow(BMNewsModel news) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Color(news.tagColor).withValues(alpha: 0.2),
            border: Border.all(color: Color(news.tagColor).withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            news.tag,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(news.tagColor),
            ),
          ),
        ),
        const Icon(Icons.arrow_outward, size: 14, color: BMColors.textSecondary),
      ],
    );
  }

  /// 构建卡片底部时间行
  /// 参数: [news] 资讯数据
  Widget _buildCardBottomRow(BMNewsModel news) {
    return Row(
      children: [
        const Icon(Icons.schedule, size: 10, color: BMColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          news.publishTime,
          style: const TextStyle(fontSize: 10, color: BMColors.textTertiary),
        ),
      ],
    );
  }
}