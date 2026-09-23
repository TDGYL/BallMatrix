/// BMLineupIncident - 阵容球员事件徽章标记 (对齐 HankLineupIncident + 真实后端 {type, time})
/// 用于球员头像右上角展示 进球/黄牌/红牌 小徽标 + 事件发生时间(后续扩展显示用)
class BMLineupIncident {
  /// 事件类型 (int 类型: 1=Goals 2=YellowCard 3=RedCard)
  final int type;

  /// 事件发生时间 (String? 类型, 例: "45+3'")
  final String? time;

  const BMLineupIncident({
    required this.type,
    this.time,
  });

  factory BMLineupIncident.fromJson(Map<String, dynamic> json) {
    final t = json['type'] ?? json['incident_type'] ?? 0;
    final typeInt = (t is num)
        ? t.toInt()
        : (int.tryParse(t.toString()) ?? 0);
    return BMLineupIncident(
      type: typeInt,
      time: (json['time'] ?? json['incident_time'])?.toString(),
    );
  }
}

/// BMLineupCoach - 教练信息 (对齐真实后端 {id, logo, name})
class BMLineupCoach {
  /// 教练ID (int 类型)
  final int id;

  /// 教练名字 (String? 类型)
  final String? name;

  /// 教练头像URL (String? 类型)
  final String? logo;

  const BMLineupCoach({
    this.id = 0,
    this.name,
    this.logo,
  });

  factory BMLineupCoach.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const BMLineupCoach();
    final idRaw = json['id'];
    return BMLineupCoach(
      id: (idRaw is num) ? idRaw.toInt() : (int.tryParse(idRaw?.toString() ?? '') ?? 0),
      name: (json['name'] ?? json['coach_name'])?.toString(),
      logo: (json['logo'] ?? json['avatar'] ?? json['photo'])?.toString(),
    );
  }
}

/// BMMatchLineupPlayer - 阵容球员条目
/// 对齐 hanklive HankLineupPlayer: playerId/shirtNumber/playerName/playerLogo/x/y/position/incidents
///   同时补全 HankLineupInjuryPlayer.reason (受伤原因, 伤停区显示用)
///   同时补真实后端 rating 字段 (球员评分, 例: "8.2")
class BMMatchLineupPlayer {
  /// 球员ID (String? 类型, 用于跳转球员详情)
  final String? playerId;
  /// 球员名 (String? 类型)
  final String? playerName;
  /// 球衣号 (int? 类型)
  final int? shirtNumber;
  /// 场上位置 (String? 类型, GK/DF/MF/FW 等, 首发/替补显示用)
  final String? position;
  /// 伤停原因 (String? 类型, 对齐 HankLineupInjuryPlayer.reason, 例: "十字韧带撕裂")
  final String? reason;
  /// 球员评分 (String? 类型, 真实后端额外字段, 例: "7.8")
  final String? rating;
  /// 球员头像 URL (String? 类型, 对齐 hanklive playerLogo)
  final String? playerLogo;
  /// 球场坐标 X (0~100 double? 类型, 对齐 hanklive x)
  final double? x;
  /// 球场坐标 Y (0~100 double? 类型, 对齐 hanklive y)
  final double? y;
  /// 事件徽标列表 (List<BMLineupIncident> 类型, 对齐 hanklive incidents)
  final List<BMLineupIncident> incidents;

  BMMatchLineupPlayer({
    this.playerId,
    this.playerName,
    this.shirtNumber,
    this.position,
    this.reason,
    this.rating,
    this.playerLogo,
    this.x,
    this.y,
    this.incidents = const [],
  });

