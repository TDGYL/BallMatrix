import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/bm_colors.dart';
import 'pages/bm_main_page.dart';
import 'utils/bm_auth_manager.dart';

/// App fullgameinput:
/// 1. WidgetsFlutterBinding.ensureInitialized() - bindnativecommon (SharedPreferences/Dio waitasyncfileenabled)
/// 2. await BMAuthManager().init() - ⭐️ launchNo. onepriority level: fromlocal SharedPreferences read token + user_info
/// - token → BMNetworkManager.setAuthToken() inputallhaslatercontinuerequestheader Authorization
/// - user_info → deserialize BMUserModel tomemory, latercontinue build displaylogged instate
/// (: onlyneednot APP, lowertimeheavystart = logged in, displaycenterloginstate UI)
/// 3. SystemChrome status barstyle
/// 4. runApp
void main() async {
 WidgetsFlutterBinding.ensureInitialized();

 // ⭐️ core: fromlocalrestoreloginstate (token inject request header + deserializeuserinfo)
 // must runApp firstlinecomplete, otherwise thenwilldisplay"not logged in"againform"logged in"
 await BMAuthManager().init();

 // settingsstatus barastomorrow
 SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
 statusBarColor: Colors.transparent,
 statusBarIconBrightness: Brightness.light,
 systemNavigationBarColor: BMColors.pitch950,
);
 SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
 runApp(const BallMatrixApp());
}

/// BallMatrixApp - green pitch intelligenceshoulduseWidget
/// feature: shoulduseinput, settingsthemeandhome
class BallMatrixApp extends StatelessWidget {
 const BallMatrixApp({super.key});

 @override
 Widget build(BuildContext context) {
 return MaterialApp(
 title: 'green pitch intelligence Pro',
 debugShowCheckedModeBanner: false,
 // intextlocalsupport（showDatePickerwaitsystemsystemwidgetmustplace，otherwise theniOSwillcardnotpop）
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