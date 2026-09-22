import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/bm_colors.dart';
import 'pages/bm_main_page.dart';
import 'utils/bm_auth_manager.dart';

/// App 全局入口:
/// 1. WidgetsFlutterBinding.ensureInitialized() - 绑定原生交互通道 (SharedPreferences/Dio 等异步插件可用)
/// 2. await BMAuthManager().init() - ⭐️ 冷启动第一优先级: 从本地沙盒 SharedPreferences 读 token + user_info
///    - token → BMNetworkManager.setAuthToken() 注入所有后续请求头 Authorization
///    - user_info → 反序列化 BMUserModel 到内存, 后续 build 直接显示已登录状态
///    (保证: 只要不卸载 APP, 下次重启 = 已登录, 首帧就显示正确登录态 UI)
/// 3. SystemChrome 状态栏样式
/// 4. runApp
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⭐️ 核心: 从本地沙盒恢复登录态 (token 注入请求头 + 反序列化用户信息)
  // 必须在 runApp 前执行完毕, 否则首帧会显示"未登录"再闪成"已登录"
  await BMAuthManager().init();

  // 设置状态栏为透明
  SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: BMColors.pitch950,
  );
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  runApp(const BallMatrixApp());
}

/// BallMatrixApp - 绿场智算应用根Widget
/// 功能: 应用入口, 设置主题与首页
class BallMatrixApp extends StatelessWidget {
  const BallMatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '绿场智算 Pro',
      debugShowCheckedModeBanner: false,
      // 中文本地化支持（showDatePicker等系统组件必须配置，否则iOS会卡死不弹出）
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: BMColors.pitch900,
        colorScheme: ColorScheme.fromSeed(
          seedColor: BMColors.accent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: BMColors.pitch900,
          foregroundColor: BMColors.textPrimary,
          elevation: 0,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: BMColors.bright,
          inactiveTrackColor: BMColors.pitch950,
          thumbColor: BMColors.bright,
          trackHeight: 6,
        ),
        fontFamily: '-apple-system',
      ),
      home: const BMMainPage(),
    );
  }
}