  factory BMMatchLineupPlayer.fromJson(Map<String, dynamic> json) {
    final incRaw = json['incidents'] ?? json['marks'] ?? json['badges'] ?? [];
    final List<BMLineupIncident> incList;
    if (incRaw is List) {
      incList = incRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => BMLineupIncident.fromJson(e))
          .toList();
    } else {
      incList = const [];
    }
    final xv = json['x'];
    final yv = json['y'];
    return BMMatchLineupPlayer(
      playerId: (json['player_id'] ?? json['playerId']).toString(),
      playerName: json['player_name'] ?? json['playerName'] ?? json['name'],
      shirtNumber: (json['shirt_number'] is num)
          ? (json['shirt_number'] as num).toInt()
          : (json['number'] is num ? (json['number'] as num).toInt() : null),
      position: json['position']?.toString(),
      // 伤停原因: 对齐 HankLineupInjuryPlayer.reason (常见后端命名 6 种兼容)
      reason: (json['reason']
          ?? json['injure_reason']
          ?? json['injure_desc']
          ?? json['injury_reason']
          ?? json['description']
          ?? json['remark'])?.toString(),
      // 球员评分 (真实后端字段, 后扩展显示)
      rating: (json['rating'] ?? json['score'] ?? json['mark'])?.toString(),
      playerLogo: (json['player_logo'] ?? json['playerLogo'] ?? json['avatar'] ?? json['photo'])?.toString(),
      x: (xv is num) ? xv.toDouble() : double.tryParse(xv?.toString() ?? ''),
      y: (yv is num) ? yv.toDouble() : double.tryParse(yv?.toString() ?? ''),
      incidents: incList,
    );
  }
}

/// BMMatchLineupSide - 主/客阵容一侧 (保留 Hank 格式兼容: home/away → {formation, coach, starters, subs, injureds})
/// 对齐 hanklive HankLineupSide (formation/coach/starters/substitutes/injureds)
class BMMatchLineupSide {
  /// 阵型 (String? 类型, 例 '4-3-3')
  final String? formation;
  /// 教练名/教练对象 (BMLineupCoach? 类型)
  final BMLineupCoach? coach;
  /// 首发11人 (List<BMMatchLineupPlayer> 类型)
  final List<BMMatchLineupPlayer> starters;
  /// 替补 (List<BMMatchLineupPlayer> 类型)
  final List<BMMatchLineupPlayer> substitutes;
  /// 伤停缺阵 (List<BMMatchLineupPlayer> 类型)
  final List<BMMatchLineupPlayer> injureds;

  BMMatchLineupSide({
    this.formation,
    this.coach,
    this.starters = const [],
    this.substitutes = const [],
    this.injureds = const [],
  });

  factory BMMatchLineupSide.fromJson(Map<String, dynamic> json) {
    List<BMMatchLineupPlayer> parseList(dynamic raw) {
      if (raw is! List) return const [];
      try {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => BMMatchLineupPlayer.fromJson(e))
            .toList();
      } catch (_) {
        return const [];
      }
    }

    return BMMatchLineupSide(
      formation: json['formation']?.toString(),
      coach: BMLineupCoach.fromJson(json['coach'] ?? json['coach_info']),
      starters: parseList(json['starters']
          ?? json['starting']
          ?? json['starting_lineups']
          ?? json['first']
          ?? json['first_team']),
      substitutes: parseList(json['substitutes']
          ?? json['subs']
          ?? json['bench']
          ?? json['substitute']),
      injureds: parseList(json['injured']
          ?? json['injureds']
          ?? json['miss']
          ?? json['injuries']),
    );
  }
}

