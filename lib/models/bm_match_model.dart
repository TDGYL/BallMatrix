import 'bm_match_api_model.dart' show safeString;

/// BMTeamModel - teamdatamodel
/// purposescope: matchdatain of home/away teaminfo
class BMTeamModel {
 /// teamuniqueidentifier (String type)
 final String teamId;

 /// teamfullname (String type)
 final String teamName;

 /// teamabbreviation (String type, common3positionlargewrite)
 final String teamShort;

 /// teamLogo URL (String? type, can be empty)
 final String? logoUrl;

 BMTeamModel({
 required String? teamId,
 required String? teamName,
 String? teamShort,
 this.logoUrl,
 }): teamId = teamId ?? '',
       teamName = teamName ?? '',
 teamShort = teamShort ?? _extractShort(teamName);

 /// build model from Map mapping (fullsecurity, no throw)
 factory BMTeamModel.fromMap(Map<String, dynamic> map) {
 return BMTeamModel(
 teamId: safeString(map['teamId']) ?? safeString(map['team_id']) ?? '',
      teamName:
          safeString(map['teamName']) ?? safeString(map['team_name']) ?? '',
      teamShort: safeString(map['teamShort']) ?? safeString(map['team_short']),
      logoUrl: safeString(map['logoUrl']) ?? safeString(map['logo_url']),
);
 }

 /// defaultabbreviationtake: takefirst3positionlargewrite (3positionwithinnerlargewrite)
 static String _extractShort(String? name) {
 if (name == null || name.isEmpty) return '';
 if (name.length <= 3) return name.toUpperCase();
 return name.substring(0, 3).toUpperCase();
 }
}

/// BMMatchStatus - matchstateenum
enum BMMatchStatus {
 /// in progress
 live,

 /// i.e.willopenmatch (NS)
 upcoming,

 /// alreadyFT
 ended,

 /// TBD TBD/othersstate
 tbd,
}

/// BMMatchSportType - sport type enum
enum BMMatchSportType {
 /// football
 football,

 /// basketball
 basketball,
}

/// BMMatchModel - matchdatamodel（100% alignment hanklive HankMatchItem property）
/// purposescope: homefocus competitioncard、competitionlistpage、match detail page、H2H navigate MatchModel
/// includes: Hank all 42 field + BallMatrix expandedfield(Wrate/xG/momentumetc)
class BMMatchModel {
 // ================ ↓↓↓ alignment HankMatchItem No. 1~42 itemsfield ↓↓↓ ================

 /// 1. matchId: matchuniqueidentifier (compatibledoubletype)
 /// - hanklive: int match_id
 /// - ballmatrix: correctouterkeep String matchId (notbadhaslogic)
 final String matchId;

 /// 2. seasonId: season ID (int? type)
 final int? seasonId;

 /// 3. competitionId: leagueID (int? type)
 final int? competitionId;

 /// 4. competitionLogo: leagueLogo URL (String? type, corresponding Hank competition_logo)
 final String? competitionLogo;

 /// 5. competitionName: league namename (String? getter type, and leagueName wait)
 /// reuselowerplane leagueName，compatibledoublename（Hank competitionName / BM leagueName）

 /// 6. competitionPrimaryColor: leagueaccent color (String? type, hex string)
 final String? competitionPrimaryColor;

 /// 7. competitionSecondaryColor: leagueauxiliarycolor (String? type, hex string)
 final String? competitionSecondaryColor;

 /// 8. homeTeamId: home teamID (int? type, top level alignment Hank home_team_id)
 final int? homeTeamId;

 /// 9. homeTeamName: home teamname (String type)
 final String homeTeamName;

 /// 10. homeTeamLogo: home teamiconURL (String? type, can be empty)
 final String? homeTeamLogo;

 /// 11. awayTeamId: away teamID (int? type, top level alignment Hank away_team_id)
 final int? awayTeamId;

 /// 12. awayTeamName: away teamname (String type)
 final String awayTeamName;

 /// 13. awayTeamLogo: away teamiconURL (String? type, can be empty)
 final String? awayTeamLogo;

 /// 14. statusId: stateID (int? type, rawAPIreturn value, prioritycheckstate)
 /// football: 1NS 2|3|4|5|7in progress 8FT 0|9|10|11|12|13 TBD
 final int? statusId;

