/// BMSearchMatch - 发布话题关联比赛的搜索结果模型
/// 作用范围: 发布话题页 (BMPostTopicPage) 关联比赛入口 + 比赛搜索页 (BMPostTopicMatchSearchPage)
/// 数据源:
///   - GET /api/livespeed/index/search          (data.matches 数组元素)
///   - GET /api/livespeed/index/search/match/hot (data 数组元素)
/// 字段 100% 对齐 hanklive HankSearchMatch (snake_case JSON -> camelCase 模型)
class BMSearchMatch {
  /// 比赛ID (int? 类型, 关联比赛提交参数 match_id)
  final int? matchId;

  /// 比赛时间戳 (int? 类型, 秒级)
  final int? matchTime;

  /// 联赛名称 (String? 类型)
  final String? competitionName;

  /// 主队ID (int? 类型)
  final int? homeTeamId;

  /// 主队名称 (String? 类型)
  final String? homeTeamName;

  /// 主队 Logo URL (String? 类型)
  final String? homeTeamLogo;

  /// 主队比分 (int? 类型)
  final int? homeTeamScore;

  /// 客队ID (int? 类型)
  final int? awayTeamId;

  /// 客队名称 (String? 类型)
  final String? awayTeamName;

  /// 客队 Logo URL (String? 类型)
  final String? awayTeamLogo;

  /// 客队比分 (int? 类型)
  final int? awayTeamScore;

  /// 运动类型ID (int? 类型, 1=足球 2=篮球, 用于过滤)
  final int? categoryId;

  /// 构造函数
  BMSearchMatch({
    this.matchId,
    this.matchTime,
    this.competitionName,
    this.homeTeamId,
    this.homeTeamName,
    this.homeTeamLogo,
    this.homeTeamScore,
    this.awayTeamId,
    this.awayTeamName,
    this.awayTeamLogo,
    this.awayTeamScore,
    this.categoryId,
  });

  /// 从 JSON Map 构建模型 (snake_case -> camelCase, MJExtension 风格映射)
  /// [json] - 接口返回的单个比赛 Map (Map<String, dynamic> 类型)
  /// 返回: BMSearchMatch
  factory BMSearchMatch.fromJson(Map<String, dynamic> json) {
    return BMSearchMatch(
      matchId: _toInt(json['match_id']),
      matchTime: _toInt(json['match_time']),
      competitionName: _toStr(json['competition_name']),
      homeTeamId: _toInt(json['home_team_id']),
      homeTeamName: _toStr(json['home_team_name']),
      homeTeamLogo: _toStr(json['home_team_logo']),
      homeTeamScore: _toInt(json['home_team_score']),
      awayTeamId: _toInt(json['away_team_id']),
      awayTeamName: _toStr(json['away_team_name']),
      awayTeamLogo: _toStr(json['away_team_logo']),
      awayTeamScore: _toInt(json['away_team_score']),
      categoryId: _toInt(json['category']),
    );
  }

  /// 安全 int 转换 (num/String -> int?)
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// 安全 String 转换 (dynamic -> String?)
  static String? _toStr(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    return v.toString();
  }
}

/// BMSearchResult - 搜索接口聚合结果模型
/// 数据源: GET /api/livespeed/index/search 返回 data 对象
/// 作用范围: 比赛搜索页按关键词搜索时解析 matches 分组
class BMSearchResult {
  /// 比赛搜索结果列表 (List<BMSearchMatch> 类型)
  final List<BMSearchMatch> matches;

  /// 构造函数
  BMSearchResult({this.matches = const []});

  /// 从 JSON Map 构建模型 (只解析发布话题需要的 matches 分组)
  /// [json] - 接口返回的 data Map (Map<String, dynamic> 类型)
  /// 返回: BMSearchResult
  factory BMSearchResult.fromJson(Map<String, dynamic> json) {
    final rawMatches = json['matches'];
    final List<BMSearchMatch> list = [];
    if (rawMatches is List) {
      for (final e in rawMatches) {
        if (e is Map<String, dynamic>) list.add(BMSearchMatch.fromJson(e));
      }
    }
    return BMSearchResult(matches: list);
  }
}
