import 'package:flutter/foundation.dart';

/// 盘口类型枚举（对应 hanklive HankOddsMenuType）
enum BMOddsType {
  /// 让球 (亚盘 AH / WL → 对应 hanklive asia)
  asianHandicap,
  /// 胜负平 (欧赔 1X2 / WDL → 对应 hanklive eu)
  matchResult,
  /// 大小球 O/U (total Goals → 对应 hanklive bs)
  overUnder,
  /// 角球数 (Corners → 对应 hanklive cr)
  corners,
}

/// 扩展: BMOddsType 转字符串
extension BMOddsTypeX on BMOddsType {
  /// 显示名(短标签,显示在 4 段 selector 上,对齐 hanklive WL/WDL/totalGoals/Corners)
  String get shortLabel {
    switch (this) {
      case BMOddsType.asianHandicap:
        return '让球';
      case BMOddsType.matchResult:
        return '胜平负';
      case BMOddsType.overUnder:
        return '大小球';
      case BMOddsType.corners:
        return '角球';
    }
  }

  /// 完整标题(显示在赔率卡片头部)
  String get fullTitle {
    switch (this) {
      case BMOddsType.asianHandicap:
        return '让球盘 (亚盘 AH)';
      case BMOddsType.matchResult:
        return '胜平负 (1X2 欧赔)';
      case BMOddsType.overUnder:
        return '大小球 (O/U)';
      case BMOddsType.corners:
        return '角球盘 (Corners)';
    }
  }

  /// 表头(从左到右,跳过公司名列和阶段标签列)
  List<String> get headers {
    switch (this) {
      case BMOddsType.asianHandicap:
        return ['主赢', '盘口', '客赢'];
      case BMOddsType.matchResult:
        return ['主胜', '平局', '客胜'];
      case BMOddsType.overUnder:
        return ['大球', '盘口', '小球'];
      case BMOddsType.corners:
        return ['大', '盘口', '小'];
    }
  }
}

/// BMCompanyOddsDetail - 单个阶段的赔率详情 (对应 hanklive HankOddsDetail)
/// 包含 3 或 4 个字段:主赔率 home (over) / 盘口值 handicap (draw 语义) / 客赔率 away (under) / 平局赔率 draw(仅 1X2)
class BMCompanyOddsDetail {
  /// 主赔率 / 让球主赔率 / 大球赔率 (String? 类型)
  final String? home;
  /// 盘口值 / 让球数 / 大小球盘口 (String? 类型,例: '-0.5' / '2.5' / '9.5')
  final String? handicap;
  /// 客赔率 / 让球客赔率 / 小球赔率 (String? 类型)
  final String? away;
  /// 平局赔率 (String? 类型,仅 1X2 有值)
  final String? draw;

  BMCompanyOddsDetail({
    this.home,
    this.handicap,
    this.away,
    this.draw,
  });

  /// 兼容多种 key: home/home_odds/over / handicap/value / away/away_odds/under / draw/draw_odds
  factory BMCompanyOddsDetail.fromJson(Map<String, dynamic>? json) {
    if (json == null) return BMCompanyOddsDetail();
    return BMCompanyOddsDetail(
      home: (json['home'] ?? json['home_odds'] ?? json['over'] ?? json['home_win'] ?? json['h'])?.toString(),
      handicap: (json['handicap'] ?? json['value'] ?? json['line'] ?? json['draw'] /* 兼容把盘口放 draw 的场景(不是欧赔)*/ ?? json['hcap'])?.toString(),
      away: (json['away'] ?? json['away_odds'] ?? json['under'] ?? json['away_win'] ?? json['a'])?.toString(),
      draw: (json['draw'] ?? json['draw_odds'] ?? json['d'] ?? json['draw_odd'])?.toString(),
    );
  }
}

/// BMCompanyOdds - 单家博彩公司的赔率(含 3 个阶段:初盘 ini / 早盘 pre / 即时盘 spot)
/// 对应 hanklive HankOddsCompany(name/pre/spot/ini)
class BMCompanyOdds {
  /// 公司 ID (String 类型,例: '28' → 皇冠)
  final String companyId;
  /// 公司名 (String? 类型,例: '皇冠')
  final String? companyName;
  /// 公司 Logo URL (String? 类型,可选显示在公司名旁)
  final String? companyLogo;
  /// 初盘 Opening (BMCompanyOddsDetail? 类型)
  final BMCompanyOddsDetail? ini;
  /// 早盘 Pre-match / 赛前 (BMCompanyOddsDetail? 类型,对应 hanklive 的 pre)
  final BMCompanyOddsDetail? pre;
  /// 即时盘 Live / Spot (BMCompanyOddsDetail? 类型,对应 hanklive 的 spot)
  final BMCompanyOddsDetail? spot;