/// BMLineupData - 首发阵容
/// API：GET /api/livespeed/football/match/lineup
///
/// 支持 2 种后端返回格式：
///
/// 【格式 A：真实 BallMatrix 后端（用户给定，扁平化结构）】优先解析：
/// {
///   "first":  { "home": [...], "away": [...] },   ← 首发
///   "sub":    { "home": [...], "away": [...] },   ← 替补
///   "injury": { "home": [...], "away": [...] },   ← 伤停
///   "home_coach": { "id": 0, "logo": "", "name": "" },
///   "away_coach": { "id": 0, "logo": "", "name": "" },
///   "home_formation": "4-3-3",
///   "away_formation": "4-2-3-1",
///   "home_market_value": 1000000,
///   "away_market_value": 800000,
/// }
///
/// 【格式 B：HankLive 兼容（主/客嵌套结构）】fallback 解析：
/// {
///   "home": { "formation": "", "coach": {}, "starters": [], "substitutes": [], "injureds": [] },
///   "away": { ... }
/// }
///
/// 快捷 getter（统一 UI 使用）：homeFormation / awayFormation / homeFirst / awayFirst / homeSub / awaySub / homeInjury / awayInjury
class BMLineupData {
  /// 主队阵容侧 (BMMatchLineupSide 类型, 保留 Hank 结构兼容)
  final BMMatchLineupSide home;
  /// 客队阵容侧 (BMMatchLineupSide 类型, 保留 Hank 结构兼容)
  final BMMatchLineupSide away;

  // 真实后端 (BallMatrix) 扁平字段 (优先使用)
  /// 主队教练 (BMLineupCoach? 类型, 真实后端 home_coach)
  final BMLineupCoach? homeCoach;
  /// 客队教练 (BMLineupCoach? 类型, 真实后端 away_coach)
  final BMLineupCoach? awayCoach;
  /// 主队总身价 (int? 类型, 真实后端 home_market_value)
  final int? homeMarketValue;
  /// 客队总身价 (int? 类型, 真实后端 away_market_value)
  final int? awayMarketValue;

  BMLineupData({
    required this.home,
    required this.away,
    this.homeCoach,
    this.awayCoach,
    this.homeMarketValue,
    this.awayMarketValue,
  });

  // ================ 统一 UI 快捷 getter（与 Hank 1:1 对应） ================
  /// 主队阵型 (对齐 data.homeFormation, 优先: 真实扁平字段, fallback: 嵌套结构)
  String? get homeFormation => home.formation;
  /// 客队阵型 (对齐 data.awayFormation)
  String? get awayFormation => away.formation;
  /// 主队首发11人 (对齐 data.homeFirst)
  List<BMMatchLineupPlayer> get homeFirst => home.starters;
  /// 客队首发11人 (对齐 data.awayFirst)
  List<BMMatchLineupPlayer> get awayFirst => away.starters;
  /// 主队替补 (对齐 data.homeSub)
  List<BMMatchLineupPlayer> get homeSub => home.substitutes;
  /// 客队替补 (对齐 data.awaySub)
  List<BMMatchLineupPlayer> get awaySub => away.substitutes;
  /// 主队伤停 (对齐 data.homeInjury)
  List<BMMatchLineupPlayer> get homeInjury => home.injureds;
  /// 客队伤停 (对齐 data.awayInjury)
  List<BMMatchLineupPlayer> get awayInjury => away.injureds;

  factory BMLineupData.fromJson(Map<String, dynamic> json) {
    // ========== ========== ========== ========== ==========
    // 【Step 1】解析扁平化球员列表（兼容真实后端 A 格式 / Hank 旧 B 格式）
    // ========== ========== ========== ========== ==========
    List<BMMatchLineupPlayer> parsePlayerList(dynamic raw) {
      if (raw is! List) return const [];
      try {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => BMMatchLineupPlayer.fromJson(e))
            .toList();
      } catch (_) {
        return const [];
      }
    }

    // 取 home/away 下球员列表 (Map<String, List>)
    List<BMMatchLineupPlayer> homeFromSection(dynamic section) =>
        (section is Map<String, dynamic>) ? parsePlayerList(section['home']) : const [];
    List<BMMatchLineupPlayer> awayFromSection(dynamic section) =>
        (section is Map<String, dynamic>) ? parsePlayerList(section['away']) : const [];

