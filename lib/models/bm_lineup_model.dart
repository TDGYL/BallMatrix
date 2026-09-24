/// BMLineupIncident - lineupplayereventbadgemarker (alignment HankLineupIncident + trueactuallaterside {type, time})
/// forplayeravatartop-right cornershow goal/yellow card/red card smalltag + eventsendtime(latercontinueexpandeddisplayusage)
class BMLineupIncident {
 /// eventtype (int type: 1=Goals 2=YellowCard 3=RedCard)
 final int type;

 /// eventsendtime (String? type, e.g.: "45+3'")
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

/// BMLineupCoach - coachinfo (alignmenttrueactuallaterside {id, logo, name})
class BMLineupCoach {
 /// coachID (int type)
 final int id;

 /// coachnametext (String? type)
 final String? name;

 /// coachavatarURL (String? type)
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

/// BMMatchLineupPlayer - lineupplayeritemsitem
/// alignment hanklive HankLineupPlayer: playerId/shirtNumber/playerName/playerLogo/x/y/position/incidents
/// simultaneouslypatchfull HankLineupInjuryPlayer.reason (byreason, injuryzonedisplayusage)
/// simultaneouslypatchtrueactuallaterside rating field (playermin, e.g.: "8.2")
class BMMatchLineupPlayer {
 /// playerID (String? type, fornavigateplayerdetail)
 final String? playerId;
 /// playername (String? type)
 final String? playerName;
 /// jerseyNo. (int? type)
 final int? shirtNumber;
 /// courtupperposition (String? type, GK/DF/MF/FW wait, starter/substitutedisplayusage)
 final String? position;
 /// injuryreason (String? type, alignment HankLineupInjuryPlayer.reason, e.g.: "tentext")
 final String? reason;
 /// playermin (String? type, trueactuallatersidequotaouterfield, e.g.: "7.8")
 final String? rating;
 /// playeravatar URL (String? type, alignment hanklive playerLogo)
 final String? playerLogo;
 /// ballcourttag X (0~100 double? type, alignment hanklive x)
 final double? x;
 /// ballcourttag Y (0~100 double? type, alignment hanklive y)
 final double? y;
 /// eventtaglist (List<BMLineupIncident> type, alignment hanklive incidents)
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
 // injuryreason: alignment HankLineupInjuryPlayer.reason (seelatersidename 6 kindcompatible)
 reason: (json['reason']
          ?? json['injure_reason']
          ?? json['injure_desc']
          ?? json['injury_reason']
          ?? json['description']
          ?? json['remark'])?.toString(),
 // playermin (trueactuallatersidefield, laterexpandeddisplay)
 rating: (json['rating'] ?? json['score'] ?? json['mark'])?.toString(),
      playerLogo: (json['player_logo'] ?? json['playerLogo'] ?? json['avatar'] ?? json['photo'])?.toString(),
      x: (xv is num) ? xv.toDouble() : double.tryParse(xv?.toString() ?? ''),
      y: (yv is num) ? yv.toDouble() : double.tryParse(yv?.toString() ?? ''),
 incidents: incList,
);
 }
}

/// BMMatchLineupSide - home/awaylineuponeside (keep Hank formatcompatible: home/away → {formation, coach, starters, subs, injureds})
/// alignment hanklive HankLineupSide (formation/coach/starters/substitutes/injureds)
class BMMatchLineupSide {
 /// formation (String? type, example '4-3-3')
 final String? formation;
 /// coachname/coachobject (BMLineupCoach? type)
 final BMLineupCoach? coach;
 /// starter11people (List<BMMatchLineupPlayer> type)
 final List<BMMatchLineupPlayer> starters;
 /// substitute (List<BMMatchLineupPlayer> type)
 final List<BMMatchLineupPlayer> substitutes;
 /// injurymissing (List<BMMatchLineupPlayer> type)
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

/// BMLineupData - starterlineup
/// API：GET /api/livespeed/football/match/lineup
///
/// support 2 kindlatersidereturnsformat：
///
/// 【format A：trueactual BallMatrix laterside（userto，Dstructure）】priorityparse：
/// {
/// "first":  { "home": [...], "away": [...] },   ← starter
///   "sub":    { "home": [...], "away": [...] },   ← substitute
///   "injury": { "home": [...], "away": [...] }, ← injury
/// "home_coach": { "id": 0, "logo": "", "name": "" },
///   "away_coach": { "id": 0, "logo": "", "name": "" },
///   "home_formation": "4-3-3",
///   "away_formation": "4-2-3-1",
///   "home_market_value": 1000000,
///   "away_market_value": 800000,
/// }
///
/// 【format B：HankLive compatible（home/awaystructure）】fallback parse：
/// {
/// "home": { "formation": "", "coach": {}, "starters": [], "substitutes": [], "injureds": [] },
///   "away": {... }
/// }
///
/// fast getter（unified UI makeusage)：homeFormation / awayFormation / homeFirst / awayFirst / homeSub / awaySub / homeInjury / awayInjury
class BMLineupData {
 /// home teamlineupside (BMMatchLineupSide type, keep Hank structurecompatible)
 final BMMatchLineupSide home;
 /// away teamlineupside (BMMatchLineupSide type, keep Hank structurecompatible)
 final BMMatchLineupSide away;

