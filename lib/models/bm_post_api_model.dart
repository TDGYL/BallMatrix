/// BMPostData - 社区话题列表API响应数据体
/// 作用范围: /api/livespeed/community/list 接口响应data字段
class BMPostData {
  /// 数据总数 (int? 类型)
  final int? total;

  /// 话题项目列表 (List<BMPostItem> 类型)
  final List<BMPostItem> results;

  BMPostData({this.total, this.results = const []});

  /// 从 JSON 解析
  factory BMPostData.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List?;
    List<BMPostItem> items = [];
    if (list != null) {
      items = list.map((e) => BMPostItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return BMPostData(
      total: json['total'] as int?,
      results: items,
    );
  }
}

/// BMPostItem - 单条社区话题数据项
/// 作用范围: /api/livespeed/community/list 接口 results 子项
class BMPostItem {
  /// 话题唯一ID (int? 类型)
  final int? id;

  /// 话题内容 (String? 类型)
  final String? content;

  /// 话题标签 (逗号分隔, 可能含 com/ 前缀)
  final String? image;

  /// 图片列表 (List<String>? 类型)
  final List<String>? images;

  /// 点赞数 (int? 类型)
  final int? likeCount;

  /// 评论数 (int? 类型)
  final int? commentCount;

  /// 创建时间戳 (int? 类型, 秒)
  final int? createTime;

  /// 作者信息 (BMPostAuthor? 类型)
  final BMPostAuthor? author;

  /// 关联比赛信息 (BMPostMatch? 类型)
  final BMPostMatch? match;

  /// 是否已点赞 (bool? 类型)
  final bool? isLike;

  BMPostItem({
    this.id,
    this.content,
    this.image,
    this.images,
    this.likeCount,
    this.commentCount,
    this.createTime,
    this.author,
    this.match,
    this.isLike,
  });

  /// 从 JSON 解析 (snake_case → camelCase)
  factory BMPostItem.fromJson(Map<String, dynamic> json) {
    return BMPostItem(
      id: json['id'] as int?,
      content: json['content'] as String?,
      image: json['image'] as String?,
      images: (json['images'] as List?)?.map((e) => e as String).toList(),
      likeCount: json['like_count'] as int?,
      commentCount: json['comment_count'] as int?,
      createTime: json['create_time'] as int?,
      author: json['author'] != null ? BMPostAuthor.fromJson(json['author']) : null,
      match: json['match'] != null ? BMPostMatch.fromJson(json['match']) : null,
      isLike: json['is_like'] as bool?,
    );
  }
}

/// BMPostAuthor - 话题作者信息
class BMPostAuthor {
  /// 作者ID (int? 类型)
  final int? id;

  /// 作者昵称 (String? 类型)
  final String? name;

  /// 是否已关注 (bool? 类型)
  final bool? isSubscribe;

  /// 作者头像URL (String? 类型)
  final String? avatar;

  /// 会员ID (int? 类型)
  final int? memberId;

  BMPostAuthor({
    this.id,
    this.name,
    this.isSubscribe,
    this.avatar,
    this.memberId,
  });

  /// 从 JSON 解析
  factory BMPostAuthor.fromJson(Map<String, dynamic> json) {
    return BMPostAuthor(
      id: json['id'] as int?,
      name: json['name'] as String?,
      isSubscribe: json['is_subscribe'] as bool?,
      avatar: json['avatar'] as String?,
      memberId: json['member_id'] as int?,
    );
  }
}

/// BMPostMatch - 话题关联比赛信息
class BMPostMatch {
  /// 比赛类型 (int? 类型: 1=足球, 2=篮球)
  final int? matchType;

  /// 比赛ID (int? 类型)
  final int? matchId;

  /// 联赛ID (int? 类型)
  final int? competitionId;

  /// 开始时间戳 (int? 类型, 秒)
  final int? startTime;

  /// 状态ID (int? 类型)
  final int? statusId;

  /// 状态名称 (String? 类型)
  final String? statusName;

  /// 联赛名称 (String? 类型)
  final String? competitionName;

  /// 主队ID (int? 类型)
  final int? homeTeamId;

  /// 主队名称 (String? 类型)
  final String? homeTeamName;

  /// 主队LogoURL (String? 类型)
  final String? homeTeamLogo;

  /// 客队ID (int? 类型)
  final int? awayTeamId;

  /// 客队名称 (String? 类型)
  final String? awayTeamName;

  /// 客队LogoURL (String? 类型)
  final String? awayTeamLogo;

  /// 主队比分 (int? 类型)
  final int? homeScore;

  /// 客队比分 (int? 类型)
  final int? awayScore;

  BMPostMatch({
    this.matchType,
    this.matchId,
    this.competitionId,
    this.startTime,
    this.statusId,
    this.statusName,
    this.competitionName,
    this.homeTeamId,
    this.homeTeamName,
    this.homeTeamLogo,
    this.awayTeamId,
    this.awayTeamName,
    this.awayTeamLogo,
    this.homeScore,
    this.awayScore,
  });

  /// 从 JSON 解析
  factory BMPostMatch.fromJson(Map<String, dynamic> json) {
    return BMPostMatch(
      matchType: json['match_type'] as int?,
      matchId: json['match_id'] as int?,
      competitionId: json['competition_id'] as int?,
      startTime: json['start_time'] as int?,
      statusId: json['status_id'] as int?,
      statusName: json['status_name'] as String?,
      competitionName: json['competition_name'] as String?,
      homeTeamId: json['home_team_id'] as int?,
      homeTeamName: json['home_team_name'] as String?,
      homeTeamLogo: json['home_team_logo'] as String?,
      awayTeamId: json['away_team_id'] as int?,
      awayTeamName: json['away_team_name'] as String?,
      awayTeamLogo: json['away_team_logo'] as String?,
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
    );
  }
}