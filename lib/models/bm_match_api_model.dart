/// 安全工具: 从json动态值提取int? (兼容int/String/num/null, 提取失败返回null)
int? safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// 安全工具: 从json动态值提取String? (兼容String/num/null, 提取失败返回null)
String? safeString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

/// 安全工具: 从json动态值提取bool? (兼容bool/int/null, 提取失败返回null)
bool? safeBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) {
    final s = v.toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
  }
  return null;
}

/// BMMatchData - 足球比赛列表API响应数据体
/// 作用范围: /api/livespeed/football/matches 接口响应data字段
class BMMatchData {
  /// 数据总数 (int? 类型)
  final int? total;

  /// 请求时间戳 (int? 类型, 秒)
  final int? timestamp;

  /// 比赛项目列表 (List<BMMatchItem> 类型)
  final List<BMMatchItem> results;

  BMMatchData({this.total, this.timestamp, this.results = const []});

  /// 从 JSON 解析 (全字段安全提取, 不抛错)
  factory BMMatchData.fromJson(Map<String, dynamic> json) {
    final list = json['results'] is List ? json['results'] as List : null;
    final List<BMMatchItem> items = [];
    if (list != null) {
      for (final e in list) {
        try {
          if (e is Map<String, dynamic>) {
            items.add(BMMatchItem.fromJson(e));
          }
        } catch (ex) {
          debugPrintSafe('BMMatchData results单项解析跳过: $ex');
        }
      }
    }
    return BMMatchData(
      total: safeInt(json['total']),
      timestamp: safeInt(json['timestamp']),
      results: items,
    );
  }
}

/// BMMatchItem - 单场足球比赛数据项
/// 作用范围: /api/livespeed/football/matches 接口 results 子项
class BMMatchItem {
  /// 比赛唯一ID (int? 类型)
  final int? matchId;

  /// 赛季ID (int? 类型)
  final int? seasonId;

  /// 联赛ID (int? 类型)
  final int? competitionId;

  /// 联赛LogoURL (String? 类型)
  final String? competitionLogo;

  /// 联赛名称 (String? 类型)
  final String? competitionName;

  /// 联赛主题色(主) (String? 类型, 十六进制色字符串可选)
  final String? competitionPrimaryColor;

  /// 联赛主题色(副) (String? 类型)
  final String? competitionSecondaryColor;

  /// 主队ID (int? 类型)
  final int? homeTeamId;

  /// 主队名称 (String? 类型)
  final String? homeTeamName;

  /// 主队LogoURL (String? 类型)
  final String? homeTeamLogo;

  /// 客队ID (int? 类型)
  final int? awayTeamId;

  /// 客队名称 (String? 类型)
  final String? awayTeamName;

  /// 客队LogoURL (String? 类型)
  final String? awayTeamLogo;

  /// 状态ID (int? 类型: 0/1=未开始, 2/3/4=进行中, 8=完场)
  final int? statusId;

  /// 状态名称 (String? 类型)
  final String? statusName;

  /// 开赛时间戳 (int? 类型, 秒)
  final int? matchTime;

  /// 是否中立场地 (int? 类型)
  final int? neutral;

  /// 主队常规比分 (int? 类型)
  final int? homeNormalScore;

  /// 主队半场比分 (int? 类型)
  final int? homeHalfScore;

  /// 主队红牌 (int? 类型)
  final int? homeRed;

  /// 主队黄牌 (int? 类型)
  final int? homeYellow;

  /// 主队角球 (int? 类型)
  final int? homeCorn;

  /// 主队加时比分 (int? 类型)
  final int? homeAddScore;

  /// 主队点球比分 (int? 类型)
  final int? homePointScore;

  /// 客队常规比分 (int? 类型)
  final int? awayNormalScore;

  /// 客队半场比分 (int? 类型)
  final int? awayHalfScore;

  /// 客队红牌 (int? 类型)
  final int? awayRed;

  /// 客队黄牌 (int? 类型)
  final int? awayYellow;

  /// 客队角球 (int? 类型)
  final int? awayCorn;

  /// 客队加时比分 (int? 类型)
  final int? awayAddScore;

  /// 客队点球比分 (int? 类型)
  final int? awayPointScore;

  /// 是否有阵容 (int? 类型)
  final int? lineup;

  /// 阶段ID (int? 类型)
  final int? stageId;

  /// 是否关注 (bool? 类型)
  final bool? subscribed;

  /// 主队排名 (String? 类型)
  final String? homePosition;

  /// 客队排名 (String? 类型)
  final String? awayPosition;

  /// 是否有加时 (bool? 类型)
  final bool? hasOt;

  /// 是否有点球 (bool? 类型)
  final bool? hasPenalty;

