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

/// BMTopicDetailPage - topic detail page
/// featurealigned with API hanklive HankCommunityDetailPage:
/// - postdetail: GET /api/livespeed/community/detail (id)
/// - commentlist: GET /api/livespeed/community/comment/list (object_id)
/// - sendcomment/reply: POST /api/livespeed/community/comment/add
/// - commentlike: POST /api/livespeed/support
/// - postlike: POST /api/livespeed/community/like
/// - removepost: POST /api/livespeed/community/delete (own of post, navigationswapfollow button)
/// - followauthor: POST /api/livespeed/imchat/subscribe
/// UI differentiation: darkpitch green theme (pitch950 bottom + left sidebright greenlinecontentcard + bottomcommonbardarkcommentbar),
/// referencepageaswhitebottom + rounded cornerwhitecard + circlepurplesendsendbutton, visually distinct
class BMTopicDetailPage extends BMBasePage {
  /// postID (int type, required, requestdetailandcommentlist)
  final int postId;

  /// listpre-passpostdata (BMPostItem? type, optional, sublessfirst screenblank screen)
  final BMPostItem? initialPost;

  /// constructor
  const BMTopicDetailPage({super.key, required this.postId, this.initialPost});

  @override
  State<BMTopicDetailPage> createState() => _BMTopicDetailPageState();
}

class _BMTopicDetailPageState extends BMBasePageState<BMTopicDetailPage> {
  /// community API service (BMCommunityApiService type)
  final BMCommunityApiService _apiService = BMCommunityApiService();

  /// postdetaildata (BMPostItem? type, lazy load)
  BMPostItem? _post;

  /// commentlist (List<BMCommentItem> type)
  List<BMCommentItem> _comments = [];

  /// commenttotal (int type)
  int _commentTotal = 0;

  /// detailloadingin (bool type)
  bool _isLoadingDetail = false;

  /// commentloadingin (bool type)
  bool _isLoadingComments = false;

  /// liked or notpost (bool type, localcachestate)
  bool _isLiked = false;

  /// whetherfollowedauthor (bool type)
  bool _isFollowing = false;

  /// whetherown of post (bool type, true whennavigationdisplayremovebutton)
  bool _isOwnPost = false;

  /// commentinputcontroller (TextEditingController type)
  final TextEditingController _inputController = TextEditingController();

  /// commentinputpoint (FocusNode type)
  final FocusNode _inputFocusNode = FocusNode();

  /// currentreply of comment (BMCommentItem? type, null=commentpost)
  BMCommentItem? _replyingTo;

  /// initialize: priorityusepre-passdata, againrequestdetailandcomment
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

  /// checkwhetherown of post (currentloginuserID == authorID)
  void _checkOwnPost() {
    final currentUserId = BMAuthManager().currentUser?.id;
    final authorId = _post?.author?.id;
    if (currentUserId != null && authorId != null) {
      _isOwnPost = currentUserId == authorId;
    }
  }

  /// requestpostdetail (GET /api/livespeed/community/detail)
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

  /// requestcommentlist (GET /api/livespeed/community/comment/list)
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

