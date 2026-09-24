import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_topic_model.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_post_api_model.dart';
import '../../services/bm_community_api_service.dart';
import '../../widgets/home/bm_hot_topics_section.dart' show TopicPostCard;
import 'bm_post_topic_page.dart';
import 'bm_topic_detail_page.dart';
import '../login/bm_login_page.dart';
import '../../utils/bm_auth_manager.dart';

/// BMTopicListPage - topiclistpage (homethird section「view all」push enter)
/// feature: trueactualGETAPI(/api/livespeed/community/list, type='2') + reusehometopic card + pull downrefresh + pull uploading
class BMTopicListPage extends BMBasePage {
 const BMTopicListPage({
 super.key,
 });

 @override
 State<BMTopicListPage> createState() => _BMTopicListPageState();
}

class _BMTopicListPageState extends BMBasePageState<BMTopicListPage> {
 /// topiclistdata (List<BMTopicModel> type)
 List<BMTopicModel> _topicList = [];

 /// pull downrefreshor first loading (bool type, makeUIfullLoading)
 bool _isRefreshing = true;

 /// pull upload morein (bool type, control bottom footer Loading)
 bool _isLoadingMore = false;

 /// requestre-entry lock (bool type, prevent duplicate requests)
 bool _isFetching = false;

 /// has next page (bool type)
 bool _hasNoMore = false;

 /// current pagecode (int type, starting from 1, innerpartuseintadd, requestwhenconvertString)
 int _page = 1;

 /// per pagecount (int type, default10, requestwhenconvertString)
 final int _size = 10;

 /// listscrollcontroller (ScrollController type, pull uploadinglistener)
 late final ScrollController _scrollController;

 /// API serviceinstance (BMCommunityApiService type, singleton)
 final BMCommunityApiService _apiService = BMCommunityApiService();

 @override
 void initState() {
 super.initState();
 _scrollController = ScrollController()..addListener(_onScroll);
 _fetchTopicList(isRefresh: true);
 }

 @override
 void dispose() {
 _scrollController.dispose();
 super.dispose();
 }

 /// scrolllistener: trigger pull within 100px of bottom upload more
 void _onScroll() {
 if (_scrollController.position.pixels >=
 _scrollController.position.maxScrollExtent - 100) {
 if (!_isFetching && !_isRefreshing && !_hasNoMore) {
 _fetchTopicList(isRefresh: false);
 }
 }
 }

 /// requesttopiclist (trueactual API: typefixed='2', GET /api/livespeed/community/list)
 /// [isRefresh] - true=reset page=1 / false=load more page+1
 Future<void> _fetchTopicList({required bool isRefresh}) async {
 if (_isFetching) {
 debugPrint('🔒 BMTopicListPage requestblocked (re-entry): isRefresh=$isRefresh');
      return;
    }
    if (!isRefresh && _hasNoMore) return;
    _isFetching = true;

    final int requestPageInt;
    if (isRefresh) {
      if (!mounted) {
        _isFetching = false;
        return;
      }
      setState(() {
        _isRefreshing = true;
        _page = 1;
        _hasNoMore = false;
      });
      requestPageInt = 1;
    } else {
      if (!mounted) {
        _isFetching = false;
        return;
      }
      setState(() {
        _isLoadingMore = true;
      });
      requestPageInt = _page + 1;
    }

    final String type = '2';
    final String requestPage = requestPageInt.toString();
    final String sizeStr = _size.toString();

    debugPrint(
      '🌐 BMTopicListPage trueactual request start: type=$type, page=$requestPage, size=$sizeStr',
    );
    List<BMTopicModel> result = [];
    int? serverTotal;
    try {
      final data = await _apiService.fetchPostList(
        type: type,
        page: requestPage,
        size: sizeStr,
      );
      serverTotal = data?.total;
      if (data != null && data.results.isNotEmpty) {
        for (final item in data.results) {
          try {
            result.add(_convertToTopic(item));
          } catch (e) {
            debugPrint('BMTopicListPage singletopicconvertskip: $e');
          }
        }
      }
      debugPrint(
        '✅ BMTopicListPage trueactual request success: this returns ${result.length} items, servicetotal count=$serverTotal',
      );
    } catch (e) {
      debugPrint(
        '❌ BMTopicListPage requestexception(isRefresh=$isRefresh, page=$requestPage): $e',
);
 result = [];
 } finally {
 _isFetching = false;
 }

 if (!mounted) return;
 setState(() {
 if (isRefresh) {
 _topicList = result;
 _page = 1;
 _isRefreshing = false;
 } else {
 _topicList.addAll(result);
 _page = requestPageInt;
 _isLoadingMore = false;
 }
 if (serverTotal != null) {
 _hasNoMore = _topicList.length >= serverTotal;
 } else {
 // none total fallback: returnscount < thistimerequest size = no more data
 _hasNoMore = result.length < _size;
 }
 });
 }

