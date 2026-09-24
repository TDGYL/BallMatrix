import 'package:flutter/material.dart';

import '../../models/bm_comment_model.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_post_api_model.dart';
import '../../services/bm_community_api_service.dart';
import '../../theme/bm_colors.dart';
import '../../utils/bm_auth_manager.dart';
import '../bm_base_page.dart';
import '../login/bm_login_page.dart';
import '../match/bm_basketball_detail_page.dart';
import '../match/bm_football_detail_page.dart';

/// BMTopicDetailPage - 话题详情页
/// 功能与接口对齐 hanklive HankCommunityDetailPage:
///   - 帖子详情:  GET /api/livespeed/community/detail (id)
///   - 评论列表:  GET /api/livespeed/community/comment/list (object_id)
///   - 发评论/回复: POST /api/livespeed/community/comment/add
///   - 评论点赞:  POST /api/livespeed/support
///   - 帖子点赞:  POST /api/livespeed/community/like
///   - 删除帖子:  POST /api/livespeed/community/delete (自己的帖子, 导航替换关注按钮)
///   - 关注作者:  POST /api/livespeed/imchat/subscribe
/// 界面差异化: 深色球场绿主题 (pitch950 底 + 左侧亮绿竖线内容卡片 + 底部通栏深色评论栏),
///   参照页为浅紫白底 + 圆角白卡片 + 圆形紫色发送按钮, 视觉完全区分
class BMTopicDetailPage extends BMBasePage {
  /// 帖子ID (int 类型, 必传, 请求详情与评论列表)
  final int postId;

  /// 列表预传帖子数据 (BMPostItem? 类型, 可选, 减少首屏白屏)
  final BMPostItem? initialPost;

  /// 构造函数
  const BMTopicDetailPage({super.key, required this.postId, this.initialPost});

  @override
  State<BMTopicDetailPage> createState() => _BMTopicDetailPageState();
}

class _BMTopicDetailPageState extends BMBasePageState<BMTopicDetailPage> {
  /// 社区 API 服务 (BMCommunityApiService 类型)
  final BMCommunityApiService _apiService = BMCommunityApiService();

  /// 帖子详情数据 (BMPostItem? 类型, 懒加载)
  BMPostItem? _post;

  /// 评论列表 (List<BMCommentItem> 类型)
  List<BMCommentItem> _comments = [];

  /// 评论总数 (int 类型)
  int _commentTotal = 0;

  /// 详情加载中 (bool 类型)
  bool _isLoadingDetail = false;

  /// 评论加载中 (bool 类型)
  bool _isLoadingComments = false;

  /// 是否已点赞帖子 (bool 类型, 本地缓存状态)
  bool _isLiked = false;

  /// 是否已关注作者 (bool 类型)
  bool _isFollowing = false;

  /// 是否自己的帖子 (bool 类型, true 时导航显示删除按钮)
  bool _isOwnPost = false;

  /// 评论输入控制器 (TextEditingController 类型)
  final TextEditingController _inputController = TextEditingController();

  /// 评论输入焦点 (FocusNode 类型)
  final FocusNode _inputFocusNode = FocusNode();

  /// 当前回复的评论 (BMCommentItem? 类型, null=直接评论帖子)
  BMCommentItem? _replyingTo;

