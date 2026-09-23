/// BMLineupIncident - 阵容球员事件徽章标记 (对齐 HankLineupIncident)
/// 用于球员头像右上角展示 进球/黄牌/红牌 小徽标
class BMLineupIncident {
  /// 事件类型 (int 类型: 1=Goals 2=YellowCard 3=RedCard)
  final int type;

  const BMLineupIncident({required this.type});

  factory BMLineupIncident.fromJson(Map<String, dynamic> json) {
    final t = json['type'] ?? json['incident_type'] ?? 0;
    return BMLineupIncident(type: (t is num) ? t.toInt() : int.tryParse(t.toString()) ?? 0);
  }
}

/// BMMatchLineupPlayer - 阵容球员条目
/// 对齐 hanklive HankLineupPlayer: playerId/shirtNumber/playerName/playerLogo/x/y/position/incidents
class BMMatchLineupPlayer {
  /// 球员ID (String? 类型, 用于跳转球员详情)
  final String? playerId;
  /// 球员名 (String? 类型)
  final String? playerName;
  /// 球衣号 (int? 类型)
  final int? shirtNumber;
  /// 位置 (String? 类型, GK/DF/MF/FW 等)
  final String? position;
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
      playerLogo: (json['player_logo'] ?? json['playerLogo'] ?? json['avatar'] ?? json['photo'])?.toString(),
      x: (xv is num) ? xv.toDouble() : double.tryParse(xv?.toString() ?? ''),
      y: (yv is num) ? yv.toDouble() : double.tryParse(yv?.toString() ?? ''),
      incidents: incList,
    );
  }
}

/// BMMatchLineupSide - 主/客阵容一侧
/// 对齐 hanklive HankLineupSide (formation/coach/starters/substitutes/injureds)
class BMMatchLineupSide {
  /// 阵型 (String? 类型, 例 '4-3-3')
  final String? formation;
  /// 教练名 (String? 类型)
  final String? coach;
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
      coach: json['coach']?.toString() ?? json['coach_name']?.toString(),
      starters: parseList(json['starters'] ?? json['starting'] ?? json['starting_lineups'] ?? json['first'] ?? json['first_team']),
      substitutes: parseList(json['substitutes'] ?? json['subs'] ?? json['bench'] ?? json['substitute']),
      injureds: parseList(json['injured'] ?? json['injureds'] ?? json['miss'] ?? json['injuries']),
    );
  }
}

/// BMLineupData - 首发阵容
/// API：GET /api/livespeed/football/match/lineup
/// 对齐 hanklive HankLineupData，保持 homeFormation/homeFirst/homeSub/homeInjury/awayFirst/awaySub/awayInjury 快捷 getter
class BMLineupData {
  /// 主队阵容侧 (BMMatchLineupSide 类型)
  final BMMatchLineupSide home;
  /// 客队阵容侧 (BMMatchLineupSide 类型)
  final BMMatchLineupSide away;

  BMLineupData({
    required this.home,
    required this.away,
  });

  // ================ 对齐 hanklive HankLineupData 快捷 getter ================
  /// 主队阵型 (对齐 data.homeFormation)
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
    final h = json['home'] ?? json['home_team'];
    final a = json['away'] ?? json['away_team'];
    return BMLineupData(
      home: (h is Map<String, dynamic>) ? BMMatchLineupSide.fromJson(h) : BMMatchLineupSide(),
      away: (a is Map<String, dynamic>) ? BMMatchLineupSide.fromJson(a) : BMMatchLineupSide(),
    );
  }
}