  /// 胜负 (int? 类型: 1=主胜, 2=平, 3=客胜)
  final int? win;

  /// 备注 (String? 类型)
  final String? note;

  /// 进行中分钟数 (String? 类型, 如 "78'")
  final String? minutes;

  /// 动画直播 (int? 类型)
  final int? mlive;

  /// 动画直播URL (String? 类型)
  final String? mliveUrl;

  /// 视频直播 (int? 类型)
  final int? liveVideo;

  /// 是否有文章 (int? 类型)
  final int? hasArticle;

  /// 阶段名称 (String? 类型)
  final String? stageName;

  /// 小组编号 (String? 类型)
  final String? groupNum;

  /// 轮次编号 (int? 类型)
  final int? roundNum;

  /// 方案数 (int? 类型)
  final int? schemeCount;

  /// 开赛倒计时 (int? 类型, 秒)
  final int? countdown;

  /// 是否世界杯 (int? 类型)
  final int? isWorldCup;

  /// 运动分类 (int? 类型)
  final int? categoryId;

  BMMatchItem({
    this.matchId,
    this.seasonId,
    this.competitionId,
    this.competitionLogo,
    this.competitionName,
    this.competitionPrimaryColor,
    this.competitionSecondaryColor,
    this.homeTeamId,
    this.homeTeamName,
    this.homeTeamLogo,
    this.awayTeamId,
    this.awayTeamName,
    this.awayTeamLogo,
    this.statusId,
    this.statusName,
    this.matchTime,
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
  });

  /// 从 JSON 解析 (snake_case → camelCase, 全安全提取不抛错)
  factory BMMatchItem.fromJson(Map<String, dynamic> json) {
    return BMMatchItem(
      matchId: safeInt(json['match_id']),
      seasonId: safeInt(json['season_id']),
      competitionId: safeInt(json['competition_id']),
      competitionLogo: safeString(json['competition_logo']),
      competitionName: safeString(json['competition_name']),
      competitionPrimaryColor: safeString(json['competition_primary_color']),
      competitionSecondaryColor: safeString(json['competition_secondary_color']),
      homeTeamId: safeInt(json['home_team_id']),
      homeTeamName: safeString(json['home_team_name']),
      homeTeamLogo: safeString(json['home_team_logo']),
      awayTeamId: safeInt(json['away_team_id']),
      awayTeamName: safeString(json['away_team_name']),
      awayTeamLogo: safeString(json['away_team_logo']),
      statusId: safeInt(json['status_id']),
      statusName: safeString(json['status_name']),
      matchTime: safeInt(json['match_time']),
      neutral: safeInt(json['neutral']),
      homeNormalScore: safeInt(json['home_normal_score']),
      homeHalfScore: safeInt(json['home_half_score']),
      homeRed: safeInt(json['home_red']),
      homeYellow: safeInt(json['home_yellow']),
      homeCorn: safeInt(json['home_corn']),
      homeAddScore: safeInt(json['home_add_score']),
      homePointScore: safeInt(json['home_point_score']),
      awayNormalScore: safeInt(json['away_normal_score']),
      awayHalfScore: safeInt(json['away_half_score']),
      awayRed: safeInt(json['away_red']),
      awayYellow: safeInt(json['away_yellow']),
      awayCorn: safeInt(json['away_corn']),
      awayAddScore: safeInt(json['away_add_score']),
      awayPointScore: safeInt(json['away_point_score']),
      lineup: safeInt(json['lineup']),
      stageId: safeInt(json['stage_id']),
      subscribed: safeBool(json['subscribed']),
      homePosition: safeString(json['home_position']),
      awayPosition: safeString(json['away_position']),
      hasOt: safeBool(json['has_ot']),
      hasPenalty: safeBool(json['has_penalty']),
      win: safeInt(json['win']),
      note: safeString(json['note']),
      minutes: safeString(json['minutes']),
      mlive: safeInt(json['mlive']),
      mliveUrl: safeString(json['mlive_url']),
      liveVideo: safeInt(json['live_video']),
      hasArticle: safeInt(json['has_article']),
      stageName: safeString(json['stage_name']),
      groupNum: safeString(json['group_num']),
      roundNum: safeInt(json['round_num']),
      schemeCount: safeInt(json['scheme_count']),
      countdown: safeInt(json['countdown']),
      isWorldCup: safeInt(json['is_world_cup']),
      categoryId: safeInt(json['category_id']) ?? safeInt(json['category']),
    );
  }
}

/// debugPrint安全壳 (避免foundation导入缺失, 统一封装)
void debugPrintSafe(String msg) {
  // ignore: avoid_print
  print('[BallMatrix Safe] $msg');
}