 /// rawpostdatacache (Map<String, BMPostItem> type, topicId -> BMPostItem, detailpagepre-passdata)
 final Map<String, BMPostItem> _postCache = {};

 /// topicconvertlogic（repeatmoment BMCommunityApiService._convertToTopicModel）
 /// data sourcealignment:
 /// 1. content -> topiccontent (aiInsight)
 /// 2. image comma split + filter com/ first -> multipletopic (hashtags)
 /// 3. match hasdata -> innermatch card (embeddedMatch)
 BMTopicModel _convertToTopic(BMPostItem item) {
 final topicId = _safeS(item.id?.toString(), '');
 if (topicId.isNotEmpty) {
 _postCache[topicId] = item; // cacherawdatadetailpagepre-pass
 }
 final hashtags = _parseHashtags(_safeString(item.image));
 final content = _safeS(item.content, 'deepdataanalysisand，exclusiveviewcorner。');
    final BMPostMatch? m = item.match;
    final BMMatchModel? match = (m != null) ? _extractEmbeddedMatch(m) : null;

    String predResult;
    if (m != null && m.homeScore != null && m.awayScore != null) {
      predResult = 'predicted score ${m.homeScore}:${m.awayScore}';
    } else {
      predResult = 'home win probability 58%';
    }

    final BMPostAuthor? author = item.author;
    final String? authorName = author?.name;
    final String? authorAvatarUrl = author?.avatar;
    final int? createTs = item.createTime;
    final String? publishTimeDesc = _formatPublishTime(createTs);

    return BMTopicModel(
      topicId: _safeS(item.id?.toString(), ''),
      categoryTag: hashtags.isNotEmpty ? hashtags.first : 'hot topic',
      categoryBgColor: 0xFFDC2626,
      categoryTextColor: 0xFFFFFFFF,
      prediction: hashtags.isNotEmpty ? hashtags.first : 'AIprediction',
 predictionColor: 0xFFF97316,
 aiInsight: content,
 predictionResult: predResult,
 confidence: 85,
 embeddedMatch: match,
 hashtags: hashtags,
 likeCount: item.likeCount ?? 0,
 commentCount: item.commentCount ?? 0,
 isLiked: item.isLike ?? false,
 authorName: authorName,
 authorAvatarUrl: authorAvatarUrl,
 publishTimeDesc: publishTimeDesc,
);
 }

 // formatpublishtimeascorrecttime
 String? _formatPublishTime(int? timestamp) {
 if (timestamp == null || timestamp == 0) return null;
 final now = DateTime.now();
 final d = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
 final diff = now.difference(d);
 if (diff.inMinutes < 60) return '${diff.inMinutes}minutefirst';
    if (diff.inHours < 24) return '${diff.inHours}hourfirst';
    if (diff.inDays < 30) return '${diff.inDays}dayfirst';
    return '${d.month}-${d.day}';
 }

 // commonsecuritytakevalue helper
 String? _safeString(dynamic v) {
 if (v == null) return null;
 if (v is String) return v;
 return v.toString();
 }

 String _safeS(dynamic v, String fallback) {
 if (v == null) return fallback;
 if (v is String) return v.isEmpty ? fallback: v;
 return v.toString();
 }

