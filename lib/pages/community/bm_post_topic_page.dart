import 'package:flutter/material.dart';

import '../../models/bm_search_match_model.dart';
import '../../services/bm_community_api_service.dart';
import '../../theme/bm_colors.dart';
import '../../utils/bm_auth_manager.dart';
import '../bm_base_page.dart';
import '../login/bm_login_page.dart';
import 'bm_post_topic_match_search_page.dart';

/// BMPostTopicPage - 发布话题页 (话题列表页右上角「发布」push 进来)
/// 功能与接口对齐 hanklive HankPostCommunityPage:
///   1. 顶部: 话题内容多行输入框 (至少10字)
///   2. 中间: 关联比赛入口 (push 搜索页选择, 可移除)
///   3. 底部: 多选话题标签菜单 (固定候选池随机展示 + 换一批)
///   4. 发布: POST /api/livespeed/community/save
///      参数: {id: 0, content, images: [话题逗号串], match_type, match_id}
///   5. 未登录先跳登录页
/// 界面差异化: 深色球场绿主题 (pitch950 底 + 亮绿主色 + 描边输入区 + 底部固定发布条),
///   参照页为浅紫白底 + 顶栏 Post 按钮布局, 视觉完全区分
class BMPostTopicPage extends BMBasePage {
  const BMPostTopicPage({super.key});

  @override
  State<BMPostTopicPage> createState() => _BMPostTopicPageState();
}

class _BMPostTopicPageState extends BMBasePageState<BMPostTopicPage> {
  /// 内容输入控制器 (TextEditingController 类型)
  final TextEditingController _contentController = TextEditingController();

  /// 社区 API 服务 (BMCommunityApiService 类型, 发布接口)
  final BMCommunityApiService _apiService = BMCommunityApiService();

  /// 话题候选池 (List<String> 类型, 对齐 hanklive 12 个话题)
  static const List<String> _allTopics = [
    '比赛讨论',
    '战术分析',
    '转会动态',
    '装备评测',
    '冠军预测',
    '青训观察',
    '球迷故事',
    '赛果竞猜',
    '球员点评',
    '历史回顾',
    '规则解读',
    '联赛总结',
  ];

  /// 当前展示的话题 (List<String> 类型, 候选池随机取5个)
  List<String> _topics = [];

  /// 已选话题 (List<String> 类型, 多选)
  final List<String> _selectedTopics = [];

  /// 已选关联比赛 (BMSearchMatch? 类型, null=未关联)
  BMSearchMatch? _selectedMatch;

  /// 发布中 (bool 类型, 防重复提交)
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // 初始随机展示 5 个话题
    _topics = _randomTopics(5);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 从候选池随机取 N 个未展示的话题
  /// [count] - 取出数量 (int 类型)
  /// 返回: List<String> 随机话题列表
  List<String> _randomTopics(int count) {
    final pool = List<String>.from(_allTopics);
    pool.shuffle();
    return pool.take(count).toList();
  }

  /// 换一批话题 (排除当前展示的, 重置随机)
  void _shuffleTopics() {
    setState(() {
      _topics = _randomTopics(5);
    });
  }

  /// 切换话题选中态 (多选)
  /// [topic] - 话题标签 (String 类型)
  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  /// 跳转比赛搜索页选择关联比赛 (pop 返回 BMSearchMatch)
  Future<void> _pickMatch() async {
    final match = await Navigator.push<BMSearchMatch>(
      context,
      MaterialPageRoute(builder: (_) => const BMPostTopicMatchSearchPage()),
    );
    if (match != null) {
      setState(() => _selectedMatch = match);
    }
  }

  /// 移除已关联比赛
  void _removeMatch() {
    setState(() => _selectedMatch = null);
  }

