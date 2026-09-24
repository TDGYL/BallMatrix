import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_basketball_quarter_model.dart';
import '../../models/bm_basketball_live_model.dart';
import '../../services/bm_match_detail_api_service.dart';
import '../../utils/bm_auth_manager.dart';
import '../login/bm_login_page.dart';
import 'bm_basketball_overview_tab.dart';
import 'bm_basketball_live_tab.dart';

/// BMBasketballDetailPage - basketballmatch detail page
/// feature: alignment basketball_match_detail.html effect
/// 1. top Hero scoreboard: statepill + home/away team Logo/name/score + Q1~Q4 per-quarter scoresheet + actualwhenWrateitems
/// 2. lowerdirectionmenuonlykeep 2 Tab: overview(overview) + live(playbyplay), iOS minsectionfilestyle
/// API: GET /api/livespeed/basketball/match/detail?match_id= (subscribe/event/minsectionscore)
/// architecture: MVVM View layer, one class per file, extends BMBasePage
class BMBasketballDetailPage extends BMBasePage {
 /// matchmodel (BMMatchModel type, listpage/homepassinput, includes matchId/teamname/scoreetc)
 final BMMatchModel match;

 const BMBasketballDetailPage({
 super.key,
 required this.match,
 });

 @override
 State<BMBasketballDetailPage> createState() => _BMBasketballDetailPageState();
}

class _BMBasketballDetailPageState extends BMBasePageState<BMBasketballDetailPage> {
 /// API Service singleton (matchdetailAPIservice)
 final BMMatchDetailApiService _apiService = BMMatchDetailApiService();

 /// eventloadingin (bool type)
 bool _loadingIncidents = true;

 /// whetheralreadysubscribe (bool type, GET detail -> subscribed field)
 bool _isSubscribed = false;

 /// home teamtotal (int? type, override Hero scoredisplay)
 int? _homeTotal;

 /// away teamtotal (int? type)
 int? _awayTotal;

 /// minsectionscore (BMBasketballQuarterScore type, Q1~Q4+AET)
 BMBasketballQuarterScore _quarters = const BMBasketballQuarterScore();

 /// detailraw data (Map<String,dynamic>? type, overview Tab statistics/trendfallbackusage)
 Map<String, dynamic>? _detailData;

 /// basketballtechnical stats (List<Map<String,dynamic>> type, process API data.stats)
 List<Map<String, dynamic>> _processStats = const [];

 /// livebysectiongroup (List<BMBasketballLivePeriod> type, process API data.tlive)
 List<BMBasketballLivePeriod> _livePeriods = const [];

 /// matchmodelcanchangecopythis (BMMatchModel type, detail returnslater refreshedWith refreshtopcard)
 late BMMatchModel _match;

 /// currentselected of Tab index (int type, 0=overview, 1=live)
 int _currentTabIndex = 0;

 @override
 void initState() {
 super.initState();
 _match = widget.match;
 final matchId = int.tryParse(widget.match.matchId) ?? 0;
 _fetchBasketballDetail(matchId);
 _fetchProcessData(matchId);
 }

 /// gettakebasketballdata (GET /api/livespeed/basketball/match/process)
 /// onetimetakeback: stats technical stats (overview Tab) + tlive bysectionlive (live Tab)
 /// [matchId] - basketball match ID (int type, required)
 Future<void> _fetchProcessData(int matchId) async {
 if (matchId == 0) return;
 final data = await _apiService.fetchBasketballProcess(matchId: matchId);
 if (!mounted || data == null) return;
 // parse stats
 final rawStats = data['stats'];
 final stats = rawStats is List
 ? rawStats.whereType<Map<String, dynamic>>().toList()
: const <Map<String, dynamic>>[];
 // parse tlive (bysectiongroup)
 final rawTlive = data['tlive'];
 final periods = <BMBasketballLivePeriod>[];
 if (rawTlive is List) {
 for (final p in rawTlive) {
 if (p is Map<String, dynamic>) {
 periods.add(BMBasketballLivePeriod.fromJson(p));
 }
 }
 }
 setState(() {
 if (stats.isNotEmpty) _processStats = stats;
 if (periods.isNotEmpty) _livePeriods = periods;
 });
 }

