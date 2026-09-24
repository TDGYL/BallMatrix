/// BMCommentData - communitycommentlistAPIresponsedatabody
/// purposescope: /api/livespeed/community/comment/list APIresponse data field
/// feature: topic detail pagebottomcommentlistdata source (total + results)
class BMCommentData {
 /// commenttotal (int? type)
 final int? total;

 /// commentitemlist (List<BMCommentItem> type)
 final List<BMCommentItem> results;

 /// constructor
 BMCommentData({this.total, this.results = const []});

 /// from JSON Map build model (MJExtension stylemapping)
 /// [json] - API response of data Map (Map<String, dynamic> type)
 /// returns: BMCommentData
 factory BMCommentData.fromJson(Map<String, dynamic> json) {
 final list = json['results'] as List?;
    final items = <BMCommentItem>[];
    if (list != null) {
      for (final e in list) {
        if (e is Map<String, dynamic>) items.add(BMCommentItem.fromJson(e));
      }
    }
    return BMCommentData(
      total: _safeInt(json['total']),
 results: items,
);
 }
}

/// BMCommentItem - singlecomment/replydataitem
/// commentandreplysharedsameonestructure, common parent_id and is_reply_child zoneminlayerlevel
/// purposescope: topic detail pagecommentlist + sendcomment/replyAPI response
class BMCommentItem {
 /// commentID (int? type, uniqueidentifier)
 int? id;

 /// closeobjectID (int? type, commentallpostID)
 int? objectId;

 /// closeobjecttype (int? type, post=3)
 int? objectType;

 /// commentuserID (int? type)
 int? userId;

 /// commentID (int? type, level-1 commentas0, replywhenitslevel-1 commentID)
 int? parentId;

 /// replygoaluserID (int? type)
 int? replyToUser;

 /// replygoalcommentID (int? type)
 int? replyToComment;

 /// commentcontent (String? type)
 String? words;

 /// likecount (int? type)
 int? support;

 /// whethersubreply (int? type, 0=level-1 comment 1=twolevelreply)
 int? isReplyChild;

 /// commenttimestamp (int? type, secondlevel)
 int? commentTime;

 /// removetime (String? type, not yetremoveasnull)
 String? deletedAt;

 /// useravatarURL (String? type)
 String? userPic;

 /// usernickname (String? type)
 String? userName;

 /// liked or not (bool? type)
 bool? isSupport;

 /// remainingsubcommentcount (int? type, not yetshow of replycount)
 int? remainChildCommentCount;

 /// show of subcommentlist (List<BMCommentItem>? type, thisitemslower of reply)
 List<BMCommentItem>? showChildComments;

 /// replygoalusernickname (String? type)
 String? replyToUserName;

 /// constructor
 BMCommentItem({
 this.id,
 this.objectId,
 this.objectType,
 this.userId,
 this.parentId,
 this.replyToUser,
 this.replyToComment,
 this.words,
 this.support,
 this.isReplyChild,
 this.commentTime,
 this.deletedAt,
 this.userPic,
 this.userName,
 this.isSupport,
 this.remainChildCommentCount,
 this.showChildComments,
 this.replyToUserName,
 });

 /// from JSON Map build model (snake_case → camelCase mapping)
 /// [json] - API response of singlecomment Map (Map<String, dynamic> type)
 /// returns: BMCommentItem
 factory BMCommentItem.fromJson(Map<String, dynamic> json) {
 final childList = json['show_child_comments'] as List?;
    return BMCommentItem(
      id: _safeInt(json['id']),
      objectId: _safeInt(json['object_id']),
      objectType: _safeInt(json['object_type']),
      userId: _safeInt(json['user_id']),
      parentId: _safeInt(json['parent_id']),
      replyToUser: _safeInt(json['reply_to_user']),
      replyToComment: _safeInt(json['reply_to_comment']),
      words: _safeString(json['words']),
      support: _safeInt(json['support']),
      isReplyChild: _safeInt(json['is_reply_child']),
      commentTime: _safeInt(json['comment_time']),
      deletedAt: _safeString(json['deleted_at']),
      userPic: _safeString(json['user_pic']),
      userName: _safeString(json['user_name']),
      isSupport: _safeBool(json['is_support']),
      remainChildCommentCount: _safeInt(json['remain_child_comment_count']),
      replyToUserName: _safeString(json['reply_to_user_name']),
      showChildComments: childList == null
          ? null
          : childList
              .whereType<Map<String, dynamic>>()
              .map(BMCommentItem.fromJson)
              .toList(),
    );
  }
}

/// security int convert (num/String -> int?)
int? _safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// security String convert (dynamic -> String?)
String? _safeString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

/// security bool convert (bool/int/String -> bool?)
bool? _safeBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return null;
}
