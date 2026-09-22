import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// BMWebViewPage - 通用本地HTML展示页
/// 功能: 加载 flutter assets 目录下的本地 HTML (例: 用户协议 / 隐私政策)
/// 差异化: 深绿 pitch900 背景 + 左侧胶囊返回 + 标题居中 + 加载骨架转圈
/// 架构: 单类单文件, 继承 BMBasePage
class BMWebViewPage extends BMBasePage {
  /// 要加载的 HTML 文件名 (String 类型, 例: 'user-agreement.html' / 'privacy-agreement.html')
  final String htmlFileName;

  /// 页面显示标题 (String? 类型, 传 null 时根据 html 文件名显示默认标题)
  final String? pageTitle;

  const BMWebViewPage({
    super.key,
    required this.htmlFileName,
    this.pageTitle,
  });

  @override
  State<BMWebViewPage> createState() => _BMWebViewPageState();
}

class _BMWebViewPageState extends BMBasePageState<BMWebViewPage> {
  /// WebViewController (webview_flutter 提供, 懒加载异步创建)
  WebViewController? _controller;

  /// 是否加载完成 (bool 类型, 控制是否隐藏骨架Loading)
  bool _loaded = false;

  /// 加载出错提示 (String? 类型)
  String? _errMsg;

  @override
  void initState() {
    super.initState();
    // 异步加载本地 assets HTML → 注入 WebViewController
    _initLocalWebView();
  }

  /// 根据 html 文件名映射显示的默认标题
  String get _title {
    if (widget.pageTitle != null && widget.pageTitle!.isNotEmpty) {
      return widget.pageTitle!;
    }
    switch (widget.htmlFileName) {
      case 'user-agreement.html':
        return '用户协议';
      case 'privacy-agreement.html':
        return '隐私政策';
      default:
        return '详情';
    }
  }

  /// 从 rootBundle 读取本地 assets HTML 字符串, base64 encode 后用 Uri.dataFromString 加载
  ///   避免需要申请 file:// 本地文件权限, 同时避免 Android WebView asset 路径兼容问题
  Future<void> _initLocalWebView() async {
    try {
      final String htmlContent = await rootBundle.loadString(
        'assets/html/${widget.htmlFileName}',
      );
      if (!mounted) return;
      final ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(BMColors.pitch900)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loaded = true);
            },
            onWebResourceError: (err) {
              debugPrint('🛡️ BMWebView error: ${err.description} code=${err.errorCode}');
              // 非致命错误(favicon 404 等)忽略, 不打断用户
            },
          ),
        )
        ..loadRequest(
          Uri.dataFromString(
            htmlContent,
            mimeType: 'text/html',
            encoding: Encoding.getByName('utf-8'),
          ),
        );
      setState(() => _controller = ctrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errMsg = '资源加载失败, 请重试 ($e)';
        _loaded = true;
      });
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  if (_errMsg != null) _buildError() else if (_controller != null) _buildWebView(),
                  if (!_loaded) _buildLoading(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部导航栏: 左胶囊返回 + 中标题
  Widget _buildAppBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        border: Border(bottom: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.3))),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
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
                child: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              _title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// WebView 渲染区
  Widget _buildWebView() {
    return SizedBox.expand(
      child: WebViewWidget(controller: _controller!),
    );
  }

  /// 骨架 Loading
  Widget _buildLoading() {
    return Container(
      color: BMColors.pitch900,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: BMColors.bright, strokeWidth: 2),
          ),
          SizedBox(height: 10),
          Text(
            '加载中...',
            style: TextStyle(fontSize: 11, color: BMColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 错误占位
  Widget _buildError() {
    return Container(
      color: BMColors.pitch900,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        _errMsg ?? '加载失败',
        style: const TextStyle(fontSize: 12, color: BMColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
