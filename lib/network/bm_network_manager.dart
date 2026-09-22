import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'bm_api_response.dart';

/// BMNetworkManager - 网络请求管理器
/// 功能: 基于 Dio 封装的单例网络请求工具, 拦截器日志、Token 管理、GET/POST 请求
/// 作用范围: 全局网络请求
class BMNetworkManager {
  /// 单例实例 (BMNetworkManager 类型)
  static final BMNetworkManager _instance = BMNetworkManager._internal();

  /// Dio 实例 (Dio 类型, 懒加载)
  late Dio _dio;

  /// 工厂构造函数, 返回单例
  factory BMNetworkManager() {
    return _instance;
  }

  /// 私有构造函数, 初始化 Dio 配置与拦截器
  BMNetworkManager._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.livespeeds.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      /// ⭐️ 自定义 validateStatus: HTTP 2xx/3xx/4xx/5xx 全部放行, 交给上层 _parseResponse 解析后端自定义{code,data,message}
      /// 原 Dio 默认行为: 500 会直接抛 DioException 导致 response.data=null 丢失后端错误体
      validateStatus: (statusCode) {
        if (statusCode == null) return false;
        return statusCode >= 200 && statusCode < 600;
      },
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-platform': 'IOS',
        'Accept-Language': 'en-US',
        'x-version': '6.0.0',
      },
    ));

    // 添加 请求/响应/错误 拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('\n==================== BMNetwork Request ====================');
        debugPrint('Method: ${options.method}');
        debugPrint('URL: ${options.baseUrl}${options.path}');
        if (options.queryParameters.isNotEmpty) {
          debugPrint('QueryParameters: ${options.queryParameters}');
        }
        debugPrint('Headers: ${options.headers}');
        if (options.data != null) {
          _printFullString('Request Data: ${options.data}');
        }
        debugPrint('=============================================================\n');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('\n==================== BMNetwork Response ===================');
        debugPrint('URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
        debugPrint('StatusCode: ${response.statusCode}');
        _printFullString('Response Data: ${response.data}');
        debugPrint('=============================================================\n');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        debugPrint('\n==================== BMNetwork Error ======================');
        debugPrint('URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
        debugPrint('Error: ${e.message}');
        if (e.response != null) {
          debugPrint('StatusCode: ${e.response?.statusCode}');
          if (e.response?.data != null) {
            _printFullString('Error Data: ${e.response?.data}');
          }
        }
        debugPrint('=============================================================\n');
        return handler.next(e);
      },
    ));
  }

  /// 设置 Authorization Token
  /// 参数: [token] 令牌字符串
  void setAuthToken(String token) {
    _dio.options.headers['authorization'] = token;
  }

  /// 清除 Authorization Token
  void clearAuthToken() {
    _dio.options.headers.remove('authorization');
  }

  /// 完整打印长字符串, 避免被 debugPrint 截断
  /// 参数: [content] 要打印的内容
  void _printFullString(String content) {
    const int chunkSize = 800;
    if (content.length <= chunkSize) {
      debugPrint(content);
      return;
    }
    int start = 0;
    while (start < content.length) {
      int end = start + chunkSize;
      if (end > content.length) end = content.length;
      debugPrint(content.substring(start, end));
      start = end;
    }
  }

  /// GET 请求
  /// 参数: [path] API路径, [queryParameters] 查询参数 (可选)
  /// 返回: BMApiResponse 包装结果
  Future<BMApiResponse<dynamic>> getRequest(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _parseResponse(response);
    } catch (e) {
      return _parseError(e);
    }
  }

  /// POST 请求
  /// 参数: [path] API路径, [data] 请求体数据 (可选)
  /// 返回: BMApiResponse 包装结果
  Future<BMApiResponse<dynamic>> postRequest(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return _parseResponse(response);
    } catch (e) {
      return _parseError(e);
    }
  }

  /// 解析响应数据
  /// 参数: [response] Dio 响应对象
  /// 返回: BMApiResponse 包装结果
  BMApiResponse<dynamic> _parseResponse(Response response) {
    try {
      final dynamic raw = response.data;
      if (raw is Map<String, dynamic>) {
        // ⭐️ 无论 HTTP statusCode 是否为 200, 只要后端按规范返回 {code,data,message}
        // 就优先取后端自定义 code/message (500/400 时后端会塞具体错误信息, 比 Network Error 更有用)
        final dynamic codeRaw = raw['code'];
        int? codeInt;
        if (codeRaw is int) {
          codeInt = codeRaw;
        } else if (codeRaw is String) {
          codeInt = int.tryParse(codeRaw);
        }
        if (codeInt != null) {
          return BMApiResponse(
            code: codeInt,
            data: raw['data'],
            message: raw['message'] as String?,
          );
        }
        // 后端 Map 但没有 code 字段 -> fallback HTTP statusCode
        return BMApiResponse(
          code: response.statusCode,
          data: raw,
          message: 'No code in response body',
        );
      }
      // data 不是 Map (List / String / 原始 JSON) -> 直接放 data 字段, code 按是否 HTTP 2xx 给 0 或 statusCode
      final httpOk = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
      return BMApiResponse(
        code: httpOk ? 0 : response.statusCode,
        data: raw,
        message: null,
      );
    } catch (e) {
      return BMApiResponse(
        code: -2,
        message: 'Response Parse Error: $e',
      );
    }
  }

  /// 解析错误信息
  /// 参数: [e] 异常对象
  /// 返回: BMApiResponse 包装结果
  BMApiResponse<dynamic> _parseError(dynamic error) {
    String msg = 'Unknown Error';
    if (error is DioException) {
      msg = error.message ?? 'Dio Error';
    }
    return BMApiResponse(code: -1, message: msg);
  }
}