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

/// BMPostData - communitytopiclistAPIresponsedatabody
/// purposescope: /api/livespeed/community/list APIresponsedatafield
class BMPostData {
 /// datatotal (int? type)
 final int? total;

 /// topicitem list (List<BMPostItem> type)
 final List<BMPostItem> results;

 BMPostData({this.total, this.results = const []});

 /// from JSON parse
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
          debugPrint('BMPostData.fromJson singleparseskip i=$i: $e');
        }
      }
    }
    return BMPostData(
      total: _safeInt(json['total']),
 results: items,
);
 }
}

/// BMPostItem - singlecommunitytopicdataitem
/// purposescope: /api/livespeed/community/list API results sub item
class BMPostItem {
 /// topicuniqueID (int? type)
 final int? id;

 /// topiccontent (String? type)
 final String? content;

 /// topictag (comma No.min, canabilityincludes com/ first)
 final String? image;

 /// imagelist (List<String>? type)
 final List<String>? images;

 /// likecount (int? type)
 final int? likeCount;

 /// commentcount (int? type)
 final int? commentCount;

 /// createtimestamp (int? type, second)
 final int? createTime;

 /// authorinfo (BMPostAuthor? type)
 final BMPostAuthor? author;

 /// related matchinfo (BMPostMatch? type)
 final BMPostMatch? match;

 /// liked or not (bool? type)
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

 /// from JSON parse (snake_case → camelCase)
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

/// BMPostAuthor - topicauthorinfo
class BMPostAuthor {
 /// authorID (int? type)
 final int? id;

 /// authornickname (String? type)
 final String? name;

 /// whetherfollowed (bool? type)
 final bool? isSubscribe;

 /// authoravatarURL (String? type)
 final String? avatar;

 /// willmemberID (int? type)
 final int? memberId;

 BMPostAuthor({
 this.id,
 this.name,
 this.isSubscribe,
 this.avatar,
 this.memberId,
 });

 /// from JSON parse
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

/// BMPostMatch - topicrelated matchinfo
class BMPostMatch {
 /// matchtype (int? type: 1=football, 2=basketball)
 final int? matchType;

 /// matchID (int? type)
 final int? matchId;

 /// leagueID (int? type)
 final int? competitionId;

 /// starttimestamp (int? type, second)
 final int? startTime;

 /// stateID (int? type)
 final int? statusId;

 /// statename (String? type)
 final String? statusName;

 /// league namename (String? type)
 final String? competitionName;

 /// home teamID (int? type)
 final int? homeTeamId;

 /// home teamname (String? type)
 final String? homeTeamName;

 /// home teamLogoURL (String? type)
 final String? homeTeamLogo;

 /// away teamID (int? type)
 final int? awayTeamId;

 /// away teamname (String? type)
 final String? awayTeamName;

 /// away teamLogoURL (String? type)
 final String? awayTeamLogo;

 /// home teamscore (int? type)
 final int? homeScore;

 /// away teamscore (int? type)
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

 /// from JSON parse
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