import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bm_user_model.dart';
import '../network/bm_network_manager.dart';

/// BMAuthManager - 用户账号登录状态管理类 (单例)
/// 功能: Token 缓存、用户信息缓存、登录状态检查、请求头同步
/// 作用范围: 全局, 使用 SharedPreferences 做本地持久化
class BMAuthManager {
  /// 单例实例 (BMAuthManager 类型)
  static final BMAuthManager _instance = BMAuthManager._internal();

  /// 工厂构造函数, 返回单例
  factory BMAuthManager() => _instance;

  /// 私有构造函数
  BMAuthManager._internal();

  /// Token 缓存 Key (String 常量)
  static const String _kTokenKey = 'bm_user_token';

  /// 用户信息缓存 Key (String 常量)
  static const String _kUserInfoKey = 'bm_user_info';

  /// 内存中的 Token (String? 类型, 未登录时为 null)
  String? _token;

  /// 内存中的用户信息 (BMUserModel? 类型, 未登录时为 null)
  BMUserModel? _currentUser;

  /// 获取当前 Token (String? 类型, 未登录时为 null)
  String? get token => _token;

  /// 获取当前用户信息 (BMUserModel? 类型, 未登录时为 null)
  BMUserModel? get currentUser => _currentUser;

  /// 是否已登录 (bool 类型, Token 非空且用户信息非空时为 true)
  bool get isLoggedIn => _token != null && _token!.isNotEmpty && _currentUser != null;

  /// 初始化, 从本地缓存读取 Token 和用户信息
  /// 功能: App 启动时调用, 恢复登录状态
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kTokenKey);
    final userInfoJson = prefs.getString(_kUserInfoKey);

    // 恢复 Token 到请求头
    if (_token != null && _token!.isNotEmpty) {
      BMNetworkManager().setAuthToken(_token!);
    }

    // 恢复用户信息
    if (userInfoJson != null && userInfoJson.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(userInfoJson);
        _currentUser = BMUserModel.fromJson(map);
      } catch (e) {
        _currentUser = null;
      }
    }
  }

  /// 保存 Token 到内存和本地, 同步设置请求头
  /// 参数: [token] 登录 API 返回的 token
  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
    BMNetworkManager().setAuthToken(token);
  }

  /// 保存用户信息到内存和本地
  /// 参数: [user] 用户信息 API 返回数据
  Future<void> saveUserInfo(BMUserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(user.toJson());
    await prefs.setString(_kUserInfoKey, jsonString);
  }

  /// 退出登录, 清除内存和本地的 Token 与用户信息, 移除请求头
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserInfoKey);
    BMNetworkManager().clearAuthToken();
  }
}