import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_news_model.dart';
import '../../services/bm_news_api_service.dart';

/// BMNewsListPage - 资讯列表页 (首页第二段「查看全部」push 进来)
/// 功能: 真实GET接口(/api/livespeed/info/list, 默认type=1) + 简化资讯卡片 + 下拉刷新 + 上拉加载
class BMNewsListPage extends BMBasePage {
  /// 文章类型 (int 类型, 1深度 2快讯 3独家, 默认1)
  final int type;

  const BMNewsListPage({super.key, this.type = 1});

  @override
  State<BMNewsListPage> createState() => _BMNewsListPageState();
}

class _BMNewsListPageState extends BMBasePageState<BMNewsListPage> {
  /// 资讯列表数据 (List<BMNewsModel> 类型)
  List<BMNewsModel> _newsList = [];

  /// 下拉刷新或首次加载中 (bool 类型, 控制UI全屏Loading)
  bool _isRefreshing = true;

  /// 上拉加载更多中 (bool 类型, 控制底部footer Loading)
  bool _isLoadingMore = false;

  /// 请求重入锁 (bool 类型, 防止重复请求)
  bool _isFetching = false;

  /// 是否还有下一页 (bool 类型)
  bool _hasNoMore = false;

  /// 当前页码 (int 类型, 从1开始)
  int _page = 1;

  /// 每页条数 (int 类型, 默认50: 避免分页过短感觉被限制, 可按真实后端调整)
  final int _size = 10;

  /// 列表滚动控制器 (ScrollController 类型, 上拉加载监听)
  late final ScrollController _scrollController;

