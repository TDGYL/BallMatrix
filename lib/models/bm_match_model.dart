import 'bm_match_api_model.dart' show safeString;

/// BMTeamModel - 球队数据模型
/// 作用范围: 比赛数据中的主客队信息
class BMTeamModel {
  /// 球队唯一标识 (String 类型)
  final String teamId;

  /// 球队全名 (String 类型)
  final String teamName;

  /// 球队缩写 (String 类型, 通常3位大写)
  final String teamShort;

  /// 球队Logo URL (String? 类型, 可空)
  final String? logoUrl;

  BMTeamModel({
    required String? teamId,
    required String? teamName,
    String? teamShort,
    this.logoUrl,
  })  : teamId = teamId ?? '',
        teamName = teamName ?? '',
        teamShort = teamShort ?? _extractShort(teamName);

  /// 从Map映射构建模型 (全安全, 不抛错)
  factory BMTeamModel.fromMap(Map<String, dynamic> map) {
    return BMTeamModel(
      teamId: safeString(map['teamId']) ?? safeString(map['team_id']) ?? '',
      teamName: safeString(map['teamName']) ?? safeString(map['team_name']) ?? '',
      teamShort: safeString(map['teamShort']) ?? safeString(map['team_short']),
      logoUrl: safeString(map['logoUrl']) ?? safeString(map['logo_url']),
    );
  }

  /// 默认缩写提取: 取前3位大写 (3位以内直接大写)
  static String _extractShort(String? name) {
    if (name == null || name.isEmpty) return '';
    if (name.length <= 3) return name.toUpperCase();
    return name.substring(0, 3).toUpperCase();
  }
}

/// BMMatchStatus - 比赛状态枚举
enum BMMatchStatus {
  /// 进行中
  live,

  /// 即将开赛 (未开始)
  upcoming,

  /// 已完场
  ended,

  /// TBD 待定/其他状态
  tbd,
}

/// BMMatchSportType - 运动类型枚举
enum BMMatchSportType {
  /// 足球
  football,

  /// 篮球
  basketball,
}

/// BMMatchModel - 比赛数据模型
/// 作用范围: 首页焦点赛事卡片、赛事列表页、比赛详情页
/// 包含比赛的基本信息: 队伍名称、比分、联赛、状态等
class BMMatchModel {
  /// 比赛唯一标识 (String 类型, 范围: 全局唯一)
  final String matchId;

  /// 主队名称 (String 类型)
  final String homeTeamName;

  /// 客队名称 (String 类型)
  final String awayTeamName;

  /// 主队图标URL (String? 类型, 可空)
  final String? homeTeamLogo;

  /// 客队图标URL (String? 类型, 可空)
  final String? awayTeamLogo;

  /// 主队结构化信息 (BMTeamModel? 类型)
  final BMTeamModel? homeTeam;

  /// 客队结构化信息 (BMTeamModel? 类型)
  final BMTeamModel? awayTeam;

  /// 主队比分 (int? 类型, 未开赛时为null, 不默认0避免假比分展示)
  final int? homeScore;

  /// 客队比分 (int? 类型, 未开赛时为null)
  final int? awayScore;

  /// 联赛名称 (String 类型)
  final String leagueName;

  /// 联赛主题色 (int 类型, ARGB格式, 默认橙色)
  final int leagueColor;

  /// 联赛名称别名 (String? getter 类型, 兼容旧代码 competitionName 字段, 与 leagueName 等价, 非空时返回 leagueName)
  String? get competitionName =>
      leagueName.isNotEmpty ? leagueName : null;

  /// 比赛标签/阶段名 (String? 类型, 如 "半决赛")
  final String? matchTag;

  /// 比赛轮次或描述 (String 类型, 非空默认取matchTag)
  final String round;

  /// 比赛状态 (BMMatchStatus 枚举)
  final BMMatchStatus status;

  /// 状态ID (int? 类型, 原始API返回值, 优先用来判断状态)
  /// 足球: 1未开始 2|3|4|5|7进行中 8已结束 0|9|10|11|12|13 TBD
  /// 篮球: 1|13未开始 2|3|4|5|6|7|8|9进行中 10|11已结束 0|12|14|15 TBD
  final int? statusId;