 /// 15. statusName: statename (String? type, APIreturnsrawintextname)
 final String? statusName;

 /// 16. matchTime(rawintsecondtimestamp) → matchTimestamp: kickoff timestamp(second)
 /// - corresponding Hank: int match_time secondlevel timestamp
 /// - BM originalhas String matchTime forUIdisplay，fieldstorerawtimestamp
 final int? matchTimestamp;

 /// 17. neutral: whetherininstantlycourt (int? type, 0/1)
 final int? neutral;

 /// 18. homeNormalScore: home team90minuteregular score (int? type, WDLstatisticscorefield)
 final int? homeNormalScore;

 /// 19. homeHalfScore: home teamHT score (int? type)
 final int? homeHalfScore;

 /// 20. homeRed: home teamred cardcount (int? type)
 final int? homeRed;

 /// 21. homeYellow: home teamyellow cardcount (int? type)
 final int? homeYellow;

 /// 22. homeCorn: home teamcornercount (int? type)
 final int? homeCorn;

 /// 23. homeAddScore: home teamextra timematchscore (int? type)
 final int? homeAddScore;

 /// 24. homePointScore: home teampenaltylargescore (int? type)
 final int? homePointScore;

 /// 25. awayNormalScore: away team90minuteregular score (int? type)
 final int? awayNormalScore;

 /// 26. awayHalfScore: away teamHT score (int? type)
 final int? awayHalfScore;

 /// 27. awayRed: away teamred cardcount (int? type)
 final int? awayRed;

 /// 28. awayYellow: away teamyellow cardcount (int? type)
 final int? awayYellow;

 /// 29. awayCorn: away teamcornercount (int? type)
 final int? awayCorn;

 /// 30. awayAddScore: away teamextra timematchscore (int? type)
 final int? awayAddScore;

 /// 31. awayPointScore: away teampenaltylargescore (int? type)
 final int? awayPointScore;

 /// 32. lineup: whetherhaslineupdata (int? type, 0=none 1=has)
 final int? lineup;

 /// 33. stageId: sectionID (int? type)
 final int? stageId;

 /// 34. subscribed: whetherfollow/subscribe (bool? type, and BM isFollowed two-way mapping)
 final bool? subscribed;

 /// 35. homePosition: home teamleaguerank (String? type, example "5")
 final String? homePosition;

 /// 36. awayPosition: away teamleaguerank (String? type)
 final String? awayPosition;

 /// 37. hasOt: whetherhasextra timematch (bool? type)
 final bool? hasOt;

 /// 38. hasPenalty: whetherhaspenaltylarge (bool? type)
 final bool? hasPenalty;

 /// 39. win: WLresult (int? type, 1=home win 2=D 3=away win)
 final int? win;

 /// 40. note: remark (String? type, example "includesextra time" "penaltyW" etc)
 final String? note;

 /// 41. minutes: in progressminute (String? type, example "78'"，and BM liveMinute two-way mapping)
 final String? minutes;

 /// 42. mlive: whetherhasanimationlive (int? type)
 final int? mlive;

 /// 43. mliveUrl: animationliveURL (String? type)
 final String? mliveUrl;

 /// 44. liveVideo: whetherhasviewlive (int? type)
 final int? liveVideo;

 /// 45. hasArticle: whetherhasclosecompetitiontextchapter (int? type)
 final int? hasArticle;

 /// 46. stageName: stage section name (String? type, example "1/4match" "halfmatch")
 final String? stageName;

 /// 47. groupNum: groupNo. (String? type, example "A")
 final String? groupNum;

 /// 48. roundNum: roundtime (int? type)
 final int? roundNum;

 /// 49. schemeCount: solutioncount (int? type)
 final int? schemeCount;

 /// 50. countdown: openmatchcountwhensecondcount (int? type)
 final int? countdown;

 /// 51. isWorldCup: whetherboundarycompetition (int? type)
 final int? isWorldCup;

 /// 52. categoryId: sport typeID (int? type, 1=football, corresponding Hank category)
 final int? categoryId;

 // ================ ↑↑↑ alignment HankMatchItem allfield ↑↑↑ ================

 // ================ ↓↓↓ BallMatrix expanded/keepfield ↓↓↓ ================

 /// home teamstructureinfo (BMTeamModel? type, BallMatrix keep)
 final BMTeamModel? homeTeam;

