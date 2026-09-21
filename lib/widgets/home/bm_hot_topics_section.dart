import 'package:flutter/material.dart';
import '../../models/bm_topic_model.dart';
import '../../models/bm_match_model.dart';
import '../../theme/bm_colors.dart';

/// BMHotTopicsSection - 热门话题列表区域
/// 参照 hanklive Community PostCard 结构: 用户头像行 → 话题标签 → 内容 → 操作栏
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
        ...topicList.map((topic) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTopicCard(topic, context),
        )),
      ],
    );
  }

  /// 构建单条话题卡片 (参照 hanklive PostCard: 头部→标签→内容→操作栏)
  Widget _buildTopicCard(BMTopicModel topic, BuildContext context) {
    return GestureDetector(
      onTap: () => onTopicTap?.call(topic),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BMColors.pitch850,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(topic, context),
            if (topic.categoryTag.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildHashtagWrap(topic),
            ],
            const SizedBox(height: 8),
            _buildContentText(topic),
            if (topic.embeddedMatch != null) ...[
              const SizedBox(height: 10),
              _buildEmbeddedMatch(topic.embeddedMatch!),
            ],
            const SizedBox(height: 10),
            _buildActionBar(topic),
          ],
        ),
      ),
    );
  }

  /// 构建用户头像头部行 (参照 PostCard _buildUserHeader)
  Widget _buildUserHeader(BMTopicModel topic, BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: BMColors.pitch700,
          child: Icon(
            Icons.person_outline,
            size: 18,
            color: BMColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.predictionResult.isNotEmpty
                    ? topic.predictionResult
                    : topic.prediction,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BMColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                topic.categoryTag,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        _buildMoreButton(context, topic),
      ],
    );
  }

  /// 构建更多按钮 (三个点图标 + 点击弹出菜单: 拉黑 / 举报)
  Widget _buildMoreButton(BuildContext context, BMTopicModel topic) {
    return Builder(
      builder: (btnCtx) {
        return GestureDetector(
          onTap: () {
            _showMoreMenu(btnCtx, topic);
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: BMColors.pitch800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.more_horiz,
              size: 16,
              color: BMColors.textSecondary,
            ),
          ),
        );
      },
    );
  }

  /// 弹出更多操作菜单 - 从更多按钮**左下角**对齐弹出
  void _showMoreMenu(BuildContext btnCtx, BMTopicModel topic) {
    final renderBox = btnCtx.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(btnCtx).context.findRenderObject() as RenderBox?;
    RelativeRect position;
    if (renderBox != null && overlay != null) {
      final btnSize = renderBox.size;
      final btnOffset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
      position = RelativeRect.fromLTRB(
        btnOffset.dx,
        btnOffset.dy + btnSize.height,
        btnOffset.dx + btnSize.width,
        btnOffset.dy + btnSize.height + 300,
      );
    } else {
      position = const RelativeRect.fromLTRB(16, 16, 16, 0);
    }
    showMenu<String>(
      context: btnCtx,
      position: position,
      color: BMColors.pitch850,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block, size: 16, color: BMColors.textSecondary),
              const SizedBox(width: 10),
              const Text(
                '拉黑',
                style: TextStyle(fontSize: 13, color: BMColors.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.report_outlined, size: 16, color: BMColors.textSecondary),
              const SizedBox(width: 10),
              const Text(
                '举报',
                style: TextStyle(fontSize: 13, color: BMColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    ).then((String? value) {
      if (value == null) return;
      if (value == 'block') {
        ScaffoldMessenger.of(btnCtx).showSnackBar(
          SnackBar(
            content: const Text('已拉黑该用户'),
            duration: const Duration(seconds: 1),
            backgroundColor: BMColors.pitch800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (value == 'report') {
        ScaffoldMessenger.of(btnCtx).showSnackBar(
          SnackBar(
            content: const Text('已提交举报, 我们会尽快处理'),
            duration: const Duration(seconds: 1),
            backgroundColor: BMColors.pitch800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  /// 构建话题标签 Wrap (参照 PostCard _buildHashtagWrap)
  Widget _buildHashtagWrap(BMTopicModel topic) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Color(topic.categoryBgColor).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(topic.categoryBgColor).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '# ${topic.categoryTag}',
            style: TextStyle(
              color: Color(topic.categoryBgColor),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建内容文本 (参照 PostCard _buildContentText)
  Widget _buildContentText(BMTopicModel topic) {
    return Text(
      topic.aiInsight,
      style: const TextStyle(
        fontSize: 12,
        height: 1.6,
        color: BMColors.textSecondary,
      ),
    );
  }

  /// 构建内嵌比赛简化卡片 (主客队名绿色高亮)
  Widget _buildEmbeddedMatch(BMMatchModel match) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BMColors.pitch800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: match.homeTeamName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: BMColors.bright,
                    ),
                  ),
                  const TextSpan(
                    text: ' vs ',
                    style: TextStyle(
                      fontSize: 11,
                      color: BMColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: match.awayTeamName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: BMColors.bright,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            match.leagueName,
            style: const TextStyle(
              fontSize: 10,
              color: BMColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部操作栏 (参照 PostCard _buildActionBar: 评论/点赞 两项)
  Widget _buildActionBar(BMTopicModel topic) {
    return Container(
      padding: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: BMColors.pitch700.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(
            icon: Icons.comment_outlined,
            label: '${topic.heatCount > 0 ? topic.heatCount : '评论'}',
            color: BMColors.purple,
          ),
          _buildActionItem(
            icon: Icons.favorite_border,
            label: '赞同',
            color: const Color(0xFFFB7185),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮项
  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}