  BMCompanyOdds({
    required this.companyId,
    this.companyName,
    this.companyLogo,
    this.ini,
    this.pre,
    this.spot,
  });

  /// 兼容解析:
  /// - 直接公司级 key: company_id / id / company_name / name / company_logo / logo
  /// - 阶段级 key: ini / initial / opening / init / pre / start / spot / live / now
  /// - 兼容 BallMatrix 老的单阶段格式(只有 home/handicap/draw/away):把它们统一塞进 ini + spot 兜底显示
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
    // BallMatrix 老的单阶段兼容:有 home/handicap 直接字段,但没 3 阶段键 → 都塞到 ini + spot 里,保证 UI 至少能显示
    final hasHome = json['home'] != null || json['home_odds'] != null;
    final hasHandicap = json['handicap'] != null || json['value'] != null;
    final hasDraw = json['draw'] != null || json['draw_odds'] != null;
    final hasAway = json['away'] != null || json['away_odds'] != null;
    if ((hasHome || hasHandicap || hasDraw || hasAway) && ini == null && pre == null && spot == null) {
      final legacy = BMCompanyOddsDetail.fromJson(json);
      return BMCompanyOdds(
        companyId: id,
        companyName: name is String ? name : null,
        companyLogo: logo is String ? logo : null,
        ini: legacy,
        spot: legacy,
      );
    }
    return BMCompanyOdds(
      companyId: id,
      companyName: name is String ? name : null,
      companyLogo: logo is String ? logo : null,
      ini: ini,
      pre: pre,
      spot: spot,
    );
  }
}

/// BMOddsData - 指数列表页(Odds Tab 用)
/// API:GET /api/livespeed/football/match/odds
/// 对应 hanklive HankOddsData: { asia, eu, bs, cr } 4 个 List
class BMOddsData {
  /// 让球 AH (asia / asian_handicap, List<BMCompanyOdds>)
  final List<BMCompanyOdds> asia;
  /// 胜平负 1X2 (eu / europe / match_result)
  final List<BMCompanyOdds> eu;
  /// 大小球 OU (bs / over_under / total)
  final List<BMCompanyOdds> bs;
  /// 角球数 Corners (cr / corners / corner)
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
      // 让球 asia: 兼容多种 key
      asia: parseList(json['asia'] ?? json['asian'] ?? json['asian_handicap'] ?? json['ah'] ?? json['handicap'] ?? json['asianHandicap']),
      // 欧赔 1X2 eu:
      eu: parseList(json['eu'] ?? json['europe'] ?? json['european'] ?? json['match_result'] ?? json['1x2'] ?? json['_1x2'] ?? json['matchResult']),
      // 大小球 bs:
      bs: parseList(json['bs'] ?? json['total'] ?? json['totals'] ?? json['over_under'] ?? json['ou'] ?? json['overUnder'] ?? json['goals']),
      // 角球 cr:
      cr: parseList(json['cr'] ?? json['corners'] ?? json['corner'] ?? json['corner_kicks']),
    );
  }

  /// 辅助:按 BMOddsType 快速取对应列表 (对齐 hanklive _getCurrentCompanies)
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

/// BMOddsHistoryPoint - 指数历史单时间点
class BMOddsHistoryPoint {
  /// 时间戳 (int? 类型,秒级)
  final int? timestamp;
  /// 单阶段赔率详情
  final BMCompanyOddsDetail detail;

  BMOddsHistoryPoint({
    this.timestamp,
    required this.detail,
  });

  factory BMOddsHistoryPoint.fromJson(Map<String, dynamic> json) {
    final ts = (json['timestamp'] is num)
        ? (json['timestamp'] as num).toInt()
        : (json['time'] is num ? (json['time'] as num).toInt() : null);
    return BMOddsHistoryPoint(
      timestamp: ts,
      detail: BMCompanyOddsDetail.fromJson(json),
    );
  }
}

/// BMOddsHistoryData - 某公司某盘口完整历史数据
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