  /// postlike/Take effect (POST /api/livespeed/community/like) optimistic update
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
      _showToast('operation failed, please retry');
    }
  }

  /// commentlike/Take effect (POST /api/livespeed/support) optimistic update
  /// [comment] - goalcomment (BMCommentItem type)
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
      _showToast('operation failed, please retry');
    }
  }

  /// follow/Take effectfollowauthor (POST /api/livespeed/imchat/subscribe) optimistic update
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
      _showToast('operation failed, please retry');
    } else if (mounted) {
      _showToast(newFollowing ? 'followed' : 'Unfollowed');
    }
  }

  /// removepost (POST /api/livespeed/community/delete) confirmation dialogconfirm
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
          'removepost',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BMColors.textPrimary,
          ),
        ),
        content: const Text(
          'needremovepost?',
          style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Take effect',
              style: TextStyle(fontSize: 14, color: BMColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'remove',
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
      _showToast('Post deleted');
      Navigator.pop(context, true);
    } else {
      _showToast('removefailure, please retry');
    }
  }

  /// startreplysomeitemscomment (fillreplygoalandinput field)
  /// [comment] - goalcomment (BMCommentItem type)
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

  /// Take effectreplymodulestyle
  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _inputController.clear();
    });
    _inputFocusNode.unfocus();
  }

  /// comment/reply (POST /api/livespeed/community/comment/add)
  Future<void> _submitComment() async {
    final words = _inputController.text.trim();
    if (words.isEmpty) return;
    if (!BMAuthManager().isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    // replylevel-1 commentwhentake parent_id (ifreply of yessubcommentthenuseitscommentID)
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
      _showToast('commentfailure, please retry');
    }
  }

  /// newcommentinsertlist (commentheader, replyinsertcorrespondinglevel-1 comment of sublist)
  /// [newComment] - newcommentdata (BMCommentItem type)
  /// [commentId] - nonnullmeansreply, insertcorrespondinglevel-1 comment (int? type)
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

  /// login guidedialog (not logged inwhendosend)
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
          'toast',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BMColors.textPrimary,
          ),
        ),
        content: const Text(
          'Login first to comment',
          style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Take effect',
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
              'login',
              style: TextStyle(fontSize: 14, color: BMColors.bright),
            ),
          ),
        ],
      ),
    );
  }

  /// display toast
  /// [message] - toasttext (String type)
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 1),
        backgroundColor: BMColors.pitch800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// formattimestampascanreadtext
  /// [timestamp] - secondlevel timestamp (int? type)
  /// returns: like "2minutefirst" / "3hourfirst" / "5dayfirst" / "03-12"
  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}minutefirst';
    if (diff.inHours < 24) return '${diff.inHours}hourfirst';
    if (diff.inDays < 30) return '${diff.inDays}dayfirst';
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// matchcardnavigatecorrespondingmatchdetail (by sport typesplit by: match_type=2 basketball / others football)
  /// [match] - postrelated match data (BMPostMatch type)
  void _pushToMatchDetail(BMPostMatch match) {
    final int? matchId = match.matchId;
    if (matchId == null) return;
    final int matchType = match.matchType ?? 1;
    // build BMMatchModel (reusedetailpageshowfield)
    final model = _buildMatchModel(match);
    Navigator.push(
      context,
      MaterialPageRoute(
        // sport typesplit by: match_type=2 -> basketball detail, others -> football detail
        builder: (_) => matchType == 2
            ? BMBasketballDetailPage(match: model)
            : BMFootballDetailPage(match: model),
      ),
    );
  }

  /// BMPostMatch convert BMMatchModel (navigatematch detail pageusage)
  /// [m] - postrelated match data (BMPostMatch type)
  /// returns: BMMatchModel
  BMMatchModel _buildMatchModel(BMPostMatch m) {
    final int? statusId = m.statusId;
    final int matchType = m.matchType ?? 1;
    final sport = matchType == 2
        ? BMMatchSportType.basketball
        : BMMatchSportType.football;
    // statemapping: basketball 1|13NS 2-9in progress 10|11end / football 1NS 2-5|7in progress 8end
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
    // kickoff timeformat (secondlevel timestamp -> HH:mm)
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

  /// topnavigation (returns + title + follow button/removebutton)
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
              'topic detail',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary,
              ),
            ),
          ),
          // own of postdisplayremovebutton, peoplepostdisplayfollow button
          if (_isOwnPost)
            GestureDetector(
              onTap: _deletePost,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                    Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'remove',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                      _isFollowing ? 'followed' : 'follow',
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

  /// main content (authorcard + content + topictag + matchcard + bar + commentlist)
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
              'Load Failed',
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
          // matchcardtapby sport typenavigatecorrespondingmatchdetail (match_type=2 basketball / others football)
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

  /// authorinfocard (avatar + nickname + publishtime)
  Widget _buildAuthorCard() {
    final author = _post!.author;
    return Row(
      children: [
        _buildAvatar(author?.avatar, author?.name ?? 'fans', 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author?.name ?? 'namefans',
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

  /// contentcard (darkcard + left sidebright greenline)
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
            Container(
              width: 3,
              decoration: BoxDecoration(color: BMColors.bright),
            ),
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

  /// parsetopictag (image comma split + filter com/ first, sectionfilter)
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

  /// topictagorder (multiple # tagpill)
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
              border: Border.all(color: BMColors.bright.withValues(alpha: 0.4)),
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

  /// related matchcard (league name + state + home/away team logoteam name + score, darkballcourt)
  Widget _buildMatchCard() {
    final match = _post!.match!;
    // stateby statusId + sportTyperulecheck (sameaslistcard, reference BMMatchModel.displayStatusLabel)
    final String statusLabel = _buildMatchModel(match).displayStatusLabel;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.bright.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // league name + statepill
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 13, color: BMColors.bright),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: BMColors.pitch800,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  // stateby statusId + sportTyperulecheck (sameaslistcard)
                  statusLabel == '-' ? (match.statusName ?? '') : statusLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: BMColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // home team + score + away team
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

  /// databar (like + commentcount + kickoff time)
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
              color: _isLiked ? const Color(0xFFDC2626) : BMColors.textTertiary,
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
              'open match ${_formatTime(_post!.match!.startTime)}',
              style: const TextStyle(
                fontSize: 11,
                color: BMColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  /// commentzonezone title
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
            'allcomment $_commentTotal',
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

  /// commentlist (loadingin/emptystate/datastatethreebranch)
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
            'No comment, fastsend~',
            style: TextStyle(fontSize: 12, color: BMColors.textTertiary),
          ),
        ),
      );
    }
    return Column(children: _comments.map(_buildCommentCard).toList());
  }

  /// singlecommentcard (darkcard + avatarnicknametime + content + subreply + likereplydo)
  /// [comment] - commentdata (BMCommentItem type)
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
          // avatar + nickname + time (tapwholeitemsheadercorrectthelevel-1 commentreply)
          GestureDetector(
            onTap: () => _startReply(comment),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _buildAvatar(comment.userPic, comment.userName ?? 'fans', 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName ?? 'namefans',
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
          // commentcontent
          Text(
            comment.deletedAt != null
                ? 'Comment deleted'
                : (comment.words ?? ''),
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: BMColors.textSecondary,
              fontStyle: comment.deletedAt != null
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
          // subreplylist
          if (comment.showChildComments != null &&
              comment.showChildComments!.isNotEmpty)
            ...comment.showChildComments!.map(
              (child) => _buildChildComment(child),
            ),
          // likedo (replyinputalreadylevel-1 commentheadertap)
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

  /// subreplyitemsitem (nickname reply @nickname: content + time/replydo)
  /// [child] - subreplydata (BMCommentItem type)
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
                  text: child.userName ?? 'fans',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BMColors.bright,
                  ),
                ),
                if (child.replyToUserName != null &&
                    child.replyToUserName!.isNotEmpty) ...[
                  const TextSpan(
                    text: ' reply ',
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
          // time (replyinput: tapsubcommentcontentzonecorrectitsreply)
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

  /// bottombar (logged in=commentinput field / not logged in=login guideinput)
  Widget _buildBottomBar() {
    if (!BMAuthManager().isLoggedIn) {
      // not logged in: logininput
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: BMColors.pitch900,
          border: Border(top: BorderSide(color: BMColors.pitch800, width: 0.5)),
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
                  'Login to comment',
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
    // logged in: commentinput field + sendsendbutton (includesreplymodulestyletoast)
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        border: Border(top: BorderSide(color: BMColors.pitch800, width: 0.5)),
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
                      'reply ${_replyingTo!.userName ?? ''}',
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
                          ? 'reply ${_replyingTo!.userName ?? ''}'
                          : 'writelower of comment...',
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
                    'send',
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

  /// avatarwidget (networkavatar + failurefallbacktext)
  /// [url] - avatarURL (String? type)
  /// [name] - nickname (String type, fallbackavatartaketext)
  /// [size] - size (double type)
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

  /// defaultavatar (nicknametext)
  /// [name] - nickname (String type)
  /// [size] - size (double type)
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

  /// team logowidget (dark circle background + network Logo + fallbackshield)
  /// [url] - Logo URL (String? type)
  /// [size] - size (double type)
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