  /// API 服务实例 (BMNewsApiService 类型, 单例)
  final BMNewsApiService _apiService = BMNewsApiService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _fetchNewsList(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听: 触底100px内触发上拉加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isFetching && !_isRefreshing && !_hasNoMore) {
        _fetchNewsList(isRefresh: false);
      }
    }
  }

  /// 请求资讯列表 (真实接口: type=widget.type, GET info/list)
  /// [isRefresh] - true=重置page=1 / false=加载更多 page+1
  Future<void> _fetchNewsList({required bool isRefresh}) async {
    if (_isFetching) {
      debugPrint('🔒 BMNewsListPage 请求被挡(重入): isRefresh=$isRefresh');
      return;
    }
    if (!isRefresh && _hasNoMore) return;
    _isFetching = true;

    final int requestPage;
    if (isRefresh) {
      if (!mounted) {
        _isFetching = false;
        return;
      }
      setState(() {
        _isRefreshing = true;
        _page = 1;
        _hasNoMore = false;
      });
      requestPage = 1;
    } else {
      if (!mounted) {
        _isFetching = false;
        return;
      }
      setState(() {
        _isLoadingMore = true;
      });
      requestPage = _page + 1;
    }

    debugPrint(
      '🌐 BMNewsListPage 真实请求发起: type=${widget.type}, page=$requestPage, size=$_size',
    );
    List<BMNewsModel> result = [];
    int? serverTotal;
    try {
      final data = await _apiService.fetchNewsList(
        page: requestPage,
        size: _size,
        type: widget.type,
      );
      serverTotal = data?.total;
      if (data != null && data.results.isNotEmpty) {
        for (final item in data.results) {
          try {
            result.add(_apiServiceConvert(item));
          } catch (e) {
            debugPrint('BMNewsListPage 单条转换跳过: $e');
          }
        }
      }
      debugPrint(
        '✅ BMNewsListPage 真实请求成功: 本次返回 ${result.length} 条, 服务端总条数=$serverTotal',
      );
    } catch (e) {
      debugPrint(
        '❌ BMNewsListPage 请求异常(isRefresh=$isRefresh, page=$requestPage): $e',
      );
      result = [];
    } finally {
      _isFetching = false;
    }

    if (!mounted) return;
    setState(() {
      if (isRefresh) {
        _newsList = result;
        _page = 1;
        _isRefreshing = false;
      } else {
        _newsList.addAll(result);
        _page = requestPage;
        _isLoadingMore = false;
      }
      if (serverTotal != null) {
        _hasNoMore = _newsList.length >= serverTotal;
      } else {
        // 无 total 兜底: 返回条数 < 本次请求 size = 没有更多
        _hasNoMore = result.length < _size;
      }
    });
  }

  /// API模型转UI模型 (复用ApiService内部_convertToNewsModel逻辑, 无公开方法在此镜像一份)
  BMNewsModel _apiServiceConvert(dynamic item) {
    // 为了避免直接调用 private 方法, 这里走 fetchNewsModels 路径: 直接用 BMNewsApiService 已公开的转换路径不方便, 改为直接构建
    // 这里直接通过 fetchNewsModels 拿 list 的方式不合适，因此直接将 item 当作 BMNewsItem 类型处理
    return _convertItem(item);
  }

  BMNewsModel _convertItem(dynamic item) {
    // 安全提取字段 (兼容BMNewsItem的snake_case字段名)
    final m = item;
    String? safeString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    int? safeInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? idStr = safeString(m.id);
    int? idInt = safeInt(m.id);
    final String newsId = idStr ?? idInt?.toString() ?? '';
    final String title = safeString(m.title) ?? '';
    final String? cover = safeString(m.cover);
    final int? typeRaw = safeInt(m.type);
    final String tag = typeRaw == 1
        ? '深度战术'
        : (typeRaw == 2 ? '快讯' : (typeRaw == 3 ? '独家' : '资讯'));
    final String? author = safeString(m.author) ?? safeString(m.source);
    final String source = author ?? '球场快讯';
    // 时间: 相对时间格式化
    final int? createdAt = safeInt(m.createdAt);
    final String timeDesc = _formatPublishTime(createdAt);
    // 阅读量: contentCounts
    final String readCountDesc = _formatReadCount(safeInt(m.contentCounts));
    return BMNewsModel(
      newsId: newsId,
      title: title,
      coverImageUrl: cover,
      thumbnailUrl: cover,
      categoryTag: tag,
      source: source,
      timeDesc: timeDesc,
      readCountDesc: readCountDesc,
      commentCount: safeInt(m.intelligenceCounts) ?? 0,
    );
  }

  /// 格式化发布时间为相对时间
  String _formatPublishTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final now = DateTime.now();
    final publishDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = now.difference(publishDate);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${publishDate.month}-${publishDate.day}';
  }

  /// 格式化阅读量
  String _formatReadCount(int? count) {
    if (count == null || count == 0) return '';
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w阅读';
    }
    return '$count阅读';
  }

  /// 下拉刷新回调
  Future<void> _onRefresh() {
    return _fetchNewsList(isRefresh: true);
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        _buildNavBar(context),
        Expanded(child: _buildNewsList()),
      ],
    );
  }

  /// 自定义导航栏 (返回 + 标题)
  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        border: Border(
          bottom: BorderSide(color: BMColors.pitch800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: BMColors.textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Expanded(
            child: Text(
              'News List',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// 资讯列表区 (首屏Loading/空态/下拉刷新/上拉加载)
  Widget _buildNewsList() {
    if (_isRefreshing && _newsList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: BMColors.bright,
          strokeWidth: 2,
        ),
      );
    }
    if (_newsList.isEmpty) {
      return RefreshIndicator(
        color: BMColors.bright,
        backgroundColor: BMColors.pitch850,
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Center(
              child: Icon(
                Icons.article_outlined,
                size: 48,
                color: BMColors.textTertiary,
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                '暂无资讯',
                style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: BMColors.bright,
      backgroundColor: BMColors.pitch850,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: _newsList.length + 1,
        itemBuilder: (ctx, index) {
          if (index == _newsList.length) return _buildFooter();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildNewsCard(_newsList[index]),
          );
        },
      ),
    );
  }

  /// 资讯列表卡片: 封面图(右) + 标题2行(左) + 底部发布时间/浏览量
  Widget _buildNewsCard(BMNewsModel news) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BMColors.pitch700.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title.isEmpty ? '资讯标题' : news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BMColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 12,
                      color: BMColors.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      news.displayPublishTime.isEmpty
                          ? '刚刚'
                          : news.displayPublishTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: BMColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (news.readCountDesc != null &&
                        news.readCountDesc!.isNotEmpty) ...[
                      const Icon(
                        Icons.remove_red_eye_outlined,
                        size: 12,
                        color: BMColors.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        news.readCountDesc!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: BMColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1.3,
              child: (news.displayCoverUrl.isNotEmpty)
                  ? Image.network(
                      news.displayCoverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: BMColors.pitch800,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: BMColors.textTertiary,
                          size: 26,
                        ),
                      ),
                    )
                  : Container(
                      color: BMColors.pitch800,
                      child: const Icon(
                        Icons.article_outlined,
                        color: BMColors.textTertiary,
                        size: 28,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 底部加载指示器
  Widget _buildFooter() {
    if (_hasNoMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 24, height: 1, color: BMColors.pitch700),
            const SizedBox(width: 8),
            const Text(
              '—— 到底啦 ——',
              style: TextStyle(fontSize: 11, color: BMColors.textTertiary),
            ),
            const SizedBox(width: 8),
            Container(width: 24, height: 1, color: BMColors.pitch700),
          ],
        ),
      );
    }
    if (_isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: BMColors.bright,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text(
              '加载中...',
              style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
