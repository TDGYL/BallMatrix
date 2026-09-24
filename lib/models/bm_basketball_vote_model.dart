// BMBasketballVoteInfo - 篮球详情实况投票数据模型
// 数据源: GET api/livespeed/basketball/match/vote-info?match_id=
// 结构: data { home_votes, away_votes, vote_status }
// 字段说明:
//   home_votes  - 主队投票数 (int, >=0)
//   away_votes  - 客队投票数 (int, >=0)
//   vote_status - 当前用户投票状态 (int, 0=未投 1=已投主队 2=已投客队)

/// BMBasketballVoteInfo - 主客队投票信息
class BMBasketballVoteInfo {
  /// 主队投票数 (int 类型)
  final int homeVotes;

  /// 客队投票数 (int 类型)
  final int awayVotes;

  /// 当前用户投票状态 (int 类型, 0=未投 1=已投主队 2=已投客队)
  final int voteStatus;

  const BMBasketballVoteInfo({
    this.homeVotes = 0,
    this.awayVotes = 0,
    this.voteStatus = 0,
  });

  /// 从接口 data Map 构建 (兼容 {code,data,msg} 包装外层传入)
  /// [json] - data Map 或整个响应 Map (Map<String, dynamic> 类型)
  factory BMBasketballVoteInfo.fromJson(Map<String, dynamic> json) {
    // 若是 {code, data, msg} 包装, 自动取内层 data
    final inner =
        json['data'] is Map ? json['data'] as Map<String, dynamic> : json;
    int toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return BMBasketballVoteInfo(
      homeVotes: toInt(inner['home_votes'] ?? inner['homeVotes']),
      awayVotes: toInt(inner['away_votes'] ?? inner['awayVotes']),
      voteStatus: toInt(inner['vote_status'] ?? inner['voteStatus']),
    );
  }

  /// 总投票数 (int 类型)
  int get totalVotes => homeVotes + awayVotes;

  /// 主队占比 (double 类型, 0.0~1.0, 无投票时 0.5)
  double get homePercent =>
      totalVotes > 0 ? homeVotes / totalVotes : 0.5;

  /// 客队占比 (double 类型, 0.0~1.0)
  double get awayPercent => 1 - homePercent;

  /// 主队百分比文案 (String 类型, 例: '64%')
  String get homePercentLabel =>
      totalVotes > 0 ? '${(homePercent * 100).round()}%' : '--';

  /// 客队百分比文案 (String 类型)
  String get awayPercentLabel =>
      totalVotes > 0 ? '${(awayPercent * 100).round()}%' : '--';

  /// 用户是否已投主队 (bool 类型)
  bool get votedHome => voteStatus == 1;

  /// 用户是否已投客队 (bool 类型)
  bool get votedAway => voteStatus == 2;

  /// 用户是否未投票 (bool 类型)
  bool get notVoted => voteStatus == 0;
}
