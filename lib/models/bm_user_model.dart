/// BMUserModel - 用户账号信息模型
/// 作用范围: 映射 /api/livespeed/member 返回的用户数据
/// 包含用户ID、账号、昵称、头像、余额等信息
class BMUserModel {
  /// 用户ID (int 类型, 用户唯一标识)
  final int? id;

  /// 登录账号 (String 类型)
  final String? account;

  /// 绑定邮箱 (String 类型)
  final String? email;

  /// 昵称 (String 类型, 用户显示名)
  final String? nickname;

  /// 头像URL (String 类型)
  final String? avatar;

  /// 个性签名 (String 类型)
  final String? signature;

  /// 绑定手机号 (String 类型)
  final String? mobile;

  /// 注册时间 (String 类型)
  final String? regTime;

  /// 用户状态 (int 类型, 0=正常 1=封禁)
  final int? status;

  /// 登录平台标识 (String 类型)
  final String? platforms;

  /// 最近登录时间 (String 类型)
  final String? lastLoginTime;

  /// 是否首次登录 (bool 类型)
  final bool? isDebut;

  /// 金币余额 (int 类型)
  final int? kMoney;

  /// 优惠券数量 (int 类型)
  final int? kCoupon;

  /// 关注人数 (int 类型)
  final int? followers;

  /// 粉丝数量 (int 类型)
  final int? fansCount;

  /// 性别 (int 类型, 0=未知 1=男 2=女)
  final int? sex;

  BMUserModel({
    this.id,
    this.account,
    this.email,
    this.nickname,
    this.avatar,
    this.signature,
    this.mobile,
    this.regTime,
    this.status,
    this.platforms,
    this.lastLoginTime,
    this.isDebut,
    this.kMoney,
    this.kCoupon,
    this.followers,
    this.fansCount,
    this.sex,
  });

  /// 从 JSON 映射构建模型 (snake_case → camelCase)
  /// 参数: [json] 原始 JSON 数据
  /// 返回: BMUserModel 实例
  factory BMUserModel.fromJson(Map<String, dynamic> json) {
    return BMUserModel(
      id: json['id'] as int?,
      account: json['account'] as String?,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      signature: json['signature'] as String?,
      mobile: json['mobile'] as String?,
      regTime: json['reg_time'] as String?,
      status: json['status'] as int?,
      platforms: json['platforms'] as String?,
      lastLoginTime: json['last_login_time'] as String?,
      isDebut: json['is_debut'] as bool?,
      kMoney: json['k_money'] as int?,
      kCoupon: json['k_coupon'] as int?,
      followers: json['followers'] as int?,
      fansCount: json['fans_count'] as int?,
      sex: json['sex'] as int?,
    );
  }

  /// 转换为 JSON (camelCase → snake_case)
  /// 返回: Map<String, dynamic>
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account': account,
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'signature': signature,
      'mobile': mobile,
      'reg_time': regTime,
      'status': status,
      'platforms': platforms,
      'last_login_time': lastLoginTime,
      'is_debut': isDebut,
      'k_money': kMoney,
      'k_coupon': kCoupon,
      'followers': followers,
      'fans_count': fansCount,
      'sex': sex,
    };
  }
}