 /// away teamstructureinfo (BMTeamModel? type, BallMatrix keep)
 final BMTeamModel? awayTeam;

 /// home teamscore (int? type, BallMatrix keeptotal score = normal+add+point fallback)
 final int? homeScore;

 /// away teamscore (int? type, BallMatrix keep)
 final int? awayScore;

 /// league namename (String type, BM name, and Hank competitionName wait 1:1 mapping)
 final String leagueName;

 /// leagueaccent color (int type, ARGBformat, BM keep, defaultorange F97316)
 final int leagueColor;

 /// league namenamedo notname (String? getter type, compatibleold code competitionName field)
 String? get competitionName => leagueName.isNotEmpty ? leagueName: null;

 /// matchtag/stage section name (String? type, like "halfmatch", BM keep and stageName two-way mapping)
 final String? matchTag;

 /// matchroundtimeordescription (String type, BM keep and roundNum/groupNum two-way mapping)
 final String round;

 /// matchstate (BMMatchStatus enum, BM keep and statusId two-way mapping)
 final BMMatchStatus status;

 /// sport type (BMMatchSportType enum, BM keep and categoryId two-way mapping)
 final BMMatchSportType sportType;

 /// match time/minute (String type, BM keepUIdisplayfield and matchTimestamp two-way mapping)
 final String matchTime;

 /// in progressminutecount (String? type, BM keep and Hank minutes completefullwait)
 final String? liveMinute;

 /// HT score (String? type, BM keepconcat "1-0" and homeHalfScore/awayHalfScore two-way mapping)
 final String? halfTimeScore;

 /// goaleventlist (List<String> type, BM keep)
 final List<String> goalEvents;

 /// AIWratecalc (double type, BM keep 0-100)
 final double aiWinRate;

 /// home teamWrate (double type, BM keep 0-100)
 final double homeWinRate;

 /// Dgameprobability (double type, BM keep 0-100)
 final double drawRate;

 /// away teamWrate (double type, BM keep 0-100)
 final double awayWinRate;

 /// home teamxGgoal (double type, BM keep)
 final double homeXG;

 /// away teamxGgoal (double type, BM keep)
 final double awayXG;

 /// actualwhenmakepowerpercent (double type, BM keep home teammakepower)
 final double momentumPercent;

 /// modelmatch level (double? type, BM keep 0-100)
 final double? modelMatchRate;

 /// predictionresultdescription (String? type, BM keep)
 final String? prediction;

 /// AItext (String? type, BM keep)
 final String? aiInsight;

 /// whetherfocus clash (bool type, BM keep)
 final bool isFeatured;

 /// whetherfollow/subscribe (bool type, BM keep and Hank subscribed two-way mapping)
 final bool isFollowed;

 // ================ constructor: compatible Hank allfield + BM expanded ================
 BMMatchModel({
 // ---- Hank core 52 field (alloptional orfrom BM field) ----
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
 // ---- BM expandedfield ----
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
 }): // ---- patchfull: Hank missing of BM needfieldfrom homeTeam/awayTeam/... take ----
 matchId = matchId ?? '',
       homeTeamName = homeTeamName ?? homeTeam?.teamName ?? '',
       awayTeamName = awayTeamName ?? awayTeam?.teamName ?? '',
 // total score homeScore/awayScore:
 // - priorityusepassinput of homeScore/awayScore (BM originalformat)
 // - itstime: onlyneed homeNormalScore/awayNormalScore notas null (yes0, table 0-0 trueactualscore) → whentotal score(includesextra timepenalty)
 // - later: onlyhas normal==null andextra time/penaltyhasminvalue, otherwise then null (tablematchfirstnoscore, display '-')
       homeScore =
           homeScore ??
           (homeNormalScore != null
               ? homeNormalScore + (homeAddScore ?? 0) + (homePointScore ?? 0)
               : ((homeAddScore ?? 0) + (homePointScore ?? 0) > 0
                     ? (homeAddScore ?? 0) + (homePointScore ?? 0)
                     : null)),
       awayScore =
           awayScore ??
           (awayNormalScore != null
               ? awayNormalScore + (awayAddScore ?? 0) + (awayPointScore ?? 0)
               : ((awayAddScore ?? 0) + (awayPointScore ?? 0) > 0
                     ? (awayAddScore ?? 0) + (awayPointScore ?? 0)
                     : null)),
       leagueName = leagueName,
       round =
           round ??
           matchTag ??
           stageName ??
           (roundNum != null ? 'No. $roundNum round' : ''),
 status = status,
 sportType =
 sportType ??
 ((categoryId != null && categoryId != 1)
 ? BMMatchSportType.basketball
: BMMatchSportType.football),
 // matchTime String: missingvaluewhenfrom matchTimestamp int secondformat (Hank -> BM compatible)
 matchTime =
 matchTime ??
 ((matchTimestamp != null)
 ? _formatMatchTimestamp(matchTimestamp)
: ''),
 // liveMinute and Hank minutes wait: missing liveMinute use minutes, 
 liveMinute = liveMinute ?? minutes,
 // isFollowed and subscribed: doubledirectionpatchfull
 isFollowed = isFollowed ?? (subscribed == true),
 aiWinRate = aiWinRate ?? (homeWinRate ?? 0),
 homeWinRate = homeWinRate ?? 0,
 drawRate = drawRate ?? 0,
 awayWinRate = awayWinRate ?? 0;