 /// gettakebasketball detail (GET /api/livespeed/basketball/match/detail?match_id=)
 /// onetimetakeback subscribestate + eventlist + actualwhentotal + minsectionscore
 /// [matchId] - basketball match ID (int type, required)
 Future<void> _fetchBasketballDetail(int matchId) async {
 if (matchId == 0) {
 if (!mounted) return;
 setState(() => _loadingIncidents = false);
 return;
 }
 final Map<String, dynamic>? data =
 await _apiService.fetchBasketballDetail(matchId: matchId);
 if (!mounted) return;
 bool subscribed = false;
 int? hTotal;
 int? aTotal;
 BMBasketballQuarterScore quarters = const BMBasketballQuarterScore();
 if (data != null) {
 subscribed = data['subscribed'] == true || data['is_subscribed'] == true;
 quarters = BMBasketballQuarterScore.fromDetailMap(data);
 if (quarters.hasData) {
 hTotal = quarters.homeTotal;
 aTotal = quarters.awayTotal;
 } else {
 // fallback: home_score/away_score singlevalueshapestyle
 final homeScoreMap = data['home_score'] ?? data['homeScores'];
        final awayScoreMap = data['away_score'] ?? data['awayScores'];
        if (homeScoreMap is Map) {
          final s = homeScoreMap['total'] ?? homeScoreMap['current'];
          if (s is num) hTotal = s.toInt();
        } else if (homeScoreMap is num) {
          hTotal = homeScoreMap.toInt();
        }
        if (awayScoreMap is Map) {
          final s = awayScoreMap['total'] ?? awayScoreMap['current'];
 if (s is num) aTotal = s.toInt();
 } else if (awayScoreMap is num) {
 aTotal = awayScoreMap.toInt();
 }
 }
 }
 setState(() {
 _isSubscribed = subscribed;
 _homeTotal = hTotal ?? widget.match.homeScore;
 _awayTotal = aTotal ?? widget.match.awayScore;
 _quarters = quarters;
 _detailData = data;
 // detail returnslatermergerefreshtopcard (team name/Logo/score/state/league, newvaluepriority)
 // manualspecified categoryId=2 (basketball), statedisplaybasketballbranchrule
 if (data != null) {
 _match = _match.refreshedWith(
 BMMatchModel.fromMap(data),
 categoryId: 2,
);
 }
 _loadingIncidents = false;
 });
 }

