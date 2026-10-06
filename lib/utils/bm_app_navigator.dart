import 'package:flutter/material.dart';
import '../pages/login/bm_login_page.dart';

/// BMAppNavigator - globalnavigationtoolclass
/// feature: global NavigatorState key (supportsnetwork layerperformredirectwhennocontext) + 401 unifiedredirect to login page
/// purposescope: BMNetworkManager code=401 whencall [goToLogin], MaterialApp mount [navigatorKey]
class BMAppNavigator {
 /// global NavigatorState key (GlobalKey type, main.dart of MaterialApp usage)
 static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

 /// whethercurrentlyon login page (bool type, login page lifecyclemaintain, prevent401 duplicatepush)
 static bool isOnLoginPage = false;

 /// privateconstructor, preventinstance
 BMAppNavigator._();

 /// redirect to login page (401 unifiedentry, duplicateprevent)
 /// feature: currentlyalreadyon login page whenignored, otherwisenavigate push BMLoginPage
 static void goToLogin() {
 // alreadyon login page -> preventduplicatepush (login page ownrequestreturn401 scenarionottriggeragain)
 if (isOnLoginPage) return;
 final nav = navigatorKey.currentState;
 if (nav == null || !nav.mounted) return;
 nav.push(
 MaterialPageRoute(builder: (_) => const BMLoginPage()),
 );
 }
}
