/// BMTopicModel - 热门话题数据模型
/// 作用范围: 首页热门话题列表
/// 用于展示热门讨论话题卡片
class BMTopicModel {
  /// 话题唯一标识 (String 类型)
  final String topicId;

  /// 话题标题 (String 类型)
  final String title;

  /// 话题分类标签 (String 类型, 如 "英超" / "NBA")
  final String category;

  /// 热度数值 (int 类型, 讨论参与人数)
  final int heatCount;

  /// 预测结果或观点摘要 (String 类型)
  final String prediction;

  /// AI洞察分析 (String 类型)
  final String aiInsight;

  /// 标签颜色值 (int 类型, ARGB格式)
  final int tagColor;

  /// 标签文本 (String 类型, 如 "模型匹配度 92%")
  final String tagText;

  /// 图标类型 (BMTopicIconType 枚举, 控制卡片图标样式)
  final BMTopicIconType iconType;

  BMTopicModel({
    required this.topicId,
    required this.title,
    required this.category,
    required this.heatCount,
    required this.prediction,
    required this.aiInsight,
    required this.tagColor,
    required this.tagText,
    required this.iconType,
  });

  /// 从Map映射构建模型
  factory BMTopicModel.fromMap(Map<String, dynamic> map) {
    return BMTopicModel(
      topicId: map['topicId'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      heatCount: map['heatCount'] as int,
      prediction: map['prediction'] as String,
      aiInsight: map['aiInsight'] as String,
      tagColor: map['tagColor'] as int,
      tagText: map['tagText'] as String,
      iconType: BMTopicIconType.values[map['iconType'] as int? ?? 0],
    );
  }
}

/// BMTopicIconType - 话题卡片图标类型枚举
enum BMTopicIconType {
  /// 信息图标 (翠绿色)
  info,
  /// 图表图标 (青色)
  chart,
}