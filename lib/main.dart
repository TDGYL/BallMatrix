import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/bm_colors.dart';
import 'pages/bm_main_page.dart';

void main() {
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