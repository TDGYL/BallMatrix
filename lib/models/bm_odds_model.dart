import 'package:flutter/foundation.dart';

/// handicaptypeenum（corresponding hanklive HankOddsMenuType）
enum BMOddsType {
 /// handicap (Asian handicap AH / WL → corresponding hanklive asia)
 asianHandicap,
 /// WLD (1X2 1X2 / WDL → corresponding hanklive eu)
 matchResult,
 /// sizeball O/U (total Goals → corresponding hanklive bs)
 overUnder,
 /// cornercount (Corners → corresponding hanklive cr)
 corners,
}

/// expanded: BMOddsType convertstring
extension BMOddsTypeX on BMOddsType {
 /// displayname(tag,display 4 section selector upper,alignment hanklive WL/WDL/totalGoals/Corners)
 String get shortLabel {
 switch (this) {
 case BMOddsType.asianHandicap:
 return 'handicap';
      case BMOddsType.matchResult:
        return '1X2';
      case BMOddsType.overUnder:
        return 'sizeball';
      case BMOddsType.corners:
        return 'corner';
 }
 }

 /// completetitle(displayoddscardheader)
 String get fullTitle {
 switch (this) {
 case BMOddsType.asianHandicap:
 return 'handicapodds (Asian handicap AH)';
      case BMOddsType.matchResult:
        return '1X2 (1X2 1X2)';
      case BMOddsType.overUnder:
        return 'sizeball (O/U)';
      case BMOddsType.corners:
        return 'cornerodds (Corners)';
 }
 }

 /// tableheader(fromlefttoright,skipnamecolumnandsectiontagcolumn)
 List<String> get headers {
 switch (this) {
 case BMOddsType.asianHandicap:
 return ['home win', 'handicap', 'away win'];
      case BMOddsType.matchResult:
        return ['home win', 'Dgame', 'away win'];
      case BMOddsType.overUnder:
        return ['over', 'handicap', 'small ball'];
      case BMOddsType.corners:
        return ['large', 'handicap', 'small'];
 }
 }
}

/// BMCompanyOddsDetail - singleitemssection of oddsdetail (corresponding hanklive HankOddsDetail)
/// includes 3 or 4 itemsfield:homeodds home (over) / handicapvalue handicap (draw ) / awayodds away (under) / Dgameodds draw(only 1X2)
class BMCompanyOddsDetail {
 /// homeodds / handicaphomeodds / overodds (String? type)
 final String? home;
 /// handicapvalue / handicapcount / sizeballhandicap (String? type,e.g.: '-0.5' / '2.5' / '9.5')
 final String? handicap;
 /// awayodds / handicapawayodds / small ballodds (String? type)
 final String? away;
 /// Dgameodds (String? type,only 1X2 hasvalue)
 final String? draw;

 BMCompanyOddsDetail({
 this.home,
 this.handicap,
 this.away,
 this.draw,
 });

 /// compatiblemorekind key: home/home_odds/over / handicap/value / away/away_odds/under / draw/draw_odds
 factory BMCompanyOddsDetail.fromJson(Map<String, dynamic>? json) {
 if (json == null) return BMCompanyOddsDetail();
 return BMCompanyOddsDetail(
 home: (json['home'] ?? json['home_odds'] ?? json['over'] ?? json['home_win'] ?? json['h'])?.toString(),
      handicap: (json['handicap'] ?? json['value'] ?? json['line'] ?? json['draw'] /* compatibletakehandicap draw of scenario(notyes1X2)*/ ?? json['hcap'])?.toString(),
      away: (json['away'] ?? json['away_odds'] ?? json['under'] ?? json['away_win'] ?? json['a'])?.toString(),
      draw: (json['draw'] ?? json['draw_odds'] ?? json['d'] ?? json['draw_odd'])?.toString(),
);
 }
}

