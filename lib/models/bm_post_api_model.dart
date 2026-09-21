import 'package:flutter/material.dart';

int? _safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String? _safeString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

bool? _safeBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
  }
  return null;
}

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
      for (int i = 0; i < list.length; i++) {
        try {
          final e = list[i];
          if (e is Map<String, dynamic>) {
            items.add(BMPostItem.fromJson(e));
          }
        } catch (e) {
          debugPrint('BMPostData.fromJson 单条解析跳过 i=$i: $e');
        }
      }
    }
    return BMPostData(
      total: _safeInt(json['total']),
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
    dynamic authorRaw = json['author'];
    dynamic matchRaw = json['match'];
    BMPostAuthor? author;
    BMPostMatch? match;
    if (authorRaw is Map<String, dynamic>) {
      try {
        author = BMPostAuthor.fromJson(authorRaw);
      } catch (_) {}
    }
    if (matchRaw is Map<String, dynamic>) {
      try {
        match = BMPostMatch.fromJson(matchRaw);
      } catch (_) {}
    }
    final listRaw = json['images'] as List?;
    List<String>? images;
    if (listRaw != null) {
      images = [];
      for (final e in listRaw) {
        final s = _safeString(e);
        if (s != null) images.add(s);
      }
    }
    return BMPostItem(
      id: _safeInt(json['id']),
      content: _safeString(json['content']),
      image: _safeString(json['image']),
      images: images,
      likeCount: _safeInt(json['like_count']),
      commentCount: _safeInt(json['comment_count']),
      createTime: _safeInt(json['create_time']),
      author: author,
      match: match,
      isLike: _safeBool(json['is_like']),
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
      id: _safeInt(json['id']),
      name: _safeString(json['name']),
      isSubscribe: _safeBool(json['is_subscribe']),
      avatar: _safeString(json['avatar']),
      memberId: _safeInt(json['member_id']),
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
      matchType: _safeInt(json['match_type']),
      matchId: _safeInt(json['match_id']),
      competitionId: _safeInt(json['competition_id']),
      startTime: _safeInt(json['start_time']),
      statusId: _safeInt(json['status_id']),
      statusName: _safeString(json['status_name']),
      competitionName: _safeString(json['competition_name']),
      homeTeamId: _safeInt(json['home_team_id']),
      homeTeamName: _safeString(json['home_team_name']),
      homeTeamLogo: _safeString(json['home_team_logo']),
      awayTeamId: _safeInt(json['away_team_id']),
      awayTeamName: _safeString(json['away_team_name']),
      awayTeamLogo: _safeString(json['away_team_logo']),
      homeScore: _safeInt(json['home_score']),
      awayScore: _safeInt(json['away_score']),
    );
  }
}