 /// matchTimestamp second → month/day when:min string (Hank intsecondtimestamp → BM matchTime display)
 static String _formatMatchTimestamp(int ts) {
 try {
 final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
 return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
 }
 }

 /// build model from Map mapping (100% alignment Hank match_id/home_team_id + compatible BM matchId/homeTeamId)
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

 // --- takevalue: simultaneouslysupport/underlinekind key (Hank + BM doublecompatible) ---
 int? matchIdInt = toInt(map['matchId']) ?? toInt(map['match_id']);
    String matchIdStr =
        safeString(map['matchId']) ??
        safeString(map['match_id']) ??
        (matchIdInt != null ? matchIdInt.toString() : '');

 // league name: leagueName(BM) + competition_name(Hank) + league_name(commonunderline)
 String leagueNameVal =
 safeString(map['leagueName']) ??
        safeString(map['competitionName']) ??
        safeString(map['competition_name']) ??
        safeString(map['league_name']) ??
        '';

 // home teamTeamId (Hank: home_team_id int top level | BM: homeTeam.teamId String)
 int? topHomeTeamId = toInt(map['homeTeamId']) ?? toInt(map['home_team_id']);
    int? topAwayTeamId = toInt(map['awayTeamId']) ?? toInt(map['away_team_id']);

 // matchTime intsecondtimestamp(Hank match_time) + BM String matchTime doublesupport
 int? matchTs = toInt(map['matchTime']) ?? toInt(map['match_time']);
    String? matchTimeStr =
        safeString(map['matchTime']) ?? safeString(map['match_time']);
 if (matchTimeStr != null && matchTimeStr.isNotEmpty) {
 // parse: likeresult matchTime itsactualyes int of string,convertform int store matchTimestamp
 final parsedTs = int.tryParse(matchTimeStr);
 if (parsedTs != null && matchTs == null) matchTs = parsedTs;
 }
 // matchTime fielddisplay: likeresultyes int typeautoformat
 String finalMatchTimeStr = matchTimeStr ?? '';
    if (finalMatchTimeStr.isEmpty && matchTs != null) {
      finalMatchTimeStr = _formatMatchTimestamp(matchTs);
    }

    // minutes(Hank) ↔ liveMinute(BM)
    String? liveMinVal =
        safeString(map['liveMinute']) ??
        safeString(map['live_minute']) ??
        safeString(map['minutes']);

 // HT score String (homeHalfScore awayHalfScore int → concatform "1-0" of halfTimeScore)
 final hh = toInt(map['homeHalfScore']) ?? toInt(map['home_half_score']);
    final ah = toInt(map['awayHalfScore']) ?? toInt(map['away_half_score']);
    String? halfTimeStr =
        safeString(map['halfTimeScore']) ?? safeString(map['half_time_score']);
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
    final BMMatchSportType sport = (sp == 'basketball' || cat == 2)
 ? BMMatchSportType.basketball
: BMMatchSportType.football;

 // home/away teamtotal score: ifmissing homeScore/awayScore has normal field, use normal fill
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

