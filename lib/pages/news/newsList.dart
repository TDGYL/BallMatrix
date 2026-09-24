import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_news_model.dart';
import '../../services/bm_news_api_service.dart';
import 'bm_news_detail_page.dart';

/// BMNewsListPage - newslistpage (homeNo. twosection「view all」push enter)
/// feature: trueactualGETAPI(/api/livespeed/info/list, defaulttype=1) + newscard + pull downrefresh + pull uploading
class BMNewsListPage extends BMBasePage {
 /// textchaptertype (int type, 1deep 2news flash 3exclusive, default1)
 final int type;

 const BMNewsListPage({super.key, this.type = 1});

 @override
 State<BMNewsListPage> createState() => _BMNewsListPageState();
}

class _BMNewsListPageState extends BMBasePageState<BMNewsListPage> {
 /// newslistdata (List<BMNewsModel> type)
 List<BMNewsModel> _newsList = [];

 /// pull downrefreshor first loading (bool type, makeUIfullLoading)
 bool _isRefreshing = true;

 /// pull upload morein (bool type, control bottom footer Loading)
 bool _isLoadingMore = false;

 /// requestre-entry lock (bool type, prevent duplicate requests)
 bool _isFetching = false;

 /// has next page (bool type)
 bool _hasNoMore = false;

 /// current pagecode (int type, starting from 1)
 int _page = 1;

 /// per pagecount (int type, default50: paginationbylimitmake, canbytrueactuallatersideadjust)
 final int _size = 10;

 /// listscrollcontroller (ScrollController type, pull uploadinglistener)
 late final ScrollController _scrollController;

 /// API serviceinstance (BMNewsApiService type, singleton)
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

 /// scrolllistener: trigger pull within 100px of bottom upload more
 void _onScroll() {
 if (_scrollController.position.pixels >=
 _scrollController.position.maxScrollExtent - 100) {
 if (!_isFetching && !_isRefreshing && !_hasNoMore) {
 _fetchNewsList(isRefresh: false);
 }
 }
 }

 /// requestnewslist (trueactual API: type=widget.type, GET info/list)
 /// [isRefresh] - true=reset page=1 / false=load more page+1
 Future<void> _fetchNewsList({required bool isRefresh}) async {
 if (_isFetching) {
 debugPrint('🔒 BMNewsListPage requestblocked (re-entry): isRefresh=$isRefresh');
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
      '🌐 BMNewsListPage trueactual request start: type=${widget.type}, page=$requestPage, size=$_size',
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
            debugPrint('BMNewsListPage singleconvertskip: $e');
          }
        }
      }
      debugPrint(
        '✅ BMNewsListPage trueactual request success: this returns ${result.length} items, servicetotal count=$serverTotal',
      );
    } catch (e) {
      debugPrint(
        '❌ BMNewsListPage requestexception(isRefresh=$isRefresh, page=$requestPage): $e',
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
 // none total fallback: returnscount < thistimerequest size = no more data
 _hasNoMore = result.length < _size;
 }
 });
 }

 /// APImodelconvertUImodel (reuseApiServiceinnerpart_convertToNewsModellogic, nonepublicmethodone)
 BMNewsModel _apiServiceConvert(dynamic item) {
 // ascall private method, fetchNewsModels path: use BMNewsApiService alreadypublic of convertpathnotdirection, change asbuild
 // common fetchNewsModels get list of directionstylenotmerge，will item whendo BMNewsItem typehandle
 return _convertItem(item);
 }

 BMNewsModel _convertItem(dynamic item) {
 // securitytakefield (compatibleBMNewsItem of snake_casefieldname)
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
        ? 'deep tactical'
        : (typeRaw == 2 ? 'news flash' : (typeRaw == 3 ? 'exclusive' : 'news'));
    final String? author = safeString(m.author) ?? safeString(m.source);
    final String source = author ?? 'pitch flash';
 // time: correcttimeformat
 final int? createdAt = safeInt(m.createdAt);
 final String timeDesc = _formatPublishTime(createdAt);
 // readvolume: contentCounts
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

 /// formatpublishtimeascorrecttime
 String _formatPublishTime(int? timestamp) {
 if (timestamp == null || timestamp == 0) return '';
    final now = DateTime.now();
    final publishDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = now.difference(publishDate);
    if (diff.inMinutes < 60) return '${diff.inMinutes}minutefirst';
    if (diff.inHours < 24) return '${diff.inHours}hourfirst';
    if (diff.inDays < 30) return '${diff.inDays}dayfirst';
    return '${publishDate.month}-${publishDate.day}';
 }

 /// formatreadvolume
 String _formatReadCount(int? count) {
 if (count == null || count == 0) return '';
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w reads';
    }
    return '$count reads';
 }

 /// pull downrefreshcallback
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

 /// custom app bar (returns + title)
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

 /// newslistzone (first screenLoading/emptystate/pull downrefresh/pull uploading)
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
 'No news',
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

 /// newslistcard: plane(right) + title2line(left) + bottompublishtime/volume
 Widget _buildNewsCard(BMNewsModel news) {
 return GestureDetector(
 behavior: HitTestBehavior.opaque,
 onTap: () {
 final int? id = int.tryParse(news.newsId);
 Navigator.push(
 context,
 MaterialPageRoute(
 builder: (_) => BMNewsDetailPage(
 newsId: id ?? 0,
 newsTitle: news.title,
),
),
);
 },
 child: Container(
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
 news.title.isEmpty ? 'news title' : news.title,
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
                          ? ''
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
    ),
  );
}

  /// bottomloadingindicator
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
              '—— no more ——',
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
              'loadingin...',
              style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