  /// 状态名称 (String? 类型, API返回的原始状态中文名)
  final String? statusName;

  /// 运动类型 (BMMatchSportType 枚举, 默认足球)
  final BMMatchSportType sportType;

  /// 比赛时间/分钟 (String 类型, 如 "68'" 或 "03:00")
  final String matchTime;

  /// 进行中分钟数 (String? 类型, 如 "68'", 与 matchTime 兼容)
  final String? liveMinute;

  /// 半场比分 (String? 类型, 如 "1-0")
  final String? halfTimeScore;

  /// 进球事件列表 (List<String> 类型, 预留)
  final List<String> goalEvents;

  /// AI胜率推算 (double 类型, 0-100)
  final double aiWinRate;

  /// 主队胜率 (double 类型, 0-100)
  final double homeWinRate;

  /// 平局概率 (double 类型, 0-100)
  final double drawRate;

  /// 客队胜率 (double 类型, 0-100)
  final double awayWinRate;

  /// 主队xG期望进球 (double 类型)
  final double homeXG;

  /// 客队xG期望进球 (double 类型)
  final double awayXG;

  /// 实时压制力百分比 (double 类型, 主队压制力)
  final double momentumPercent;

  /// 模型匹配度 (double? 类型, 0-100)
  final double? modelMatchRate;

  /// 预测结果描述 (String? 类型)
  final String? prediction;

  /// AI洞察文字 (String? 类型)
  final String? aiInsight;

  /// 是否焦点对决 (bool 类型)
  final bool isFeatured;

  /// 是否关注/订阅 (bool 类型)
  final bool isFollowed;

  BMMatchModel({
    required this.matchId,
    String? homeTeamName,
    String? awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.homeTeam,
    this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.leagueName,
    this.leagueColor = 0xFFF97316,
    this.matchTag,
    String? round,
    required this.status,
    this.statusId,
    this.statusName,
    this.sportType = BMMatchSportType.football,
    required this.matchTime,
    this.liveMinute,
    this.halfTimeScore,
    this.goalEvents = const [],
    double? aiWinRate,
    double? homeWinRate,
    double? drawRate,
    double? awayWinRate,
    this.homeXG = 0,
    this.awayXG = 0,
    this.momentumPercent = 0,
    this.modelMatchRate,
    this.prediction,
    this.aiInsight,
    this.isFeatured = false,
    this.isFollowed = false,
  })  : homeTeamName = homeTeamName ?? homeTeam?.teamName ?? '',
        awayTeamName = awayTeamName ?? awayTeam?.teamName ?? '',
        round = round ?? matchTag ?? '',
        homeWinRate = homeWinRate ?? 0,
        drawRate = drawRate ?? 0,
        awayWinRate = awayWinRate ?? 0,
        aiWinRate = aiWinRate ?? (homeWinRate ?? 0);

