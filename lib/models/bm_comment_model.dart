/// BMCommentData - 社区评论列表接口响应数据体
/// 作用范围: /api/livespeed/community/comment/list 接口响应 data 字段
/// 功能: 话题详情页底部评论列表数据源 (total + results)
class BMCommentData {
  /// 评论总数 (int? 类型)
  final int? total;

  /// 评论项列表 (List<BMCommentItem> 类型)
  final List<BMCommentItem> results;

  /// 构造函数
  BMCommentData({this.total, this.results = const []});

  /// 从 JSON Map 构建模型 (MJExtension 风格映射)
  /// [json] - 接口返回的 data Map (Map<String, dynamic> 类型)
  /// 返回: BMCommentData
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

/// BMCommentItem - 单条评论/回复数据项
/// 评论与回复共用同一结构, 通过 parent_id 与 is_reply_child 区分层级
/// 作用范围: 话题详情页评论列表 + 发评论/回复接口返回
class BMCommentItem {
  /// 评论ID (int? 类型, 唯一标识)
  int? id;

  /// 关联对象ID (int? 类型, 评论所属帖子ID)
  int? objectId;

  /// 关联对象类型 (int? 类型, 帖子=3)
  int? objectType;

  /// 评论用户ID (int? 类型)
  int? userId;

  /// 父评论ID (int? 类型, 一级评论为0, 回复时为其一级评论ID)
  int? parentId;

  /// 回复目标用户ID (int? 类型)
  int? replyToUser;

  /// 回复目标评论ID (int? 类型)
  int? replyToComment;

  /// 评论内容 (String? 类型)
  String? words;

  /// 点赞数 (int? 类型)
  int? support;

  /// 是否子回复 (int? 类型, 0=一级评论 1=二级回复)
  int? isReplyChild;

  /// 评论时间戳 (int? 类型, 秒级)
  int? commentTime;

  /// 删除时间 (String? 类型, 未删除为null)
  String? deletedAt;

  /// 用户头像URL (String? 类型)
  String? userPic;

  /// 用户昵称 (String? 类型)
  String? userName;

  /// 是否已点赞 (bool? 类型)
  bool? isSupport;

  /// 剩余子评论数 (int? 类型, 未展示的回复数)
  int? remainChildCommentCount;

  /// 展示的子评论列表 (List<BMCommentItem>? 类型, 本条下的回复)
  List<BMCommentItem>? showChildComments;

  /// 回复目标用户昵称 (String? 类型)
  String? replyToUserName;

  /// 构造函数
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

  /// 从 JSON Map 构建模型 (snake_case → camelCase 映射)
  /// [json] - 接口返回的单条评论 Map (Map<String, dynamic> 类型)
  /// 返回: BMCommentItem
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

/// 安全 int 转换 (num/String -> int?)
int? _safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// 安全 String 转换 (dynamic -> String?)
String? _safeString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

/// 安全 bool 转换 (bool/int/String -> bool?)
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