/// BMCompanyOdds - single of odds(includes 3 itemssection:opening odds ini / early odds pre / liveodds spot)
/// corresponding hanklive HankOddsCompany(name/pre/spot/ini)
class BMCompanyOdds {
 /// ID (String type,e.g.: '28' → champion)
 final String companyId;
 /// name (String? type,e.g.: 'champion')
 final String? companyName;
 /// Logo URL (String? type,optionaldisplayname)
 final String? companyLogo;
 /// opening odds Opening (BMCompanyOddsDetail? type)
 final BMCompanyOddsDetail? ini;
 /// early odds Pre-match / matchfirst (BMCompanyOddsDetail? type,corresponding hanklive of pre)
 final BMCompanyOddsDetail? pre;
 /// liveodds Live / Spot (BMCompanyOddsDetail? type,corresponding hanklive of spot)
 final BMCompanyOddsDetail? spot;

 BMCompanyOdds({
 required this.companyId,
 this.companyName,
 this.companyLogo,
 this.ini,
 this.pre,
 this.spot,
 });

 /// compatibleparse:
 /// - level key: company_id / id / company_name / name / company_logo / logo
 /// - sectionlevel key: ini / initial / opening / init / pre / start / spot / live / now
 /// - compatible BallMatrix of singlesectionformat(onlyhas home/handicap/draw/away):takeunified ini + spot fallbackdisplay
 factory BMCompanyOdds.fromJson(Map<String, dynamic> json) {
 final id = (json['company_id'] ?? json['companyId'] ?? json['id'] ?? json['bookmaker_id'] ?? '').toString();
    final name = json['company_name'] ?? json['companyName'] ?? json['name'] ?? json['bookmaker'];
    final logo = json['company_logo'] ?? json['companyLogo'] ?? json['logo'];
    BMCompanyOddsDetail? parse(dynamic raw) {
      if (raw is Map<String, dynamic>) {
        return BMCompanyOddsDetail.fromJson(raw);
      }
      return null;
    }

    final ini = parse(json['ini'] ?? json['initial'] ?? json['opening'] ?? json['init'] ?? json['open'] ?? json['first']);
    final pre = parse(json['pre'] ?? json['prematch'] ?? json['pre_match'] ?? json['start'] ?? json['start_odds'] ?? json['early']);
    final spot = parse(json['spot'] ?? json['live'] ?? json['now'] ?? json['current'] ?? json['latest'] ?? json['last'] ?? json['match']);
 // BallMatrix of singlesectioncompatible:has home/handicap field,no 3 section → to ini + spot , UI lessabilitydisplay
 final hasHome = json['home'] != null || json['home_odds'] != null;
    final hasHandicap = json['handicap'] != null || json['value'] != null;
    final hasDraw = json['draw'] != null || json['draw_odds'] != null;
    final hasAway = json['away'] != null || json['away_odds'] != null;
 if ((hasHome || hasHandicap || hasDraw || hasAway) && ini == null && pre == null && spot == null) {
 final legacy = BMCompanyOddsDetail.fromJson(json);
 return BMCompanyOdds(
 companyId: id,
 companyName: name is String ? name: null,
 companyLogo: logo is String ? logo: null,
 ini: legacy,
 spot: legacy,
);
 }
 return BMCompanyOdds(
 companyId: id,
 companyName: name is String ? name: null,
 companyLogo: logo is String ? logo: null,
 ini: ini,
 pre: pre,
 spot: spot,
);
 }
}

/// BMOddsData - indexlistpage(Odds Tab usage)
/// API:GET /api/livespeed/football/match/odds
/// corresponding hanklive HankOddsData: { asia, eu, bs, cr } 4 items List
class BMOddsData {
 /// handicap AH (asia / asian_handicap, List<BMCompanyOdds>)
 final List<BMCompanyOdds> asia;
 /// 1X2 1X2 (eu / europe / match_result)
 final List<BMCompanyOdds> eu;
 /// sizeball OU (bs / over_under / total)
 final List<BMCompanyOdds> bs;
 /// cornercount Corners (cr / corners / corner)
 final List<BMCompanyOdds> cr;

 BMOddsData({
 this.asia = const [],
 this.eu = const [],
 this.bs = const [],
 this.cr = const [],
 });