  /// 发布话题 (POST /api/livespeed/community/save)
  /// 校验: 内容至少10字 → 未登录跳登录 → 提交 → 成功 pop(true)
  Future<void> _handlePublish() async {
    final content = _contentController.text.trim();
    if (content.length < 10) {
      _toast('话题内容至少输入10个字');
      return;
    }
    // 未登录先去登录, 登录成功继续发布
    if (!BMAuthManager().isLoggedIn) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const BMLoginPage()),
      );
      if (ok != true) return;
    }
    setState(() => _isPublishing = true);
    final (ok, msg) = await _apiService.saveTopicPost(
      content: content,
      topics: _selectedTopics,
      matchId: _selectedMatch?.matchId,
      matchType: _selectedMatch?.categoryId,
    );
    if (!mounted) return;
    if (ok) {
      _toast('发布成功');
      Navigator.pop(context, true);
      return;
    }
    setState(() => _isPublishing = false);
    _toast(msg);
  }

  /// SnackBar 提示
  /// [message] - 提示文案 (String 类型)
  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Container(
      color: BMColors.pitch950,
      child: Column(
        children: [
          _buildNavBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContentInput(),
                  const SizedBox(height: 14),
                  _buildMatchSection(),
                  const SizedBox(height: 14),
                  _buildTopicsSection(),
                ],
              ),
            ),
          ),
          _buildPublishBar(),
        ],
      ),
    );
  }

  /// 顶部导航 (返回 + 标题)
  Widget _buildNavBar() {
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
            onPressed: () => Navigator.pop(context),
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
              '发布话题',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// 第 1 段: 话题内容输入框 (深色描边 + 角标计数)
  Widget _buildContentInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _contentController,
            maxLines: 6,
            maxLength: 500,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: BMColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: '分享你的观点, 至少输入10个字...',
              hintStyle: TextStyle(
                color: BMColors.textTertiary,
                fontSize: 13,
              ),
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (_) {
              if (mounted) setState(() {});
            },
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _contentController,
            builder: (_, value, __) {
              return Text(
                '${value.text.length}/500',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: BMColors.textTertiary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 第 2 段: 关联比赛入口 (未选=入口卡片 / 已选=比赛卡片可移除)
  Widget _buildMatchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              const Icon(
                Icons.sports_soccer,
                size: 14,
                color: BMColors.bright,
              ),
              const SizedBox(width: 5),
              const Text(
                '关联比赛',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: BMColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: BMColors.pitch900,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: BMColors.pitch800),
                ),
                child: const Text(
                  '选填',
                  style: TextStyle(
                    fontSize: 10,
                    color: BMColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 内容区
        if (_selectedMatch == null) _buildMatchEntry() else _buildMatchCard(),
      ],
    );
  }

  /// 未关联时的入口卡片 (左侧亮绿加号圆形 + 引导文案, 点击进搜索页)
  /// 差异化: 参照页为虚线边框整卡居中, 本页为左对齐横排入口
  Widget _buildMatchEntry() {
    return GestureDetector(
      onTap: _pickMatch,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: BMColors.pitch900.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: BMColors.bright.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: BMColors.bright.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: BMColors.bright.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.add,
                size: 18,
                color: BMColors.bright,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '点击选择比赛',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: BMColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '关联比赛后话题展示比赛卡片',
                    style: TextStyle(
                      fontSize: 11,
                      color: BMColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: BMColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  /// 已关联比赛卡片 (联赛名 + 主客队标队名比分 + 右上移除按钮)
  Widget _buildMatchCard() {
    final m = _selectedMatch!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.bright.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // 联赛名 + 移除按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  m.competitionName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: BMColors.bright,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _removeMatch,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: BMColors.pitch800,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 13,
                    color: BMColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 主队 + 比分 + 客队
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildTeamLogo(m.homeTeamLogo, 34),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        m.homeTeamName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BMColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${m.homeTeamScore ?? 0} - ${m.awayTeamScore ?? 0}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: BMColors.bright,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        m.awayTeamName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BMColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTeamLogo(m.awayTeamLogo, 34),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 第 3 段: 多选话题菜单 (候选随机展示 + 换一批 + 多选 chips)
  Widget _buildTopicsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行 + 换一批
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择话题',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: BMColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: _shuffleTopics,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: const [
                    Icon(Icons.refresh, size: 12, color: BMColors.bright),
                    SizedBox(width: 3),
                    Text(
                      '换一批',
                      style: TextStyle(
                        fontSize: 11,
                        color: BMColors.bright,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 多选 chips (选中=亮绿描边+亮字, 未选=灰字)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topics.map((topic) {
              final selected = _selectedTopics.contains(topic);
              return GestureDetector(
                onTap: () => _toggleTopic(topic),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? BMColors.bright.withValues(alpha: 0.15)
                        : BMColors.pitch950.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? BMColors.bright
                          : BMColors.pitch800,
                      width: selected ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(
                          Icons.check,
                          size: 11,
                          color: BMColors.bright,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        topic,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? BMColors.bright
                              : BMColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 底部固定发布条 (左侧已选话题计数 + 右侧发布按钮)
  /// 差异化: 参照页 Post 按钮在顶栏, 本页为底部通栏大按钮
  Widget _buildPublishBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        border: Border(
          top: BorderSide(color: BMColors.pitch800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 已选话题计数
          Text(
            '已选话题 ${_selectedTopics.length}',
            style: const TextStyle(
              fontSize: 11,
              color: BMColors.textTertiary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _isPublishing ? null : _handlePublish,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isPublishing
                      ? BMColors.bright.withValues(alpha: 0.4)
                      : BMColors.bright,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isPublishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BMColors.pitch950,
                        ),
                      )
                    : const Text(
                        '发布',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: BMColors.pitch950,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 队标 (圆形深色底 + 网络 Logo + 失败兜底盾牌图标)
  /// [url] - Logo URL (String? 类型)
  /// [size] - 尺寸 (double 类型)
  Widget _buildTeamLogo(String? url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: BMColors.pitch800,
      ),
      child: ClipOval(
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(size),
              )
            : _fallbackIcon(size),
      ),
    );
  }

  /// 队标兜底图标 (盾牌)
  /// [size] - 尺寸 (double 类型)
  Widget _fallbackIcon(double size) {
    return Icon(
      Icons.shield,
      size: size * 0.55,
      color: BMColors.textTertiary,
    );
  }
}
