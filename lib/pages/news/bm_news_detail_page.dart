import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_news_api_model.dart';
import '../../services/bm_news_api_service.dart';

/// BMNewsDetailPage - 资讯详情页
/// 功能 1:1 对齐 hanklive HankNewsDetailPage - GET /api/livespeed/info/detail 拿 title/author/createdAt/content
///         拼成 HTML(含样式) 注入 WebViewController.loadHtmlString 渲染
/// 差异化设计(vs 紫色 hanklive):
///   - 主题: 深绿 pitch900/pitch850/pitch700 背景 + BMColors.bright 亮绿点缀 (替换紫色 violet50/violet700)
///   - 返回按钮: 方形圆角 34x34 pitch850 背景 (vs 圆形 violet100)
///   - 顶部分隔: 下 0.3α pitch700 border (vs violet200)
///   - HTML body: pitch900 深绿背景 + 白字/灰字 (vs 白底黑字)
///   - 链接色: BMColors.bright 亮绿 (vs 紫色 7C3AED)
/// 架构: 单类单文件, 继承 BMBasePage
class BMNewsDetailPage extends BMBasePage {
  /// 资讯 ID (int 类型, 对应 /api/livespeed/info/detail?id=xxx 的查询参数)
  final int newsId;

  /// 资讯标题 (String? 类型, 列表传过来用于初始标题展示, API 返回前用)
  final String? newsTitle;

  const BMNewsDetailPage({
    super.key,
    required this.newsId,
    this.newsTitle,
  });

  @override
  State<BMNewsDetailPage> createState() => _BMNewsDetailPageState();
}

class _BMNewsDetailPageState extends BMBasePageState<BMNewsDetailPage> {
  /// WebView 控制器 (WebViewController? 类型, 懒加载创建后用于 loadHtmlString)
  WebViewController? _controller;

  /// 是否正在加载详情 (bool 类型, true 显示骨架屏)
  bool _isLoading = true;

  /// 详情数据 (BMNewsItem? 类型, API 返回后赋值, 若为 null 表示接口失败)
  BMNewsItem? _newsDetail;