  /// 从Map映射构建模型 (模拟MJExtension映射, 全安全提取不抛错)
  factory BMMatchModel.fromMap(Map<String, dynamic> map) {
    BMMatchStatus parseStatus(dynamic v) {
      if (v is int) {
        if (v >= 0 && v < BMMatchStatus.values.length) {
          return BMMatchStatus.values[v];
        }
      }
      if (v is String) {
        for (final s in BMMatchStatus.values) {
          if (s.name == v) return s;
        }
      }
      return BMMatchStatus.tbd;
    }

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    BMTeamModel? readTeam(dynamic v) {
      if (v is Map<String, dynamic>) return BMTeamModel.fromMap(v);
      return null;
    }

    List<String> readGoalEvents(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    return BMMatchModel(
      matchId: safeString(map['matchId']) ?? safeString(map['match_id']) ?? '',
      homeTeamName: safeString(map['homeTeamName']) ?? safeString(map['home_team_name']),
      awayTeamName: safeString(map['awayTeamName']) ?? safeString(map['away_team_name']),
      homeTeamLogo: safeString(map['homeTeamLogo']) ?? safeString(map['home_team_logo']),
      awayTeamLogo: safeString(map['awayTeamLogo']) ?? safeString(map['away_team_logo']),
      homeTeam: readTeam(map['homeTeam']) ?? readTeam(map['home_team']),
      awayTeam: readTeam(map['awayTeam']) ?? readTeam(map['away_team']),
      homeScore: (map['homeScore'] is num) ? (map['homeScore'] as num).toInt() : int.tryParse(safeString(map['homeScore']) ?? ''),
      awayScore: (map['awayScore'] is num) ? (map['awayScore'] as num).toInt() : int.tryParse(safeString(map['awayScore']) ?? ''),
      leagueName: safeString(map['leagueName']) ?? safeString(map['league_name']) ?? '',
      leagueColor: (map['leagueColor'] is num)
          ? (map['leagueColor'] as num).toInt()
          : (int.tryParse(safeString(map['leagueColor']) ?? '') ?? 0xFFF97316),
      matchTag: safeString(map['matchTag']) ?? safeString(map['match_tag']),
      round: safeString(map['round']) ?? safeString(map['round_name']),
      status: parseStatus(map['status']),
      statusId: (map['statusId'] is num) ? (map['statusId'] as num).toInt() : int.tryParse(safeString(map['statusId']) ?? ''),
      statusName: safeString(map['statusName']) ?? safeString(map['status_name']),
      sportType: safeString(map['sportType']) == 'basketball'
          ? BMMatchSportType.basketball
          : BMMatchSportType.football,
      matchTime: safeString(map['matchTime']) ?? safeString(map['match_time']) ?? '',
      liveMinute: safeString(map['liveMinute']) ?? safeString(map['live_minute']),
      halfTimeScore: safeString(map['halfTimeScore']) ?? safeString(map['half_time_score']),
      goalEvents: readGoalEvents(map['goalEvents']),
      aiWinRate: toDouble(map['aiWinRate']),
      homeWinRate: toDouble(map['homeWinRate']),
      drawRate: toDouble(map['drawRate']),
      awayWinRate: toDouble(map['awayWinRate']),
      homeXG: toDouble(map['homeXG']) ?? 0,
      awayXG: toDouble(map['awayXG']) ?? 0,
      momentumPercent: toDouble(map['momentumPercent']) ?? 0,
      modelMatchRate: toDouble(map['modelMatchRate']),
      prediction: safeString(map['prediction']),
      aiInsight: safeString(map['aiInsight']),
      isFeatured: map['isFeatured'] == true || map['isFeatured'] == 1 || safeString(map['isFeatured']) == 'true',
    );
  }
}

/// BMMatchModel 扩展：显示相关 getter
///   - displayStatusLabel: 显示状态字符串 (LIVE/FT/未开始/待定)
///   - kickoffText: 开赛时间字符串 (matchTime/liveMinute 任一个有值就展示, 用于判空非空串)
///   - displayMatchTime: 格式化开赛/轮次或时间 合并显示
extension BMMatchModelDisplayX on BMMatchModel {
  /// 显示状态字符串 (String 类型, 用于 scoreboard LIVE 胶囊)
  ///   live: "LIVE 75'"
  ///   ended: "完场"
  ///   upcoming: "未开始"
  ///   tbd: "待定"
  String get displayStatusLabel {
    switch (status) {
      case BMMatchStatus.live:
        final min = (liveMinute != null && liveMinute!.isNotEmpty)
            ? liveMinute!.replaceAll("'", '')
            : null;
        if (min != null && min.isNotEmpty) return 'LIVE $min\'';
        return 'LIVE';
      case BMMatchStatus.ended:
        return '完场';
      case BMMatchStatus.upcoming:
        return '未开始';
      case BMMatchStatus.tbd:
        return '待定';
    }
  }

  /// 开赛时间非空串 (String 类型, 用于判断 "开赛时间/轮次至少一个有值吗")
  ///   liveMinute 非空优先, 否则 matchTime, 否则 round
  String get kickoffText =>
      (liveMinute != null && liveMinute!.isNotEmpty)
          ? liveMinute!
          : (matchTime.isNotEmpty ? matchTime : round);

  /// 显示合并信息: matchTime + round 组合
  ///   例: '2026/10/01 03:00 · 第 5 轮'
  String get displayMatchTime {
    final List<String> parts = [];
    if (matchTime.isNotEmpty) parts.add(matchTime);
    if (round.isNotEmpty) parts.add(round);
    return parts.join(' · ');
  }
}

