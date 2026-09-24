/// BMNewsType - newstypeenum
enum BMNewsType {
 /// deep tactical/dedicatedtitle
 feature,

 /// news flash
 flash,

 /// exclusive
 exclusive,
}

/// BMNewsModel - hot newsdatamodel
/// purposescope: homehot newsBannerlist
/// forshownewBannercarouseldata, supportkindconstructordirectionstyle (home/detailexpanded)
class BMNewsModel {
 /// newsuniqueidentifier (String type)
 final String newsId;

 /// newstype (BMNewsType enum, defaultfeature)
 final BMNewsType type;

 /// news title (String type)
 final String title;

 /// newsneed (String? type, optional)
 final String? summary;

 /// BannerimageURL (String? type, optional, andimageUrltwoone)
 final String? coverImageUrl;

 /// URL (String? type, optional)
 final String? thumbnailUrl;

 /// oldBannerURL (String type, defaultemptystring, compatibleold code)
 final String imageUrl;

 /// split classestag (String type, like "deep tactical" / "news flash")
 final String categoryTag;

 /// split classestagbackground color (int type, ARGBformat)
 final int categoryBgColor;

 /// split classestagtext color (int type, ARGBformat)
 final int categoryTextColor;

 /// sourcetag (String? type, compatibleold code)
 final String? source;

 /// oldtagsign (String type, defaultemptystring, compatibleold code)
 final String tag;

 /// oldtagcolorvalue (int type, compatibleold code)
 final int tagColor;

 /// publishtimedescription (String? type, correcttime)
 final String? timeDesc;

 /// readvolumedescription (String? type, like "1.8w reads")
 final String? readCountDesc;

 /// commentcount (int type)
 final int commentCount;

 /// oldpublishtime (String type, defaultempty, compatibleold code)
 final String publishTime;

 BMNewsModel({
 required this.newsId,
 this.type = BMNewsType.feature,
 required this.title,
 this.summary,
 this.coverImageUrl,
 this.thumbnailUrl,
 String? imageUrl,
 this.categoryTag = 'news',
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

 /// showuseplaneURL (prioritycoverImageUrl, otherwise thenimageUrl)
 String get displayCoverUrl {
 if (coverImageUrl != null && coverImageUrl!.isNotEmpty) return coverImageUrl!;
 return imageUrl;
 }

 /// showusetagsign (prioritycategoryTag, otherwise thentag)
 String get displayTag {
 if (categoryTag.isNotEmpty) return categoryTag;
 return tag;
 }

 /// showusetagcolor (prioritycategoryBgColor, otherwise thentagColor)
 int get displayTagColor {
 if (categoryBgColor != 0) return categoryBgColor;
 return tagColor;
 }

 /// showusepublishtime
 String get displayPublishTime {
 if (timeDesc != null && timeDesc!.isNotEmpty) return timeDesc!;
 if (publishTime.isNotEmpty) return publishTime;
 return '';
 }

 /// build model from Map mapping
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