 /// switchfollowstate (not logged infirstjumploginpage)
 /// subscribe: POST /api/livespeed/basketball/match/subscribe data:{match_id}
 /// unsubscribe: POST /api/livespeed/basketball/match/unsubscribe data:{match_id}
 Future<void> _toggleSubscribe() async {
 if (!BMAuthManager().isLoggedIn) {
 final ok = await Navigator.push<bool>(
 context,
 MaterialPageRoute(builder: (_) => const BMLoginPage()),
);
 if (ok != true) return;
 }
 final matchId = int.tryParse(_match.matchId) ?? 0;
 if (matchId == 0) return;
 final willSub = !_isSubscribed;
 final bool success = willSub
 ? await _apiService.subscribeBasketballMatch(matchId: matchId)
: await _apiService.unsubscribeBasketballMatch(matchId: matchId);
 if (!mounted) return;
 if (success) {
 setState(() => _isSubscribed = willSub);
 }
 if (!mounted) return;
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(
 success
 ? (willSub ? 'followed' : 'Unfollowed')
              : 'operation failed, please retry',
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
),
 backgroundColor: BMColors.pitch800,
 duration: const Duration(milliseconds: 1200),
 behavior: SnackBarBehavior.floating,
),
);
 }

 // =========== UI: wholelayout ===========
 @override
 Widget buildBody(BuildContext context) {
 return Container(
 color: BMColors.pitch950,
 child: SafeArea(
 top: false,
 child: Column(
 children: [
 _buildNavBar(),
 Expanded(
 child: SingleChildScrollView(
 physics: const BouncingScrollPhysics(),
 padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
 child: Column(
 children: [
 _buildHeroScoreboard(),
 const SizedBox(height: 12),
 _buildSegmentedTabs(),
 const SizedBox(height: 12),
 if (_currentTabIndex == 0)
 BMBasketballOverviewTab(
 match: widget.match,
 quarters: _quarters,
 detailData: _detailData,
 processStats: _processStats,
 loading: _loadingIncidents,
)
 else
 BMBasketballLiveTab(
 periods: _livePeriods,
 homeName: _match.homeTeamName,
 awayName: _match.awayTeamName,
 matchId: int.tryParse(_match.matchId) ?? 0,
 statusId: _match.statusId,
 loading: _loadingIncidents,
),
 ],
),
),
),
 ],
),
),
);
 }

 /// estimatecalcleft sidestatepillwidth (forright sideplaceholder, league nametruecentercentercard)
 /// [isLive] - whetherin progress (bool type, LIVE whenmoreone 6px point)
 /// [label] - statetext (String type, e.g.: "LIVE 75'" / "FT")
 /// returns: double pillestimatewidth
 double _statusChipWidth(bool isLive, String label) {
 // textwidthestimatecalc: intext≈11px/text, textnumber≈6.2px/text (11px textNo.)
 double textWidth = 0;
 for (final ch in label.runes) {
 textWidth += ch > 0x2E7F ? 11.0: 6.2;
 }
 // padding horizontal 10*2 + border 1*2 + LIVE point 6+5
 final dot = isLive ? 11.0: 0.0;
 return textWidth + 20.0 + 2.0 + dot;
 }

 // =========== UI: topapp bar (returns + subscribe, user requirement: removemiddleleaguetitle) ===========
 Widget _buildNavBar() {
 return Container(
 padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
 color: BMColors.pitch950,
 child: Row(
 children: [
 GestureDetector(
 behavior: HitTestBehavior.opaque,
 onTap: () => Navigator.of(context).pop(),
 child: Container(
 width: 34,
 height: 34,
 margin: const EdgeInsets.only(left: 8),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: const Icon(Icons.arrow_back_ios_new,
 size: 16, color: BMColors.textPrimary),
),
),
 // center of app bartitle (basketball detail)
 const Expanded(
 child: Text(
 'Basketball Detail',
 textAlign: TextAlign.center,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(
 color: Colors.white,
 fontSize: 15,
 fontWeight: FontWeight.w800,
),
),
),
 GestureDetector(
 behavior: HitTestBehavior.opaque,
 onTap: _toggleSubscribe,
 child: Container(
 width: 34,
 height: 34,
 margin: const EdgeInsets.only(right: 8),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: Icon(
 _isSubscribed ? Icons.notifications: Icons.notifications_none,
 size: 18,
 color: _isSubscribed ? BMColors.bright: BMColors.textTertiary,
),
),
),
 ],
),
);
 }

 // =========== UI: Hero scoreboard (alignment html glass-panel-accent module) ===========
 Widget _buildHeroScoreboard() {
 final m = _match; // detail refreshlater of canchangemodelcopythis
 final homeName = m.homeTeamName.isNotEmpty ? m.homeTeamName: 'Home';
    final awayName = m.awayTeamName.isNotEmpty ? m.awayTeamName : 'Away';
 final statusLabel = m.displayStatusLabel;
 // basketballin progresscheck (statusId 2~9 in progresswhen, user requirementrule)
 final sid = m.statusId;
 final isLive = (sid != null && sid >= 2 && sid <= 9) ||
 (sid == null && m.status == BMMatchStatus.live);
 return Container(
 padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
 decoration: BoxDecoration(
 gradient: const LinearGradient(
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 colors: [Color(0xFF153B2F), Color(0xFF0B251C)],
),
 borderRadius: BorderRadius.circular(18),
 border: Border.all(color: BMColors.bright.withValues(alpha: 0.25)),
 boxShadow: [
 BoxShadow(
 color: BMColors.accent.withValues(alpha: 0.12),
 blurRadius: 16,
),
 ],
),
 child: Column(
 children: [
 // ---- No. 1 line: 【left】statepill + 【in】league name (vertically centered) ----
 // user requirement: league namecardin, andleftstatepillvertically centered
 Row(
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: isLive
 ? const Color(0xFFEF4444).withValues(alpha: 0.18)
: BMColors.pitch850,
 borderRadius: BorderRadius.circular(999),
 border: Border.all(
 color: isLive
 ? const Color(0xFFEF4444).withValues(alpha: 0.45)
: BMColors.pitch700,
),
),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 if (isLive)...[
 Container(
 width: 6,
 height: 6,
 margin: const EdgeInsets.only(right: 5),
 decoration: const BoxDecoration(
 color: Color(0xFFF87171),
 shape: BoxShape.circle,
),
),
 ],
 Text(
 statusLabel,
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w800,
 color: isLive ? const Color(0xFFF87171): BMColors.textSecondary,
),
),
 ],
),
),
 // league name: dataremainingemptyhorizontally centered, lineinnervertically centered, accent colorhighlight
 Expanded(
 child: Center(
 child: Text(
 m.leagueName,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 color: BMColors.bright, // accent color (bright green)
 fontSize: 12,
 fontWeight: FontWeight.w800,
),
),
),
),
 // placeholder: andleft sidestatepillmonospace, league nametruecentercentercard
 SizedBox(
 width: _statusChipWidth(isLive, statusLabel),
 height: 1,
),
 ],
),
 const SizedBox(height: 14),
 // ---- No. 2 line: home team Logo/name + middlelargescore + away team (html: Teams Score Display 7columngrid) ----
 Row(
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 Expanded(
 child: Column(
 children: [
 _buildTeamLogo(
 m.homeTeamLogo ?? m.homeTeam?.logoUrl,
 true,
),
 const SizedBox(height: 8),
 Text(
 homeName,
 textAlign: TextAlign.center,
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 color: BMColors.bright,
 fontSize: 14,
 fontWeight: FontWeight.w800,
 height: 1.2,
),
),
 ],
),
),
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 10),
 child: Column(
 children: [
 Text(
 _homeTotal == null ? '-' : _homeTotal.toString(),
                      style: const TextStyle(
                        color: BMColors.bright,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: BMColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      _awayTotal == null ? '-' : _awayTotal.toString(),
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        fontFamily: 'monospace',
),
),
 ],
),
),
 Expanded(
 child: Column(
 children: [
 _buildTeamLogo(
 m.awayTeamLogo ?? m.awayTeam?.logoUrl,
 false,
),
 const SizedBox(height: 8),
 Text(
 awayName,
 textAlign: TextAlign.center,
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 color: Color(0xFF3B82F6),
 fontSize: 14,
 fontWeight: FontWeight.w800,
 height: 1.2,
),
),
 ],
),
),
 ],
),
 // ---- No. 3 line: Q1~Q4(+AET) per-quarter scoresheet (html: Quarter Scores Matrix Table) ----
 if (_quarters.hasData)...[
 const SizedBox(height: 14),
 Container(
 padding: const EdgeInsets.only(top: 10),
 decoration: const BoxDecoration(
 border: Border(top: BorderSide(color: Color(0x33244739), width: 0.6)),
),
 child: _buildQuarterMatrix(),
),
 ],
 ],
),
);
 }

 /// minsectionscoresheet (tableheader: team Q1..Q4 total / linedata)
 Widget _buildQuarterMatrix() {
 final labels = _quarters.quarterLabels;
 final homeName = _match.homeTeamName.isNotEmpty
 ? _match.homeTeamName
: 'home team';
    final awayName = _match.awayTeamName.isNotEmpty
        ? _match.awayTeamName
        : 'away team';
    Widget cell(String text, {Color? color, bool bold = false, double fontSize = 11}) {
      return Expanded(
        child: Center(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color ?? BMColors.textSecondary,
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    }

    Widget row({
      required String name,
      required Color nameColor,
      required List<int> scores,
      required int total,
      required bool showTopDivider,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: showTopDivider
            ? const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0x2E244739), width: 0.5),
                ),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: nameColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...List.generate(labels.length, (i) {
              return cell(
                i < scores.length ? scores[i].toString() : '-',
);
 }),
 cell(
 total.toString(),
 color: nameColor,
 bold: true,
),
 ],
),
);
 }

 return Column(
 children: [
 // tableheader
 Row(
 children: [
 const Expanded(
 flex: 2,
 child: Text(
 'team',
                style: TextStyle(
                  color: BMColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...labels.map((l) => cell(l, color: BMColors.textTertiary, fontSize: 10)),
            const Expanded(
              child: Center(
                child: Text(
                  'total',
 style: TextStyle(
 color: BMColors.textPrimary,
 fontSize: 10,
 fontWeight: FontWeight.w800,
),
),
),
),
 ],
),
 row(
 name: homeName,
 nameColor: BMColors.bright,
 scores: _quarters.homeQuarters,
 total: _quarters.homeTotal,
 showTopDivider: false,
),
 row(
 name: awayName,
 nameColor: const Color(0xFF3B82F6),
 scores: _quarters.awayQuarters,
 total: _quarters.awayTotal,
 showTopDivider: true,
),
 ],
);
 }

 /// team Logo container (52x52 rounded corner, home teamedge/away teamblueedge, contentverticalhorizontally centered)
 /// [url] - Logo URL (String? type, asemptydisplaybasketballfallbackicon)
 /// [isHome] - is home team (bool type)
 Widget _buildTeamLogo(String? url, bool isHome) {
 final borderColor = isHome
 ? BMColors.bright.withValues(alpha: 0.6)
: const Color(0x4D3B82F6);
 final iconColor = isHome ? BMColors.bright: const Color(0xFF3B82F6);
 return Container(
 width: 52,
 height: 52,
 alignment: Alignment.center, // ⭐️ contentverticalhorizontally centered (fix Icon top-left corner)
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: borderColor, width: 1.2),
),
 child: ClipRRect(
 borderRadius: BorderRadius.circular(13),
 child: Center(
 child: (url == null || url.isEmpty)
 ? Icon(Icons.sports_basketball, size: 26, color: iconColor)
: Image.network(
 url,
 width: 40,
 height: 40,
 fit: BoxFit.contain,
 errorBuilder: (_, _, _) =>
 Icon(Icons.sports_basketball, size: 26, color: iconColor),
),
),
),
);
 }

 // =========== UI: iOS minsectionfile Tab (overview | live) ===========
 Widget _buildSegmentedTabs() {
 const tabs = ['overview', 'live'];
    const icons = [Icons.pie_chart_outline, Icons.format_list_numbered];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _currentTabIndex == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _currentTabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? BMColors.pitch800 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[i],
                      size: 13,
                      color: selected ? BMColors.bright : BMColors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? BMColors.bright : BMColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
