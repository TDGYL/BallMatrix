import 'package:flutter/material.dart';
import '../../models/bm_topic_model.dart';
import '../../theme/bm_colors.dart';

/// BMHotTopicsSection - 热门话题列表区域
/// 功能: 展示热门话题卡片列表, 包含AI洞察分析
/// 修改点3: 替换原"今日重点偏离模型简报"为"热门话题"
/// 作用范围: 首页第三段
class BMHotTopicsSection extends StatelessWidget {
  /// 热门话题列表 (List<BMTopicModel> 类型)
  final List<BMTopicModel> topicList;

  /// 话题点击回调 (ValueChanged<BMTopicModel> 类型, 可空)
  final ValueChanged<BMTopicModel>? onTopicTap;

  /// View All按钮点击回调 (VoidCallback 类型, 可空)
  final VoidCallback? onViewAll;

  const BMHotTopicsSection({
    super.key,
    required this.topicList,
    this.onTopicTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 12),
        ...topicList.map((topic) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTopicCard(topic),
        )),
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
          ],
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              '全部赛事',
              style: TextStyle(fontSize: 12, color: BMColors.bright),
            ),
          ),
      ],
    );
  }

  /// 构建单条话题卡片
  /// 参数: [topic] 话题数据
  Widget _buildTopicCard(BMTopicModel topic) {
    return GestureDetector(
      onTap: () => onTopicTap?.call(topic),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xD9143328), Color(0xF00E261E)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BMColors.pitch600.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardTopRow(topic),
            const SizedBox(height: 10),
            _buildCardMiddleRow(topic),
            const SizedBox(height: 10),
            _buildAiInsightBox(topic),
          ],
        ),
      ),
    );
  }

  /// 构建卡片顶部行 (分类 + 标签)
  /// 参数: [topic] 话题数据
  Widget _buildCardTopRow(BMTopicModel topic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          topic.category,
          style: const TextStyle(fontSize: 12, color: BMColors.textSecondary),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Color(topic.tagColor).withValues(alpha: 0.1),
            border: Border.all(color: Color(topic.tagColor).withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            topic.tagText,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Color(topic.tagColor),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建卡片中间行 (标题 + 预测)
  /// 参数: [topic] 话题数据
  Widget _buildCardMiddleRow(BMTopicModel topic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          topic.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BMColors.textPrimary),
        ),
        Text(
          topic.prediction,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: topic.iconType == BMTopicIconType.info
                ? BMColors.amber
                : BMColors.bright,
          ),
        ),
      ],
    );
  }

  /// 构建AI洞察信息框
  /// 参数: [topic] 话题数据
  Widget _buildAiInsightBox(BMTopicModel topic) {
    final Color iconColor = topic.iconType == BMTopicIconType.info
        ? BMColors.bright
        : BMColors.cyan;
    final IconData iconData = topic.iconType == BMTopicIconType.info
        ? Icons.info_outline
        : Icons.bar_chart;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BMColors.pitch950.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 12, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              topic.aiInsight,
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}