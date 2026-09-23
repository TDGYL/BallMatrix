/// 盘口类型枚举
enum BMOddsType {
  /// 让球 (亚盘 AH)
  asianHandicap,
  /// 胜负平 (欧赔 1X2)
  matchResult,
  /// 大小球 O/U
  overUnder,
  /// 角球数 Corners
  corners,
}

/// 扩展: BMOddsType 转字符串
extension BMOddsTypeX on BMOddsType {
  /// 显示名
  String get label {
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
}

/// BMCompanyOdds - 单家博彩公司在某盘口下的赔率数据
class BMCompanyOdds {
  /// 公司ID (String 类型, 例: '28' → 皇冠, '1' → Bet365)
  final String companyId;
  /// 公司名 (String? 类型, 例: '皇冠')
  final String? companyName;
  /// 主赔率 / 让球主队赔率 (String? 类型)
  final String? home;
  /// 让球数 / 大小球盘口值 (String? 类型, 例: '-0.5' / '2.5')
  final String? handicap;
  /// 客赔率 / 大小球客赔率 (String? 类型)
  final String? away;
  /// 欧赔 平局赔率 (String? 类型, 仅 1X2 有值)
  final String? draw;

  BMCompanyOdds({
    required this.companyId,
    this.companyName,
    this.home,
    this.handicap,
    this.away,
    this.draw,
  });

  factory BMCompanyOdds.fromJson(Map<String, dynamic> json) {
    return BMCompanyOdds(
      companyId: (json['company_id'] ?? json['companyId'] ?? json['id'] ?? '').toString(),
      companyName: json['company_name'] ?? json['companyName'] ?? json['name'],
      home: json['home']?.toString() ?? json['home_odds']?.toString(),
      handicap: json['handicap']?.toString() ?? json['value']?.toString(),
      away: json['away']?.toString() ?? json['away_odds']?.toString(),
      draw: json['draw']?.toString() ?? json['draw_odds']?.toString(),
    );
  }
}

/// BMOddsData - 指数列表页（Odds Tab 用）
/// API：GET /api/livespeed/football/match/odds
class BMOddsData {
  /// 让球 AH (List<BMCompanyOdds>)
  final List<BMCompanyOdds> asianHandicap;
  /// 胜平负 1X2
  final List<BMCompanyOdds> matchResult;
  /// 大小球 OU
  final List<BMCompanyOdds> overUnder;
  /// 角球数
  final List<BMCompanyOdds> corners;

  BMOddsData({
    this.asianHandicap = const [],
    this.matchResult = const [],
    this.overUnder = const [],
    this.corners = const [],
  });

  factory BMOddsData.fromJson(Map<String, dynamic> json) {
    List<BMCompanyOdds> parseList(dynamic raw) {
      if (raw is! List) return const [];
      try {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => BMCompanyOdds.fromJson(e))
            .toList();
      } catch (_) {
        return const [];
      }
    }

    return BMOddsData(
      asianHandicap: parseList(json['asian_handicap'] ?? json['ah'] ?? json['handicap']),
      matchResult: parseList(json['match_result'] ?? json['europe'] ?? json['_1x2']),
      overUnder: parseList(json['over_under'] ?? json['ou'] ?? json['total']),
      corners: parseList(json['corners'] ?? json['corner']),
    );
  }
}

/// BMOddsHistoryPoint - 指数历史单时间点
class BMOddsHistoryPoint {
  /// 时间戳 (int? 类型, 秒级)
  final int? timestamp;
  /// 主赔率 / 主队 (String? 类型)
  final String? home;
  /// 盘口值 (String? 类型, 让球数/大小球盘口)
  final String? handicap;
  /// 客赔率 (String? 类型)
  final String? away;
  /// 平局赔率 (String? 类型, 仅1X2)
  final String? draw;

  BMOddsHistoryPoint({
    this.timestamp,
    this.home,
    this.handicap,
    this.away,
    this.draw,
  });

  factory BMOddsHistoryPoint.fromJson(Map<String, dynamic> json) {
    return BMOddsHistoryPoint(
      timestamp: (json['timestamp'] is num)
          ? (json['timestamp'] as num).toInt()
          : (json['time'] is num ? (json['time'] as num).toInt() : null),
      home: json['home']?.toString(),
      handicap: json['handicap']?.toString() ?? json['value']?.toString(),
      away: json['away']?.toString(),
      draw: json['draw']?.toString(),
    );
  }
}

/// BMOddsHistoryData - 某公司某盘口完整历史数据
/// API：GET /api/livespeed/football/match/odd-histories?match_id=&company_id=
class BMOddsHistoryData {
  final List<BMOddsHistoryPoint> asianHandicap;
  final List<BMOddsHistoryPoint> matchResult;
  final List<BMOddsHistoryPoint> overUnder;
  final List<BMOddsHistoryPoint> corners;

  BMOddsHistoryData({
    this.asianHandicap = const [],
    this.matchResult = const [],
    this.overUnder = const [],
    this.corners = const [],
  });

  factory BMOddsHistoryData.fromJson(Map<String, dynamic> json) {
    List<BMOddsHistoryPoint> parseList(dynamic raw) {
      if (raw is! List) return const [];
      try {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => BMOddsHistoryPoint.fromJson(e))
            .toList();
      } catch (_) {
        return const [];
      }
    }

    return BMOddsHistoryData(
      asianHandicap: parseList(json['asian_handicap'] ?? json['ah']),
      matchResult: parseList(json['match_result'] ?? json['europe']),
      overUnder: parseList(json['over_under'] ?? json['ou']),
      corners: parseList(json['corners'] ?? json['corner']),
    );
  }
}
