/// BMApiResponse - 网络响应包装类
/// 作用范围: 所有网络请求的统一响应结构
/// 包含业务状态码 code、响应数据 data、消息 message
class BMApiResponse<T> {
  /// 业务状态码 (int 类型, 0 表示成功)
  final int? code;

  /// 响应数据体 (泛型 T 类型)
  final T? data;

  /// 响应消息 (String 类型)
  final String? message;

  BMApiResponse({this.code, this.data, this.message});

  /// 是否请求成功 (bool 类型, code == 0 时为 true)
  bool get isSuccess => code == 0;
}