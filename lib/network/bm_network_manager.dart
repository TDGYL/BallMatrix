import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'bm_api_response.dart';

/// BMNetworkManager - networkrequestdevice
/// feature: Dio of singletonnetworkrequesttool, interceptdevicelog、Token 、GET/POST request
/// purposescope: fullgamenetworkrequest
class BMNetworkManager {
 /// singletoninstance (BMNetworkManager type)
 static final BMNetworkManager _instance = BMNetworkManager._internal();

 /// Dio instance (Dio type, lazy load)
 late Dio _dio;

 /// factory constructor, returnssingleton
 factory BMNetworkManager() {
 return _instance;
 }

 /// privateconstructor, initialize Dio placeandinterceptdevice
 BMNetworkManager._internal() {
 _dio = Dio(BaseOptions(
 baseUrl: 'https://api.livespeeds.com',
 connectTimeout: const Duration(seconds: 15),
 receiveTimeout: const Duration(seconds: 15),
 responseType: ResponseType.json,
 /// ⭐️ validateStatus: HTTP 2xx/3xx/4xx/5xx allline, toupperlayer _parseResponse parselaterside{code,data,message}
 /// original Dio defaultlineas: 500 will DioException response.data=null latersideerrorbody
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

 // add request/response/error interceptdevice
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

  /// settings Authorization Token
  /// argument: [token] tokenstring
  void setAuthToken(String token) {
    _dio.options.headers['authorization'] = token;
 }

 /// div Authorization Token
 void clearAuthToken() {
 _dio.options.headers.remove('authorization');
 }

 /// completeprintlengthstring, by debugPrint break
 /// argument: [content] needprint of content
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

 /// GET request
 /// argument: [path] APIpath, [queryParameters] argument (optional)
 /// returns: BMApiResponse wrapped result
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

 /// POST request
 /// argument: [path] APIpath, [data] requestbodydata (optional)
 /// returns: BMApiResponse wrapped result
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

 /// parseresponsedata
 /// argument: [response] Dio responseobject
 /// returns: BMApiResponse wrapped result
 BMApiResponse<dynamic> _parseResponse(Response response) {
 try {
 final dynamic raw = response.data;
 if (raw is Map<String, dynamic>) {
 // ⭐️ none HTTP statusCode whetheras 200, onlyneedlatersidebyconventionreturns {code,data,message}
 // prioritytakelaterside code/message (500/400 whenlatersidewillbodyerrorinfo, ratio Network Error hasusage)
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
 // laterside Map nohas code field -> fallback HTTP statusCode
 return BMApiResponse(
 code: response.statusCode,
 data: raw,
 message: 'No code in response body',
);
 }
 // data notyes Map (List / String / raw JSON) -> data field, code bywhether HTTP 2xx to 0 or statusCode
 final httpOk = response.statusCode != null &&
 response.statusCode! >= 200 &&
 response.statusCode! < 300;
 return BMApiResponse(
 code: httpOk ? 0: response.statusCode,
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

 /// parseerrorinfo
 /// argument: [e] exceptionobject
 /// returns: BMApiResponse wrapped result
 BMApiResponse<dynamic> _parseError(dynamic error) {
 String msg = 'Unknown Error';
    if (error is DioException) {
      msg = error.message ?? 'Dio Error';
    }
    return BMApiResponse(code: -1, message: msg);
  }
}