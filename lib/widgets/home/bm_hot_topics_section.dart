import 'package:flutter/material.dart';
import '../../models/bm_topic_model.dart';
import '../../models/bm_match_model.dart';
import '../../theme/bm_colors.dart';

/// TopicPostCard - 单条话题独立卡片 (首页第三段 + 话题列表页共用)
/// 参照 hanklive PostCard 5层结构: 用户头 -> 标签 -> 内容 -> 内嵌比赛 -> 操作栏
class TopicPostCard extends StatelessWidget {
  /// 话题数据 (BMTopicModel 类型)
  final BMTopicModel topic;

  /// 点击卡片回调 (VoidCallback 类型, 可空)
  final VoidCallback? onTap;

  /// 更多操作回调 (action 为 'block'/'report', topicId 为话题ID)
  final void Function(String action, String topicId)? onMoreAction;

  const TopicPostCard({
    super.key,
    required this.topic,
    this.onTap,
    this.onMoreAction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            _buildUserHeader(context),
            if (topic.categoryTag.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildHashtagWrap(),
            ],
            const SizedBox(height: 8),
            _buildContentText(),
            if (topic.embeddedMatch != null) ...[
              const SizedBox(height: 10),
              _buildEmbeddedMatch(topic.embeddedMatch!),
            ],
            const SizedBox(height: 10),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  /// 构建用户头像头部行
  Widget _buildUserHeader(BuildContext context) {
    return Row(
      children: [
        _buildUserAvatar(),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (topic.authorName != null && topic.authorName!.isNotEmpty)
                    ? topic.authorName!
                    : '球场用户',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: BMColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                (topic.publishTimeDesc != null &&
                        topic.publishTimeDesc!.isNotEmpty)
                    ? topic.publishTimeDesc!
                    : topic.categoryTag,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildMoreButton(context),
      ],
    );
  }

  /// 构建用户头像 (优先 authorAvatarUrl 真实图, 否则默认占位)
  Widget _buildUserAvatar() {
    final avatar = topic.authorAvatarUrl;
    if (avatar != null && avatar.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: BMColors.pitch700,
        backgroundImage: NetworkImage(avatar),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: BMColors.pitch700,
      child: const Icon(
        Icons.person_outline,
        size: 18,
        color: BMColors.textSecondary,
      ),
    );
  }

  /// 更多按钮(三个点) + 点击弹出菜单 拉黑/举报
  Widget _buildMoreButton(BuildContext context) {
    return Builder(
      builder: (btnCtx) {
        return GestureDetector(
          onTap: () {
            _showMoreMenu(btnCtx);
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: BMColors.pitch800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.more_horiz,
              size: 16,
              color: BMColors.textSecondary,
            ),
          ),
        );
      },
    );
  }

  /// 弹出更多菜单 - 锚定更多按钮左下角
  void _showMoreMenu(BuildContext btnCtx) {
    final renderBox = btnCtx.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(btnCtx).context.findRenderObject() as RenderBox?;
    RelativeRect position;
    if (renderBox != null && overlay != null) {
      final btnSize = renderBox.size;
      final btnOffset =
          renderBox.localToGlobal(Offset.zero, ancestor: overlay);
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
        const PopupMenuItem<String>(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block, size: 16, color: BMColors.textSecondary),
              SizedBox(width: 10),
              Text(
                '拉黑',
                style: TextStyle(fontSize: 13, color: BMColors.textPrimary),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.report_outlined,
                  size: 16, color: BMColors.textSecondary),
              SizedBox(width: 10),
              Text(
                '举报',
                style: TextStyle(fontSize: 13, color: BMColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    ).then((String? value) {
      if (value == null) return;
      onMoreAction?.call(value, topic.topicId);
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

  /// 构建话题标签 (单 #标签 胶囊)
  Widget _buildHashtagWrap() {
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

  /// 构建内容文本 (AI洞察)
  Widget _buildContentText() {
    return Text(
      topic.aiInsight,
      style: const TextStyle(
        fontSize: 12,
        height: 1.6,
        color: BMColors.textSecondary,
      ),
    );
  }

  /// 构建内嵌比赛简化卡片 (联赛名在左上角 + logo左+队名 vs logo右+队名 + 状态胶囊)
  Widget _buildEmbeddedMatch(BMMatchModel match) {
    final String leagueName = (match.competitionName != null && match.competitionName!.isNotEmpty)
        ? match.competitionName!
        : '';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: BMColors.pitch800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行: 左上角联赛名 + 右边状态胶囊
          Row(
            children: [
              if (leagueName.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(match.leagueColor).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    leagueName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(match.leagueColor),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _matchStatusBg(match.status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _matchStatusLabel(match),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _matchStatusText(match.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 第二行: 主队 logo + 队名 vs 客队 logo + 队名
          Row(
            children: [
              // 主队区: logo 左 + 队名 右
              _buildTeamLogo(
                logoUrl: match.homeTeam?.logoUrl ?? match.homeTeamLogo,
                teamShort: match.homeTeam?.teamShort ?? match.homeTeamName,
                fallbackIcon: _teamFallbackIcon(match.sportType),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  match.homeTeamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BMColors.bright,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'vs',
                style: TextStyle(
                  fontSize: 10,
                  color: BMColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              // 客队区: 队名 左 + logo 右
              Expanded(
                child: Text(
                  match.awayTeamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BMColors.bright,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildTeamLogo(
                logoUrl: match.awayTeam?.logoUrl ?? match.awayTeamLogo,
                teamShort: match.awayTeam?.teamShort ?? match.awayTeamName,
                fallbackIcon: _teamFallbackIcon(match.sportType),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建单支球队 logo 圆形 (16px, 加载失败显示队名缩写首字或图标)
  Widget _buildTeamLogo({
    required String? logoUrl,
    required String teamShort,
    required IconData fallbackIcon,
  }) {
    final String url = logoUrl ?? '';
    final String label = (teamShort.isNotEmpty && teamShort.length <= 3)
        ? teamShort
        : (teamShort.isNotEmpty ? teamShort.substring(0, 2).toUpperCase() : '');
    if (url.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 16,
          height: 16,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              if (label.isNotEmpty) {
                return Container(
                  color: BMColors.pitch900,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: BMColors.textSecondary,
                    ),
                  ),
                );
              }
              return Container(
                color: BMColors.pitch900,
                alignment: Alignment.center,
                child: Icon(fallbackIcon, size: 10, color: BMColors.textTertiary),
              );
            },
          ),
        ),
      );
    }
    // 无 logo 兜底
    if (label.isNotEmpty) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: BMColors.pitch900,
          shape: BoxShape.circle,
          border: Border.all(color: BMColors.pitch700, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            color: BMColors.textSecondary,
          ),
        ),
      );
    }
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: BMColors.pitch900,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: 10, color: BMColors.textTertiary),
    );
  }

  /// 根据运动类型取兜底图标 (足球/篮球)
  IconData _teamFallbackIcon(BMMatchSportType sport) {
    if (sport == BMMatchSportType.basketball) {
      return Icons.sports_basketball_outlined;
    }
    return Icons.sports_soccer_outlined;
  }

  Color _matchStatusBg(BMMatchStatus s) {
    switch (s) {
      case BMMatchStatus.live:
        return const Color(0xFFDC2626).withValues(alpha: 0.2);
      case BMMatchStatus.upcoming:
        return const Color(0xFF22D3EE).withValues(alpha: 0.2);
      case BMMatchStatus.ended:
        return const Color(0xFF64748B).withValues(alpha: 0.25);
      case BMMatchStatus.tbd:
        return const Color(0xFFF59E0B).withValues(alpha: 0.2);
    }
  }

  Color _matchStatusText(BMMatchStatus s) {
    switch (s) {
      case BMMatchStatus.live:
        return const Color(0xFFEF4444);
      case BMMatchStatus.upcoming:
        return const Color(0xFF22D3EE);
      case BMMatchStatus.ended:
        return const Color(0xFF94A3B8);
      case BMMatchStatus.tbd:
        return const Color(0xFFF59E0B);
    }
  }

  String _matchStatusLabel(BMMatchModel m) {
    if (m.liveMinute != null && m.liveMinute!.isNotEmpty) return m.liveMinute!;
    if (m.statusName != null && m.statusName!.isNotEmpty) return m.statusName!;
    switch (m.status) {
      case BMMatchStatus.live:
        return 'LIVE';
      case BMMatchStatus.upcoming:
        return m.matchTime.isNotEmpty ? m.matchTime : '未开始';
      case BMMatchStatus.ended:
        return 'FT';
      case BMMatchStatus.tbd:
        return 'TBD';
    }
  }

  /// 操作栏 (按要求删除信心 85% 胶囊, 保留空占位保持间距)
  Widget _buildActionBar() {
    return const SizedBox.shrink();
  }
}

/// BMHotTopicsSection - 热门话题列表区域 (首页第三段用, 直接用 TopicPostCard 组合)
/// 修改点3: 替换原"今日重点偏离模型简报"为"热门话题"
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
              child: TopicPostCard(
                topic: topic,
                onTap: () => onTopicTap?.call(topic),
                onMoreAction: (_, __) {},
              ),
            )),
      ],
    );
  }
}
