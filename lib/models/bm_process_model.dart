/// 事件类型枚举
enum BMIncidentType {
  /// 进球
  goal,
  /// 点球
  penalty,
  /// 乌龙球
  ownGoal,
  /// 黄牌
  yellowCard,
  /// 红牌
  redCard,
  /// 两黄变红
  secondYellow,
  /// 换人
  substitution,
  /// 伤停补时
  injuryTime,
  /// 中场/终场
  whistle,
  /// 其他
  other,
}

/// 事件发生侧枚举
enum BMIncidentSide { home, away, neutral }

/// BMIncident - 单条比赛事件（Live Tab 用）
class BMIncident {
  /// 分钟数 (int? 类型, 可能是 null 表示开赛前)
  final int? minute;
  /// 伤停补时分钟数 (int? 类型)
  final int? addedTime;
  /// 事件类型 (BMIncidentType 枚举)
  final BMIncidentType type;
  /// 发生侧 (BMIncidentSide)
  final BMIncidentSide side;
  /// 主球员名 (String? 类型)
  final String? playerName;
  /// 球员ID (int? 类型)
  final int? playerId;
  /// 助攻/替换上 副球员名 (String? 类型)
  final String? subPlayerName;
  /// 事件额外描述 (String? 类型, 例: '点球', 'VAR取消')
  final String? detail;
  /// 事件发生时主队实时比分 (int? 类型, 得分事件才有, 对齐hanklive homeScore)
  final int? homeScore;
  /// 事件发生时客队实时比分 (int? 类型, 得分事件才有)
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

/// BMStatRow - 单条技术统计项（Stats Tab 用）
class BMStatRow {
  /// 主队数值 (String 类型, 例: '62%')
  final String homeValue;
  /// 统计项名字 (String 类型, 例: '控球率')
  final String label;
  /// 客队数值 (String 类型, 例: '38%')
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

/// BMProcessData - 比赛进程（事件 + 技术统计）
/// API：GET /api/livespeed/football/match/process
class BMProcessData {
  /// 事件列表 (List<BMIncident> 类型, 按时间升序)
  final List<BMIncident> incidents;
  /// 技术统计 (List<BMStatRow> 类型, 控球率/射门/射正等)
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
