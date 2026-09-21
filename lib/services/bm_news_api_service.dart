import '../network/bm_network_manager.dart';
import '../models/bm_news_api_model.dart';
import '../models/bm_news_model.dart';

/// BMNewsApiService - 新闻列表API服务
/// 作用范围: 首页热门资讯Banner列表
class BMNewsApiService {
  /// 单例实例 (BMNewsApiService 类型)
  static final BMNewsApiService _instance = BMNewsApiService._internal();

  /// 工厂构造函数, 返回单例
  factory BMNewsApiService() {
    return _instance;
  }

  /// 私有构造函数
  BMNewsApiService._internal();

  /// API路径
  static const String _apiPath = '/api/livespeed/info/list';

  /// 请求新闻列表 (GET)
  /// [page] - 页码 (从1开始)
  /// [size] - 每页数量
  /// [type] - 文章类型, 默认1
  /// 返回: BMNewsData?
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
      _apiPath,
      queryParameters: params,
    );

    if (response.isSuccess && response.data != null) {
      return BMNewsData.fromJson(response.data as Map<String, dynamic>);
    }

    return null;
  }

  /// 请求新闻并转换为UI模型 (首页热门资讯用, 取指定条数)
  /// [count] - 请求条数, 默认5
  /// 返回: List<BMNewsModel>
  Future<List<BMNewsModel>> fetchNewsModels({int count = 5}) async {
    final data = await fetchNewsList(page: 1, size: count, type: 1);
    if (data == null || data.results.isEmpty) return [];
    return data.results.map((item) => _convertToNewsModel(item)).toList();
  }

  /// API模型 -> UI模型 转换
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
      source: item.author ?? item.source ?? '球场快讯',
      timeDesc: _formatPublishTime(item.createdAt),
      readCountDesc: _formatReadCount(item.contentCounts),
      commentCount: item.intelligenceCounts ?? 0,
    );
  }

  /// 根据文章类型获取分类标签
  String _getCategoryTag(int? type) {
    switch (type) {
      case 1:
        return '深度战术';
      case 2:
        return '快讯';
      case 3:
        return '独家';
      default:
        return '资讯';
    }
  }

  /// 格式化发布时间为相对时间描述
  String _formatPublishTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final now = DateTime.now();
    final publishDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = now.difference(publishDate);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 30) {
      return '${diff.inDays}天前';
    } else {
      return '${publishDate.month}-${publishDate.day}';
    }
  }

  /// 格式化阅读量
  String _formatReadCount(int? count) {
    if (count == null || count == 0) return '';
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w阅读';
    }
    return '$count阅读';
  }
}