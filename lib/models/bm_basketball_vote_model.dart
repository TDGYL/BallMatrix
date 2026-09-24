// BMBasketballVoteInfo - basketball detaillivevotedatamodel
// data source: GET api/livespeed/basketball/match/vote-info?match_id=
// structure: data { home_votes, away_votes, vote_status }
// fielddescription:
// home_votes - home teamvote count (int, >=0)
// away_votes - away teamvote count (int, >=0)
// vote_status - currentuservote state (int, 0=not voted 1=alreadyvote home team 2=alreadyvote away team)

/// BMBasketballVoteInfo - home/away teamvote info
class BMBasketballVoteInfo {
 /// home teamvote count (int type)
 final int homeVotes;

 /// away teamvote count (int type)
 final int awayVotes;

 /// currentuservote state (int type, 0=not voted 1=alreadyvote home team 2=alreadyvote away team)
 final int voteStatus;

 const BMBasketballVoteInfo({
 this.homeVotes = 0,
 this.awayVotes = 0,
 this.voteStatus = 0,
 });

 /// fromAPI data Map build (compatible {code,data,msg} outerpassinput)
 /// [json] - data Map orwholeitemsresponse Map (Map<String, dynamic> type)
 factory BMBasketballVoteInfo.fromJson(Map<String, dynamic> json) {
 // ifyes {code, data, msg} , autotakeinnerlayer data
 final inner =
 json['data'] is Map ? json['data'] as Map<String, dynamic> : json;
    int toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return BMBasketballVoteInfo(
      homeVotes: toInt(inner['home_votes'] ?? inner['homeVotes']),
      awayVotes: toInt(inner['away_votes'] ?? inner['awayVotes']),
      voteStatus: toInt(inner['vote_status'] ?? inner['voteStatus']),
);
 }

 /// vote count (int type)
 int get totalVotes => homeVotes + awayVotes;

 /// home teamshare (double type, 0.0~1.0, nonevotewhen 0.5)
 double get homePercent =>
 totalVotes > 0 ? homeVotes / totalVotes: 0.5;

 /// away teamshare (double type, 0.0~1.0)
 double get awayPercent => 1 - homePercent;

 /// home teampercenttext (String type, e.g.: '64%')
  String get homePercentLabel =>
      totalVotes > 0 ? '${(homePercent * 100).round()}%' : '--';

 /// away teampercenttext (String type)
 String get awayPercentLabel =>
 totalVotes > 0 ? '${(awayPercent * 100).round()}%' : '--';

 /// userwhetheralreadyvote home team (bool type)
 bool get votedHome => voteStatus == 1;

 /// userwhetheralreadyvote away team (bool type)
 bool get votedAway => voteStatus == 2;

 /// userwhethernot voted (bool type)
 bool get notVoted => voteStatus == 0;
}
