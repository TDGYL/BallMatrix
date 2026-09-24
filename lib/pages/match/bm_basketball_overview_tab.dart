import 'package:flutter/material.dart';

import '../../models/bm_match_model.dart';
import '../../models/bm_basketball_quarter_model.dart';
import '../../theme/bm_colors.dart';
import '../../widgets/match/bm_basketball_flow_chart_painter.dart';

/// BMBasketballOverviewTab - basketball detailpage「overview」Tab
/// alignment basketball_match_detail.html TAB 1: OVERVIEW effect
/// 1. thiscourt MVP correctcard (Leaders): home/away teamplayer 3 itemdatacompare
/// 2. match trend and min diff: eachsectionaccumulatemindiffstate (Chart.js line of Flutter implement)
/// 3. keytechnical statscompare: doubledirectioncompareitems (datadetailAPI stats, nonedatawhenshowminsectiongetmincompare)
/// architecture: StatelessWidget, one class per file
class BMBasketballOverviewTab extends StatelessWidget {
 /// matchmodel (BMMatchModel type)
 final BMMatchModel match;

 /// minsectionscore (BMBasketballQuarterScore type, trenddata source)
 final BMBasketballQuarterScore quarters;

 /// detailAPIraw data (Map<String,dynamic>? type, stats/leaders fallback)
 final Map<String, dynamic>? detailData;

 /// basketballtechnical stats (List<Map<String,dynamic>> type, process API data.stats, [{type,home,away,name}])
 final List<Map<String, dynamic>> processStats;

 /// dataloadingin (bool type)
 final bool loading;

 const BMBasketballOverviewTab({
 super.key,
 required this.match,
 required this.quarters,
 this.detailData,
 this.processStats = const [],
 this.loading = false,
 });

