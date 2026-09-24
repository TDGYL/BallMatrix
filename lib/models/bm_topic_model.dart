import 'bm_match_model.dart';

/// BMTopicIconType - topic cardicontypeenum
enum BMTopicIconType {
 /// infoicon (color)
 info,

 /// tableicon (color)
 chart,
}

/// BMTopicModel - hot topicdatamodel
/// purposescope: homehot topic list
/// forshowtopic card, supportkindconstructordirectionstyle (home/detailexpanded)
class BMTopicModel {
 /// topicuniqueidentifier (String type)
 final String topicId;

 /// split classestag (String type, like "Premier League" / "exclusiveanalysis")
 final String categoryTag;

 /// split classestagbackground color (int type, ARGBformat)
 final int categoryBgColor;

 /// split classestagtext color (int type, ARGBformat)
 final int categoryTextColor;

 /// predictionresultpoint (String type, like "predicted score 2:1")
 final String prediction;

 /// predictionhomecolor (int type, ARGBformat)
 final int predictionColor;

 /// AIanalysis (String type)
 final String aiInsight;

 /// predictionresultdescription (String type, like "home win probability 58%")
 final String predictionResult;

 /// value (int type, 0-100)
 final int confidence;

 /// related match data (BMMatchModel? type, optional)
 final BMMatchModel? embeddedMatch;

 /// topictaglist (List<String> type, image comma split + filter com/ firstlater of multipletopic)
 final List<String> hashtags;

 /// likecount (int type, corresponding BMPostItem.likeCount)
 final int likeCount;

 /// commentcount (int type, corresponding BMPostItem.commentCount)
 final int commentCount;

 /// liked or not (bool type, corresponding BMPostItem.isLike)
 final bool isLiked;

 /// authorname (String? type, topicpublishonenickname, correspondingBMPostAuthor.name)
 final String? authorName;

 /// authoravatarURL (String? type, correspondingBMPostAuthor.avatar)
 final String? authorAvatarUrl;

 /// publishtimedescription (String? type, correcttime: like 2hourfirst, correspondingBMPostItem.createTimeformat)
 final String? publishTimeDesc;

 // ===== compatibleoldfield =====
 /// oldtitle (String type, defaultempty)
 final String title;

 /// oldsplit classes (String type, defaultempty)
 final String category;

 /// olddegreecount (int type, default0)
 final int heatCount;

 /// oldtagcolor (int type)
 final int tagColor;

 /// oldtagtext (String type)
 final String tagText;

 /// oldicontype (BMTopicIconType enum)
 final BMTopicIconType iconType;

 BMTopicModel({
 required this.topicId,
 this.categoryTag = 'hot topic',
    this.categoryBgColor = 0xFFDC2626,
    this.categoryTextColor = 0xFFFFFFFF,
    this.prediction = 'AIprediction',
    this.predictionColor = 0xFFF97316,
    required this.aiInsight,
    this.predictionResult = 'home win probability 58%',
    this.confidence = 85,
    this.embeddedMatch,
    this.hashtags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
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

 /// build model from Map mapping (compatibleold)
 factory BMTopicModel.fromMap(Map<String, dynamic> map) {
 return BMTopicModel(
 topicId: map['topicId'] as String,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? '',
      heatCount: map['heatCount'] as int? ?? 0,
      prediction: map['prediction'] as String? ?? 'AIprediction',
      aiInsight: map['aiInsight'] as String? ?? '',
      tagColor: map['tagColor'] as int? ?? 0xFFDC2626,
      tagText: map['tagText'] as String? ?? '',
      iconType: BMTopicIconType.values[map['iconType'] as int? ?? 0],
    );
  }
}