 // round / matchTag / stageName two-way mapping
 final matchTagVal =
 safeString(map['matchTag']) ?? safeString(map['match_tag']);
    final stageNameVal =
        safeString(map['stageName']) ?? safeString(map['stage_name']);
    final roundNumVal = toInt(map['roundNum']) ?? toInt(map['round_num']);
    final roundVal =
        safeString(map['round']) ??
        safeString(map['round_name']) ??
        matchTagVal ??
        stageNameVal ??
        (roundNumVal != null ? 'No. $roundNumVal round' : '');

    return BMMatchModel(
      // ---- Hank 42+ field ----
      matchId: matchIdStr,
      seasonId: toInt(map['seasonId']) ?? toInt(map['season_id']),
      competitionId:
          toInt(map['competitionId']) ?? toInt(map['competition_id']),
      competitionLogo:
          safeString(map['competitionLogo']) ??
          safeString(map['competition_logo']),
      competitionPrimaryColor:
          safeString(map['competitionPrimaryColor']) ??
          safeString(map['competition_primary_color']),
      competitionSecondaryColor:
          safeString(map['competitionSecondaryColor']) ??
          safeString(map['competition_secondary_color']),
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
      homePointScore:
          toInt(map['homePointScore']) ?? toInt(map['home_point_score']),
      awayNormalScore: an,
      awayHalfScore: ah,
      awayRed: toInt(map['awayRed']) ?? toInt(map['away_red']),
      awayYellow: toInt(map['awayYellow']) ?? toInt(map['away_yellow']),
      awayCorn: toInt(map['awayCorn']) ?? toInt(map['away_corn']),
      awayAddScore: toInt(map['awayAddScore']) ?? toInt(map['away_add_score']),
      awayPointScore:
          toInt(map['awayPointScore']) ?? toInt(map['away_point_score']),
      lineup: toInt(map['lineup']),
      stageId: toInt(map['stageId']) ?? toInt(map['stage_id']),
      subscribed: finalSub,
      homePosition:
          safeString(map['homePosition']) ?? safeString(map['home_position']),
      awayPosition:
          safeString(map['awayPosition']) ?? safeString(map['away_position']),
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
      // ---- BM expandedfield ----
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

/// BMMatchModel expanded：displayrelated getter + detailrefreshmerge
/// - displayStatusLabel: displaystatestring (LIVE/FT/NS/TBD)
/// - kickoffText: kickoff timestring (matchTime/liveMinute anyonehasvalueshow, foremptynon-nullstring)
/// - displayMatchTime: formatopenmatch/roundtimeortime mergedisplay
/// - refreshedWith: detailAPI responselatermergerefreshtopcardfield
extension BMMatchModelDisplayX on BMMatchModel {
 /// usedetailAPI response of modelmergerefreshcurrentmodel (newvaluepriority, newvalueasemptykeepoldvalue)
 /// fordetailpagerequest detail laterrefreshtopcard (team name/Logo/score/state/league)
 /// [fresh] - detail APINew of model (BMMatchModel type)
 /// [categoryId] - manualspecifiedsport typeID (int? type, football detailpass1, basketball detailpass2; prioritylevelheight)
 /// returns: BMMatchModel mergelater of newinstance
 BMMatchModel refreshedWith(BMMatchModel fresh, {int? categoryId}) {
 String? pickStr(String? freshV, String? oldV) =>
 (freshV != null && freshV.isNotEmpty) ? freshV: oldV;
 // manual categoryId priority, itstime fresh, lateroldvalue
 final int? mergedCategory =
 categoryId ?? fresh.categoryId ?? this.categoryId;
 // categoryId sportType (2=basketball, others=football)
 final BMMatchSportType mergedSport = (mergedCategory == 2)
 ? BMMatchSportType.basketball
: BMMatchSportType.football;
 return BMMatchModel(
 matchId: fresh.matchId.isNotEmpty ? fresh.matchId: matchId,
 homeTeamId: fresh.homeTeamId ?? homeTeamId,
 awayTeamId: fresh.awayTeamId ?? awayTeamId,
 homeTeamName: pickStr(fresh.homeTeamName, homeTeamName),
 homeTeamLogo: pickStr(fresh.homeTeamLogo, homeTeamLogo),
 awayTeamName: pickStr(fresh.awayTeamName, awayTeamName),
 awayTeamLogo: pickStr(fresh.awayTeamLogo, awayTeamLogo),
 statusId: fresh.statusId ?? statusId,
 statusName: pickStr(fresh.statusName, statusName),
 homeScore: fresh.homeScore ?? homeScore,
 awayScore: fresh.awayScore ?? awayScore,
 leagueName: fresh.leagueName.isNotEmpty ? fresh.leagueName: leagueName,
 round: fresh.round.isNotEmpty ? fresh.round: round,
 matchTime: fresh.matchTime.isNotEmpty ? fresh.matchTime: matchTime,
 liveMinute: (fresh.liveMinute ?? liveMinute),
 minutes: (fresh.minutes ?? minutes),
 categoryId: mergedCategory,
 sportType: mergedSport,
 status: fresh.status,
 homeTeam: fresh.homeTeam ?? homeTeam,
 awayTeam: fresh.awayTeam ?? awayTeam,
 isFollowed: fresh.isFollowed,
 homeNormalScore: fresh.homeNormalScore ?? homeNormalScore,
 awayNormalScore: fresh.awayNormalScore ?? awayNormalScore,
 homeAddScore: fresh.homeAddScore ?? homeAddScore,
 awayAddScore: fresh.awayAddScore ?? awayAddScore,
 homePointScore: fresh.homePointScore ?? homePointScore,
 awayPointScore: fresh.awayPointScore ?? awayPointScore,
);
 }

 /// displaystatestring (String type, for scoreboard LIVE pill)
 /// live: "LIVE 75'"
  ///   ended: "FT"
  ///   upcoming: "NS"
  ///   tbd: "TBD"
 /// statepriority level: statusId numbertype > status enum
 /// footballnumberrule(user requirement): statusId=1NS / 2|3|4|5|7in progress / 8FT / 0|9|10|11|12|13 TBDTBD
 /// basketballnumberrule(user requirement): statusId=1|13NS / 2|3|4|5|6|7|8|9in progress / 10|11FT / 0|12|14|15 TBDTBD
 String get displayStatusLabel {
 final id = statusId;
 print('print-----${id}--${sportType}');
 if (id != null) {
 // basketballrulebranch
 if (sportType == BMMatchSportType.basketball) {
 if (id == 1 || id == 13) return 'NS';
        if (id >= 2 && id <= 9) {
          final minRaw = (liveMinute != null && liveMinute!.isNotEmpty)
              ? liveMinute
              : (minutes != null && minutes!.isNotEmpty ? minutes : null);
          final min = minRaw?.replaceAll("'", '');
          if (min != null && min.isNotEmpty) return 'LIVE $min\'';
          return 'LIVE';
        }
        if (id == 10 || id == 11) return 'FT';
        if (id == 0 || id == 12 || id == 14 || id == 15) return 'TBD';
 } else {
 // footballrulebranch
 // in progress(2|3|4|5|7) priority liveMinute display LIVE 75'
 if (id == 2 || id == 3 || id == 4 || id == 5 || id == 7) {
 final minRaw = (liveMinute != null && liveMinute!.isNotEmpty)
 ? liveMinute
: (minutes != null && minutes!.isNotEmpty ? minutes: null);
 final min = minRaw?.replaceAll("'", '');
          if (min != null && min.isNotEmpty) return 'LIVE $min\'';
          return 'LIVE';
        }
        if (id == 1) return 'NS';
        if (id == 8) return 'FT';
        if (id == 0 ||
            id == 9 ||
            id == 10 ||
            id == 11 ||
            id == 12 ||
            id == 13) {
          return 'TBD';
        }
      }
    }

    return '-';
 }

 /// kickoff timenon-nullstring (String type, forcheck "kickoff time/roundtimelessonehasvalue")
 /// liveMinute non-nullpriority, otherwise then matchTime, otherwise then round
 String get kickoffText => (liveMinute != null && liveMinute!.isNotEmpty)
 ? liveMinute!
: (minutes != null && minutes!.isNotEmpty
 ? minutes!
: (matchTime.isNotEmpty ? matchTime: round));

 /// displaymergeinfo: matchTime + round groupmerge
 /// e.g.: '2026/10/01 03:00 · No. 5 round'
  String get displayMatchTime {
    final List<String> parts = [];
    if (matchTime.isNotEmpty) parts.add(matchTime);
    if (round.isNotEmpty) parts.add(round);
    return parts.join(' · ');
  }
}
