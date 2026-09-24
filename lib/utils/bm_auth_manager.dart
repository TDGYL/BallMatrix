import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bm_user_model.dart';
import '../network/bm_network_manager.dart';

/// BMAuthManager - useraccountloginstateclass (singleton)
/// feature: Token cache、userinfocache、loginstatecheck、requestheadersync
/// purposescope: fullgame, makeuse SharedPreferences dolocalpersist
class BMAuthManager {
 /// singletoninstance (BMAuthManager type)
 static final BMAuthManager _instance = BMAuthManager._internal();

 /// factory constructor, returnssingleton
 factory BMAuthManager() => _instance;

 /// privateconstructor
 BMAuthManager._internal();

 /// Token cache Key (String constant)
 static const String _kTokenKey = 'bm_user_token';

 /// userinfocache Key (String constant)
 static const String _kUserInfoKey = 'bm_user_info';

 /// memoryin of Token (String? type, not logged inwhen null)
 String? _token;

 /// memoryin of userinfo (BMUserModel? type, not logged inwhen null)
 BMUserModel? _currentUser;

 /// gettakecurrent Token (String? type, not logged inwhen null)
 String? get token => _token;

 /// gettakecurrentuserinfo (BMUserModel? type, not logged inwhen null)
 BMUserModel? get currentUser => _currentUser;

 /// whetherlogged in (bool type, Token non-nullanduserinfonon-nullwhen true)
 bool get isLoggedIn => _token != null && _token!.isNotEmpty && _currentUser != null;

 /// initialize, fromlocalcacheread Token anduserinfo
 /// feature: App launchwhencall, restoreloginstate
 Future<void> init() async {
 final prefs = await SharedPreferences.getInstance();
 _token = prefs.getString(_kTokenKey);
 final userInfoJson = prefs.getString(_kUserInfoKey);

 // restore Token torequestheader
 if (_token != null && _token!.isNotEmpty) {
 BMNetworkManager().setAuthToken(_token!);
 }

 // restoreuserinfo
 if (userInfoJson != null && userInfoJson.isNotEmpty) {
 try {
 final Map<String, dynamic> map = jsonDecode(userInfoJson);
 _currentUser = BMUserModel.fromJson(map);
 } catch (e) {
 _currentUser = null;
 }
 }
 }

 /// save Token tomemoryandlocal, syncsettingsrequestheader
 /// argument: [token] login API returns of token
 Future<void> saveToken(String token) async {
 _token = token;
 final prefs = await SharedPreferences.getInstance();
 await prefs.setString(_kTokenKey, token);
 BMNetworkManager().setAuthToken(token);
 }

 /// saveuserinfotomemoryandlocal
 /// argument: [user] userinfo API returnsdata
 Future<void> saveUserInfo(BMUserModel user) async {
 _currentUser = user;
 final prefs = await SharedPreferences.getInstance();
 final jsonString = jsonEncode(user.toJson());
 await prefs.setString(_kUserInfoKey, jsonString);
 }

 /// logout, divmemoryandlocal of Token anduserinfo, removerequestheader
 Future<void> logout() async {
 _token = null;
 _currentUser = null;
 final prefs = await SharedPreferences.getInstance();
 await prefs.remove(_kTokenKey);
 await prefs.remove(_kUserInfoKey);
 BMNetworkManager().clearAuthToken();
 }
}