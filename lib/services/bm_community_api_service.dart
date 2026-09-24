import 'package:flutter/foundation.dart';
import '../network/bm_network_manager.dart';
import '../models/bm_post_api_model.dart';
import '../models/bm_topic_model.dart';
import '../models/bm_match_model.dart';
import '../models/bm_search_match_model.dart';
import '../models/bm_comment_model.dart';

/// BMCommunityTab - communitylistTabtypeenum
/// mappingtoAPI typeargument: recommended=1, latest=2, follow=3
enum BMCommunityTab {
 /// recommended type=1
 recommend(1),

 /// latest type=2
 recent(2),

 /// follow type=3
 follow(3);

 /// APImapping of typevalue (int type)
 final int value;
 const BMCommunityTab(this.value);
}

/// BMCommunityApiService - communitytopiclistAPIservice
/// purposescope: homehot topic list
class BMCommunityApiService {
 /// singletoninstance (BMCommunityApiService type)
 static final BMCommunityApiService _instance = BMCommunityApiService._internal();

 /// factory constructor, returnssingleton
 factory BMCommunityApiService() {
 return _instance;
 }

 /// privateconstructor
 BMCommunityApiService._internal();

 /// APIpath
 static const String _apiPath = '/api/livespeed/community/list';

 /// requestcommunitytopiclist (GET)
 /// [type] - type (String type: 1recommended 2latest 3follow, default'2')
 /// [page] - page number (String type, from'1'start)
 /// [size] - per pagecount (String type)
 /// [matchType] - matchtype, 1=football, 2=basketball, can be empty, asnullwhennotrequestintheargument
 /// returns: BMPostData?
 Future<BMPostData?> fetchPostList({
 String type = '2',
    String page = '1',
    String size = '10',
    int? matchType,
  }) async {
    final params = <String, dynamic>{
      'type': type,
      'page': page,
      'size': size,
    };
    if (matchType != null) {
      params['match_type'] = matchType.toString();
    }

    final response = await BMNetworkManager().getRequest(
      _apiPath,
      queryParameters: params,
    );

    if (response.isSuccess && response.data != null) {
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final code = raw['code'];
        if (code == 0 || code == '0' || code == 200 || response.isSuccess) {
          final innerData = raw['data'];
 if (innerData is Map<String, dynamic>) {
 return BMPostData.fromJson(innerData);
 }
 return BMPostData.fromJson(raw);
 }
 }
 }