 // =========== UI: wholelayout (user requirement: removethiscourt MVP correctmodule) ===========
 @override
 Widget build(BuildContext context) {
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 _buildGameFlowCard(),
 const SizedBox(height: 12),
 _buildStatsCompareCard(),
 ],
);
 }

 // =========== 1. match trend and min diff (Game Flow, html: Chart.js gameFlowChart) ===========
 Widget _buildGameFlowCard() {
 return Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: BMColors.pitch900.withValues(alpha: 0.85),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.7)),
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 const Row(
 children: [
 Icon(Icons.show_chart, size: 13, color: BMColors.bright),
 SizedBox(width: 5),
 Text(
 'match trend and min diff',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BMColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Text(
                'full court score change',
 style: TextStyle(fontSize: 10, color: BMColors.textTertiary),
),
 ],
),
 const SizedBox(height: 12),
 _buildFlowChart(),
 ],
),
);
 }

 /// mindifftrendpolyline (alignment html: <canvas id="gameFlowChart"> doublecurvemindiff)
 /// data: home_scores/away_scores eachsectionaccumulatemindiff, home teambright greenpoint / away teambluenonepoint
 Widget _buildFlowChart() {
 if (!quarters.hasData) {
 return const Padding(
 padding: EdgeInsets.symmetric(vertical: 24),
 child: Center(
 child: Text(
 'No per-quarter scoredata',
 style: TextStyle(color: BMColors.textTertiary, fontSize: 11),
),
),
);
 }
 const homeColor = BMColors.bright;
 const awayColor = Color(0xFF3B82F6);
 // per-quarter cumulative diff series (html: data: [0, -2, 3, 5, 2, -1, 2, 4] samestruct)
 final homeDiffs = _cumulativeDiffs(isHome: true);
 final awayDiffs = homeDiffs.map((d) => -d).toList();
 final labels = _flowLabels();
 return Column(
 children: [
 // tablecanvas (html: h-40)
 SizedBox(
 height: 160,
 width: double.infinity,
 child: CustomPaint(
 painter: BMBasketballFlowChartPainter(
 homeDiffs: homeDiffs,
 awayDiffs: awayDiffs,
 homeColor: homeColor,
 awayColor: awayColor,
),
),
),
 const SizedBox(height: 6),
 // bottomsectiontag (html: Q1 Q2 Q3 Q4(current), lateronesectionaccent colorhighlight)
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 8),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: List.generate(labels.length, (i) {
 final isLast = i == labels.length - 1;
 return Text(
 labels[i],
 style: TextStyle(
 fontSize: 10,
 fontFamily: 'monospace',
 fontWeight: isLast ? FontWeight.w800: FontWeight.w500,
 color: isLast ? BMColors.bright: BMColors.textTertiary,
),
);
 }),
),
),
 const SizedBox(height: 10),
 // example (html legend notdisplay, color block+team name)
 Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 _flowLegend(homeColor, match.homeTeamName),
 const SizedBox(width: 14),
 _flowLegend(awayColor, match.awayTeamName),
 ],
),
 ],
);
 }

 /// computesinglesideper-quarter cumulative diff series
 /// [isHome] - is home team (bool type)
 /// returns: List<int> e.g.: home 23,21 vs away 18,25 → [5, 1]
 List<int> _cumulativeDiffs({required bool isHome}) {
 final mine = isHome ? quarters.homeQuarters: quarters.awayQuarters;
 final other = isHome ? quarters.awayQuarters: quarters.homeQuarters;
 final n = mine.length > other.length ? mine.length: other.length;
 int accMine = 0;
 int accOther = 0;
 final result = <int>[];
 for (int i = 0; i < n; i++) {
 accMine += i < mine.length ? mine[i]: 0;
 accOther += i < other.length ? other[i]: 0;
 result.add(accMine - accOther);
 }
 return result;
 }

 /// trendbottomsectiontaglist (String type, Q1..Q4 + OT, sectiondisplay "Q4 (current)")
  List<String> _flowLabels() {
    final labels = quarters.quarterLabels;
    if (labels.isEmpty) return const [];
    final last = labels.length - 1;
    return [
      for (int i = 0; i < labels.length; i++)
        i == last ? '${labels[i]} (current)': labels[i],
 ];
 }

 /// trendexample (color block + team name)
 Widget _flowLegend(Color color, String name) {
 return Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Container(
 width: 9,
 height: 9,
 decoration: BoxDecoration(
 color: color.withValues(alpha: 0.85),
 borderRadius: BorderRadius.circular(2),
),
),
 const SizedBox(width: 4),
 Text(
 name,
 style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.95)),
),
 ],
);
 }

 // =========== 3. keytechnical statscompare (Stat Bars) ===========
 Widget _buildStatsCompareCard() {
 final statRows = _readStatRows();
 return Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: BMColors.pitch900.withValues(alpha: 0.85),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.7)),
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Container(
 padding: const EdgeInsets.only(bottom: 10),
 decoration: const BoxDecoration(
 border: Border(bottom: BorderSide(color: Color(0x33244739), width: 0.6)),
),
 child: const Row(
 children: [
 Icon(Icons.tune, size: 13, color: BMColors.bright),
 SizedBox(width: 5),
 Text(
 'keytechnical statscompare',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: BMColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (statRows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No technical statsdata',
 style: TextStyle(color: BMColors.textTertiary, fontSize: 11),
),
),
)
 else
...statRows.map((r) => _buildStatBar(r)),
 ],
),
);
 }

 /// readtechnical statsline (priority level: process API stats > detail data.stats)
 /// process API: GET /api/livespeed/basketball/match/process -> data.stats [{type,home,away,name}]
 /// returns: List<_StatPair> (homevalue/tag/awayvalue)
 List<_StatPair> _readStatRows() {
 final rows = <_StatPair>[];
 // 1. priority: process API stats
 for (final s in processStats) {
 final name = s['name'];
      if (name == null || name.toString().isEmpty) continue;
      rows.add(_StatPair(
        home: _statValueText(s['home']),
        label: name.toString(),
        away: _statValueText(s['away']),
));
 }
 // 2. fallback: detail data of stats
 if (rows.isEmpty && detailData != null) {
 final rawStats = detailData!['stats'] ?? detailData!['statistics'];
      if (rawStats is List) {
        for (final s in rawStats) {
          if (s is Map) {
            final label = s['label'] ?? s['name'];
            if (label == null) continue;
            rows.add(_StatPair(
              home: _statValueText(s['home']),
              label: label.toString(),
              away: _statValueText(s['away']),
));
 }
 }
 }
 }
 return rows;
 }

 /// statisticsvalueconvertshowtext (null→'-', num→smallcountpointzero)
 /// [v] - rawvalue (dynamic type, num/String/null)
 /// returns: String showtext
 String _statValueText(dynamic v) {
 if (v == null) return '-';
    if (v is num) {
      return v.toInt() == v ? v.toInt().toString() : v.toString();
    }
    final s = v.toString();
    return s.isEmpty ? '-': s;
 }

 /// singledoubledirectioncompareitems (html: Stat Bar, homeleftbright green awayrightblue)
 /// [row] - statisticsitem (StatPair type)
 Widget _buildStatBar(_StatPair row) {
 final homeNum = double.tryParse(row.home);
 final awayNum = double.tryParse(row.away);
 // home/awayshare (valueillegalwhen 50:50)
 double homeRatio = 0.5;
 if (homeNum != null && awayNum != null) {
 final sum = homeNum + awayNum;
 homeRatio = sum > 0 ? homeNum / sum: 0.5;
 }
 return Padding(
 padding: const EdgeInsets.only(bottom: 12),
 child: Column(
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(
 row.home,
 style: const TextStyle(
 fontSize: 11,
 fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  color: BMColors.bright,
                ),
              ),
              Text(
                row.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: BMColors.textSecondary,
                ),
              ),
              Text(
                row.away,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
 fontWeight: FontWeight.w800,
 color: Color(0xFF3B82F6),
),
),
 ],
),
 const SizedBox(height: 4),
 SizedBox(
 height: 6,
 child: Row(
 children: [
 Expanded(
 flex: (homeRatio * 1000).round().clamp(1, 999),
 child: Container(
 decoration: BoxDecoration(
 color: BMColors.bright.withValues(alpha: 0.85),
 borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
),
),
),
 Expanded(
 flex: ((1 - homeRatio) * 1000).round().clamp(1, 999),
 child: Container(
 decoration: BoxDecoration(
 color: const Color(0xFF3B82F6).withValues(alpha: 0.85),
 borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
),
),
),
 ],
),
),
 ],
),
);
 }
}

/// _StatPair - singlestatisticscompareitem (privateauxiliaryclass)
class _StatPair {
 /// home teamvalue (String type)
 final String home;

 /// statisticstag (String type, e.g.: 'baskethit inrate')
 final String label;

 /// away teamvalue (String type)
 final String away;

 _StatPair({required this.home, required this.label, required this.away});
}
