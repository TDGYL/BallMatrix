/// BMNewsData - 新闻列表API响应数据体
/// 作用范围: /api/livespeed/info/list 接口响应data字段
class BMNewsData {
  /// 数据总数 (int? 类型)
  final int? total;

  /// 新闻项目列表 (List<BMNewsItem> 类型)
  final List<BMNewsItem> results;

  BMNewsData({this.total, this.results = const []});

  /// 从 JSON 解析
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

/// BMNewsItem - 单条新闻数据项
/// 作用范围: /api/livespeed/info/list 接口 results 子项
class BMNewsItem {
  /// 文章唯一ID (int? 类型)
  final int? id;

  /// 文章标题 (String? 类型)
  final String? title;

  /// 封面图URL (String? 类型)
  final String? cover;

  /// 文章类型 (int? 类型: 1=深度战术, 2=快讯, 3=独家)
  final int? type;

  /// 作者 (String? 类型)
  final String? author;

  /// 作者头像URL (String? 类型)
  final String? authorAvatar;

  /// 来源 (String? 类型)
  final String? source;

  /// 创建时间戳 (int? 类型, 秒)
  final int? createdAt;

  /// 正文内容 (String? 类型)
  final String? content;

  /// 阅读量 (int? 类型)
  final int? contentCounts;

  /// 情报/评论数 (int? 类型)
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

  /// 从 JSON 解析 (snake_case → camelCase)
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