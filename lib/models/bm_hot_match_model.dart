import 'bm_match_model.dart';

/// BMHotMatchModel - 热门比赛模型
/// 作用范围: 映射 /api/livespeed/index/search/match/hot GET 返回的热门比赛列表
/// 字段包含: 比赛ID、开赛时间、项目分类、联赛名、主客队信息、当前比分
class BMHotMatchModel {
  /// 比赛唯一ID (int 类型)
  final int? matchId;

  /// 开赛时间 - UNIX秒级时间戳 (int 类型, 秒)
  final int? matchTime;

  /// 项目分类 (int 类型, 1=足球 2=篮球)
  final int? category;

  /// 联赛名称 (String 类型, 例: WCBA / 英超)
  final String? competitionName;

  /// 主队ID (int 类型)
  final int? homeTeamId;

  /// 主队名称 (String 类型)
  final String? homeTeamName;

  /// 主队Logo URL (String 类型)
  final String? homeTeamLogo;

  /// 主队当前比分 (int 类型, 未开赛=0)
  final int? homeTeamScore;

  /// 客队ID (int 类型)
  final int? awayTeamId;

  /// 客队名称 (String 类型)
  final String? awayTeamName;

  /// 客队Logo URL (String 类型)
  final String? awayTeamLogo;

  /// 客队当前比分 (int 类型, 未开赛=0)
  final int? awayTeamScore;

  BMHotMatchModel({
    this.matchId,
    this.matchTime,
    this.category,
    this.competitionName,
    this.homeTeamId,
    this.homeTeamName,
    this.homeTeamLogo,
    this.homeTeamScore,
    this.awayTeamId,
    this.awayTeamName,
    this.awayTeamLogo,
    this.awayTeamScore,
  });

  /// 从 JSON 映射构建模型 (snake_case → camelCase)
  /// 参数: [json] 接口返回的单条比赛原始 Map
  /// 返回: BMHotMatchModel 实例
  factory BMHotMatchModel.fromJson(Map<String, dynamic> json) {
    return BMHotMatchModel(
      matchId: json['match_id'] as int?,
      matchTime: json['match_time'] as int?,
      category: json['category'] as int?,
      competitionName: json['competition_name'] as String?,
      homeTeamId: json['home_team_id'] as int?,
      homeTeamName: json['home_team_name'] as String?,
      homeTeamLogo: (json['home_team_logo'] is String)
          ? (json['home_team_logo'] as String).trim()
          : null,
      homeTeamScore: json['home_team_score'] as int?,
      awayTeamId: json['away_team_id'] as int?,
      awayTeamName: json['away_team_name'] as String?,
      awayTeamLogo: (json['away_team_logo'] is String)
          ? (json['away_team_logo'] as String).trim()
          : null,
      awayTeamScore: json['away_team_score'] as int?,
    );
  }

  /// 转换为 JSON (camelCase → snake_case)
  /// 返回: Map<String, dynamic>
  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'match_time': matchTime,
      'category': category,
      'competition_name': competitionName,
      'home_team_id': homeTeamId,
      'home_team_name': homeTeamName,
      'home_team_logo': homeTeamLogo,
      'home_team_score': homeTeamScore,
      'away_team_id': awayTeamId,
      'away_team_name': awayTeamName,
      'away_team_logo': awayTeamLogo,
      'away_team_score': awayTeamScore,
    };
  }

  /// 项目分类文字描述 (String 类型: '足球'/'篮球'/'其他')
  String get categoryLabel {
    switch (category) {
      case 1:
        return '足球';
      case 2:
        return '篮球';
      default:
        return '综合';
    }
  }

  /// 格式化开赛时间为 MM/DD HH:mm (空时间戳返回 '待定')
  String get formattedMatchTime {
    if (matchTime == null || matchTime == 0) return '待定';
    final dt = DateTime.fromMillisecondsSinceEpoch(matchTime! * 1000);
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$mm/$dd $hh:$mi';
  }

  /// 转为 BMMatchModel (用于 push 比赛详情页, 详情页 initState 会重新请求 detail 覆盖)
  BMMatchModel get toMatchModel {
    final BMMatchStatus status;
    if (category == 1) {
      // 足球状态: 未开赛=1 进行中=2..7 已结束=8
      final hasStarted = (homeTeamScore ?? 0) > 0 || (awayTeamScore ?? 0) > 0;
      if (!hasStarted) {
        status = BMMatchStatus.upcoming;
      } else if ((matchTime ?? 0) == 0) {
        status = BMMatchStatus.live;
      } else {
        status = BMMatchStatus.ended;
      }
    } else {
      // 篮球: 开赛且有比分=ended or live, 否则upcoming
      final hasStarted = (homeTeamScore ?? 0) > 0 || (awayTeamScore ?? 0) > 0;
      if (!hasStarted) {
        status = BMMatchStatus.upcoming;
      } else if ((matchTime ?? 0) == 0) {
        status = BMMatchStatus.live;
      } else {
        status = BMMatchStatus.ended;
      }
    }
    return BMMatchModel(
      matchId: matchId?.toString() ?? '',
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      homeTeamLogo: homeTeamLogo,
      awayTeamLogo: awayTeamLogo,
      homeScore: homeTeamScore,
      awayScore: awayTeamScore,
      leagueName: competitionName ?? '',
      status: status,
      sportType: category == 2
          ? BMMatchSportType.basketball
          : BMMatchSportType.football,
      matchTime: formattedMatchTime,
      round: '',
    );
  }
}
