import '../network/bm_network_manager.dart';
import '../models/bm_news_api_model.dart';
import '../models/bm_news_model.dart';

/// BMNewsApiService - newlistAPIservice
/// purposescope: homehot newsBannerlist
class BMNewsApiService {
 /// singletoninstance (BMNewsApiService type)
 static final BMNewsApiService _instance = BMNewsApiService._internal();

 /// factory constructor, returnssingleton
 factory BMNewsApiService() {
 return _instance;
 }

 /// privateconstructor
 BMNewsApiService._internal();

 /// APIpath
 static const String _listApiPath = '/api/livespeed/info/list';
  static const String _detailApiPath = '/api/livespeed/info/detail';

 /// requestnewlist (GET)
 /// [page] - page number (starting from 1)
 /// [size] - per pagecount
 /// [type] - textchaptertype, default1
 /// returns: BMNewsData?
 Future<BMNewsData?> fetchNewsList({
 int page = 1,
 int size = 10,
 int type = 1,
 }) async {
 final params = <String, dynamic>{
 'type': type,
      'page': page,
      'size': size,
 };

 final response = await BMNetworkManager().getRequest(
 _listApiPath,
 queryParameters: params,
);

 if (response.isSuccess && response.data != null) {
 return BMNewsData.fromJson(response.data as Map<String, dynamic>);
 }

 return null;
 }

 /// requestsinglenewdetail (GET)
 /// [id] - textchapterID (int type, required)
 /// returns: BMNewsItem? (includescomplete content/author/createdAt waitdetailfield)
 Future<BMNewsItem?> fetchNewsDetail({required int id}) async {
 final response = await BMNetworkManager().getRequest(
 _detailApiPath,
 queryParameters: <String, dynamic>{'id': id},
);
 if (response.isSuccess && response.data != null) {
 return BMNewsItem.fromJson(response.data as Map<String, dynamic>);
 }
 return null;
 }

 /// requestnewandconvertasUImodel (homehot newsuse, takespecifiedcount)
 /// [count] - requestcount, default5
 /// returns: List<BMNewsModel>
 Future<List<BMNewsModel>> fetchNewsModels({int count = 5}) async {
 final data = await fetchNewsList(page: 1, size: count, type: 1);
 if (data == null || data.results.isEmpty) return [];
 return data.results.map((item) => _convertToNewsModel(item)).toList();
 }

 /// APImodel -> UImodel convert
 BMNewsModel _convertToNewsModel(BMNewsItem item) {
 return BMNewsModel(
 newsId: item.id?.toString() ?? '',
      type: BMNewsType.feature,
      title: item.title ?? '',
      coverImageUrl: item.cover,
      thumbnailUrl: item.cover,
      categoryTag: _getCategoryTag(item.type),
      categoryBgColor: 0xFF7C3AED,
      categoryTextColor: 0xFFFFFFFF,
      source: item.author ?? item.source ?? 'pitch flash',
 timeDesc: _formatPublishTime(item.createdAt),
 readCountDesc: _formatReadCount(item.contentCounts),
 commentCount: item.intelligenceCounts ?? 0,
);
 }

 /// datatextchaptertypegettakesplit classestag
 String _getCategoryTag(int? type) {
 switch (type) {
 case 1:
 return 'deep tactical';
      case 2:
        return 'news flash';
      case 3:
        return 'exclusive';
      default:
        return 'news';
 }
 }

 /// formatpublishtimeascorrecttimedescription
 String _formatPublishTime(int? timestamp) {
 if (timestamp == null || timestamp == 0) return '';
    final now = DateTime.now();
    final publishDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = now.difference(publishDate);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}minutefirst';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}hourfirst';
    } else if (diff.inDays < 30) {
      return '${diff.inDays}dayfirst';
    } else {
      return '${publishDate.month}-${publishDate.day}';
 }
 }

 /// formatreadvolume
 String _formatReadCount(int? count) {
 if (count == null || count == 0) return '';
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w reads';
    }
    return '$count reads';
  }
}