 return null;
 }

 /// requesttopicandconvertasUImodel (homehot topicusage)
 /// [count] - requestcount, default3
 /// [matchType] - matchtype, 1=football, 2=basketball, can be empty, asnullwhennotrequestintheargument
 /// returns: List<BMTopicModel>
 Future<List<BMTopicModel>> fetchTopicModels({
 int count = 3,
 int? matchType,
 }) async {
 final data = await fetchPostList(
 type: BMCommunityTab.recent.value.toString(),
 page: '1',
      size: count.toString(),
      matchType: matchType,
    );
    if (data == null || data.results.isEmpty) return [];
    return data.results.map((item) => _convertToTopicModel(item)).toList();
  }

  /// APImodel -> UImodel convert
  BMTopicModel _convertToTopicModel(BMPostItem item) {
    final hashtags = _parseHashtags(item.image);
    final content = item.content ?? '';

    BMMatchModel? embeddedMatch;
    if (item.match != null) {
      final m = item.match!;
      final sport = (m.matchType ?? 1) == 2 ? BMMatchSportType.basketball : BMMatchSportType.football;
      embeddedMatch = BMMatchModel(
        matchId: m.matchId?.toString() ?? '',
        leagueName: m.competitionName ?? '',
        leagueColor: 0xFF8B5CF6,
        homeTeam: BMTeamModel(
          teamId: m.homeTeamId?.toString() ?? '',
          teamName: m.homeTeamName ?? '',
          teamShort: _extractShort(m.homeTeamName),
          logoUrl: m.homeTeamLogo,
        ),
        awayTeam: BMTeamModel(
          teamId: m.awayTeamId?.toString() ?? '',
          teamName: m.awayTeamName ?? '',
          teamShort: _extractShort(m.awayTeamName),
          logoUrl: m.awayTeamLogo,
        ),
        homeScore: m.homeScore ?? 0,
        awayScore: m.awayScore ?? 0,
        matchTime: _formatMatchTime(m.startTime),
        status: _statusFromId(m.statusId, sport),
        statusId: m.statusId,
        statusName: m.statusName,
        sportType: sport,
        liveMinute: null,
        halfTimeScore: null,
        goalEvents: [],
        isFeatured: false,
        isFollowed: false,
        homeWinRate: 0,
        drawRate: 0,
        awayWinRate: 0,
        matchTag: m.competitionName,
      );
    }

    return BMTopicModel(
      topicId: item.id?.toString() ?? '',
      categoryTag: hashtags.isNotEmpty ? hashtags.first : 'hot topic',
      categoryBgColor: 0xFFDC2626,
      categoryTextColor: 0xFFFFFFFF,
      prediction: hashtags.isNotEmpty ? hashtags.first : 'AIprediction',
      predictionColor: 0xFFF97316,
      aiInsight: content.isNotEmpty ? content : 'deepdataanalysisand，exclusiveviewcorner。',
 predictionResult: _buildPredictionResult(item),
 confidence: 85,
 embeddedMatch: embeddedMatch,
 hashtags: hashtags,
 likeCount: item.likeCount ?? 0,
 commentCount: item.commentCount ?? 0,
 isLiked: item.isLike ?? false,
 authorName: item.author?.name,
 authorAvatarUrl: item.author?.avatar,
 publishTimeDesc: _formatPublishTime(item.createTime),
);
 }

 /// buildpredictionresultstring
 String _buildPredictionResult(BMPostItem item) {
 if (item.match != null) {
 final m = item.match!;
 if (m.homeScore != null && m.awayScore != null) {
 return 'predicted score ${m.homeScore}:${m.awayScore}';
      }
    }
    return 'home win probability 58%';
 }

 /// formatpublishtimeascorrecttimedescription
 String _formatPublishTime(int? timestamp) {
 if (timestamp == null || timestamp == 0) return '';
    final now = DateTime.now();
    final publishDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = now.difference(publishDate);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}minutefirst';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}hourfirst';
    } else if (diff.inDays < 30) {
      return '${diff.inDays}dayfirst';
    } else {
      return '${publishDate.month}-${publishDate.day}';
 }
 }

 /// parsetopictag
 List<String> _parseHashtags(String? rawImage) {
 if (rawImage == null || rawImage.isEmpty) return [];
 String raw = rawImage;
 if (raw.contains('com/')) {
      raw = raw.substring(raw.indexOf('com/') + 4);
    }
    return raw
        .split(',')
.map((t) => t.trim())
.where((t) => t.isNotEmpty)
.toList();
 }

 /// formatmatch timestamp -> HH:mm
 String _formatMatchTime(int? timestamp) {
 if (timestamp == null || timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
 }

 /// fromstateIDmappingmatchstate (bysport typeminrule)
 /// football: 1NS, 2|3|4|5|7in progress, 8FT, 0|9|10|11|12|13 TBD
 /// basketball: 1|13NS, 2|3|4|5|6|7|8|9in progress, 10|11FT, 0|12|14|15 TBD
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
 case 0:
 case 9:
 case 10:
 case 11:
 case 12:
 case 13:
 return BMMatchStatus.tbd;
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
 case 0:
 case 12:
 case 14:
 case 15:
 return BMMatchStatus.tbd;
 default:
 return BMMatchStatus.tbd;
 }
 }
 }

 /// taketeam nameabbreviation
 String _extractShort(String? name) {
 if (name == null || name.isEmpty) return '';
 if (name.length <= 3) return name.toUpperCase();
 return name.substring(0, 3).toUpperCase();
 }

 // ==================== post topicrelatedAPI ====================

 /// post topicpost (POST /api/livespeed/community/save)
 /// feature: post topiccontent + multi-selecttopictag(store images field) + related match
 /// [content] - posttextcontent (String type, less10text)
 /// [topics] - selected of topictaglist (List<String> type, withcomma No.concatstoreinput images[0])
 /// [matchId] - related matchID (int? type, null=notclose)
 /// [matchType] - related matchtype (int? type, 1=football 2=basketball, null=not)
 /// returns: (bool success, String toastmessage)
 Future<(bool, String)> saveTopicPost({
 required String content,
 List<String> topics = const [],
 int? matchId,
 int? matchType,
 }) async {
 // topictagwithcomma No.concatstoreinput images array (alignment hanklive field)
 final List<String> images = [];
 if (topics.isNotEmpty) {
 images.add(topics.join(','));
    }
    final Map<String, dynamic> params = {
      'id': 0,
      'content': content,
      'images': images,
    };
    if (matchId != null) {
      params['match_type'] = matchType ?? 1;
      params['match_id'] = matchId;
    }
    final response = await BMNetworkManager().postRequest(
      '/api/livespeed/community/save',
      data: params,
    );
    if (response.isSuccess) {
      return (true, 'Posted');
    }
    return (false, response.message ?? 'Post Failed');
 }

 /// search match (GET /api/livespeed/index/search, text=key)
 /// feature: post topicrelated matchwhenbyteam namesearch match
 /// structure: {code, data:{experts, matches, schemes, users, competitions}, message}
 /// networklayeralreadyunwrap code/message, response.data i.e. data object
 /// [text] - search keyword (String type, team name)
 /// returns: BMSearchResult? onlytake data.matches group (othersgroupdiscard, null=request failure)
 Future<BMSearchResult?> fetchSearchResults({required String text}) async {
 final response = await BMNetworkManager().getRequest(
 '/api/livespeed/index/search',
      queryParameters: {'text': text},
);
 if (response.isSuccess && response.data != null) {
 final raw = response.data;
 Map<String, dynamic>? dataMap;
 if (raw is Map<String, dynamic>) {
 // response.data alreadyyesunwraplater of data object (includes matches group)
 // onlywhenpasscompleteouter {code, data, matches} structurewhenneedsagainonelayer
 dataMap = (raw['data'] is Map<String, dynamic> && raw['matches'] == null)
            ? raw['data'] as Map<String, dynamic>
            : raw;
      }
      if (dataMap != null) {
        final result = BMSearchResult.fromJson(dataMap);
        debugPrint(
            'BMCommunityApiService search results matches=${result.matches.length} items');
 return result;
 }
 }
 return null;
 }

 /// fetch hot matcheslist (GET /api/livespeed/index/search/match/hot)
 /// feature: post topicrelated match entry of defaultwaitlist
 /// returns: List<BMSearchMatch> (emptylist=nonedata/failure)
 Future<List<BMSearchMatch>> fetchHotMatches() async {
 final response = await BMNetworkManager().getRequest(
 '/api/livespeed/index/search/match/hot',
    );
    if (response.isSuccess) {
      List<dynamic> rawList = [];
      if (response.data is List) {
        rawList = response.data as List<dynamic>;
      } else if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>)['data'] is List) {
        rawList = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
 }
 return rawList