 /// innermatchfromAPImodel -> BMMatchModel (reusecommunityserviceconvertlogic)
 BMMatchModel? _extractEmbeddedMatch(BMPostMatch m) {
 int? safeInt(dynamic v) {
 if (v == null) return null;
 if (v is int) return v;
 if (v is num) return v.toInt();
 if (v is String) return int.tryParse(v);
 return null;
 }

 String? safeStr(dynamic v) {
 if (v == null) return null;
 if (v is String) return v;
 return v.toString();
 }

 String safeS(dynamic v, String fallback) {
 if (v == null) return fallback;
 if (v is String) return v.isEmpty ? fallback: v;
 return v.toString();
 }

 final matchType = safeInt(m.matchType) ?? 1;
 final sport = matchType == 2
 ? BMMatchSportType.basketball
: BMMatchSportType.football;
 final int? statusId = safeInt(m.statusId);
 final BMMatchStatus status = _statusFromId(statusId, sport);
 String matchTime = '';
    final int? startTs = safeInt(m.startTime);
    if (startTs != null && startTs > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(startTs * 1000);
      matchTime =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return BMMatchModel(
      matchId: safeS(m.matchId, safeS(m.competitionId, '')),
      leagueName: safeS(m.competitionName, ''),
      leagueColor: 0xFF8B5CF6,
      status: status,
      statusId: statusId,
      statusName: safeStr(m.statusName),
      sportType: sport,
      matchTime: matchTime,
      homeTeam: BMTeamModel(
        teamId: safeStr(m.homeTeamId),
        teamName: safeS(m.homeTeamName, ''),
        teamShort: _extractShort(safeStr(m.homeTeamName)),
        logoUrl: safeStr(m.homeTeamLogo),
      ),
      awayTeam: BMTeamModel(
        teamId: safeStr(m.awayTeamId),
        teamName: safeS(m.awayTeamName, ''),
 teamShort: _extractShort(safeStr(m.awayTeamName)),
 logoUrl: safeStr(m.awayTeamLogo),
),
 homeScore: safeInt(m.homeScore),
 awayScore: safeInt(m.awayScore),
 liveMinute: null,
 halfTimeScore: null,
 goalEvents: const [],
 isFeatured: false,
 isFollowed: false,
 homeWinRate: 0,
 drawRate: 0,
 awayWinRate: 0,
 matchTag: safeStr(m.competitionName),
);
 }

 /// fromstateID + sport typecheckmatchstate
 BMMatchStatus _statusFromId(int? statusId, BMMatchSportType sport) {
 if (sport == BMMatchSportType.football) {
 switch (statusId) {
 case 1:
 return BMMatchStatus.upcoming;
 case 2:
 case 3:
 case 4:
 case 5:
 case 7:
 return BMMatchStatus.live;
 case 8:
 return BMMatchStatus.ended;
 default:
 return BMMatchStatus.tbd;
 }
 } else {
 switch (statusId) {
 case 1:
 case 13:
 return BMMatchStatus.upcoming;
 case 2:
 case 3:
 case 4:
 case 5:
 case 6:
 case 7:
 case 8:
 case 9:
 return BMMatchStatus.live;
 case 10:
 case 11:
 return BMMatchStatus.ended;
 default:
 return BMMatchStatus.tbd;
 }
 }
 }

 /// team nametakefirst3textlargewrite
 String _extractShort(String? name) {
 if (name == null || name.isEmpty) return '';
 if (name.length <= 3) return name.toUpperCase();
 return name.substring(0, 3).toUpperCase();
 }

 /// parsetopictag (image comma split, per itemtopicfilter com/ thisheightandbefore of text)
 /// [raw] - image rawstring (String? type, example "xxx.com/topicA,topicB")
  /// returns: List<String> topiclist
  List<String> _parseHashtags(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
.map((seg) {
 // sectionfilter: com/ anditsbefore of text
 final s = seg.trim();
 final idx = s.indexOf('com/');
 return idx >= 0 ? s.substring(idx + 4).trim(): s;
 })
.where((t) => t.isNotEmpty)
.toList();
 }

 /// pull downrefreshcallback
 Future<void> _onRefresh() {
 return _fetchTopicList(isRefresh: true);
 }

 /// navigatepost topicpage (top-right cornerpost button)
 /// publishlogin required, not logged innavigate to loginUI
 /// Posted (pop true) laterrefreshlistshownewtopic
 Future<void> _gotoPostTopic() async {
 // not logged infirstjumploginpage (loginsuccessreturnslatercontinuepublish)
 if (!BMAuthManager().isLoggedIn) {
 final ok = await Navigator.push<bool>(
 context,
 MaterialPageRoute(builder: (_) => const BMLoginPage()),
);
 if (ok != true) return;
 if (!mounted) return;
 }
 final ok = await Navigator.push<bool>(
 context,
 MaterialPageRoute(builder: (_) => const BMPostTopicPage()),
);
 if (ok == true) {
 _fetchTopicList(isRefresh: true);
 }
 }

 @override
 Widget buildBody(BuildContext context) {
 return Column(
 children: [
 _buildNavBar(context),
 Expanded(child: _buildTopicList()),
 ],
);
 }

 /// custom app bar (returns + title + post button)
 Widget _buildNavBar(BuildContext context) {
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
 onPressed: () => Navigator.of(context).pop(),
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
 'Topic List',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _gotoPostTopic,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 60,
              height: 36,
              decoration: BoxDecoration(
                color: BMColors.bright.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BMColors.bright.withValues(alpha: 0.35)),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: BMColors.bright),
                  SizedBox(width: 3),
                  Text(
                    'publish',
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
 ],
),
);
 }

 /// topiclistzone (first screenLoading/emptystate/pull downrefresh/pull uploading)
 Widget _buildTopicList() {
 if (_isRefreshing && _topicList.isEmpty) {
 return const Center(
 child: CircularProgressIndicator(
 color: BMColors.bright,
 strokeWidth: 2,
),
);
 }
 if (_topicList.isEmpty) {
 return RefreshIndicator(
 color: BMColors.bright,
 backgroundColor: BMColors.pitch850,
 onRefresh: _onRefresh,
 child: ListView(
 physics: const AlwaysScrollableScrollPhysics(),
 children: const [
 SizedBox(height: 140),
 Center(
 child: Icon(
 Icons.bolt_outlined,
 size: 48,
 color: BMColors.textTertiary,
),
),
 SizedBox(height: 12),
 Center(
 child: Text(
 'No topic',
 style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
),
),
 ],
),
);
 }
 return RefreshIndicator(
 color: BMColors.bright,
 backgroundColor: BMColors.pitch850,
 onRefresh: _onRefresh,
 child: ListView.builder(
 controller: _scrollController,
 physics: const AlwaysScrollableScrollPhysics(),
 padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
 itemCount: _topicList.length + 1,
 itemBuilder: (ctx, index) {
 if (index == _topicList.length) return _buildFooter();
 final t = _topicList[index];
 return Padding(
 padding: const EdgeInsets.only(bottom: 12),
 child: TopicPostCard(
 topic: t,
 onTap: () => _navigateToDetail(t),
 onMoreAction: (action, topicId) =>
 _onMoreAction(action, t),
),
);
 },
),
);
 }

 /// navigatetopic detail page (rawpostdatapre-pass)
 /// [topic] - tap of topicmodel (BMTopicModel type)
 /// returns true meanspostbyremove, localremovethecard
 Future<void> _navigateToDetail(BMTopicModel topic) async {
 final int postId = int.tryParse(topic.topicId) ?? 0;
 if (postId == 0) return;
 final deleted = await Navigator.push(
 context,
 MaterialPageRoute(
 builder: (_) => BMTopicDetailPage(
 postId: postId,
 initialPost: _postCache[topic.topicId],
),
),
);
 if (deleted == true && mounted) {
 setState(() {
 _topicList.removeWhere((t) => t.topicId == topic.topicId);
 });
 }
 }

 /// moremenutap handler (report/block)
 /// [action] - menudo (String type, 'report'=report 'block'=block)
 /// [topic] - currenttopicmodel (BMTopicModel type, fortake postId anddelete locally)
 Future<void> _onMoreAction(String action, BMTopicModel topic) async {
 if (action != 'block') return; // report toast bycardinnerparthandle
 // blocklogin required, not logged innavigate to loginUI (loginsuccessreturnslatercontinueblock)
 if (!BMAuthManager().isLoggedIn) {
 final ok = await Navigator.push<bool>(
 context,
 MaterialPageRoute(builder: (_) => const BMLoginPage()),
);
 if (ok != true) return;
 if (!mounted) return;
 }
 final int postId = int.tryParse(topic.topicId) ?? 0;
 if (postId == 0) return;

 // blockfirstconfirmation dialogconfirm
 final bool? confirmed = await showDialog<bool>(
 context: context,
 builder: (ctx) => AlertDialog(
 backgroundColor: BMColors.pitch850,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(14),
 side: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 title: const Text(
 'Block Confirm',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BMColors.textPrimary,
          ),
        ),
        content: const Text(
          'You will no longer see this post after blocking',
          style: TextStyle(
            fontSize: 13,
            color: BMColors.textSecondary,
          ),
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
              'block',
 style: TextStyle(fontSize: 14, color: Color(0xFFDC2626)),
),
),
 ],
),
);
 if (confirmed != true || !mounted) return;

 // block: APIsuccesslaterdelete locallythepost
 final bool ok = await _apiService.blockPost(postId: postId, type: 1);
 if (!mounted) return;
 if (ok) {
 setState(() {
 _topicList.removeWhere((t) => t.topicId == topic.topicId);
 });
 } else {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: const Text(
 'blockfailure, please retry later',
            style: TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: BMColors.pitch800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// bottomloadingindicator
  Widget _buildFooter() {
    if (_hasNoMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 24, height: 1, color: BMColors.pitch700),
            const SizedBox(width: 8),
            const Text(
              '—— no more ——',
              style: TextStyle(fontSize: 11, color: BMColors.textTertiary),
            ),
            const SizedBox(width: 8),
            Container(width: 24, height: 1, color: BMColors.pitch700),
          ],
        ),
      );
    }
    if (_isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: BMColors.bright,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'loadingin...',
              style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
