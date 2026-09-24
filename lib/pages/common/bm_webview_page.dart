import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// BMWebViewPage - commonlocalHTMLshowpage
/// feature: loading flutter assets itemlower of local HTML (e.g.: User Agreement / Privacy Policy)
/// differentiation: dark green pitch900 background + left sidepillreturns + titlecenter + loadingskeletonconvert
/// architecture: one class per file, extends BMBasePage
class BMWebViewPage extends BMBasePage {
 /// needloading of HTML textfilename (String type, e.g.: 'user-agreement.html' / 'privacy-agreement.html')
 final String htmlFileName;

 /// pagedisplaytitle (String? type, pass null whendata html textfilenamedisplaydefaulttitle)
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
 /// WebViewController (webview_flutter , lazy loadasynccreate)
 WebViewController? _controller;

 /// whetherloadingdone (bool type, makewhetherhideskeletonLoading)
 bool _loaded = false;

 /// loadingoutputwrongtoast (String? type)
 String? _errMsg;

 @override
 void initState() {
 super.initState();
 // asyncloadinglocal assets HTML → input WebViewController
 _initLocalWebView();
 }

 /// data html textfilenamemappingdisplay of defaulttitle
 String get _title {
 if (widget.pageTitle != null && widget.pageTitle!.isNotEmpty) {
 return widget.pageTitle!;
 }
 switch (widget.htmlFileName) {
 case 'user-agreement.html':
        return 'User Agreement';
      case 'privacy-agreement.html':
        return 'Privacy Policy';
      default:
        return 'detail';
 }
 }

 /// from rootBundle readlocal assets HTML string, base64 encode lateruse Uri.dataFromString loading
 /// needs file:// localtextfilepermission, simultaneously Android WebView asset pathcompatibleissue
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
 // nonerror(favicon 404 etc)ignore, notbreakuser
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
        _errMsg = 'resourceLoad Failed, please retry ($e)';
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

 /// topapp bar: leftpillreturns + intitle
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

 /// WebView renderzone
 Widget _buildWebView() {
 return SizedBox.expand(
 child: WebViewWidget(controller: _controller!),
);
 }

 /// skeleton Loading
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
 'loadingin...',
            style: TextStyle(fontSize: 11, color: BMColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// errorplaceholder
  Widget _buildError() {
    return Container(
      color: BMColors.pitch900,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        _errMsg ?? 'Load Failed',
        style: const TextStyle(fontSize: 12, color: BMColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
