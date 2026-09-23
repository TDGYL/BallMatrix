/// BMTeamInfo - 足球球队详细信息
/// API: GET /api/livespeed/football/team/data?team_id=
/// 用户指定返回结构 14 字段:
///   competition_id: 82
///   competition_name: "ENG Premier League"
///   name: "Manchester City"
///   logo: "https://..."
///   foundation_time: 1880 (年)
///   country_name: "England"
///   country_logo: "https://..."
///   venue_name: "Etihad Stadium"
///   venue_capacity: 55097
///   manager_name: "Pep Guardiola"
///   manager_logo: "https://..."
///   market_value: 1050000000
///   is_subscribe: false
///   website: "http://..."
class BMTeamInfo {
  /// 所属联赛 ID (int? 类型)
  final int? competitionId;

  /// 所属联赛名称 (String? 类型)
  final String? competitionName;

  /// 球队名 (String? 类型)
  final String? name;

  /// 球队 Logo URL (String? 类型)
  final String? logo;

  /// 成立年份 (int? 类型, 例: 1880)
  final int? foundationTime;

  /// 所属国家名 (String? 类型)
  final String? countryName;

  /// 国家 Logo / 国旗 URL (String? 类型)
  final String? countryLogo;

  /// 主场名称 (String? 类型)
  final String? venueName;

  /// 主场容量 (int? 类型)
  final int? venueCapacity;

  /// 主教练名 (String? 类型)
  final String? managerName;

  /// 主教练头像 URL (String? 类型)
  final String? managerLogo;

  /// 球队总身价 (int? 类型, 单位: 币种默认为 EUR 万/亿换算)
  final int? marketValue;

  /// 是否订阅 (bool? 类型, 用户关注此球队)
  final bool? isSubscribe;

  /// 球队官网 URL (String? 类型)
  final String? website;

  const BMTeamInfo({
    this.competitionId,
    this.competitionName,
    this.name,
    this.logo,
    this.foundationTime,
    this.countryName,
    this.countryLogo,
    this.venueName,
    this.venueCapacity,
    this.managerName,
    this.managerLogo,
    this.marketValue,
    this.isSubscribe,
    this.website,
  });

  factory BMTeamInfo.fromJson(Map<String, dynamic> json) {
    final cid = json['competition_id'] ?? json['competitionId'];
    final ft = json['foundation_time'] ?? json['foundationTime'];
    final vc = json['venue_capacity'] ?? json['venueCapacity'];
    final mv = json['market_value'] ?? json['marketValue'];
    return BMTeamInfo(
      competitionId: (cid is num)
          ? cid.toInt()
          : int.tryParse(cid?.toString() ?? ''),
      competitionName: (json['competition_name'] ?? json['competitionName'] ?? json['leagueName'] ?? json['league_name'])?.toString(),
      name: (json['name'] ?? json['teamName'] ?? json['team_name'])?.toString(),
      logo: (json['logo'] ?? json['teamLogo'] ?? json['team_logo'] ?? json['logoUrl'])?.toString().trim(),
      foundationTime: (ft is num)
          ? ft.toInt()
          : int.tryParse(ft?.toString() ?? ''),
      countryName: (json['country_name'] ?? json['countryName'] ?? json['country'])?.toString(),
      countryLogo: (json['country_logo'] ?? json['countryLogo'] ?? json['flag'])?.toString().trim(),
      venueName: (json['venue_name'] ?? json['venueName'] ?? json['stadium'] ?? json['stadium_name'])?.toString(),
      venueCapacity: (vc is num)
          ? vc.toInt()
          : int.tryParse(vc?.toString() ?? ''),
      managerName: (json['manager_name'] ?? json['managerName'] ?? json['coach'] ?? json['coach_name'])?.toString(),
      managerLogo: (json['manager_logo'] ?? json['managerLogo'] ?? json['coachLogo'] ?? json['coach_logo'])?.toString().trim(),
      marketValue: (mv is num)
          ? mv.toInt()
          : double.tryParse(mv?.toString() ?? '')?.toInt(),
      isSubscribe: json['is_subscribe'] is bool
          ? json['is_subscribe']
          : (json['isSubscribe'] is bool ? json['isSubscribe'] : (json['is_follow'] is bool ? json['is_follow'] : null)),
      website: (json['website'] ?? json['site'] ?? json['homepage'])?.toString().trim(),
    );
  }

  /// 成立年份格式化: 1880 → "1880年"
  String get foundationLabel {
    if (foundationTime == null || foundationTime == 0) return '-';
    return '$foundationTime年';
  }

  /// 球场容量格式化: 55097 → "55,097人"
  String get venueCapacityLabel {
    if (venueCapacity == null || venueCapacity == 0) return '-';
    final s = venueCapacity.toString();
    final len = s.length;
    // 加千分位逗号
    final buf = StringBuffer();
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}人';
  }

  /// 身价格式化: 1050000000 → "€10.5亿" (万/亿自动换算)
  String get marketValueLabel {
    if (marketValue == null || marketValue == 0) return '-';
    final v = marketValue!;
    const unit = '€';  // 足球球队身价默认欧元
    String numStr;
    if (v >= 100000000) {
      // 亿
      numStr = '${(v / 100000000).toStringAsFixed(1)}亿';
    } else if (v >= 10000) {
      // 万
      numStr = '${(v / 10000).toStringAsFixed(0)}万';
    } else {
      numStr = '$v';
    }
    return '$unit$numStr';
  }
}