  /// 初始化: 优先用预传数据, 再请求详情与评论
  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _post = widget.initialPost;
      _isLiked = widget.initialPost!.isLike ?? false;
      _isFollowing = widget.initialPost!.author?.isSubscribe ?? false;
      _checkOwnPost();
    }
    _fetchPostDetail();
    _fetchComments();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// 检查是否自己的帖子 (当前登录用户ID == 作者ID)
  void _checkOwnPost() {
    final currentUserId = BMAuthManager().currentUser?.id;
    final authorId = _post?.author?.id;
    if (currentUserId != null && authorId != null) {
      _isOwnPost = currentUserId == authorId;
    }
  }

  /// 请求帖子详情 (GET /api/livespeed/community/detail)
  Future<void> _fetchPostDetail() async {
    setState(() {
      _isLoadingDetail = true;
    });
    final result = await _apiService.fetchPostDetail(postId: widget.postId);
    if (!mounted) return;
    setState(() {
      if (result != null) {
        _post = result;
        _isLiked = result.isLike ?? false;
        _isFollowing = result.author?.isSubscribe ?? false;
        _checkOwnPost();
      }
      _isLoadingDetail = false;
    });
  }

  /// 请求评论列表 (GET /api/livespeed/community/comment/list)
  Future<void> _fetchComments() async {
    setState(() {
      _isLoadingComments = true;
    });
    final result = await _apiService.fetchComments(objectId: widget.postId);
    if (!mounted) return;
    setState(() {
      if (result != null) {
        _comments = result.results;
        _commentTotal = result.total ?? result.results.length;
      }
      _isLoadingComments = false;
    });
  }

  /// 帖子点赞/取消 (POST /api/livespeed/community/like) 乐观更新
  Future<void> _toggleLike() async {
    if (!BMAuthManager().isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    final newIsLiked = !_isLiked;
    setState(() {
      _isLiked = newIsLiked;
    });
    final success = await _apiService.likePost(
      postId: widget.postId,
      type: newIsLiked ? 1 : 2,
    );
    if (!success && mounted) {
      setState(() {
        _isLiked = !newIsLiked;
      });
      _showToast('操作失败, 请重试');
    }
  }

  /// 评论点赞/取消 (POST /api/livespeed/support) 乐观更新
  /// [comment] - 目标评论 (BMCommentItem 类型)
  Future<void> _toggleCommentSupport(BMCommentItem comment) async {
    if (!BMAuthManager().isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    final newIsSupport = !(comment.isSupport ?? false);
    final oldCount = comment.support ?? 0;
    final newCount = newIsSupport
        ? oldCount + 1
        : (oldCount > 0 ? oldCount - 1 : 0);
    setState(() {
      comment.isSupport = newIsSupport;
      comment.support = newCount;
    });
    final success = await _apiService.supportComment(
      objectId: comment.id ?? 0,
      isSupport: newIsSupport,
    );
    if (!success && mounted) {
      setState(() {
        comment.isSupport = !newIsSupport;
        comment.support = newIsSupport ? newCount - 1 : newCount + 1;
      });
      _showToast('操作失败, 请重试');
    }
  }

  /// 关注/取消关注作者 (POST /api/livespeed/imchat/subscribe) 乐观更新
  Future<void> _toggleFollowAuthor() async {
    if (!BMAuthManager().isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    final authorId = _post?.author?.id;
    if (authorId == null) return;
    final newFollowing = !_isFollowing;
    setState(() {
      _isFollowing = newFollowing;
    });
    final success = await _apiService.toggleFollowAuthor(
      targetId: authorId,
      type: newFollowing ? 1 : 2,
    );
    if (!success && mounted) {
      setState(() {
        _isFollowing = !newFollowing;
      });
      _showToast('操作失败, 请重试');
    } else if (mounted) {
      _showToast(newFollowing ? '已关注' : '已取消关注');
    }
  }

  /// 删除帖子 (POST /api/livespeed/community/delete) 二次弹窗确认
  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BMColors.pitch850,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.5)),
        ),
        title: const Text(
          '删除帖子',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BMColors.textPrimary,
          ),
        ),
        content: const Text(
          '确定要删除这篇帖子吗?',
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
              '删除',
              style: TextStyle(fontSize: 14, color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await _apiService.deletePost(postId: widget.postId);
    if (!mounted) return;
    if (success) {
      _showToast('帖子已删除');
      Navigator.pop(context, true);
    } else {
      _showToast('删除失败, 请重试');
    }
  }

  /// 开始回复某条评论 (填充回复目标并聚焦输入框)
  /// [comment] - 目标评论 (BMCommentItem 类型)
  void _startReply(BMCommentItem comment) {
    if (!BMAuthManager().isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    setState(() {
      _replyingTo = comment;
    });
    FocusScope.of(context).requestFocus(_inputFocusNode);
  }

  /// 取消回复模式
  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _inputController.clear();
    });
    _inputFocusNode.unfocus();
  }

  /// 提交评论/回复 (POST /api/livespeed/community/comment/add)
  Future<void> _submitComment() async {
    final words = _inputController.text.trim();
    if (words.isEmpty) return;
    if (!BMAuthManager().isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    // 回复一级评论时取 parent_id (若回复的是子评论则用其父评论ID)
    int? commentId;
    if (_replyingTo != null) {
      final parent = _replyingTo!.parentId;
      commentId = (parent != null && parent != 0) ? parent : _replyingTo!.id;
    }
    final newComment = await _apiService.addComment(
      objectId: widget.postId,
      words: words,
      commentId: commentId,
    );
    if (!mounted) return;
    if (newComment != null) {
      _insertComment(newComment, commentId);
      setState(() {
        _commentTotal++;
        _inputController.clear();
        _replyingTo = null;
      });
      _inputFocusNode.unfocus();
    } else {
      _showToast('评论失败, 请重试');
    }
  }

  /// 新评论插入列表 (直接评论插头部, 回复插入对应一级评论的子列表)
  /// [newComment] - 新评论数据 (BMCommentItem 类型)
  /// [commentId] - 非null表示回复, 插入对应一级评论 (int? 类型)
  void _insertComment(BMCommentItem newComment, int? commentId) {
    if (commentId == null) {
      _comments.insert(0, newComment);
    } else {
      for (final parent in _comments) {
        if (parent.id == commentId) {
          parent.showChildComments ??= [];
          parent.showChildComments!.add(newComment);
          parent.remainChildCommentCount =
              (parent.remainChildCommentCount ?? 0) + 1;
          break;
        }
      }
    }
  }

  /// 登录引导弹窗 (未登录时操作触发)
  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BMColors.pitch850,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.5)),
        ),
        title: const Text(
          '提示',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BMColors.textPrimary,
          ),
        ),
        content: const Text(
          '请先登录后再操作',
          style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '取消',
              style: TextStyle(fontSize: 14, color: BMColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BMLoginPage()),
              );
            },
            child: const Text(
              '去登录',
              style: TextStyle(fontSize: 14, color: BMColors.bright),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示 toast
  /// [message] - 提示文案 (String 类型)
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: BMColors.pitch800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 格式化时间戳为可读文案
  /// [timestamp] - 秒级时间戳 (int? 类型)
  /// 返回: 如 "2分钟前" / "3小时前" / "5天前" / "03-12"
  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 比赛卡跳转对应比赛详情 (按球类型分流: match_type=2 篮球 / 其他 足球)
  /// [match] - 帖子关联比赛数据 (BMPostMatch 类型)
  void _pushToMatchDetail(BMPostMatch match) {
    final int? matchId = match.matchId;
    if (matchId == null) return;
    final int matchType = match.matchType ?? 1;
    // 构建 BMMatchModel (复用详情页展示字段)
    final model = _buildMatchModel(match);
    Navigator.push(
      context,
      MaterialPageRoute(
        // 球类型分流: match_type=2 -> 篮球详情, 其他 -> 足球详情
        builder: (_) => matchType == 2
            ? BMBasketballDetailPage(match: model)
            : BMFootballDetailPage(match: model),
      ),
    );
  }

  /// BMPostMatch 转 BMMatchModel (跳转比赛详情页用)
  /// [m] - 帖子关联比赛数据 (BMPostMatch 类型)
  /// 返回: BMMatchModel
  BMMatchModel _buildMatchModel(BMPostMatch m) {
    final int? statusId = m.statusId;
    final int matchType = m.matchType ?? 1;
    final sport = matchType == 2
        ? BMMatchSportType.basketball
        : BMMatchSportType.football;
    // 状态映射: 篮球 1|13未开始 2-9进行 10|11结束 / 足球 1未开始 2-5|7进行 8结束
    BMMatchStatus status;
    if (sport == BMMatchSportType.basketball) {
      switch (statusId) {
        case 1:
        case 13:
          status = BMMatchStatus.upcoming;
          break;
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
          status = BMMatchStatus.live;
          break;
        case 10:
        case 11:
          status = BMMatchStatus.ended;
          break;
        default:
          status = BMMatchStatus.tbd;
      }
    } else {
      switch (statusId) {
        case 1:
          status = BMMatchStatus.upcoming;
          break;
        case 2:
        case 3:
        case 4:
        case 5:
        case 7:
          status = BMMatchStatus.live;
          break;
        case 8:
          status = BMMatchStatus.ended;
          break;
        default:
          status = BMMatchStatus.tbd;
      }
    }
    // 开赛时间格式化 (秒级时间戳 -> HH:mm)
    String matchTime = '';
    final int? startTs = m.startTime;
    if (startTs != null && startTs > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(startTs * 1000);
      matchTime =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return BMMatchModel(
      matchId: m.matchId?.toString() ?? '',
      leagueName: m.competitionName ?? '',
      status: status,
      statusId: statusId,
      statusName: m.statusName,
      sportType: sport,
      matchTime: matchTime,
      homeTeam: BMTeamModel(
        teamId: m.homeTeamId?.toString() ?? '',
        teamName: m.homeTeamName ?? '',
        teamShort: '',
        logoUrl: m.homeTeamLogo,
      ),
      awayTeam: BMTeamModel(
        teamId: m.awayTeamId?.toString() ?? '',
        teamName: m.awayTeamName ?? '',
        teamShort: '',
        logoUrl: m.awayTeamLogo,
      ),
      homeScore: m.homeScore,
      awayScore: m.awayScore,
      isFeatured: false,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Container(
      color: BMColors.pitch950,
      child: Column(
        children: [
          _buildNavBar(),
          Expanded(child: _buildBody()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// 顶部导航 (返回 + 标题 + 关注按钮/删除按钮)
  Widget _buildNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
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
              '话题详情',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary,
              ),
            ),
          ),
          // 自己的帖子显示删除按钮, 他人帖子显示关注按钮
          if (_isOwnPost)
            GestureDetector(
              onTap: _deletePost,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline,
                        size: 14, color: Color(0xFFDC2626)),
                    SizedBox(width: 4),
                    Text(
                      '删除',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _toggleFollowAuthor,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isFollowing
                      ? BMColors.pitch800
                      : BMColors.bright.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _isFollowing ? BMColors.pitch700 : BMColors.bright,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFollowing ? Icons.check : Icons.add,
                      size: 14,
                      color: _isFollowing
                          ? BMColors.textTertiary
                          : BMColors.bright,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isFollowing ? '已关注' : '关注',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isFollowing
                            ? BMColors.textTertiary
                            : BMColors.bright,
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

  /// 主体内容 (作者卡 + 内容 + 话题标签 + 比赛卡 + 互动栏 + 评论列表)
  Widget _buildBody() {
    if (_isLoadingDetail && _post == null) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: BMColors.bright,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_post == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline, size: 44, color: BMColors.pitch600),
            SizedBox(height: 12),
            Text(
              '加载失败',
              style: TextStyle(color: BMColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        _buildAuthorCard(),
        const SizedBox(height: 12),
        _buildContentCard(),
        if (_parseHashtags().isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildTagsRow(),
        ],
        if (_post!.match != null) ...[
          const SizedBox(height: 12),
          // 比赛卡点击按球类型跳转对应比赛详情 (match_type=2 篮球 / 其他 足球)
          GestureDetector(
            onTap: () => _pushToMatchDetail(_post!.match!),
            behavior: HitTestBehavior.opaque,
            child: _buildMatchCard(),
          ),
        ],
        const SizedBox(height: 12),
        _buildStatsRow(),
        const SizedBox(height: 18),
        _buildCommentsHeader(),
        _buildCommentsList(),
      ],
    );
  }

  /// 作者信息卡 (头像 + 昵称 + 发布时间)
  Widget _buildAuthorCard() {
    final author = _post!.author;
    return Row(
      children: [
        _buildAvatar(author?.avatar, author?.name ?? '球迷', 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author?.name ?? '匿名球迷',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: BMColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatTime(_post!.createTime),
                style: const TextStyle(
                  fontSize: 11,
                  color: BMColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 内容卡片 (深色卡 + 左侧亮绿竖线)
  Widget _buildContentCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, decoration: BoxDecoration(color: BMColors.bright)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _post!.content ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: BMColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 解析话题标签 (image 逗号切割 + 过滤 com/ 前缀, 逐段过滤)
  List<String> _parseHashtags() {
    final rawImage = (_post!.images != null && _post!.images!.isNotEmpty)
        ? _post!.images!.first
        : _post!.image;
    if (rawImage == null || rawImage.isEmpty) return [];
    return rawImage
        .split(',')
        .map((seg) {
          final s = seg.trim();
          final idx = s.indexOf('com/');
          return idx >= 0 ? s.substring(idx + 4).trim() : s;
        })
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// 话题标签横排 (多个 # 标签胶囊)
  Widget _buildTagsRow() {
    final tags = _parseHashtags();
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: BMColors.bright.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BMColors.bright.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '#${tags[index]}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BMColors.bright,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 关联比赛卡 (联赛名 + 状态 + 主客队标队名 + 比分, 深色球场风)
  Widget _buildMatchCard() {
    final match = _post!.match!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.bright.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // 联赛名 + 状态胶囊
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  size: 13, color: BMColors.bright),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  match.competitionName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BMColors.bright,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: BMColors.pitch800,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  match.statusName ?? '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: BMColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 主队 + 比分 + 客队
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildTeamLogo(match.homeTeamLogo, 34),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        match.homeTeamName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BMColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                  style: const TextStyle(
                    fontSize: 16,
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
                        match.awayTeamName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BMColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTeamLogo(match.awayTeamLogo, 34),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 互动数据栏 (点赞 + 评论数 + 开赛时间)
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleLike,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color:
                  _isLiked ? const Color(0xFFDC2626) : BMColors.textTertiary,
            ),
          ),
          const SizedBox(width: 22),
          const Icon(
            Icons.chat_bubble_outline,
            size: 15,
            color: BMColors.textTertiary,
          ),
          const SizedBox(width: 5),
          Text(
            '$_commentTotal',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: BMColors.textTertiary,
            ),
          ),
          const Spacer(),
          if (_post!.match?.startTime != null)
            Text(
              '开赛 ${_formatTime(_post!.match!.startTime)}',
              style: const TextStyle(
                fontSize: 11,
                color: BMColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  /// 评论区分区标题
  Widget _buildCommentsHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: BMColors.bright,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '全部评论 $_commentTotal',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: BMColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 评论列表 (加载中/空态/数据态三分支)
  Widget _buildCommentsList() {
    if (_isLoadingComments && _comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: BMColors.bright,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            '暂无评论, 快来抢沙发~',
            style: TextStyle(fontSize: 12, color: BMColors.textTertiary),
          ),
        ),
      );
    }
    return Column(
      children: _comments.map(_buildCommentCard).toList(),
    );
  }

  /// 单条评论卡片 (深色卡 + 头像昵称时间 + 内容 + 子回复 + 点赞回复操作)
  /// [comment] - 评论数据 (BMCommentItem 类型)
  Widget _buildCommentCard(BMCommentItem comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像 + 昵称 + 时间 (点击整个头部对该一级评论回复)
          GestureDetector(
            onTap: () => _startReply(comment),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _buildAvatar(comment.userPic, comment.userName ?? '球迷', 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName ?? '匿名球迷',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BMColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatTime(comment.commentTime),
                        style: const TextStyle(
                          fontSize: 10,
                          color: BMColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 评论内容
          Text(
            comment.deletedAt != null ? '该评论已删除' : (comment.words ?? ''),
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: BMColors.textSecondary,
              fontStyle:
                  comment.deletedAt != null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          // 子回复列表
          if (comment.showChildComments != null &&
              comment.showChildComments!.isNotEmpty)
            ...comment.showChildComments!
                .map((child) => _buildChildComment(child)),
          // 点赞操作 (回复入口已移至一级评论头部点击)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleCommentSupport(comment),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (comment.isSupport ?? false)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 13,
                        color: (comment.isSupport ?? false)
                            ? const Color(0xFFDC2626)
                            : BMColors.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${comment.support ?? 0}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: (comment.isSupport ?? false)
                              ? const Color(0xFFDC2626)
                              : BMColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 子回复条目 (昵称 回复 @昵称: 内容 + 时间/回复操作)
  /// [child] - 子回复数据 (BMCommentItem 类型)
  Widget _buildChildComment(BMCommentItem child) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: child.userName ?? '球迷',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BMColors.bright,
                  ),
                ),
                if (child.replyToUserName != null &&
                    child.replyToUserName!.isNotEmpty) ...[
                  const TextSpan(
                    text: ' 回复 ',
                    style: TextStyle(
                      fontSize: 12,
                      color: BMColors.textTertiary,
                    ),
                  ),
                  TextSpan(
                    text: child.replyToUserName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BMColors.bright,
                    ),
                  ),
                ],
                TextSpan(
                  text: '：${child.words ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BMColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 时间 (回复入口: 点击子评论内容区对其回复)
          GestureDetector(
            onTap: () => _startReply(child),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(child.commentTime),
                  style: const TextStyle(
                    fontSize: 10,
                    color: BMColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 底部栏 (已登录=评论输入框 / 未登录=登录引导入口)
  Widget _buildBottomBar() {
    if (!BMAuthManager().isLoggedIn) {
      // 未登录: 引导登录入口
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: BMColors.pitch900,
          border: Border(
            top: BorderSide(color: BMColors.pitch800, width: 0.5),
          ),
        ),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BMLoginPage()),
          ),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BMColors.bright.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BMColors.bright.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 15, color: BMColors.bright),
                SizedBox(width: 6),
                Text(
                  '登录后参与评论',
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
      );
    }
    // 已登录: 评论输入框 + 发送按钮 (含回复模式提示)
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        border: Border(
          top: BorderSide(color: BMColors.pitch800, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: BMColors.pitch850,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BMColors.pitch800),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 13, color: BMColors.bright),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '回复 ${_replyingTo!.userName ?? ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: BMColors.bright,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 13,
                        color: BMColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BMColors.pitch850,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BMColors.pitch800),
                  ),
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    style: const TextStyle(
                      fontSize: 13,
                      color: BMColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: _replyingTo != null
                          ? '回复 ${_replyingTo!.userName ?? ''}'
                          : '写下你的评论...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: BMColors.textTertiary,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitComment,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BMColors.bright,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '发送',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF06281A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 头像组件 (网络头像 + 失败兜底首字)
  /// [url] - 头像URL (String? 类型)
  /// [name] - 昵称 (String 类型, 兜底头像取首字)
  /// [size] - 尺寸 (double 类型)
  Widget _buildAvatar(String? url, String name, double size) {
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
                errorBuilder: (_, __, ___) => _defaultAvatar(name, size),
              )
            : _defaultAvatar(name, size),
      ),
    );
  }

  /// 默认头像 (昵称首字)
  /// [name] - 昵称 (String 类型)
  /// [size] - 尺寸 (double 类型)
  Widget _defaultAvatar(String name, double size) {
    final initial = name.isNotEmpty ? name.characters.first : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: BMColors.pitch700,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: BMColors.bright,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// 队标组件 (圆形深色底 + 网络 Logo + 兜底盾牌)
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
                errorBuilder: (_, __, ___) => Icon(
                  Icons.shield,
                  size: size * 0.5,
                  color: BMColors.textTertiary,
                ),
              )
            : Icon(
                Icons.shield,
                size: size * 0.5,
                color: BMColors.textTertiary,
              ),
      ),
    );
  }
}