 // trueactuallaterside (BallMatrix) Dfield (prioritymakeusage)
 /// home teamcoach (BMLineupCoach? type, trueactuallaterside home_coach)
 final BMLineupCoach? homeCoach;
 /// away teamcoach (BMLineupCoach? type, trueactuallaterside away_coach)
 final BMLineupCoach? awayCoach;
 /// home teamtotal market value (int? type, trueactuallaterside home_market_value)
 final int? homeMarketValue;
 /// away teamtotal market value (int? type, trueactuallaterside away_market_value)
 final int? awayMarketValue;

 BMLineupData({
 required this.home,
 required this.away,
 this.homeCoach,
 this.awayCoach,
 this.homeMarketValue,
 this.awayMarketValue,
 });

 // ================ unified UI fast getter（and Hank 1:1 corresponding） ================
 /// home teamformation (alignment data.homeFormation, priority: trueactualDfield, fallback: structure)
 String? get homeFormation => home.formation;
 /// away teamformation (alignment data.awayFormation)
 String? get awayFormation => away.formation;
 /// home teamstarter11people (alignment data.homeFirst)
 List<BMMatchLineupPlayer> get homeFirst => home.starters;
 /// away teamstarter11people (alignment data.awayFirst)
 List<BMMatchLineupPlayer> get awayFirst => away.starters;
 /// home teamsubstitute (alignment data.homeSub)
 List<BMMatchLineupPlayer> get homeSub => home.substitutes;
 /// away teamsubstitute (alignment data.awaySub)
 List<BMMatchLineupPlayer> get awaySub => away.substitutes;
 /// home teaminjury (alignment data.homeInjury)
 List<BMMatchLineupPlayer> get homeInjury => home.injureds;
 /// away teaminjury (alignment data.awayInjury)
 List<BMMatchLineupPlayer> get awayInjury => away.injureds;

 factory BMLineupData.fromJson(Map<String, dynamic> json) {
 // ========== ========== ========== ========== ==========
 // 【Step 1】parseDplayerlist（compatibletrueactuallaterside A format / Hank old B format）
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

 // take home/away lowerplayerlist (Map<String, List>)
 List<BMMatchLineupPlayer> homeFromSection(dynamic section) =>
 (section is Map<String, dynamic>) ? parsePlayerList(section['home']) : const [];
    List<BMMatchLineupPlayer> awayFromSection(dynamic section) =>
        (section is Map<String, dynamic>) ? parsePlayerList(section['away']): const [];

 // ---------- trueactuallaterside A：first / sub / injury 3 section Map + home/away ----------
 final firstHome = homeFromSection(json['first']);
    final firstAway = awayFromSection(json['first']);
    final subHome = homeFromSection(json['sub']);
    final subAway = awayFromSection(json['sub']);
    final injHome = homeFromSection(json['injury']);
    final injAway = awayFromSection(json['injury']);

 // ---------- compatibleold Hank B：home / away object (starters / substitutes / injureds) ----------
 final hNested = json['home'] ?? json['home_team'];
    final aNested = json['away'] ?? json['away_team'];
 final homeSide = (hNested is Map<String, dynamic>)
 ? BMMatchLineupSide.fromJson(hNested)
: BMMatchLineupSide();
 final awaySide = (aNested is Map<String, dynamic>)
 ? BMMatchLineupSide.fromJson(aNested)
: BMMatchLineupSide();

 // merge：priorityusetrueactuallatersideD (first/sub/injury home/away)，asemptyagain fallback Hank old
 final finalHomeFirst = firstHome.isNotEmpty ? firstHome: homeSide.starters;
 final finalAwayFirst = firstAway.isNotEmpty ? firstAway: awaySide.starters;
 final finalHomeSub = subHome.isNotEmpty ? subHome: homeSide.substitutes;
 final finalAwaySub = subAway.isNotEmpty ? subAway: awaySide.substitutes;
 final finalHomeInj = injHome.isNotEmpty ? injHome: homeSide.injureds;
 final finalAwayInj = injAway.isNotEmpty ? injAway: awaySide.injureds;

 // ========== ========== ========== ========== ==========
 // 【Step 2】formationname / coach / market value
 // ========== ========== ========== ========== ==========
 // formationname：priority home_formation / away_formation (trueactuallaterside A)，fallback homeSide.formation (Hank B)
 final hFormation =
 (json['home_formation'] ?? json['homeFormation'] ?? homeSide.formation)
            ?.toString();
    final aFormation =
        (json['away_formation'] ?? json['awayFormation'] ?? awaySide.formation)
 ?.toString();
 // coach：priority home_coach / away_coach Map → BMLineupCoach，fallback homeSide.coach
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
 // market value：home_market_value / away_market_value (int / double / String compatible)
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
 // 【Step 3】group BMMatchLineupSide（unifiedstructureto UI usage)
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