  /// API 服务实例 (BMNewsApiService 类型, 单例, 用于请求详情接口)
  final BMNewsApiService _apiService = BMNewsApiService();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(BMColors.pitch900);
    _fetchNewsDetail();
  }

  /// 请求资讯详情: GET /api/livespeed/info/detail?id=${widget.newsId}
  ///   成功 -> setState 更新 _newsDetail + 加载HTML + 缓存本地
  ///   失败 -> setState 关闭loading, 页面显示错误占位
  Future<void> _fetchNewsDetail() async {
    try {
      final data = await _apiService.fetchNewsDetail(id: widget.newsId);
      if (!mounted) return;
      setState(() {
        _newsDetail = data;
        _isLoading = false;
      });
      if (data != null) {
        _loadHtmlContent();
      }
    } catch (e) {
      debugPrint('🛡️ BMNewsDetailPage 详情请求失败: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// 将详情数据(title/author/time/content)拼成完整HTML字符串,注入WebView
  ///   样式: 深绿背景+亮绿链接, BMColors主题, 最大宽度图片自适应
  void _loadHtmlContent() {
    if (_newsDetail == null || _controller == null) return;
    final String title = _newsDetail!.title ?? widget.newsTitle ?? '';
    final String author = _newsDetail!.author ?? _newsDetail!.source ?? '球场快讯';
    final String time = _formatTime(_newsDetail!.createdAt);
    final String content = _newsDetail!.content ?? '';
    final String bright = _colorHex(BMColors.bright);
    final String pitch900 = _colorHex(BMColors.pitch900);
    final String pitch850 = _colorHex(BMColors.pitch850);

    final htmlString = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
        <style>
          * { box-sizing: border-box; }
          body {
            padding: 16px 16px 40px 16px;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: $pitch900;
            color: #F1F5F9;
            line-height: 1.6;
            margin: 0;
          }
          .title {
            font-size: 22px;
            font-weight: 800;
            margin-bottom: 14px;
            color: #FFFFFF;
            line-height: 1.35;
          }
          .meta {
            font-size: 12px;
            color: #9CA3AF;
            margin-bottom: 20px;
            padding: 10px 12px;
            background-color: $pitch850;
            border-radius: 10px;
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          .meta .author { color: #FFFFFF; font-weight: 700; }
          .meta .time { color: #94A3B8; }
          .content {
            font-size: 15px;
            color: #CBD5E1;
            overflow-wrap: break-word;
            word-wrap: break-word;
          }
          .content img {
            max-width: 100%;
            height: auto;
            border-radius: 10px;
            margin: 12px 0;
            display: block;
            border: 1px solid rgba(255,255,255,0.06);
          }
          .content p { margin: 0 0 14px 0; }
          .content h1, .content h2, .content h3 { color: #FFFFFF; margin: 20px 0 12px; }
          .content blockquote {
            margin: 16px 0;
            padding: 10px 14px;
            border-left: 3px solid $bright;
            background-color: $pitch850;
            color: #E5E7EB;
            border-radius: 0 8px 8px 0;
          }
          a {
            color: $bright;
            text-decoration: none;
            font-weight: 600;
          }
          a:hover { text-decoration: underline; }
        </style>
      </head>
      <body>
        <div class="title">$title</div>
        <div class="meta">
          <span class="author">$author</span>
          <span class="time">$time</span>
        </div>
        <div class="content">
          $content
        </div>
      </body>
      </html>
    ''';
    _controller!.loadHtmlString(htmlString);
  }

  /// 颜色 Flutter Color -> HTML #AARRGGBB (如 BMColors.bright -> '#FF12FF80')
  String _colorHex(Color c) {
    return '#${c.alpha.toRadixString(16).padLeft(2, '0')}'
        '${c.red.toRadixString(16).padLeft(2, '0')}'
        '${c.green.toRadixString(16).padLeft(2, '0')}'
        '${c.blue.toRadixString(16).padLeft(2, '0')}';
  }

  /// 格式化时间戳 (秒级unix) -> yyyy-MM-dd HH:mm
  /// [timestamp] - 秒级时间戳 (int? 类型)
  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// 顶部导航栏: 左侧方形返回 + 中间标题(maxLines 1 ellipsis)
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        border: Border(
          bottom: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.3), width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: BMColors.pitch850,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.chevron_left, size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _newsDetail?.title ?? widget.newsTitle ?? '资讯详情',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(width: 34),
          ],
        ),
      ),
    );
  }

  /// 主体区: Loading骨架 / 错误占位 / WebView
  Widget _buildBody() {
    if (_isLoading) return _buildSkeleton();
    if (_newsDetail == null) return _buildError();
    return WebViewWidget(controller: _controller!);
  }

  /// Loading 骨架屏: 顶部标题 2 行 + meta 条 + 正文段落占位
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skel(w: double.infinity, h: 22, r: 6),
          const SizedBox(height: 10),
          _skel(w: 260, h: 22, r: 6),
          const SizedBox(height: 18),
          _skel(w: double.infinity, h: 32, r: 10),
          const SizedBox(height: 20),
          _skel(w: double.infinity, h: 12, r: 4),
          const SizedBox(height: 8),
          _skel(w: double.infinity, h: 12, r: 4),
          const SizedBox(height: 8),
          _skel(w: double.infinity - 60, h: 12, r: 4),
          const SizedBox(height: 14),
          _skel(w: double.infinity, h: 180, r: 10),
          const SizedBox(height: 14),
          _skel(w: double.infinity, h: 12, r: 4),
          const SizedBox(height: 8),
          _skel(w: double.infinity - 100, h: 12, r: 4),
        ],
      ),
    );
  }

  /// 骨架条
  Widget _skel({required double w, required double h, required double r}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: BMColors.pitch800,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }

  /// 接口失败错误占位
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error_outline, size: 40, color: BMColors.textTertiary),
            SizedBox(height: 14),
            Text(
              '资讯加载失败, 请稍后重试',
              style: TextStyle(color: BMColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
