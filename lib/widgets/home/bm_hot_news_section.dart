import 'package:flutter/material.dart';
import '../../models/bm_news_model.dart';
import '../../theme/bm_colors.dart';

/// BMHotNewsSection - 热门资讯Banner列表区域
/// 功能: 展示热门资讯Banner轮播, 一页可看到1.5个卡片
/// 作用范围: 首页第二段, 仅展示: 图片 / 2行标题 / 发布时间
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
        _buildBannerList(context),
      ],
    );
  }

  /// 构建Banner横向列表, 使用PageView实现一页看1.5个
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
  /// 仅展示: 图片背景 + 标题(2行) + 发布时间, 无其他标签
  Widget _buildNewsCard(BMNewsModel news) {
    final coverUrl = news.displayCoverUrl;
    final hasCover = coverUrl.isNotEmpty;
    final publishText = news.displayPublishTime;
    return GestureDetector(
      onTap: () => onNewsTap?.call(news),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: BMColors.pitch850,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
          image: hasCover
              ? DecorationImage(
                  image: NetworkImage(coverUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: hasCover
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black54,
                        Colors.black87,
                      ],
                      stops: [0.3, 0.7, 1.0],
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  news.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasCover ? Colors.white : BMColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (publishText.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 10, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        publishText,
                        style: TextStyle(
                          fontSize: 10,
                          color: hasCover ? Colors.white70 : BMColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}