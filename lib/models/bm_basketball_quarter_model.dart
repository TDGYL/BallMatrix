/// BMBasketballQuarterScore - basketballmatchsectioncountscoremodel
/// purposescope: basketball detailpagetopscoreboard Q1~Q4(+AET) per-quarter scoresheet
/// datasource:
/// 1. GET /api/livespeed/basketball/match/detail returns of home_scores/away_scores (comma No.minstring, e.g.: "28,32,24,28")
/// 2. BMBasketballMatchItem of homeQ1~homeQ4 / awayQ1~awayQ4 field
/// 3. BMMatchModel passinput of homeTeam/homeScore fallback
class BMBasketballQuarterScore {
 /// home teamper-quarter score (List<int> type, index 0=Q1, 1=Q2, 2=Q3, 3=Q4, 4+=AET)
 final List<int> homeQuarters;

 /// away teamper-quarter score (List<int> type, and homeQuarters waitlength)
 final List<int> awayQuarters;

 /// home teamtotal (int type, eachsectionaccumulate, nonedataas 0)
 final int homeTotal;

 /// away teamtotal (int type, eachsectionaccumulate, nonedataas 0)
 final int awayTotal;

 const BMBasketballQuarterScore({
 this.homeQuarters = const [],
 this.awayQuarters = const [],
 this.homeTotal = 0,
 this.awayTotal = 0,
 });

 /// whetherhasvalidsectioncountdata (bool type, lesshasonesectiondataas true)
 bool get hasData => homeQuarters.isNotEmpty || awayQuarters.isNotEmpty;

 /// sectioncount (int type, takehome/away teamlengthlistlengthdegree, e.g.: 4= 5+=includesAET)
 int get quarterCount =>
 homeQuarters.length > awayQuarters.length
 ? homeQuarters.length
: awayQuarters.length;

 /// sectiontaglist (List<String> type, e.g.: ['Q1','Q2','Q3','Q4','OT1'])
  List<String> get quarterLabels {
    return List<String>.generate(quarterCount, (i) => i < 4 ? 'Q${i + 1}' : 'OT${i - 3}');
 }

 /// fromcomma No.minstringparseper-quarter score (e.g.: "28,32,24,28" → [28,32,24,28])
 /// [raw] - rawscorestring (String? type, supportnull)
 /// returns: List<int> per-quarter score (parsefailurereturnsemptyarray)
 static List<int> _parseQuarters(String? raw) {
 if (raw == null || raw.trim().isEmpty) return const [];
 final parts = raw.split(',');
 final result = <int>[];
 for (final p in parts) {
 final v = int.tryParse(p.trim());
 if (v != null) result.add(v);
 }
 return result;
 }

 /// fromdetailAPI data Map build (prioritycomma No.minstring)
 /// [data] - detailAPI response of data Map (Map<String,dynamic> type)
 /// returns: BMBasketballQuarterScore (nonedatawhen hasData=false)
 factory BMBasketballQuarterScore.fromDetailMap(Map<String, dynamic>? data) {
 if (data == null) return const BMBasketballQuarterScore();
 // compatible key: home_scores/homeScores/home_score/homeScore (String comma No.minor List)
 dynamic rawHome = data['home_scores'] ?? data['homeScores'] ?? data['home_score'] ?? data['homeScore'];
    dynamic rawAway = data['away_scores'] ?? data['awayScores'] ?? data['away_score'] ?? data['awayScore'];
 // home_score canabilityyes Map {total, q1...} or String "28,32,24,28" or List
 List<int> homeQ = _coerceQuarters(rawHome);
 List<int> awayQ = _coerceQuarters(rawAway);
 if (homeQ.isEmpty && awayQ.isEmpty) return const BMBasketballQuarterScore();
 final homeTotal = data['home_total'] is num
        ? (data['home_total'] as num).toInt()
        : homeQ.fold(0, (a, b) => a + b);
    final awayTotal = data['away_total'] is num
        ? (data['away_total'] as num).toInt()
: awayQ.fold(0, (a, b) => a + b);
 return BMBasketballQuarterScore(
 homeQuarters: homeQ,
 awayQuarters: awayQ,
 homeTotal: homeTotal,
 awayTotal: awayTotal,
);
 }

 /// moretypevalueconvertsectioncountlist (String comma No.min / List / Map{q1..q4} threestatecompatible)
 /// [v] - rawvalue (dynamic type)
 /// returns: List<int> per-quarter score
 static List<int> _coerceQuarters(dynamic v) {
 if (v == null) return const [];
 if (v is String) return _parseQuarters(v);
 if (v is List) {
 return v.map((e) => int.tryParse(e.toString()) ?? 0).toList();
 }
 if (v is Map) {
 // Map shapestyle: {q1: 28, q2: 32,...} or {Q1: 28,...}
 final result = <int>[];
 for (int i = 1; i <= 12; i++) {
 final qv = v['q$i'] ?? v['Q$i'] ?? v['quarter$i'];
        if (qv == null) break;
        result.add(int.tryParse(qv.toString()) ?? 0);
      }
      return result;
    }
    if (v is num) return [v.toInt()];
    return const [];
  }
}
