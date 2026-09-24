/// BMUserModel - useraccountinfomodel
/// purposescope: mapping /api/livespeed/member returns of userdata
/// includesuserID、account、nickname、avatar、remainingquotawaitinfo
class BMUserModel {
 /// userID (int type, useruniqueidentifier)
 final int? id;

 /// loginaccount (String type)
 final String? account;

 /// bindemail (String type)
 final String? email;

 /// nickname (String type, userdisplayname)
 final String? nickname;

 /// avatarURL (String type)
 final String? avatar;

 /// itemssign (String type)
 final String? signature;

 /// bindphoneNo. (String type)
 final String? mobile;

 /// registertime (String type)
 final String? regTime;

 /// userstate (int type, 0=center 1=forbidden)
 final int? status;

 /// loginDidentifier (String type)
 final String? platforms;

 /// nearlogintime (String type)
 final String? lastLoginTime;

 /// whetherfirst timelogin (bool type)
 final bool? isDebut;

 /// remainingquota (int type)
 final int? kMoney;

 /// bestcount (int type)
 final int? kCoupon;

 /// followpeoplecount (int type)
 final int? followers;

 /// fanscount (int type)
 final int? fansCount;

 /// gender (int type, 0=not yetknow 1=male 2=female)
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

 /// from JSON mappingbuild model (snake_case → camelCase)
 /// argument: [json] raw JSON data
 /// returns: BMUserModel instance
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

 /// convertas JSON (camelCase → snake_case)
 /// returns: Map<String, dynamic>
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