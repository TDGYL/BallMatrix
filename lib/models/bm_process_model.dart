/// eventtypeenum
enum BMIncidentType {
 /// goal
 goal,
 /// penalty
 penalty,
 /// ball
 ownGoal,
 /// yellow card
 yellowCard,
 /// red card
 redCard,
 /// two yellows to red
 secondYellow,
 /// substitution
 substitution,
 /// injury patch when
 injuryTime,
 /// incourt/finalcourt
 whistle,
 /// others
 other,
}

/// eventsendsideenum
enum BMIncidentSide { home, away, neutral }

/// BMIncident - singlematchevent（Live Tab usage)
class BMIncident {
 /// minutecount (int? type, canabilityyes null meansopenmatchfirst)
 final int? minute;
 /// injury patch whenminutecount (int? type)
 final int? addedTime;
 /// eventtype (BMIncidentType enum)
 final BMIncidentType type;
 /// sendside (BMIncidentSide)
 final BMIncidentSide side;
 /// homeplayername (String? type)
 final String? playerName;
 /// playerID (int? type)
 final int? playerId;
 /// assist/swapupper copyplayername (String? type)
 final String? subPlayerName;
 /// eventquotaouterdescription (String? type, e.g.: 'penalty', 'VARTake effect')
 final String? detail;
 /// eventsendwhenhome teamlive score (int? type, getmineventhas, alignmenthanklive homeScore)
 final int? homeScore;
 /// eventsendwhenaway teamlive score (int? type, getmineventhas)
 final int? awayScore;

 BMIncident({
 this.minute,
 this.addedTime,
 required this.type,
 required this.side,
 this.playerName,
 this.playerId,
 this.subPlayerName,
 this.detail,
 this.homeScore,
 this.awayScore,
 });

 factory BMIncident.fromJson(Map<String, dynamic> json) {
 final t = json['type'] ?? json['incident_type'] ?? '';
    BMIncidentType type;
    switch (t.toString().toLowerCase()) {
      case 'goal':
      case '1':
        type = BMIncidentType.goal;
        break;
      case 'penalty':
      case 'goal_penalty':
        type = BMIncidentType.penalty;
        break;
      case 'own_goal':
      case 'owngoal':
        type = BMIncidentType.ownGoal;
        break;
      case 'yellow':
      case 'yellow_card':
      case '2':
        type = BMIncidentType.yellowCard;
        break;
      case 'red':
      case 'red_card':
      case '3':
        type = BMIncidentType.redCard;
        break;
      case 'second_yellow':
      case 'yellow_red':
        type = BMIncidentType.secondYellow;
        break;
      case 'sub':
      case 'substitution':
      case '4':
        type = BMIncidentType.substitution;
        break;
      case 'injury_time':
      case 'added_time':
        type = BMIncidentType.injuryTime;
        break;
      case 'whistle':
      case 'halftime':
      case 'fulltime':
        type = BMIncidentType.whistle;
        break;
      default:
        type = BMIncidentType.other;
    }
    final s = json['side'] ?? json['home_away'] ?? '';
    BMIncidentSide side;
    switch (s.toString().toLowerCase()) {
      case 'home':
      case '1':
      case 'h':
        side = BMIncidentSide.home;
        break;
      case 'away':
      case '2':
      case 'a':
        side = BMIncidentSide.away;
        break;
      default:
        side = BMIncidentSide.neutral;
    }
    final minute = json['minute'];
    final added = json['added_time'] ?? json['extra_time'];
    final hs = json['home_score'] ?? json['homeScore'] ?? json['score_home'];
    final aws = json['away_score'] ?? json['awayScore'] ?? json['score_away'];
    return BMIncident(
      minute: minute is num ? minute.toInt() : int.tryParse(minute?.toString() ?? ''),
      addedTime: added is num ? added.toInt() : int.tryParse(added?.toString() ?? ''),
      type: type,
      side: side,
      playerName: json['player'] ?? json['player_name'],
      playerId: (json['player_id'] is num) ? (json['player_id'] as num).toInt() : null,
      subPlayerName: json['assist'] ?? json['assist_name'] ?? json['sub_in'] ?? json['player_on'],
      detail: json['detail'] ?? json['comment'] ?? json['description'],
      homeScore: hs is num ? hs.toInt() : int.tryParse(hs?.toString() ?? ''),
      awayScore: aws is num ? aws.toInt() : int.tryParse(aws?.toString() ?? ''),
);
 }
}

/// BMStatRow - singletechnical statsitem（Stats Tab usage)
class BMStatRow {
 /// home teamvalue (String type, e.g.: '62%')
 final String homeValue;
 /// statisticsitemnametext (String type, e.g.: 'ballrate')
 final String label;
 /// away teamvalue (String type, e.g.: '38%')
  final String awayValue;

  BMStatRow({
    required this.homeValue,
    required this.label,
    required this.awayValue,
  });

  factory BMStatRow.fromJson(Map<String, dynamic> json) {
    return BMStatRow(
      homeValue: json['home']?.toString() ?? json['home_value']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? '',
      awayValue: json['away']?.toString() ?? json['away_value']?.toString() ?? '',
);
 }
}

/// BMProcessData - match（event + technical stats）
/// API：GET /api/livespeed/football/match/process
class BMProcessData {
 /// eventlist (List<BMIncident> type, bytimeindex)
 final List<BMIncident> incidents;
 /// technical stats (List<BMStatRow> type, ballrate//centeretc)
 final List<BMStatRow> stats;

 BMProcessData({
 this.incidents = const [],
 this.stats = const [],
 });

 factory BMProcessData.fromJson(Map<String, dynamic> json) {
 List<BMIncident> inc = [];
 try {
 final rawi = json['incidents'] ?? json['events'] ?? json['timeline'] ?? [];
      if (rawi is List) {
        inc = rawi
            .whereType<Map<String, dynamic>>()
            .map((e) => BMIncident.fromJson(e))
            .toList();
      }
    } catch (_) {
      inc = [];
    }
    List<BMStatRow> stats = [];
    try {
      final raws = json['stats'] ?? json['statistics'] ?? [];
      if (raws is List) {
        stats = raws
            .whereType<Map<String, dynamic>>()
            .map((e) => BMStatRow.fromJson(e))
            .toList();
      }
    } catch (_) {
      stats = [];
    }
    return BMProcessData(incidents: inc, stats: stats);
  }
}
