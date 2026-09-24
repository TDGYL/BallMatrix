/// BMTeamInfo - footballteamdetail info
/// API: GET /api/livespeed/football/team/data?team_id=
/// userspecifiedreturnsstructure 14 field:
/// competition_id: 82
/// competition_name: "ENG Premier League"
///   name: "Manchester City"
///   logo: "https://..."
///   foundation_time: 1880 (year)
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
 /// allleague ID (int? type)
 final int? competitionId;

 /// allleague namename (String? type)
 final String? competitionName;

 /// team name (String? type)
 final String? name;

 /// team Logo URL (String? type)
 final String? logo;

 /// formatyear (int? type, e.g.: 1880)
 final int? foundationTime;

 /// allcountryname (String? type)
 final String? countryName;

 /// country Logo / URL (String? type)
 final String? countryLogo;

 /// homecourtname (String? type)
 final String? venueName;

 /// homecourtcapacity (int? type)
 final int? venueCapacity;

 /// homecoachname (String? type)
 final String? managerName;

 /// homecoachavatar URL (String? type)
 final String? managerLogo;

 /// teamtotal market value (int? type, singleposition: kinddefaultas EUR 10k/100Mswapcalc)
 final int? marketValue;

 /// whethersubscribe (bool? type, userfollowteam)
 final bool? isSubscribe;

 /// teamofficial site URL (String? type)
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

 /// formatyearformat: 1880 → "1880year"
  String get foundationLabel {
    if (foundationTime == null || foundationTime == 0) return '-';
    return '$foundationTime yr';
 }

 /// ballcourtcapacityformat: 55097 → "55,097people"
  String get venueCapacityLabel {
    if (venueCapacity == null || venueCapacity == 0) return '-';
 final s = venueCapacity.toString();
 final len = s.length;
 // addthousandminpositioncomma No.
 final buf = StringBuffer();
 for (int i = 0; i < len; i++) {
 if (i > 0 && (len - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}people';
 }

 /// market valueformat: 1050000000 → "€10.5100M" (auto convert 10k/100M)
 String get marketValueLabel {
 if (marketValue == null || marketValue == 0) return '-';
    final v = marketValue!;
    const unit = '€'; // footballteammarket valuedefaultelement
 String numStr;
 if (v >= 100000000) {
 // 100M
 numStr = '${(v / 100000000).toStringAsFixed(1)}100M';
 } else if (v >= 10000) {
 // 10k
 numStr = '${(v / 10000).toStringAsFixed(0)}10k';
    } else {
      numStr = '$v';
    }
    return '$unit$numStr';
  }
}
