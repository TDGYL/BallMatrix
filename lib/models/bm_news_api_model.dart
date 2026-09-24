/// BMNewsData - newlistAPIresponsedatabody
/// purposescope: /api/livespeed/info/list APIresponsedatafield
class BMNewsData {
 /// datatotal (int? type)
 final int? total;

 /// newitem list (List<BMNewsItem> type)
 final List<BMNewsItem> results;

 BMNewsData({this.total, this.results = const []});

 /// from JSON parse
 factory BMNewsData.fromJson(Map<String, dynamic> json) {
 final list = json['results'] as List?;
    List<BMNewsItem> items = [];
    if (list != null) {
      items = list.map((e) => BMNewsItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return BMNewsData(
      total: json['total'] as int?,
 results: items,
);
 }
}

/// BMNewsItem - singlenewdataitem
/// purposescope: /api/livespeed/info/list API results sub item
class BMNewsItem {
 /// textchapteruniqueID (int? type)
 final int? id;

 /// textchaptertitle (String? type)
 final String? title;

 /// planeURL (String? type)
 final String? cover;

 /// textchaptertype (int? type: 1=deep tactical, 2=news flash, 3=exclusive)
 final int? type;

 /// author (String? type)
 final String? author;

 /// authoravatarURL (String? type)
 final String? authorAvatar;

 /// source (String? type)
 final String? source;

 /// createtimestamp (int? type, second)
 final int? createdAt;

 /// centertextcontent (String? type)
 final String? content;

 /// readvolume (int? type)
 final int? contentCounts;

 /// /commentcount (int? type)
 final int? intelligenceCounts;

 BMNewsItem({
 this.id,
 this.title,
 this.cover,
 this.type,
 this.author,
 this.authorAvatar,
 this.source,
 this.createdAt,
 this.content,
 this.contentCounts,
 this.intelligenceCounts,
 });

 /// from JSON parse (snake_case → camelCase)
 factory BMNewsItem.fromJson(Map<String, dynamic> json) {
 return BMNewsItem(
 id: json['id'] != null ? (json['id'] as num).toInt() : null,
      title: json['title'] as String?,
      cover: json['cover'] as String?,
      type: json['type'] != null ? (json['type'] as num).toInt() : null,
      author: json['author'] as String?,
      authorAvatar: json['author_avatar'] as String?,
      source: json['source'] as String?,
      createdAt: json['created_at'] != null ? (json['created_at'] as num).toInt() : null,
      content: json['content'] as String?,
      contentCounts: json['content_counts'] != null ? (json['content_counts'] as num).toInt() : null,
      intelligenceCounts: json['intelligence_counts'] != null ? (json['intelligence_counts'] as num).toInt() : null,
    );
  }
}