    // ---------- 真实后端 A：first / sub / injury 3 段 Map + home/away ----------
    final firstHome = homeFromSection(json['first']);
    final firstAway = awayFromSection(json['first']);
    final subHome = homeFromSection(json['sub']);
    final subAway = awayFromSection(json['sub']);
    final injHome = homeFromSection(json['injury']);
    final injAway = awayFromSection(json['injury']);

    // ---------- 兼容旧 Hank B：home / away 对象嵌套 (starters / substitutes / injureds) ----------
    final hNested = json['home'] ?? json['home_team'];
    final aNested = json['away'] ?? json['away_team'];
    final homeSide = (hNested is Map<String, dynamic>)
        ? BMMatchLineupSide.fromJson(hNested)
        : BMMatchLineupSide();
    final awaySide = (aNested is Map<String, dynamic>)
        ? BMMatchLineupSide.fromJson(aNested)
        : BMMatchLineupSide();

    // 合并：优先用真实后端扁平 (first/sub/injury home/away)，为空再 fallback Hank 旧嵌套
    final finalHomeFirst = firstHome.isNotEmpty ? firstHome : homeSide.starters;
    final finalAwayFirst = firstAway.isNotEmpty ? firstAway : awaySide.starters;
    final finalHomeSub = subHome.isNotEmpty ? subHome : homeSide.substitutes;
    final finalAwaySub = subAway.isNotEmpty ? subAway : awaySide.substitutes;
    final finalHomeInj = injHome.isNotEmpty ? injHome : homeSide.injureds;
    final finalAwayInj = injAway.isNotEmpty ? injAway : awaySide.injureds;

    // ========== ========== ========== ========== ==========
    // 【Step 2】阵型名 / 教练 / 身价
    // ========== ========== ========== ========== ==========
    // 阵型名：优先 home_formation / away_formation (真实后端 A)，fallback homeSide.formation (Hank B)
    final hFormation =
        (json['home_formation'] ?? json['homeFormation'] ?? homeSide.formation)
            ?.toString();
    final aFormation =
        (json['away_formation'] ?? json['awayFormation'] ?? awaySide.formation)
            ?.toString();
    // 教练：优先 home_coach / away_coach Map → BMLineupCoach，fallback homeSide.coach
    final hCoach = BMLineupCoach.fromJson(json['home_coach'] ?? json['homeCoach']);
    final aCoach = BMLineupCoach.fromJson(json['away_coach'] ?? json['awayCoach']);
    final finalHomeCoach =
        (hCoach.id != 0 || (hCoach.name != null && hCoach.name!.isNotEmpty))
            ? hCoach
            : homeSide.coach;
    final finalAwayCoach =
        (aCoach.id != 0 || (aCoach.name != null && aCoach.name!.isNotEmpty))
            ? aCoach
            : awaySide.coach;
    // 身价：home_market_value / away_market_value (int / double / String 都兼容)
    int? toIntAny(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }
    final hValue = toIntAny(json['home_market_value'] ?? json['homeMarketValue']);
    final aValue = toIntAny(json['away_market_value'] ?? json['awayMarketValue']);

    // ========== ========== ========== ========== ==========
    // 【Step 3】组装 BMMatchLineupSide（统一结构给 UI 用）
    // ========== ========== ========== ========== ==========
    final homeSideFinal = BMMatchLineupSide(
      formation: hFormation,
      coach: finalHomeCoach,
      starters: finalHomeFirst,
      substitutes: finalHomeSub,
      injureds: finalHomeInj,
    );
    final awaySideFinal = BMMatchLineupSide(
      formation: aFormation,
      coach: finalAwayCoach,
      starters: finalAwayFirst,
      substitutes: finalAwaySub,
      injureds: finalAwayInj,
    );

    return BMLineupData(
      home: homeSideFinal,
      away: awaySideFinal,
      homeCoach: finalHomeCoach,
      awayCoach: finalAwayCoach,
      homeMarketValue: hValue,
      awayMarketValue: aValue,
    );
  }
}