.whereType<Map<String, dynamic>>()
.map(BMSearchMatch.fromJson)
.toList();
 }
 return [];
 }

 /// blockpost (POST /api/livespeed/community/block_post)
 /// feature: topic cardmoremenu「block」do, successlatercalldirectiondelete locallythepost
 /// [postId] - postID (int type, correspondingtopiclistitem id)
 /// [type] - blocktype (int type, fixed=1)
 /// returns: bool whetherblocksuccess
 Future<bool> blockPost({required int postId, int type = 1}) async {
 final response = await BMNetworkManager().postRequest(
 '/api/livespeed/community/block_post',
      data: {
        'post_id': postId,
        'type': type,
 },
);
 return response.isSuccess;
 }

 /// postdetail (GET /api/livespeed/community/detail)
 /// feature: topic detail pagetopdata source (content/author/related match/likecommentcount)
 /// [postId] - postID (int type)
 /// returns: BMPostItem? detaildata (null=failure)
 Future<BMPostItem?> fetchPostDetail({required int postId}) async {
 final response = await BMNetworkManager().getRequest(
 '/api/livespeed/community/detail',
      queryParameters: {'id': postId},
    );
    if (response.isSuccess && response.data is Map<String, dynamic>) {
      return BMPostItem.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  /// commentlist (GET /api/livespeed/community/comment/list)
  /// feature: topic detail pagebottomcommentlistdata source
  /// [objectId] - postID (int type)
  /// returns: BMCommentData? commentlist (null=failure)
  Future<BMCommentData?> fetchComments({required int objectId}) async {
    final response = await BMNetworkManager().getRequest(
      '/api/livespeed/community/comment/list',
      queryParameters: {'object_id': objectId},
);
 if (response.isSuccess && response.data is Map<String, dynamic>) {
 return BMCommentData.fromJson(response.data as Map<String, dynamic>);
 }
 return null;
 }

 /// sendtablecomment/reply (POST /api/livespeed/community/comment/add)
 /// feature: topic detail pagebottomcommentinput
 /// [objectId] - postID (int type)
 /// [words] - commentcontent (String type)
 /// [commentId] - replywhenlevel-1 commentID (int? type, commentpostwhennull)
 /// returns: BMCommentItem? newcommentdata (null=failure)
 Future<BMCommentItem?> addComment({
 required int objectId,
 required String words,
 int? commentId,
 }) async {
 final params = <String, dynamic>{
 'object_id': objectId,
      'words': words,
    };
    if (commentId != null) {
      params['comment_id'] = commentId;
    }
    final response = await BMNetworkManager().postRequest(
      '/api/livespeed/community/comment/add',
      data: params,
    );
    if (response.isSuccess && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final commentJson = data['comment'];
 if (commentJson is Map<String, dynamic>) {
 return BMCommentItem.fromJson(commentJson);
 }
 }
 return null;
 }

 /// commentlike/Take effect (POST /api/livespeed/support)
 /// [objectId] - commentID (int type)
 /// [isSupport] - true=like false=Take effect (bool type)
 /// returns: bool whethersuccess
 Future<bool> supportComment({
 required int objectId,
 required bool isSupport,
 }) async {
 final response = await BMNetworkManager().postRequest(
 '/api/livespeed/support',
      data: {
        'object_id': objectId,
        'object_type': 3,
        'is_support': isSupport,
 },
);
 return response.isSuccess;
 }

 /// postlike/Take effect (POST /api/livespeed/community/like)
 /// [postId] - postID (int type)
 /// [type] - 1=like 2=Take effect (int type)
 /// returns: bool whethersuccess
 Future<bool> likePost({required int postId, required int type}) async {
 final response = await BMNetworkManager().postRequest(
 '/api/livespeed/community/like',
      data: {
        'post_id': postId,
        'type': type,
 },
);
 return response.isSuccess;
 }

 /// removepost (POST /api/livespeed/community/delete)
 /// feature: ownpublish of postdetailpagenavigationswapfollow button of removedo
 /// [postId] - postID (int type)
 /// returns: bool whethersuccess
 Future<bool> deletePost({required int postId}) async {
 final response = await BMNetworkManager().postRequest(
 '/api/livespeed/community/delete',
      data: {'id': postId},
);
 return response.isSuccess;
 }

 /// follow/Take effectfollowauthor (POST /api/livespeed/imchat/subscribe)
 /// [targetId] - authoruserID (int type)
 /// [type] - 1=follow 2=Take effect (int type)
 /// returns: bool whethersuccess
 Future<bool> toggleFollowAuthor({
 required int targetId,
 required int type,
 }) async {
 final response = await BMNetworkManager().postRequest(
 '/api/livespeed/imchat/subscribe',
      data: {
        'target_id': targetId,
        'type': type,
      },
    );
    return response.isSuccess;
  }
}