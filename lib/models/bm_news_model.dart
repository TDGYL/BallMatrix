/// BMNewsType - 资讯类型枚举
enum BMNewsType {
  /// 深度战术/专题报道
  feature,

  /// 快讯
  flash,

  /// 独家
  exclusive,
}

/// BMNewsModel - 热门资讯数据模型
/// 作用范围: 首页热门资讯Banner列表
/// 用于展示新闻Banner轮播数据, 支持两种构造方式 (首页简版/详情扩展版)
class BMNewsModel {
  /// 资讯唯一标识 (String 类型)
  final String newsId;

  /// 资讯类型 (BMNewsType 枚举, 默认feature)
  final BMNewsType type;

  /// 资讯标题 (String 类型)
  final String title;

  /// 资讯摘要 (String? 类型, 可选)
  final String? summary;

  /// Banner图片URL (String? 类型, 可选, 与imageUrl二选一)
  final String? coverImageUrl;

  /// 缩略图URL (String? 类型, 可选)
  final String? thumbnailUrl;

  /// 旧Banner图URL (String 类型, 默认空字符串, 兼容旧代码)
  final String imageUrl;

  /// 分类标签 (String 类型, 如 "深度战术" / "快讯")
  final String categoryTag;

  /// 分类标签背景色 (int 类型, ARGB格式)
  final int categoryBgColor;

  /// 分类标签文字颜色 (int 类型, ARGB格式)
  final int categoryTextColor;

  /// 来源标签 (String? 类型, 兼容旧代码)
  final String? source;

  /// 旧标签名 (String 类型, 默认空字符串, 兼容旧代码)
  final String tag;

  /// 旧标签颜色值 (int 类型, 兼容旧代码)
  final int tagColor;

  /// 发布时间描述 (String? 类型, 相对时间)
  final String? timeDesc;

  /// 阅读量描述 (String? 类型, 如 "1.8w阅读")
  final String? readCountDesc;

  /// 评论数 (int 类型)
  final int commentCount;

  /// 旧发布时间 (String 类型, 默认空, 兼容旧代码)
  final String publishTime;

  BMNewsModel({
    required this.newsId,
    this.type = BMNewsType.feature,
    required this.title,
    this.summary,
    this.coverImageUrl,
    this.thumbnailUrl,
    String? imageUrl,
    this.categoryTag = '资讯',
    this.categoryBgColor = 0xFF7C3AED,
    this.categoryTextColor = 0xFFFFFFFF,
    this.source,
    String? tag,
    int? tagColor,
    this.timeDesc,
    this.readCountDesc,
    this.commentCount = 0,
    String? publishTime,
  })  : imageUrl = imageUrl ?? coverImageUrl ?? '',
        tag = tag ?? categoryTag,
        tagColor = tagColor ?? categoryBgColor,
        publishTime = publishTime ?? timeDesc ?? '';

  /// 展示用封面图URL (优先coverImageUrl, 否则imageUrl)
  String get displayCoverUrl {
    if (coverImageUrl != null && coverImageUrl!.isNotEmpty) return coverImageUrl!;
    return imageUrl;
  }

  /// 展示用标签名 (优先categoryTag, 否则tag)
  String get displayTag {
    if (categoryTag.isNotEmpty) return categoryTag;
    return tag;
  }

  /// 展示用标签颜色 (优先categoryBgColor, 否则tagColor)
  int get displayTagColor {
    if (categoryBgColor != 0) return categoryBgColor;
    return tagColor;
  }

  /// 展示用发布时间
  String get displayPublishTime {
    if (timeDesc != null && timeDesc!.isNotEmpty) return timeDesc!;
    if (publishTime.isNotEmpty) return publishTime;
    return '';
  }

  /// 从Map映射构建模型
  factory BMNewsModel.fromMap(Map<String, dynamic> map) {
    return BMNewsModel(
      newsId: map['newsId'] as String,
      title: map['title'] as String,
      summary: map['summary'] as String?,
      imageUrl: map['imageUrl'] as String? ?? '',
      tag: map['tag'] as String? ?? '',
      tagColor: map['tagColor'] as int? ?? 0xFF7C3AED,
      publishTime: map['publishTime'] as String? ?? '',
    );
  }
}