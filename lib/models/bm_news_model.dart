/// BMNewsModel - 热门资讯数据模型
/// 作用范围: 首页热门资讯Banner列表
/// 用于展示新闻Banner轮播数据
class BMNewsModel {
  /// 资讯唯一标识 (String 类型)
  final String newsId;

  /// 资讯标题 (String 类型)
  final String title;

  /// 资讯摘要 (String 类型)
  final String summary;

  /// Banner图片URL (String 类型)
  final String imageUrl;

  /// 来源标签 (String 类型, 如 "独家" / "快讯")
  final String tag;

  /// 标签颜色值 (int 类型, ARGB格式)
  final int tagColor;

  /// 发布时间 (String 类型)
  final String publishTime;

  BMNewsModel({
    required this.newsId,
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.tag,
    required this.tagColor,
    required this.publishTime,
  });

  /// 从Map映射构建模型
  factory BMNewsModel.fromMap(Map<String, dynamic> map) {
    return BMNewsModel(
      newsId: map['newsId'] as String,
      title: map['title'] as String,
      summary: map['summary'] as String,
      imageUrl: map['imageUrl'] as String,
      tag: map['tag'] as String,
      tagColor: map['tagColor'] as int,
      publishTime: map['publishTime'] as String,
    );
  }
}