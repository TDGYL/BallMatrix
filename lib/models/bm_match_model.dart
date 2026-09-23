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
  }) : teamId = teamId ?? '',
       teamName = teamName ?? '',
       teamShort = teamShort ?? _extractShort(teamName);

  /// 从Map映射构建模型 (全安全, 不抛错)
  factory BMTeamModel.fromMap(Map<String, dynamic> map) {
    return BMTeamModel(
      teamId: safeString(map['teamId']) ?? safeString(map['team_id']) ?? '',
      teamName:
          safeString(map['teamName']) ?? safeString(map['team_name']) ?? '',
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

/// BMMatchModel - 比赛数据模型（100% 对齐 hanklive HankMatchItem 属性）
/// 作用范围: 首页焦点赛事卡片、赛事列表页、比赛详情页、H2H 跳转 MatchModel
/// 包含: Hank 全部 42 字段 + BallMatrix 扩展字段(胜率/xG/momentum等)
class BMMatchModel {
  // ================ ↓↓↓ 对齐 HankMatchItem 第 1~42 个字段 ↓↓↓ ================

  /// 1. matchId: 比赛唯一标识 (兼容双类型)
  ///   - hanklive: int match_id
  ///   - ballmatrix: 对外保持 String matchId (不破坏现有逻辑)
  final String matchId;

  /// 2. seasonId: 赛季ID (int? 类型)
  final int? seasonId;

  /// 3. competitionId: 联赛ID (int? 类型)
  final int? competitionId;

  /// 4. competitionLogo: 联赛Logo URL (String? 类型, 对应 Hank competition_logo)
  final String? competitionLogo;

  /// 5. competitionName: 联赛名称 (String? getter 类型, 与 leagueName 等价)
  ///   直接复用下面 leagueName，兼容双命名（Hank competitionName / BM leagueName）

  /// 6. competitionPrimaryColor: 联赛主题色 (String? 类型, hex 字符串)
  final String? competitionPrimaryColor;

  /// 7. competitionSecondaryColor: 联赛辅色 (String? 类型, hex 字符串)
  final String? competitionSecondaryColor;

  /// 8. homeTeamId: 主队ID (int? 类型, 顶层直接访问 对齐 Hank home_team_id)
  final int? homeTeamId;

  /// 9. homeTeamName: 主队名称 (String 类型)
  final String homeTeamName;

  /// 10. homeTeamLogo: 主队图标URL (String? 类型, 可空)
  final String? homeTeamLogo;

  /// 11. awayTeamId: 客队ID (int? 类型, 顶层直接访问 对齐 Hank away_team_id)
  final int? awayTeamId;

  /// 12. awayTeamName: 客队名称 (String 类型)
  final String awayTeamName;

  /// 13. awayTeamLogo: 客队图标URL (String? 类型, 可空)
  final String? awayTeamLogo;

  /// 14. statusId: 状态ID (int? 类型, 原始API返回值, 优先判断状态)
  /// 足球: 1未开始 2|3|4|5|7进行中 8已结束 0|9|10|11|12|13 TBD
  final int? statusId;

  /// 15. statusName: 状态名称 (String? 类型, API返回原始中文名)
  final String? statusName;

  /// 16. matchTime(原始int秒时间戳) → matchTimestamp: 开赛时间戳(秒)
  ///   - 对应 Hank: int match_time 秒级时间戳
  ///   - BM 原有 String matchTime 用于UI显示，此字段存原始时间戳
  final int? matchTimestamp;

  /// 17. neutral: 是否中立场 (int? 类型, 0/1)
  final int? neutral;

  /// 18. homeNormalScore: 主队90分钟常规比分 (int? 类型, WDL统计核心字段)
  final int? homeNormalScore;

  /// 19. homeHalfScore: 主队半场比分 (int? 类型)
  final int? homeHalfScore;

  /// 20. homeRed: 主队红牌数 (int? 类型)
  final int? homeRed;

  /// 21. homeYellow: 主队黄牌数 (int? 类型)
  final int? homeYellow;

  /// 22. homeCorn: 主队角球数 (int? 类型)
  final int? homeCorn;

  /// 23. homeAddScore: 主队加时赛比分 (int? 类型)
  final int? homeAddScore;

  /// 24. homePointScore: 主队点球大战比分 (int? 类型)
  final int? homePointScore;

  /// 25. awayNormalScore: 客队90分钟常规比分 (int? 类型)
  final int? awayNormalScore;

  /// 26. awayHalfScore: 客队半场比分 (int? 类型)
  final int? awayHalfScore;

  /// 27. awayRed: 客队红牌数 (int? 类型)
  final int? awayRed;

  /// 28. awayYellow: 客队黄牌数 (int? 类型)
  final int? awayYellow;

  /// 29. awayCorn: 客队角球数 (int? 类型)
  final int? awayCorn;

  /// 30. awayAddScore: 客队加时赛比分 (int? 类型)
  final int? awayAddScore;

  /// 31. awayPointScore: 客队点球大战比分 (int? 类型)
  final int? awayPointScore;

  /// 32. lineup: 是否有阵容数据 (int? 类型, 0=无 1=有)
  final int? lineup;

  /// 33. stageId: 阶段ID (int? 类型)
  final int? stageId;

  /// 34. subscribed: 是否关注/订阅 (bool? 类型, 与 BM isFollowed 双向映射)
  final bool? subscribed;

  /// 35. homePosition: 主队联赛排名 (String? 类型, 例 "5")
  final String? homePosition;

  /// 36. awayPosition: 客队联赛排名 (String? 类型)
  final String? awayPosition;

  /// 37. hasOt: 是否有加时赛 (bool? 类型)
  final bool? hasOt;

  /// 38. hasPenalty: 是否有点球大战 (bool? 类型)
  final bool? hasPenalty;

  /// 39. win: 胜负结果 (int? 类型, 1=主胜 2=平 3=客胜)
  final int? win;

  /// 40. note: 备注 (String? 类型, 例 "含加时" "点球决胜" 等)
  final String? note;

  /// 41. minutes: 进行中分钟 (String? 类型, 例 "78'"，与 BM liveMinute 双向映射)
  final String? minutes;

  /// 42. mlive: 是否有动画直播 (int? 类型)
  final int? mlive;

  /// 43. mliveUrl: 动画直播URL (String? 类型)
  final String? mliveUrl;

  /// 44. liveVideo: 是否有视频直播 (int? 类型)
  final int? liveVideo;

  /// 45. hasArticle: 是否有关联赛事文章 (int? 类型)
  final int? hasArticle;

  /// 46. stageName: 阶段名称 (String? 类型, 例 "1/4决赛" "半决赛")
  final String? stageName;

  /// 47. groupNum: 分组号 (String? 类型, 例 "A")
  final String? groupNum;

  /// 48. roundNum: 轮次 (int? 类型)
  final int? roundNum;

  /// 49. schemeCount: 方案数量 (int? 类型)
  final int? schemeCount;

  /// 50. countdown: 开赛倒计时秒数 (int? 类型)
  final int? countdown;

  /// 51. isWorldCup: 是否世界杯赛事 (int? 类型)
  final int? isWorldCup;

  /// 52. categoryId: 运动类型ID (int? 类型, 1=足球, 对应 Hank category)
  final int? categoryId;

  // ================ ↑↑↑ 对齐 HankMatchItem 全部字段 ↑↑↑ ================

  // ================ ↓↓↓ BallMatrix 扩展/保留字段 ↓↓↓ ================

  /// 主队结构化信息 (BMTeamModel? 类型, BallMatrix 保留)
  final BMTeamModel? homeTeam;

  /// 客队结构化信息 (BMTeamModel? 类型, BallMatrix 保留)
  final BMTeamModel? awayTeam;

  /// 主队比分 (int? 类型, BallMatrix 保留总比分 = normal+add+point 兜底)
  final int? homeScore;

  /// 客队比分 (int? 类型, BallMatrix 保留)
  final int? awayScore;

  /// 联赛名称 (String 类型, BM 命名, 与 Hank competitionName 等价 1:1 映射)
  final String leagueName;

  /// 联赛主题色 (int 类型, ARGB格式, BM 保留, 默认橙色 F97316)
  final int leagueColor;

  /// 联赛名称别名 (String? getter 类型, 兼容旧代码 competitionName 字段)
  String? get competitionName => leagueName.isNotEmpty ? leagueName : null;

  /// 比赛标签/阶段名 (String? 类型, 如 "半决赛", BM 保留 与 stageName 双向映射)
  final String? matchTag;

  /// 比赛轮次或描述 (String 类型, BM 保留 与 roundNum/groupNum 双向映射)
  final String round;

  /// 比赛状态 (BMMatchStatus 枚举, BM 保留 与 statusId 双向映射)
  final BMMatchStatus status;

  /// 运动类型 (BMMatchSportType 枚举, BM 保留 与 categoryId 双向映射)
  final BMMatchSportType sportType;

  /// 比赛时间/分钟 (String 类型, BM 保留UI显示字段 与 matchTimestamp 双向映射)
  final String matchTime;

  /// 进行中分钟数 (String? 类型, BM 保留 与 Hank minutes 完全等价)
  final String? liveMinute;

  /// 半场比分 (String? 类型, BM 保留拼接 "1-0" 与 homeHalfScore/awayHalfScore 双向映射)
  final String? halfTimeScore;

  /// 进球事件列表 (List<String> 类型, BM 保留预留)
  final List<String> goalEvents;

  /// AI胜率推算 (double 类型, BM 保留 0-100)
  final double aiWinRate;

  /// 主队胜率 (double 类型, BM 保留 0-100)
  final double homeWinRate;

  /// 平局概率 (double 类型, BM 保留 0-100)
  final double drawRate;

  /// 客队胜率 (double 类型, BM 保留 0-100)
  final double awayWinRate;

  /// 主队xG期望进球 (double 类型, BM 保留)
  final double homeXG;

  /// 客队xG期望进球 (double 类型, BM 保留)
  final double awayXG;

  /// 实时压制力百分比 (double 类型, BM 保留 主队压制力)
  final double momentumPercent;

  /// 模型匹配度 (double? 类型, BM 保留 0-100)
  final double? modelMatchRate;

  /// 预测结果描述 (String? 类型, BM 保留)
  final String? prediction;

  /// AI洞察文字 (String? 类型, BM 保留)
  final String? aiInsight;

  /// 是否焦点对决 (bool 类型, BM 保留)
  final bool isFeatured;

  /// 是否关注/订阅 (bool 类型, BM 保留 与 Hank subscribed 双向映射)
  final bool isFollowed;

  // ================ 构造函数: 兼容 Hank 全部字段 + BM 扩展 ================
  BMMatchModel({
    // ---- Hank 核心 52 字段 (全部可选 或从 BM 字段推导) ----
    String? matchId,
    this.seasonId,
    this.competitionId,
    this.competitionLogo,
    this.competitionPrimaryColor,
    this.competitionSecondaryColor,
    this.homeTeamId,
    String? homeTeamName,
    this.homeTeamLogo,
    this.awayTeamId,
    String? awayTeamName,
    this.awayTeamLogo,
    this.statusId,
    this.statusName,
    this.matchTimestamp,
    this.neutral,
    this.homeNormalScore,
    this.homeHalfScore,
    this.homeRed,
    this.homeYellow,
    this.homeCorn,
    this.homeAddScore,
    this.homePointScore,
    this.awayNormalScore,
    this.awayHalfScore,
    this.awayRed,
    this.awayYellow,
    this.awayCorn,
    this.awayAddScore,
    this.awayPointScore,
    this.lineup,
    this.stageId,
    this.subscribed,
    this.homePosition,
    this.awayPosition,
    this.hasOt,
    this.hasPenalty,
    this.win,
    this.note,
    this.minutes,
    this.mlive,
    this.mliveUrl,
    this.liveVideo,
    this.hasArticle,
    this.stageName,
    this.groupNum,
    this.roundNum,
    this.schemeCount,
    this.countdown,
    this.isWorldCup,
    this.categoryId,
    // ---- BM 扩展字段 ----
    this.homeTeam,
    this.awayTeam,
    int? homeScore,
    int? awayScore,
    required String leagueName,
    this.leagueColor = 0xFFF97316,
    this.matchTag,
    String? round,
    required BMMatchStatus status,
    BMMatchSportType? sportType,
    String? matchTime,
    String? liveMinute,
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
    bool? isFollowed,
  })  :
        // ---- 推导补全: Hank 缺失的 BM 必需字段从 homeTeam/awayTeam/... 取 ----
        matchId = matchId ?? '',
        homeTeamName = homeTeamName ?? homeTeam?.teamName ?? '',
        awayTeamName = awayTeamName ?? awayTeam?.teamName ?? '',
        // 总比分 homeScore/awayScore:
        //   - 优先用直接传入的 homeScore/awayScore (BM 原格式)
        //   - 其次: 只要 homeNormalScore/awayNormalScore 不为 null (哪怕是0, 代表 0-0 真实比分) → 直接当总比分(含加时点球)
        //   - 最后: 只有 normal==null 且加时/点球有分才赋值, 否则 null (代表赛前没比分, 显示 '-')
        homeScore = homeScore ??
            (homeNormalScore != null
                ? homeNormalScore + (homeAddScore ?? 0) + (homePointScore ?? 0)
                : ((homeAddScore ?? 0) + (homePointScore ?? 0) > 0
                    ? (homeAddScore ?? 0) + (homePointScore ?? 0)
                    : null)),
        awayScore = awayScore ??
            (awayNormalScore != null
                ? awayNormalScore + (awayAddScore ?? 0) + (awayPointScore ?? 0)
                : ((awayAddScore ?? 0) + (awayPointScore ?? 0) > 0
                    ? (awayAddScore ?? 0) + (awayPointScore ?? 0)
                    : null)),
        leagueName = leagueName,
        round = round ?? matchTag ?? stageName ?? (roundNum != null ? '第 $roundNum 轮' : ''),
        status = status,
        sportType = sportType ??
            ((categoryId != null && categoryId != 1)
                ? BMMatchSportType.basketball
                : BMMatchSportType.football),
        // matchTime String: 缺值时从 matchTimestamp int 秒格式化 (Hank -> BM 兼容)
        matchTime = matchTime ??
            ((matchTimestamp != null)
                ? _formatMatchTimestamp(matchTimestamp)
                : ''),
        // liveMinute 与 Hank minutes 等价: 缺 liveMinute 用 minutes, 反之亦然
        liveMinute = liveMinute ?? minutes,
        // isFollowed 与 subscribed: 双向补全
        isFollowed = isFollowed ?? (subscribed == true),
        aiWinRate = aiWinRate ?? (homeWinRate ?? 0),
        homeWinRate = homeWinRate ?? 0,
        drawRate = drawRate ?? 0,
        awayWinRate = awayWinRate ?? 0;

  /// matchTimestamp 秒 → 月/日 时:分 字符串 (Hank int秒时间戳 → BM matchTime 显示)
  static String _formatMatchTimestamp(int ts) {
    try {
      final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return '${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')} '
          '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '';
    }
  }

  /// 从Map映射构建模型 (100% 对齐 Hank match_id/home_team_id + 兼容 BM matchId/homeTeamId)
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

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    bool? toBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == 'true' || v == '1';
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

    // --- 便捷取值: 同时支持驼峰/下划线两种 key (Hank + BM 双兼容) ---
    int? matchIdInt = toInt(map['matchId']) ?? toInt(map['match_id']);
    String matchIdStr = safeString(map['matchId']) ?? safeString(map['match_id']) ?? (matchIdInt != null ? matchIdInt.toString() : '');

    // 联赛名: leagueName(BM) + competition_name(Hank) + league_name(通用下划线)
    String leagueNameVal =
        safeString(map['leagueName']) ??
        safeString(map['competitionName']) ??
        safeString(map['competition_name']) ??
        safeString(map['league_name']) ??
        '';

    // 主队TeamId (Hank: home_team_id int 顶层 | BM: homeTeam.teamId String)
    int? topHomeTeamId = toInt(map['homeTeamId']) ?? toInt(map['home_team_id']);
    int? topAwayTeamId = toInt(map['awayTeamId']) ?? toInt(map['away_team_id']);

    // matchTime int秒时间戳(Hank match_time) + BM String matchTime 双支持
    int? matchTs = toInt(map['matchTime']) ?? toInt(map['match_time']);
    String? matchTimeStr = safeString(map['matchTime']) ?? safeString(map['match_time']);
    if (matchTimeStr != null && matchTimeStr.isNotEmpty) {
      // 尝试解析: 如果 matchTime 其实是 int 的字符串,转成 int 存 matchTimestamp
      final parsedTs = int.tryParse(matchTimeStr);
      if (parsedTs != null && matchTs == null) matchTs = parsedTs;
    }
    // matchTime 字段显示: 如果是 int 类型自动格式化
    String finalMatchTimeStr = matchTimeStr ?? '';
    if (finalMatchTimeStr.isEmpty && matchTs != null) {
      finalMatchTimeStr = _formatMatchTimestamp(matchTs);
    }

    // minutes(Hank) ↔ liveMinute(BM)
    String? liveMinVal = safeString(map['liveMinute']) ?? safeString(map['live_minute']) ?? safeString(map['minutes']);

    // 半场比分 String (homeHalfScore awayHalfScore int → 拼接成 "1-0" 的 halfTimeScore)
    final hh = toInt(map['homeHalfScore']) ?? toInt(map['home_half_score']);
    final ah = toInt(map['awayHalfScore']) ?? toInt(map['away_half_score']);
    String? halfTimeStr = safeString(map['halfTimeScore']) ?? safeString(map['half_time_score']);
    if (halfTimeStr == null && hh != null && ah != null) {
      halfTimeStr = '$hh-$ah';
    }

    // subscribed(Hank bool) ↔ isFollowed(BM bool/int/string)
    final sub = toBool(map['subscribed']);
    final fol =
        map['isFollowed'] == true ||
        map['isFollowed'] == 1 ||
        safeString(map['isFollowed']) == 'true';
    final bool? finalSub = sub ?? fol;
    final bool finalFol = fol || (sub == true);

    // categoryId(Hank category int) ↔ sportType BM enum
    final cat = toInt(map['categoryId']) ?? toInt(map['category']);
    final sp = safeString(map['sportType']);
    final BMMatchSportType sport =
        (sp == 'basketball' || cat == 2) ? BMMatchSportType.basketball : BMMatchSportType.football;

    // 主客队总比分: 若缺 homeScore/awayScore 但有 normal 字段, 用 normal 填充
    int? hs = (map['homeScore'] is num)
        ? (map['homeScore'] as num).toInt()
        : int.tryParse(safeString(map['homeScore']) ?? '');
    int? as = (map['awayScore'] is num)
        ? (map['awayScore'] as num).toInt()
        : int.tryParse(safeString(map['awayScore']) ?? '');
    final hn = toInt(map['homeNormalScore']) ?? toInt(map['home_normal_score']);
    final an = toInt(map['awayNormalScore']) ?? toInt(map['away_normal_score']);
    if (hs == null && hn != null) hs = hn;
    if (as == null && an != null) as = an;

    // round / matchTag / stageName 双向映射
    final matchTagVal = safeString(map['matchTag']) ?? safeString(map['match_tag']);
    final stageNameVal = safeString(map['stageName']) ?? safeString(map['stage_name']);
    final roundNumVal = toInt(map['roundNum']) ?? toInt(map['round_num']);
    final roundVal =
        safeString(map['round']) ??
        safeString(map['round_name']) ??
        matchTagVal ??
        stageNameVal ??
        (roundNumVal != null ? '第 $roundNumVal 轮' : '');

    return BMMatchModel(
      // ---- Hank 42+ 字段 ----
      matchId: matchIdStr,
      seasonId: toInt(map['seasonId']) ?? toInt(map['season_id']),
      competitionId: toInt(map['competitionId']) ?? toInt(map['competition_id']),
      competitionLogo: safeString(map['competitionLogo']) ?? safeString(map['competition_logo']),
      competitionPrimaryColor: safeString(map['competitionPrimaryColor']) ?? safeString(map['competition_primary_color']),
      competitionSecondaryColor: safeString(map['competitionSecondaryColor']) ?? safeString(map['competition_secondary_color']),
      homeTeamId: topHomeTeamId,
      homeTeamName:
          safeString(map['homeTeamName']) ?? safeString(map['home_team_name']),
      homeTeamLogo:
          safeString(map['homeTeamLogo']) ?? safeString(map['home_team_logo']),
      awayTeamId: topAwayTeamId,
      awayTeamName:
          safeString(map['awayTeamName']) ?? safeString(map['away_team_name']),
      awayTeamLogo:
          safeString(map['awayTeamLogo']) ?? safeString(map['away_team_logo']),
      statusId: toInt(map['statusId']) ?? toInt(map['status_id']),
      statusName:
          safeString(map['statusName']) ?? safeString(map['status_name']),
      matchTimestamp: matchTs,
      neutral: toInt(map['neutral']),
      homeNormalScore: hn,
      homeHalfScore: hh,
      homeRed: toInt(map['homeRed']) ?? toInt(map['home_red']),
      homeYellow: toInt(map['homeYellow']) ?? toInt(map['home_yellow']),
      homeCorn: toInt(map['homeCorn']) ?? toInt(map['home_corn']),
      homeAddScore: toInt(map['homeAddScore']) ?? toInt(map['home_add_score']),
      homePointScore: toInt(map['homePointScore']) ?? toInt(map['home_point_score']),
      awayNormalScore: an,
      awayHalfScore: ah,
      awayRed: toInt(map['awayRed']) ?? toInt(map['away_red']),
      awayYellow: toInt(map['awayYellow']) ?? toInt(map['away_yellow']),
      awayCorn: toInt(map['awayCorn']) ?? toInt(map['away_corn']),
      awayAddScore: toInt(map['awayAddScore']) ?? toInt(map['away_add_score']),
      awayPointScore: toInt(map['awayPointScore']) ?? toInt(map['away_point_score']),
      lineup: toInt(map['lineup']),
      stageId: toInt(map['stageId']) ?? toInt(map['stage_id']),
      subscribed: finalSub,
      homePosition: safeString(map['homePosition']) ?? safeString(map['home_position']),
      awayPosition: safeString(map['awayPosition']) ?? safeString(map['away_position']),
      hasOt: toBool(map['hasOt']) ?? toBool(map['has_ot']),
      hasPenalty: toBool(map['hasPenalty']) ?? toBool(map['has_penalty']),
      win: toInt(map['win']),
      note: safeString(map['note']),
      minutes: liveMinVal,
      mlive: toInt(map['mlive']),
      mliveUrl: safeString(map['mliveUrl']) ?? safeString(map['mlive_url']),
      liveVideo: toInt(map['liveVideo']) ?? toInt(map['live_video']),
      hasArticle: toInt(map['hasArticle']) ?? toInt(map['has_article']),
      stageName: stageNameVal,
      groupNum: safeString(map['groupNum']) ?? safeString(map['group_num']),
      roundNum: roundNumVal,
      schemeCount: toInt(map['schemeCount']) ?? toInt(map['scheme_count']),
      countdown: toInt(map['countdown']),
      isWorldCup: toInt(map['isWorldCup']) ?? toInt(map['is_world_cup']),
      categoryId: cat,
      // ---- BM 扩展字段 ----
      homeTeam: readTeam(map['homeTeam']) ?? readTeam(map['home_team']),
      awayTeam: readTeam(map['awayTeam']) ?? readTeam(map['away_team']),
      homeScore: hs,
      awayScore: as,
      leagueName: leagueNameVal,
      leagueColor: (map['leagueColor'] is num)
          ? (map['leagueColor'] as num).toInt()
          : (int.tryParse(safeString(map['leagueColor']) ?? '') ?? 0xFFF97316),
      matchTag: matchTagVal,
      round: roundVal,
      status: parseStatus(map['status']),
      sportType: sport,
      matchTime: finalMatchTimeStr,
      liveMinute: liveMinVal,
      halfTimeScore: halfTimeStr,
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
      isFeatured:
          map['isFeatured'] == true ||
          map['isFeatured'] == 1 ||
          safeString(map['isFeatured']) == 'true',
      isFollowed: finalFol,
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
  /// 状态优先级: statusId 数字强类型 > status 枚举
  /// 足球数字规则(用户要求): statusId=1未开始 / 2|3|4|5|7进行中 / 8已结束 / 0|9|10|11|12|13 TBD待定
  String get displayStatusLabel {
    final id = statusId;
    if (id != null) {
      // 进行中(2|3|4|5|7) 优先拼 liveMinute 显示 LIVE 75'
      if (id == 2 || id == 3 || id == 4 || id == 5 || id == 7) {
        final minRaw = (liveMinute != null && liveMinute!.isNotEmpty)
            ? liveMinute
            : (minutes != null && minutes!.isNotEmpty ? minutes : null);
        final min = minRaw?.replaceAll("'", '');
        if (min != null && min.isNotEmpty) return 'LIVE $min\'';
        return 'LIVE';
      }
      if (id == 1) return '未开始';
      if (id == 8) return '完场';
      if (id == 0 || id == 9 || id == 10 || id == 11 || id == 12 || id == 13) {
        return '待定';
      }
    }
    // statusId 为空时 fallback 到 BMMatchStatus enum
    switch (status) {
      case BMMatchStatus.live:
        final minRaw = (liveMinute != null && liveMinute!.isNotEmpty)
            ? liveMinute
            : minutes;
        final min = minRaw?.replaceAll("'", '');
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
  String get kickoffText => (liveMinute != null && liveMinute!.isNotEmpty)
      ? liveMinute!
      : (minutes != null && minutes!.isNotEmpty
          ? minutes!
          : (matchTime.isNotEmpty ? matchTime : round));

  /// 显示合并信息: matchTime + round 组合
  ///   例: '2026/10/01 03:00 · 第 5 轮'
  String get displayMatchTime {
    final List<String> parts = [];
    if (matchTime.isNotEmpty) parts.add(matchTime);
    if (round.isNotEmpty) parts.add(round);
    return parts.join(' · ');
  }
}
