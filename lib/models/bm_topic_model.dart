import 'bm_match_model.dart';

/// BMTopicIconType - 话题卡片图标类型枚举
enum BMTopicIconType {
  /// 信息图标 (翠绿色)
  info,

  /// 图表图标 (青色)
  chart,
}

/// BMTopicModel - 热门话题数据模型
/// 作用范围: 首页热门话题列表
/// 用于展示热门讨论话题卡片, 支持两种构造方式 (首页简版/详情扩展版)
class BMTopicModel {
  /// 话题唯一标识 (String 类型)
  final String topicId;

  /// 分类标签 (String 类型, 如 "英超" / "独家分析")
  final String categoryTag;

  /// 分类标签背景色 (int 类型, ARGB格式)
  final int categoryBgColor;

  /// 分类标签文字颜色 (int 类型, ARGB格式)
  final int categoryTextColor;

  /// 预测结果观点 (String 类型, 如 "预测比分 2:1")
  final String prediction;

  /// 预测主色 (int 类型, ARGB格式)
  final int predictionColor;

  /// AI洞察分析 (String 类型)
  final String aiInsight;

  /// 预测结果说明 (String 类型, 如 "主胜概率 58%")
  final String predictionResult;

  /// 信心值 (int 类型, 0-100)
  final int confidence;

  /// 关联比赛数据 (BMMatchModel? 类型, 可选)
  final BMMatchModel? embeddedMatch;

  /// 作者名称 (String? 类型, 话题发布者昵称, 对应BMPostAuthor.name)
  final String? authorName;

  /// 作者头像URL (String? 类型, 对应BMPostAuthor.avatar)
  final String? authorAvatarUrl;

  /// 发布时间描述 (String? 类型, 相对时间: 如 2小时前, 对应BMPostItem.createTime格式化)
  final String? publishTimeDesc;

  // ===== 兼容旧字段 =====
  /// 旧标题 (String 类型, 默认空)
  final String title;

  /// 旧分类 (String 类型, 默认空)
  final String category;

  /// 旧热度数 (int 类型, 默认0)
  final int heatCount;

  /// 旧标签颜色 (int 类型)
  final int tagColor;

  /// 旧标签文本 (String 类型)
  final String tagText;

  /// 旧图标类型 (BMTopicIconType 枚举)
  final BMTopicIconType iconType;

  BMTopicModel({
    required this.topicId,
    this.categoryTag = '热门话题',
    this.categoryBgColor = 0xFFDC2626,
    this.categoryTextColor = 0xFFFFFFFF,
    this.prediction = 'AI预测',
    this.predictionColor = 0xFFF97316,
    required this.aiInsight,
    this.predictionResult = '主胜概率 58%',
    this.confidence = 85,
    this.embeddedMatch,
    this.authorName,
    this.authorAvatarUrl,
    this.publishTimeDesc,
    String? title,
    String? category,
    int? heatCount,
    int? tagColor,
    String? tagText,
    BMTopicIconType? iconType,
  })  : title = title ?? '',
        category = category ?? categoryTag,
        heatCount = heatCount ?? 0,
        tagColor = tagColor ?? categoryBgColor,
        tagText = tagText ?? predictionResult,
        iconType = iconType ?? BMTopicIconType.info;

  /// 从Map映射构建模型 (兼容旧版)
  factory BMTopicModel.fromMap(Map<String, dynamic> map) {
    return BMTopicModel(
      topicId: map['topicId'] as String,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? '',
      heatCount: map['heatCount'] as int? ?? 0,
      prediction: map['prediction'] as String? ?? 'AI预测',
      aiInsight: map['aiInsight'] as String? ?? '',
      tagColor: map['tagColor'] as int? ?? 0xFFDC2626,
      tagText: map['tagText'] as String? ?? '',
      iconType: BMTopicIconType.values[map['iconType'] as int? ?? 0],
    );
  }
}