 factory BMOddsData.fromJson(Map<String, dynamic> json) {
 List<BMCompanyOdds> parseList(dynamic raw) {
 if (raw is! List) return const [];
 try {
 return raw.whereType<Map<String, dynamic>>().map((e) => BMCompanyOdds.fromJson(e)).toList();
 } catch (e, s) {
 debugPrint('parse odds list failed: $e\n$s');
 return const [];
 }
 }

 return BMOddsData(
 // handicap asia: compatiblemorekind key
 asia: parseList(json['asia'] ?? json['asian'] ?? json['asian_handicap'] ?? json['ah'] ?? json['handicap'] ?? json['asianHandicap']),
 // 1X2 1X2 eu:
 eu: parseList(json['eu'] ?? json['europe'] ?? json['european'] ?? json['match_result'] ?? json['1x2'] ?? json['_1x2'] ?? json['matchResult']),
 // sizeball bs:
 bs: parseList(json['bs'] ?? json['total'] ?? json['totals'] ?? json['over_under'] ?? json['ou'] ?? json['overUnder'] ?? json['goals']),
      // corner cr:
      cr: parseList(json['cr'] ?? json['corners'] ?? json['corner'] ?? json['corner_kicks']),
);
 }

 /// auxiliary:by BMOddsType fasttakecorrespondinglist (alignment hanklive _getCurrentCompanies)
 List<BMCompanyOdds> listBy(BMOddsType type) {
 switch (type) {
 case BMOddsType.asianHandicap:
 return asia;
 case BMOddsType.matchResult:
 return eu;
 case BMOddsType.overUnder:
 return bs;
 case BMOddsType.corners:
 return cr;
 }
 }
}

/// BMOddsHistoryPoint - indexhistorysingletimepoint
class BMOddsHistoryPoint {
 /// timestamp (int? type,secondlevel)
 final int? timestamp;
 /// singlesectionoddsdetail
 final BMCompanyOddsDetail detail;

 BMOddsHistoryPoint({
 this.timestamp,
 required this.detail,
 });

 factory BMOddsHistoryPoint.fromJson(Map<String, dynamic> json) {
 final ts = (json['timestamp'] is num)
        ? (json['timestamp'] as num).toInt()
        : (json['time'] is num ? (json['time'] as num).toInt(): null);
 return BMOddsHistoryPoint(
 timestamp: ts,
 detail: BMCompanyOddsDetail.fromJson(json),
);
 }
}

/// BMOddsHistoryData - somesomehandicapcompletehistorydata
/// API:GET /api/livespeed/football/match/odd-histories?match_id=&company_id=
class BMOddsHistoryData {
 final List<BMOddsHistoryPoint> asia;
 final List<BMOddsHistoryPoint> eu;
 final List<BMOddsHistoryPoint> bs;
 final List<BMOddsHistoryPoint> cr;

 BMOddsHistoryData({
 this.asia = const [],
 this.eu = const [],
 this.bs = const [],
 this.cr = const [],
 });

 factory BMOddsHistoryData.fromJson(Map<String, dynamic> json) {
 List<BMOddsHistoryPoint> parseList(dynamic raw) {
 if (raw is! List) return const [];
 try {
 return raw.whereType<Map<String, dynamic>>().map((e) => BMOddsHistoryPoint.fromJson(e)).toList();
 } catch (_) {
 return const [];
 }
 }

 return BMOddsHistoryData(
 asia: parseList(json['asia'] ?? json['asian_handicap'] ?? json['ah']),
      eu: parseList(json['eu'] ?? json['europe'] ?? json['match_result'] ?? json['1x2']),
      bs: parseList(json['bs'] ?? json['over_under'] ?? json['ou']),
      cr: parseList(json['cr'] ?? json['corners'] ?? json['corner']),
    );
  }

  List<BMOddsHistoryPoint> listBy(BMOddsType type) {
    switch (type) {
      case BMOddsType.asianHandicap:
        return asia;
      case BMOddsType.matchResult:
        return eu;
      case BMOddsType.overUnder:
        return bs;
      case BMOddsType.corners:
        return cr;
    }
  }
}
