import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_process_model.dart';
import '../../models/bm_odds_model.dart';
import '../../models/bm_h2h_model.dart';
import '../../models/bm_lineup_model.dart';
import '../../models/bm_player_info_model.dart';
import '../../models/bm_team_info_model.dart';
import '../../services/bm_match_detail_api_service.dart';
import '../../utils/bm_auth_manager.dart';
import '../login/bm_login_page.dart';
import 'bm_odds_history_page.dart';

/// BMFootballDetailTab - detail Tab enum (event / lineup / index / encounters)
enum BMFootballDetailTab {
 /// matchevent / Live Timeline + toptechnical stats
 live,
 /// starterlineup / Lineup
 lineup,
 /// indexodds / Odds (AH/1X2/O/U/Corners)
 odds,
 /// historyencounters / H2H
 h2h,
}

/// BMFootballDetailPage - footballmatch detail page
/// feature/API 1:1 reference hanklive MatchDetailPage (APIpathcompletefullsame, heightimplement)
/// differentiation UI (vs purplehanklive):
/// - theme: dark green pitch900/pitch850/pitch700 (swap violet50/violet700)
/// - AppBar: square rounded cornerreturns + league namepill(bright green12%+1.2pxstroke, andtopicpagepost buttonsamestyle) vs purplecircle+violet100
/// - Scoreboard: changedark greenbackground + bright green LIVE tag vs whitecard
/// - TabBar: scrollstylepill Tab(BouncingScrollPhysics) + selectedbright greenactualpill, unselectedin pitch800 text
/// - eventlist: homesidebright greencolor block/awaysidedaybluecolor block(vs purpleeventpoint)
/// - index Odds Tab: 4itemspilltypesection (vs hanklive list)
/// - H2H Tab: singlecard pitch850, tap push matchlistpage
/// architecture: one class per file, extends BMBasePage
class BMFootballDetailPage extends BMBasePage {
 /// matchmodel (BMMatchModel type, listpage/homepass)
 final BMMatchModel match;

 const BMFootballDetailPage({
 super.key,
 required this.match,
 });

 @override
 State<BMFootballDetailPage> createState() => _BMFootballDetailPageState();
}

class _BMFootballDetailPageState extends BMBasePageState<BMFootballDetailPage> {
 /// currentselected Tab (BMFootballDetailTab type)
 BMFootballDetailTab _currentTab = BMFootballDetailTab.live;

 /// API Service (matchdetailAPI，pathandhanklive 100%same)
 final BMMatchDetailApiService _apiService = BMMatchDetailApiService();

 /// match (incidentsevent + statsstatistics, reuse)
 BMProcessData? _processData;

 /// loading or not /event
 bool _loadingProcess = true;

 /// indexdata (4kindhandicap)
 BMOddsData? _oddsData;

 /// loading or not Odds
 bool _loadingOdds = false;

 /// home teamrecentencounterslist
 List<BMH2HMatch> _h2hHomeList = [];

 /// away teamrecentencounterslist
 List<BMH2HMatch> _h2hAwayList = [];

 /// loading or not H2H
 bool _loadingH2H = false;

 /// whetheralreadyloading H2H (lazy load)
 bool _fetchedH2H = false;

 // ======== H2H home teamsectionfilterdevice ========
 /// home teamrecent match - displaycountlimitmake (10 / 6)
 int _h2hHomeLimit = 10;
 /// home teamrecent match - whetheronlykeep currenthome teamyes home and currentaway teamyes away (samehome/away)
 bool _h2hHomeSameSide = false;
 /// home teamrecent match - whetheronlykeepleague (filtercup name includes cup/Cup)
 bool _h2hHomeLeagueOnly = false;

 // ======== H2H away teamsectionfilterdevice ========
 /// away teamrecent match - displaycountlimitmake (10 / 6)
 int _h2hAwayLimit = 10;
 /// away teamrecent match - whetheronlykeepsamehome/awayside
 bool _h2hAwaySameSide = false;
 /// away teamrecent match - whetheronlykeepleague
 bool _h2hAwayLeagueOnly = false;

 /// lineupdata (lineup)
 BMLineupData? _lineupData;

 /// loading or not lineup
 bool _loadingLineup = false;

 /// whetheralreadyloading lineup (lazy load)
 bool _fetchedLineup = false;

 /// whetheralreadysubscribe (bool, GET match.detail -> subscribed field)
 bool _isSubscribed = false;

 /// matchmodelcanchangecopythis (BMMatchModel type, detail returnslater refreshedWith refreshtopcard)
 late BMMatchModel _match;

 @override
 void initState() {
 super.initState();
 _match = widget.match;
 final matchId = int.tryParse(widget.match.matchId) ?? 0;
 _fetchMatchDetail(matchId);
 _fetchProcess(matchId);
 }

 /// gettakesubscribestate + refreshtopcard
 Future<void> _fetchMatchDetail(int matchId) async {
 if (matchId == 0) return;
 final Map<String, dynamic>? data = await _apiService.fetchMatchDetail(matchId: matchId);
 if (!mounted || data == null) return;
 setState(() {
 _isSubscribed = data['subscribed'] == true;
 // detail returnslatermergerefreshtopcard (team name/Logo/score/state/league, newvaluepriority)
 // manualspecified categoryId=1 (football), statedisplayfootballbranchrule
 _match = _match.refreshedWith(
 BMMatchModel.fromMap(data),
 categoryId: 1,
);
 });
 }

 /// gettakematch(event+statistics)
 Future<void> _fetchProcess(int matchId) async {
 final d = matchId == 0 ? null: await _apiService.fetchMatchProcess(matchId: matchId);
 if (!mounted) return;
 setState(() {
 _processData = d;
 _loadingProcess = false;
 });
 }

 /// switchfollow (not logged infirstlogin)
 /// subscribe: POST /api/livespeed/football/match/subscribe data:{match_id}
 /// unsubscribe: POST /api/livespeed/football/match/unsubscribe data:{match_id}
 Future<void> _toggleSubscribe() async {
 if (!BMAuthManager().isLoggedIn) {
 final ok = await Navigator.push<bool>(
 context,
 MaterialPageRoute(builder: (_) => const BMLoginPage()),
);
 if (ok != true) return;
 }
 final matchId = int.tryParse(widget.match.matchId) ?? 0;
 if (matchId == 0) return;
 final willSub = !_isSubscribed;
 final bool success = willSub
 ? await _apiService.subscribeFootballMatch(matchId: matchId)
: await _apiService.unsubscribeFootballMatch(matchId: matchId);
 if (!mounted) return;
 if (success) {
 setState(() => _isSubscribed = willSub);
 _snack(willSub ? 'followed' : 'Unfollowed');
    } else {
      _snack('operation failed, please retry');
 }
 }

 /// lazy loadindex
 Future<void> _ensureOdds() async {
 if (_oddsData != null || _loadingOdds) return;
 final matchId = int.tryParse(widget.match.matchId) ?? 0;
 if (matchId == 0) return;
 setState(() => _loadingOdds = true);
 final d = await _apiService.fetchMatchOdds(matchId: matchId);
 if (!mounted) return;
 setState(() {
 _oddsData = d;
 _loadingOdds = false;
 });
 }

 /// lazy load H2H (splithome team/away teamsection)
 Future<void> _ensureH2H() async {
 if (_fetchedH2H || _loadingH2H) return;
 final matchId = int.tryParse(widget.match.matchId) ?? 0;
 if (matchId == 0) return;
 setState(() => _loadingH2H = true);
 final splited = await _apiService.fetchH2HSplitedData(matchId: matchId);
 if (!mounted) return;
 setState(() {
 _h2hHomeList = splited['home'] ?? [];
      _h2hAwayList = splited['away'] ?? [];
 // compatiblefallback：likeresultAPInohas home/away field，has vs，take vs Dequally divided/mergetotwolistfallbackdisplay
 if (_h2hHomeList.isEmpty && _h2hAwayList.isEmpty) {
 final vs = splited['vs'] ?? [];
 _h2hHomeList = vs;
 _h2hAwayList = vs;
 }
 _loadingH2H = false;
 _fetchedH2H = true;
 });
 }

 /// lazy load lineup Lineup
 Future<void> _ensureLineup() async {
 if (_fetchedLineup || _loadingLineup) return;
 final matchId = int.tryParse(widget.match.matchId) ?? 0;
 if (matchId == 0) return;
 setState(() => _loadingLineup = true);
 final BMLineupData? data = await _apiService.fetchMatchLineup(matchId: matchId);
 if (!mounted) return;
 setState(() {
 _lineupData = data;
 _loadingLineup = false;
 _fetchedLineup = true;
 });
 }

 /// indexhistorynavigate (completefullreference hanklive odds_history_page - newinput: BMCompanyOdds levelobject)
 void _gotoOddsHistory(BMCompanyOdds company) {
 Navigator.push(
 context,
 MaterialPageRoute(
 builder: (_) => BMOddsHistoryPage(
 matchId: int.tryParse(widget.match.matchId) ?? 0,
 companyId: company.companyId,
 companyName: company.companyName ?? '',
 oddsType: _oddsSel,
),
),
);
 }

 @override
 Widget buildBody(BuildContext context) {
 return Scaffold(
 backgroundColor: BMColors.pitch900,
 body: Column(
 children: [
 _buildAppBar(),
 Expanded(
 child: SingleChildScrollView(
 physics: const AlwaysScrollableScrollPhysics(),
 child: Column(
 children: [
 _buildScoreboard(),
 _buildTabBar(),
 _buildTabContent(),
 const SizedBox(height: 20),
 ],
),
),
),
 ],
),
);
 }

 // ==================== AppBar ====================

 Widget _buildAppBar() {
 return Container(
 padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
 decoration: BoxDecoration(
 color: BMColors.pitch900,
 border: Border(bottom: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.3), width: 0.5)),
),
 child: SafeArea(
 bottom: false,
 child: Row(
 children: [
 GestureDetector(
 onTap: () => Navigator.pop(context),
 behavior: HitTestBehavior.opaque,
 child: Container(
 width: 34,
 height: 34,
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 child: const Icon(Icons.chevron_left, size: 18, color: Colors.white),
),
),
 const SizedBox(width: 12),
 // center of app bartitle (football detail)
 const Expanded(
 child: Text(
 'Football Detail',
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
 const SizedBox(width: 12),
 GestureDetector(
 onTap: _toggleSubscribe,
 behavior: HitTestBehavior.opaque,
 child: SizedBox(
 width: 34,
 height: 34,
 child: Icon(
 _isSubscribed ? Icons.notifications: Icons.notifications_outlined,
 size: 22,
 color: _isSubscribed ? BMColors.bright: BMColors.textSecondary,
),
),
),
 ],
),
),
);
 }

 // ==================== Scoreboard scoreboard ====================

 Widget _buildScoreboard() {
 final m = _match; // detail refreshlater of canchangemodelcopythis
 final homeLogo = m.homeTeamLogo ?? m.homeTeam?.logoUrl;
 final awayLogo = m.awayTeamLogo ?? m.awayTeam?.logoUrl;
 final homeName = m.homeTeamName.isNotEmpty
 ? m.homeTeamName
: m.homeTeam?.teamName ?? 'home team';
    final awayName = m.awayTeamName.isNotEmpty
        ? m.awayTeamName
        : m.awayTeam?.teamName ?? 'away team';
 final statusLabel = m.displayStatusLabel;
 final bool live = m.status == BMMatchStatus.live;
 final leagueName = m.leagueName;
 return Container(
 margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
 padding: const EdgeInsets.fromLTRB(14, 10, 12, 16), // right padding change as 12 (user requirementleague namedistanceright12px)
 decoration: BoxDecoration(
 gradient: const LinearGradient(
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 colors: [Color(0xFF153B2F), Color(0xFF0B251C)],
),
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6), width: 0.6),
 boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 4))],
),
 child: Column(
 children: [
 // ========================================
 // No. 1 line: 【in】 leaguepill (horizontally centereddisplay)
 // user requirement: topleaguehorizontally centered (originalasright aligned, distanceright 12px)
 // ========================================
 Row(
 mainAxisAlignment: MainAxisAlignment.center, // horizontally centered
 children: [
 Expanded(
 child: Container(
 alignment: Alignment.center,
 decoration: const BoxDecoration(
 color: Colors.transparent, // pillbackgroundtomorrow
),
 child: Text(
 leagueName,
 maxLines: 2,
 textAlign: TextAlign.center,
 softWrap: true,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 fontSize: 11,
 color: BMColors.bright,
 fontWeight: FontWeight.w700,
 height: 1.2,
),
),
),
),
 ],
),
 const SizedBox(height: 8),
 // No. 2 line: 【home teamcolumn】+【middle: statetimefile(scoreupperdirection) + scoredisplay】+【away teamcolumn】
 // user requirement: takescoreupperplane of statetimefile (original of LIVE 75' pill) scoredisplay of upperdirection
 Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // home team: left aligned + Flex 5
 Expanded(
 flex: 5,
 child: () {
 // compatible 2 kind teamId take: ① top level homeTeamId (alignment hanklive BMMatchModel newfield) ② homeTeam.teamId String (structure)
 final idFromTop = m.homeTeamId;
 final idFromTeam = m.homeTeam?.teamId;
 int? teamId;
 if (idFromTop != null && idFromTop != 0) {
 teamId = idFromTop;
 } else if (idFromTeam != null && idFromTeam.isNotEmpty) {
 teamId = int.tryParse(idFromTeam);
 }
 return GestureDetector(
 onTap: () {
 final tId = teamId;
 if (tId == null || tId <= 0) return;
 _showTeamInfoSheet(
 teamId: tId,
 fallbackName: homeName,
 fallbackLogo: homeLogo,
 isHome: true,
);
 },
 behavior: HitTestBehavior.opaque,
 child: _teamHomeColumn(homeLogo, homeName),
);
 }(),
),
 // middlescorezone: Flex 4 center, scoreupperdirectionstatetimefile (user requirement)
 Expanded(
 flex: 4,
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
 decoration: BoxDecoration(
 color: live
 ? BMColors.bright.withValues(alpha: 0.16)
: BMColors.pitch800,
 borderRadius: BorderRadius.circular(999),
 border: Border.all(
 color: live ? BMColors.bright.withValues(alpha: 0.55): BMColors.pitch700,
),
),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 if (live)...[
 Container(width: 6, height: 6, decoration: const BoxDecoration(color: BMColors.bright, shape: BoxShape.circle)),
 const SizedBox(width: 5),
 ],
 Text(
 statusLabel,
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.w800,
 color: live ? BMColors.bright: BMColors.textSecondary,
 letterSpacing: 0.4,
),
),
 ],
),
),
 const SizedBox(height: 10),
 // scoredisplay (statefilelowerdirection, user requirement: file"scoreupperplane" → fileupper, scorelower)
 Row(
 mainAxisAlignment: MainAxisAlignment.center,
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 Text(
 m.homeScore?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: BMColors.bright,
                            height: 1.05,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(':', style: TextStyle(fontSize: 22, color: Color(0xFF6B7280), fontWeight: FontWeight.w900)),
                        ),
                        Text(
                          m.awayScore?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3B82F6),
                            height: 1.05,
                            fontFamily: 'monospace',
),
),
 ],
),
 ],
),
),
 // away team: right aligned + Flex 5
 Expanded(
 flex: 5,
 child: () {
 final idFromTop = m.awayTeamId;
 final idFromTeam = m.awayTeam?.teamId;
 int? teamId;
 if (idFromTop != null && idFromTop != 0) {
 teamId = idFromTop;
 } else if (idFromTeam != null && idFromTeam.isNotEmpty) {
 teamId = int.tryParse(idFromTeam);
 }
 return GestureDetector(
 onTap: () {
 final tId = teamId;
 if (tId == null || tId <= 0) return;
 _showTeamInfoSheet(
 teamId: tId,
 fallbackName: awayName,
 fallbackLogo: awayLogo,
 isHome: false,
);
 },
 behavior: HitTestBehavior.opaque,
 child: _teamAwayColumn(awayLogo, awayName),
);
 }(),
),
 ],
),
 const SizedBox(height: 12),
 ],
),
);
 }

 /// home teamteamcolumn: Logo + nametext, left sidealignment
 Widget _teamHomeColumn(String? logo, String name) {
 return Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Align(
 alignment: Alignment.centerLeft,
 child: Container(
 width: 46,
 height: 46,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 shape: BoxShape.circle,
 border: Border.all(color: BMColors.bright.withValues(alpha: 0.45), width: 1.1),
 boxShadow: [
 BoxShadow(
 color: BMColors.bright.withValues(alpha: 0.12),
 blurRadius: 8,
 offset: const Offset(0, 2),
),
 ],
),
 clipBehavior: Clip.antiAlias,
 alignment: Alignment.center,
 child: (logo != null && logo.isNotEmpty)
 ? Image.network(
 logo,
 fit: BoxFit.contain,
 errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 22, color: BMColors.bright),
)
: const Icon(Icons.sports_soccer, size: 22, color: BMColors.bright),
),
),
 const SizedBox(height: 7),
 Text(
 name,
 maxLines: 3,
 softWrap: true,
 overflow: TextOverflow.visible,
 textAlign: TextAlign.left,
 style: const TextStyle(
 color: BMColors.bright,
 fontSize: 13,
 height: 1.25,
 fontWeight: FontWeight.w800,
 letterSpacing: 0.3,
),
),
 ],
);
 }

 /// away teamteamcolumn: Logo + nametext, **right sidegridalignment** (user requirementpoint)
 Widget _teamAwayColumn(String? logo, String name) {
 return Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 Align(
 alignment: Alignment.centerRight,
 child: Container(
 width: 46,
 height: 46,
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 shape: BoxShape.circle,
 border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.45), width: 1.1),
 boxShadow: [
 BoxShadow(
 color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
 blurRadius: 8,
 offset: const Offset(0, 2),
),
 ],
),
 clipBehavior: Clip.antiAlias,
 alignment: Alignment.center,
 child: (logo != null && logo.isNotEmpty)
 ? Image.network(
 logo,
 fit: BoxFit.contain,
 errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 22, color: Color(0xFF3B82F6)),
)
: const Icon(Icons.sports_soccer, size: 22, color: Color(0xFF3B82F6)),
),
),
 const SizedBox(height: 7),
 Text(
 name,
 maxLines: 3,
 softWrap: true,
 overflow: TextOverflow.visible,
 textAlign: TextAlign.right,
 style: const TextStyle(
 color: Color(0xFF3B82F6),
 fontSize: 13,
 height: 1.25,
 fontWeight: FontWeight.w800,
 letterSpacing: 0.3,
),
),
 ],
);
 }

 // =========== teaminfo Bottom Sheet (taptopteamavatarpop, user requirement) ===========

 /// core: pop Bottom Sheet + asyncrequest GET /api/livespeed/football/team/data?team_id=
 void _showTeamInfoSheet({
 required int teamId,
 required String fallbackName,
 String? fallbackLogo,
 required bool isHome,
 }) {
 if (teamId <= 0) return;
 final sideColor = isHome ? BMColors.bright: const Color(0xFF3B82F6);
 final loadingVN = ValueNotifier<bool>(true);
 final infoVN = ValueNotifier<BMTeamInfo?>(null);
 showModalBottomSheet(
 context: context,
 isScrollControlled: true,
 backgroundColor: Colors.transparent,
 barrierColor: Colors.black.withValues(alpha: 0.55),
 builder: (_) {
 Future.microtask(() async {
 final info = await BMMatchDetailApiService().fetchTeamData(teamId: teamId);
 loadingVN.value = false;
 infoVN.value = info;
 });
 return ValueListenableBuilder<bool>(
 valueListenable: loadingVN,
 builder: (_, loading, __) {
 return ValueListenableBuilder<BMTeamInfo?>(
 valueListenable: infoVN,
 builder: (_, info, ___) {
 return Container(
 constraints: BoxConstraints(
 maxHeight: MediaQuery.of(context).size.height * 0.68,
),
 padding: EdgeInsets.only(
 left: 14,
 right: 14,
 top: 12,
 bottom: 14 + MediaQuery.of(context).padding.bottom,
),
 decoration: BoxDecoration(
 color: BMColors.pitch900,
 borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 // topdrag
 Container(
 width: 38,
 height: 4,
 decoration: BoxDecoration(
 color: BMColors.pitch700,
 borderRadius: BorderRadius.circular(4),
),
),
 const SizedBox(height: 14),
 // title row: icon + teaminfotext + home/awaysmallcolorpoint
 Row(
 children: [
 Icon(Icons.shield_rounded, size: 15, color: sideColor),
 const SizedBox(width: 6),
 const Text(
 'teaminfo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: BMColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: sideColor, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(
                            isHome ? 'home team' : 'away team',
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.w700,
 color: sideColor,
),
),
 ],
),
 const SizedBox(height: 14),
 if (loading)
 Padding(
 padding: const EdgeInsets.symmetric(vertical: 24),
 child: Center(
 child: SizedBox(
 width: 22,
 height: 22,
 child: CircularProgressIndicator(
 strokeWidth: 2.2,
 valueColor: AlwaysStoppedAnimation<Color>(sideColor),
),
),
),
)
 else if (info == null)
 _teamSheetEmpty(fallbackName, sideColor)
 else
 Flexible(
 child: SingleChildScrollView(
 physics: const BouncingScrollPhysics(),
 child: _teamSheetContent(info, sideColor, fallbackName, fallbackLogo),
),
),
 const SizedBox(height: 12),
 ],
),
);
 },
);
 },
);
 },
);
 }

 /// teamemptystate (request failure/nonedata)
 Widget _teamSheetEmpty(String fallbackName, Color sideColor) {
 return Container(
 margin: const EdgeInsets.symmetric(vertical: 12),
 padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(12),
),
 child: Column(
 children: [
 Icon(Icons.holiday_village, size: 30, color: sideColor.withValues(alpha: 0.75)),
 const SizedBox(height: 8),
 Text(
 'No  $fallbackName of detail info',
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w600,
 color: BMColors.textTertiary,
),
),
 ],
),
);
 }

 /// teamdatastate (2 sectioncard: tophomeinfocard + 2column6linedetail infocard)
 Widget _teamSheetContent(BMTeamInfo info, Color sideColor, String fbName, String? fbLogo) {
 final name = (info.name?.isNotEmpty ?? false) ? info.name!: fbName;
 final logo = (info.logo?.isNotEmpty ?? false) ? info.logo!: fbLogo;
 return Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 // ========== card 1: tophomeinfo (Logo 66x66 + team name + league + country + subscribestate) ==========
 Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: sideColor.withValues(alpha: 0.28)),
),
 child: Row(
 children: [
 // team Logo 66x66 
 Container(
 width: 66,
 height: 66,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: BMColors.pitch700.withValues(alpha: 0.7),
 border: Border.all(color: sideColor.withValues(alpha: 0.45), width: 1.1),
),
 clipBehavior: Clip.antiAlias,
 child: (logo != null && logo.isNotEmpty)
 ? Padding(
 padding: const EdgeInsets.all(8),
 child: Image.network(
 logo,
 fit: BoxFit.contain,
 errorBuilder: (_, __, ___) =>
 Icon(Icons.shield_rounded, size: 28, color: sideColor),
),
)
: Center(
 child: Icon(Icons.shield_rounded, size: 32, color: sideColor),
),
),
 const SizedBox(width: 14),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // team name + subscribestate(top-right corner)
 Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Flexible(
 child: Text(
 name,
 maxLines: 2,
 softWrap: true,
 style: const TextStyle(
 fontSize: 16,
 fontWeight: FontWeight.w900,
 color: BMColors.textPrimary,
 height: 1.15,
),
),
),
 if (info.isSubscribe == true)...[
 const SizedBox(width: 8),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: sideColor.withValues(alpha: 0.16),
 borderRadius: BorderRadius.circular(999),
 border: Border.all(color: sideColor.withValues(alpha: 0.5)),
),
 child: Icon(Icons.star_rounded, size: 11, color: sideColor),
),
 ],
 ],
),
 const SizedBox(height: 8),
 // league + /country
 Wrap(
 spacing: 8,
 runSpacing: 6,
 crossAxisAlignment: WrapCrossAlignment.center,
 children: [
 if (info.competitionName?.isNotEmpty ?? false)
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
 decoration: BoxDecoration(
 color: sideColor.withValues(alpha: 0.14),
 borderRadius: BorderRadius.circular(6),
),
 child: Text(
 info.competitionName!,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 10.5,
 fontWeight: FontWeight.w700,
 color: sideColor,
),
),
),
 if (info.countryName?.isNotEmpty ?? false)
 Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 if (info.countryLogo?.isNotEmpty ?? false)
 Padding(
 padding: const EdgeInsets.only(right: 5),
 child: ClipRRect(
 borderRadius: BorderRadius.circular(2),
 child: Image.network(
 info.countryLogo!,
 width: 16,
 height: 12,
 fit: BoxFit.cover,
 errorBuilder: (_, __, ___) =>
 const SizedBox(width: 0, height: 0),
),
),
),
 Flexible(
 child: Text(
 info.countryName!,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w600,
 color: BMColors.textSecondary,
),
),
),
 ],
),
 ],
),
 ],
),
),
 ],
),
),
 const SizedBox(height: 12),
 // ========== card 2: 2column6field detail info (format/ballcourt/capacity/coach/market value/official site) ==========
 Container(
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: Column(
 children: [
 _teamInfoRow(Icons.cake, 'format', info.foundationLabel, Icons.stadium, 'homecourt', info.venueName ?? '-'),
              _teamInfoDivider(),
              _teamInfoRow(Icons.chair_alt, 'capacity', info.venueCapacityLabel, Icons.people, 'coach', info.managerName ?? '-',
                  managerLogo: info.managerLogo),
              _teamInfoDivider(),
              _teamInfoRow(Icons.euro_symbol, 'market value', info.marketValueLabel, Icons.public, 'official site',
                  (info.website != null && info.website!.isNotEmpty) ? _shortUrl(info.website!) : '-'),
 ],
),
),
 ],
);
 }

 /// URL show: http://www.mcfc.co.uk/ → mcfc.co.uk
 static String _shortUrl(String url) {
 try {
 final u = Uri.parse(url);
 String host = u.host;
 if (host.startsWith('www.')) host = host.substring(4);
      if (host.endsWith('/')) host = host.substring(0, host.length - 1);
      if (host.isEmpty) {
        if (url.length > 26) return '${url.substring(0, 24)}...';
        return url;
      }
      if (u.path.isNotEmpty && u.path != '/') {
        return '$host${u.path}';
      }
      return host;
    } catch (_) {
      if (url.length > 26) return '${url.substring(0, 24)}...';
 return url;
 }
 }

 /// 2columnonelineteaminfo, middle 0.5px divider; coachquotaoutersupportsmallavatar (managerLogo)
 Widget _teamInfoRow(
 IconData li, String ll, String lv, IconData ri, String rl, String rv, {String? managerLogo}) {
 return Padding(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
 child: Row(
 children: [
 Expanded(
 child: Row(
 children: [
 Icon(li, size: 15, color: BMColors.textTertiary),
 const SizedBox(width: 6),
 Text(
 '$ll  ',
 style: const TextStyle(
 fontSize: 10.5,
 fontWeight: FontWeight.w600,
 color: BMColors.textTertiary,
),
),
 const Spacer(),
 Flexible(
 child: Text(
 lv,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 textAlign: TextAlign.right,
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w800,
 color: BMColors.textPrimary,
),
),
),
 ],
),
),
 Container(
 width: 0.5,
 height: 20,
 color: BMColors.pitch700.withValues(alpha: 0.8),
 margin: const EdgeInsets.symmetric(horizontal: 12),
),
 Expanded(
 child: Row(
 children: [
 // coachfieldprioritydisplay managerLogo 20x20
 if (rl == 'coach' && managerLogo != null && managerLogo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ClipOval(
                      child: Image.network(
                        managerLogo,
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(ri, size: 15, color: BMColors.textTertiary),
                      ),
                    ),
                  )
                else
                  Icon(ri, size: 15, color: BMColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  '$rl  ',
 style: const TextStyle(
 fontSize: 10.5,
 fontWeight: FontWeight.w600,
 color: BMColors.textTertiary,
),
),
 const Spacer(),
 Flexible(
 child: Text(
 rv,
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 textAlign: TextAlign.right,
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w800,
 color: BMColors.textPrimary,
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

 /// teaminfofield 0.5px divider
 Widget _teamInfoDivider() => Container(
 height: 0.5,
 color: BMColors.pitch700.withValues(alpha: 0.6),
 margin: const EdgeInsets.symmetric(horizontal: 12),
);

 // ==================== Tab Bar (pillstyle, differentiation) ====================

 Widget _buildTabBar() {
 return Container(
 height: 42,
 margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
 child: ListView(
 scrollDirection: Axis.horizontal,
 physics: const BouncingScrollPhysics(),
 children: [
 _buildTabChip(BMFootballDetailTab.live, 'event'),
          const SizedBox(width: 8),
          _buildTabChip(BMFootballDetailTab.lineup, 'lineup'),
          const SizedBox(width: 8),
          _buildTabChip(BMFootballDetailTab.odds, 'index'),
          const SizedBox(width: 8),
          _buildTabChip(BMFootballDetailTab.h2h, 'encounters'),
 ],
),
);
 }

 Widget _buildTabChip(BMFootballDetailTab t, String label) {
 final selected = _currentTab == t;
 return GestureDetector(
 behavior: HitTestBehavior.opaque,
 onTap: () {
 if (_currentTab == t) return;
 setState(() => _currentTab = t);
 if (t == BMFootballDetailTab.lineup) _ensureLineup();
 if (t == BMFootballDetailTab.odds) _ensureOdds();
 if (t == BMFootballDetailTab.h2h) _ensureH2H();
 },
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
 decoration: BoxDecoration(
 color: selected ? BMColors.bright: BMColors.pitch850,
 borderRadius: BorderRadius.circular(999),
 border: Border.all(
 color: selected ? BMColors.bright: BMColors.pitch700.withValues(alpha: 0.5),
 width: selected ? 1.2: 0.6,
),
 boxShadow: selected
 ? [BoxShadow(color: BMColors.bright.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 3))]
: null,
),
 alignment: Alignment.center,
 child: Text(
 label,
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w800,
 color: selected ? BMColors.pitch900: BMColors.textSecondary,
 letterSpacing: 0.6,
),
),
),
);
 }

 // ==================== Tab Contents ====================

 Widget _buildTabContent() {
 switch (_currentTab) {
 case BMFootballDetailTab.live:
 return _buildLiveTab();
 case BMFootballDetailTab.lineup:
 return _buildLineupTab();
 case BMFootballDetailTab.odds:
 return _buildOddsTab();
 case BMFootballDetailTab.h2h:
 return _buildH2HTab();
 }
 }

 Widget _buildLoading(Color c) {
 return Padding(
 padding: const EdgeInsets.symmetric(vertical: 40),
 child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: c, strokeWidth: 2))),
);
 }

 Widget _buildLiveTab() {
 if (_loadingProcess) return _buildLoading(BMColors.bright);
 final stats = _processData?.stats ?? [];
 final allList = _processData?.incidents ?? [];
 final knownList = allList
.where((e) => e.type != BMIncidentType.other)
.toList();
 // topstatistics Section + divider Header + bottom Timeline event
 final eventHeight = (knownList.length * 120.0).clamp(0.0, 12000.0);
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // ============ top: technical statsdata (original statistics Tab) ============
 if (stats.isNotEmpty)...[
 _buildStatsTitleHeader(),
 _buildStatsSection(stats),
 const SizedBox(height: 16),
 ],
 // ============ middle: eventlistdivider Header ============
 if (knownList.isNotEmpty)...[
 _buildEventListHeader(),
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
 child: SizedBox(
 height: eventHeight,
 child: _buildTimelineV2(knownList),
),
),
 ],
 // ============ fallback: nonestatistics & noneevent ============
 if (stats.isEmpty && allList.isEmpty)
 const Padding(
 padding: EdgeInsets.symmetric(vertical: 30),
 child: Center(child: Text('No matchevent', style: TextStyle(color: BMColors.textTertiary, fontSize: 12))),
          ),
        if (stats.isNotEmpty && knownList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No matchevent', style: TextStyle(color: BMColors.textTertiary, fontSize: 12))),
),
 const SizedBox(height: 20),
 ],
);
 }

 /// technical statstitle Header (icon + bright greenvertical items)
 Widget _buildStatsTitleHeader() {
 return Padding(
 padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
 child: Row(
 children: [
 Container(
 width: 3,
 height: 16,
 decoration: BoxDecoration(
 color: BMColors.bright,
 borderRadius: BorderRadius.circular(999),
),
),
 const SizedBox(width: 8),
 const Icon(Icons.bar_chart_rounded, size: 15, color: BMColors.bright),
 const SizedBox(width: 5),
 const Text(
 'technical stats',
 style: TextStyle(
 fontSize: 13,
 fontWeight: FontWeight.w800,
 color: BMColors.textPrimary,
 letterSpacing: 0.4,
),
),
 ],
),
);
 }

 /// eventlisttitle Header (icon + bluechangevertical items)
 Widget _buildEventListHeader() {
 return Padding(
 padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
 child: Row(
 children: [
 Container(
 width: 3,
 height: 16,
 decoration: BoxDecoration(
 gradient: const LinearGradient(
 begin: Alignment.topCenter,
 end: Alignment.bottomCenter,
 colors: [BMColors.bright, Color(0xFF3B82F6)],
),
 borderRadius: BorderRadius.circular(999),
),
),
 const SizedBox(width: 8),
 const Icon(Icons.timeline, size: 15, color: Color(0xFF3B82F6)),
 const SizedBox(width: 5),
 const Text(
 'matchevent',
 style: TextStyle(
 fontSize: 13,
 fontWeight: FontWeight.w800,
 color: BMColors.textPrimary,
 letterSpacing: 0.4,
),
),
 ],
),
);
 }

 /// technical statshomebody (original _buildStatsTab)
 Widget _buildStatsSection(List<BMStatRow> stats) {
 return Padding(
 padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
 child: Container(
 padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: Column(
 children: List.generate(stats.length, (i) {
 final row = stats[i];
 final homePct = _parseStatsPct(row.homeValue, row.awayValue, true);
 final awayPct = _parseStatsPct(row.homeValue, row.awayValue, false);
 return Container(
 margin: const EdgeInsets.only(bottom: 14),
 child: Column(
 children: [
 Row(
 children: [
 Expanded(child: Text(row.homeValue, textAlign: TextAlign.left, style: const TextStyle(color: BMColors.bright, fontSize: 13, fontWeight: FontWeight.w800))),
 Expanded(child: Text(row.label, textAlign: TextAlign.center, style: const TextStyle(color: BMColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600))),
 Expanded(child: Text(row.awayValue, textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w800))),
 ],
),
 const SizedBox(height: 7),
 Row(
 children: [
 Expanded(
 flex: homePct > 0 ? homePct: 1,
 child: Container(height: 6, decoration: BoxDecoration(color: BMColors.bright, borderRadius: BorderRadius.circular(999))),
),
 const SizedBox(width: 4),
 Expanded(
 flex: awayPct > 0 ? awayPct: 1,
 child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(999))),
),
 ],
),
 ],
),
);
 }),
),
),
);
 }

 int _parseStatsPct(String a, String b, bool first) {
 int? av = int.tryParse(a.replaceAll('%', ''));
    int? bv = int.tryParse(b.replaceAll('%', ''));
 if (av != null && bv != null && av + bv > 0) {
 final s = av + bv;
 return ((first ? av: bv) * 100 / s).round();
 }
 try {
 double? ad = double.tryParse(a);
 double? bd = double.tryParse(b);
 if (ad != null && bd != null) {
 final s = ad + bd;
 if (s <= 0) return 50;
 return (((first ? ad: bd) / s) * 100).round();
 }
 } catch (_) {}
 return 50;
 }

 // ==================== eventcommonauxiliary (V2 differentiationalsoreuse) ====================

 /// BMIncidentType -> numberNo. (completefullalignment hanklive type field)
 int _incidentTypeNumber(BMIncidentType t) {
 switch (t) {
 case BMIncidentType.goal:
 return 1;
 case BMIncidentType.yellowCard:
 return 3;
 case BMIncidentType.redCard:
 return 4;
 case BMIncidentType.penalty:
 return 8;
 case BMIncidentType.substitution:
 return 9;
 case BMIncidentType.secondYellow:
 return 15;
 case BMIncidentType.ownGoal:
 return 17;
 default:
 return 0;
 }
 }

 /// byeventtype/sidereturnscolor (alignment hanklive: home team=rose away team=blue goalunifiedbright green yellow card red card substitution=neutral)
 Color _incidentColor(BMIncident inc) {
 final n = _incidentTypeNumber(inc.type);
 final isHome = inc.side == BMIncidentSide.home;
 // goalclass: unifiedbright green
 if (n == 1 || n == 8 || n == 17 || n == 29) return BMColors.bright;
 // yellow card
 if (n == 3) return const Color(0xFFF59E0B);
 // red card / two yellows to red
 if (n == 4 || n == 15) return const Color(0xFFEF4444);
 // substitution
 if (n == 9) return isHome ? BMColors.bright: const Color(0xFF3B82F6);
 // othersbyhome/away team
 return isHome ? BMColors.bright: const Color(0xFF3B82F6);
 }

 /// eventtypeintextname (alignment hanklive custTypeName)
 String _custTypeName(BMIncident inc) {
 switch (inc.type) {
 case BMIncidentType.goal:
 return 'goal';
      case BMIncidentType.penalty:
        return 'penaltygoal';
      case BMIncidentType.ownGoal:
        return 'ball';
      case BMIncidentType.yellowCard:
        return 'yellow card';
      case BMIncidentType.redCard:
        return 'red card';
      case BMIncidentType.secondYellow:
        return 'two yellows to red';
      case BMIncidentType.substitution:
        return 'substitution';
      case BMIncidentType.injuryTime:
        return 'injury patch when';
      case BMIncidentType.whistle:
        return '';
      default:
        return inc.detail ?? 'event';
    }
  }

  String _custPlayerName(BMIncident inc) {
    if (inc.playerName != null && inc.playerName!.trim().isNotEmpty) {
      return inc.playerName!;
    }
    return '';
  }

  /// timeformat: 90' + 3'
  String _incidentTime(BMIncident inc) {
    if (inc.minute == null) return "0'";
    if (inc.addedTime != null && inc.addedTime! > 0) {
      return "${inc.minute}' +${inc.addedTime}'";
    }
    return "${inc.minute}'";
 }

 // ==================== eventicon & typename (keeporiginalmethod，doas fallback，upperplane dotIcon alsousage)
 IconData _incidentIcon(BMIncidentType t) {
 switch (t) {
 case BMIncidentType.goal:
 case BMIncidentType.penalty:
 return Icons.sports_soccer;
 case BMIncidentType.ownGoal:
 return Icons.repeat_rounded;
 case BMIncidentType.yellowCard:
 return Icons.style_rounded;
 case BMIncidentType.redCard:
 case BMIncidentType.secondYellow:
 return Icons.content_cut;
 case BMIncidentType.substitution:
 return Icons.swap_vert;
 case BMIncidentType.injuryTime:
 return Icons.timelapse;
 case BMIncidentType.whistle:
 return Icons.alarm;
 default:
 return Icons.info;
 }
 }

 // ================ V2 differentiationeventlist UI (zonedo not hanklive original + lazy loadfixcard) ================

 /// V2 time: changeline + lazy load ListView.builder (fixlengthlistonetimebuildcard)
 Widget _buildTimelineV2(List<BMIncident> incidents) {
 final count = incidents.length;
 return Stack(
 clipBehavior: Clip.none,
 children: [
 // changetimeline (bright green → pitch700)
 Positioned(
 left: 12,
 top: 14,
 bottom: 14,
 child: Container(
 width: 3,
 decoration: BoxDecoration(
 gradient: LinearGradient(
 begin: Alignment.topCenter,
 end: Alignment.bottomCenter,
 colors: [
 BMColors.bright.withValues(alpha: 0.85),
 const Color(0xFF3B82F6).withValues(alpha: 0.6),
 ],
),
 borderRadius: BorderRadius.circular(999),
),
),
),
 ListView.builder(
 itemCount: count,
 shrinkWrap: true,
 physics: const NeverScrollableScrollPhysics(),
 padding: EdgeInsets.zero,
 itemBuilder: (ctx, i) {
 if (i >= count) return const SizedBox.shrink();
 final inc = incidents[i];
 return Padding(
 padding: const EdgeInsets.only(bottom: 14),
 child: _buildEventItemV2(inc),
);
 },
),
 ],
);
 }

 /// V2 singleeventline: leftRRectrounded cornerdirectionpoint + middletimepill + rightcard (Matrix4heavyheight)
 Widget _buildEventItemV2(BMIncident inc) {
 final color = _incidentColor(inc);
 final isHome = inc.side == BMIncidentSide.home;
 final sideStripeColor = isHome ? BMColors.bright: const Color(0xFF3B82F6);
 final n = _incidentTypeNumber(inc.type);
 final isGoal = n == 1 || n == 8 || n == 17 || n == 29;

 return Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // =========== left side: 18x18 RRect rounded cornerdirectionpoint ( Matrix4，subless Transform heavyopen) ===========
 SizedBox(
 width: 28,
 child: Stack(
 alignment: Alignment.center,
 children: [
 Container(
 width: 18,
 height: 18,
 decoration: BoxDecoration(
 color: BMColors.pitch900,
 borderRadius: BorderRadius.circular(5),
 border: Border.all(color: color, width: 1.6),
),
),
 if (isGoal)
 Container(
 width: 8,
 height: 8,
 decoration: BoxDecoration(
 color: color,
 borderRadius: BorderRadius.circular(2.5),
),
),
 ],
),
),
 const SizedBox(width: 8),
 // =========== middle: timepill (square rounded corner) ===========
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
 margin: const EdgeInsets.only(top: 2),
 decoration: BoxDecoration(
 color: isGoal
 ? color.withValues(alpha: 0.18)
: BMColors.pitch850.withValues(alpha: 0.95),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(
 color: isGoal
 ? color.withValues(alpha: 0.6)
: BMColors.pitch700.withValues(alpha: 0.65),
 width: 0.9,
),
),
 child: Text(
 _incidentTime(inc),
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w800,
 color: isGoal ? color: BMColors.textSecondary,
 fontFamily: 'monospace',
 letterSpacing: 0.4,
),
),
),
 const SizedBox(width: 10),
 // =========== right side: card (home/away colorvertical items) ===========
 Expanded(
 child: Container(
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(14),
 color: isGoal
 ? BMColors.bright.withValues(alpha: 0.06)
: BMColors.pitch850,
 border: Border.all(
 color: isGoal
 ? color.withValues(alpha: 0.42)
: BMColors.pitch700.withValues(alpha: 0.55),
 width: isGoal ? 1.1: 0.85,
),
),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // home/away colorvertical items
 Container(
 width: 4,
 decoration: BoxDecoration(
 color: sideStripeColor,
 borderRadius: const BorderRadius.only(
 topLeft: Radius.circular(14),
 bottomLeft: Radius.circular(14),
),
),
),
 // cardcontentzone
 Expanded(
 child: Padding(
 padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Row1: eventtype Tag + right side largeNo.score/home/awayidentifier
 Row(
 children: [
 // event Tag
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
 decoration: BoxDecoration(
 color: color.withValues(alpha: 0.16),
 borderRadius: BorderRadius.circular(6),
 border: Border.all(
 color: color.withValues(alpha: 0.5),
 width: 0.8,
),
),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(_incidentIcon(inc.type), size: 11, color: color),
 const SizedBox(width: 4),
 Text(
 _custTypeName(inc),
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w800,
 color: color,
 letterSpacing: 0.3,
),
),
 ],
),
),
 const Spacer(),
 // score (largeNo.add) or home/awaytag
 if (inc.homeScore != null && inc.awayScore != null)
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
 decoration: BoxDecoration(
 color: BMColors.pitch900.withValues(alpha: 0.85),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(
 color: isHome
 ? BMColors.bright.withValues(alpha: 0.5)
: const Color(0xFF3B82F6).withValues(alpha: 0.5),
 width: 0.8,
),
),
 child: RichText(
 text: TextSpan(
 children: [
 TextSpan(
 text: '${inc.homeScore}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: BMColors.bright,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' : ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: BMColors.textTertiary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${inc.awayScore}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF3B82F6),
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: sideStripeColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: sideStripeColor.withValues(alpha: 0.4),
                                    width: 0.7,
                                  ),
                                ),
                                child: Text(
                                  isHome ? 'home team' : 'away team',
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w700,
 color: sideStripeColor,
),
),
),
 ],
),
 const SizedBox(height: 9),
 // Row2: player/substitutiondescription
 _buildEventDescriptionV2(inc),
 // Row3 (score onlyevent): changebottomscoreitems
 if (isGoal && inc.homeScore != null && inc.awayScore != null)...[
 const SizedBox(height: 10),
 Container(
 padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(8),
 color: BMColors.bright.withValues(alpha: 0.12),
 border: Border.all(
 color: BMColors.bright.withValues(alpha: 0.28),
 width: 0.7,
),
),
 child: Row(
 children: [
 Container(
 width: 22,
 height: 22,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: BMColors.pitch900.withValues(alpha: 0.7),
),
 child: const Icon(Icons.sports_soccer, size: 12, color: BMColors.bright),
),
 const SizedBox(width: 7),
 const Expanded(
 child: Text(
 'live scoreupdate',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: BMColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${inc.homeScore} - ${inc.awayScore}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: BMColors.textPrimary,
                                    fontFamily: 'monospace',
),
),
 ],
),
),
 ],
 ],
),
),
),
 ],
),
),
),
 ],
);
 }

 /// V2 descriptiontext (substitutionusearrowminupperlowerline, othersaddplayername)
 Widget _buildEventDescriptionV2(BMIncident inc) {
 final n = _incidentTypeNumber(inc.type);
 final isHome = inc.side == BMIncidentSide.home;
 final sideColor = isHome ? BMColors.bright: const Color(0xFF3B82F6);
 // substitution: upperlower lowerupper icon + line out/in player
 if (n == 9) {
 final out = inc.playerName ?? '';
      final inP = inc.subPlayerName ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (out.isNotEmpty)
            Row(
              children: [
                Icon(Icons.arrow_downward, size: 12, color: const Color(0xFFEF4444)),
                const SizedBox(width: 5),
                const Text(
                  'lowercourt: ',
                  style: TextStyle(fontSize: 11, color: BMColors.textTertiary, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: Text(
                    out,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          if (out.isNotEmpty && inP.isNotEmpty) const SizedBox(height: 4),
          if (inP.isNotEmpty)
            Row(
              children: [
                Icon(Icons.arrow_upward, size: 12, color: BMColors.bright),
                const SizedBox(width: 5),
                const Text(
                  'uppercourt: ',
                  style: TextStyle(fontSize: 11, color: BMColors.textTertiary, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: Text(
                    inP,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BMColors.bright,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          if (out.isEmpty && inP.isEmpty)
            Text(
              'substitution adjust',
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w600,
 color: sideColor,
 height: 1.45,
),
),
 ],
);
 }
 // othersevent: playername (largetext) + detail smalltext (likeresulthas)
 final p = _custPlayerName(inc);
 final detail = inc.detail;
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 if (p.isNotEmpty)
 Text(
 p,
 style: TextStyle(
 fontSize: 13,
 fontWeight: FontWeight.w800,
 color: sideColor,
 height: 1.4,
),
),
 if (detail != null && detail.isNotEmpty && detail != _custTypeName(inc))...[
 if (p.isNotEmpty) const SizedBox(height: 3),
 Text(
 detail,
 style: const TextStyle(
 fontSize: 11,
 color: BMColors.textSecondary,
 height: 1.5,
),
),
 ],
 ],
);
 }

 // =========== Odds Tab (datagettakereference hanklive match_detail_odds_tab.dart，UI dark greendifferentiation) ===========
 BMOddsType _oddsSel = BMOddsType.asianHandicap;

 /// index Tab: display 2 lineodds of state (user requirement: default true=opening odds+early odds, tapswitchlater false=early odds+live)
 bool _oddsShowIniPre = true;

 Widget _buildOddsTab() {
 _ensureOdds();
 final companies = _oddsData?.listBy(_oddsSel) ?? [];
 final is1x2 = _oddsSel == BMOddsType.matchResult;
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // ① 4 section selector (stylemodifyformtopmatchdetail Tab pillstyleone: selected = bright greenfill + pitch900 darktext + shadow)
 Padding(
 padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
 child: SizedBox(
 height: 42,
 child: ListView(
 scrollDirection: Axis.horizontal,
 physics: const NeverScrollableScrollPhysics(),
 children: BMOddsType.values.asMap().entries.map((e) {
 final i = e.key;
 final t = e.value;
 final selected = _oddsSel == t;
 return Padding(
 padding: EdgeInsets.only(right: (i == BMOddsType.values.length - 1) ? 0: 8),
 child: GestureDetector(
 onTap: () {
 if (_oddsSel == t) return;
 setState(() {
 _oddsSel = t;
 // switchhandicaptypewhen, heavyplaceasdefaultopening odds+early odds(user)
 _oddsShowIniPre = true;
 });
 },
 behavior: HitTestBehavior.opaque,
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
 decoration: BoxDecoration(
 color: selected ? BMColors.bright: BMColors.pitch850,
 borderRadius: BorderRadius.circular(999),
 border: Border.all(
 color: selected
 ? BMColors.bright
: BMColors.pitch700.withValues(alpha: 0.5),
 width: selected ? 1.2: 0.6,
),
 boxShadow: selected
 ? [
 BoxShadow(
 color: BMColors.bright.withValues(alpha: 0.22),
 blurRadius: 10,
 offset: const Offset(0, 3),
)
 ]
: null,
),
 alignment: Alignment.center,
 child: Text(
 t.shortLabel,
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w800,
 color: selected ? BMColors.pitch900: BMColors.textSecondary,
 letterSpacing: 0.6,
),
),
),
),
);
 }).toList(),
),
),
),
 // ② Loading / emptystate / oddsdatacard
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 14),
 child: _loadingOdds && companies.isEmpty
 ? _buildLoading(BMColors.bright)
: companies.isEmpty
 ? Container(
 padding: const EdgeInsets.symmetric(vertical: 40),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: const Center(
 child: Text('No oddsdata',
 style:
 TextStyle(fontSize: 13, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
),
)
: Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
 boxShadow: [
 BoxShadow(
 color: BMColors.bright.withValues(alpha: 0.05),
 blurRadius: 10,
 offset: const Offset(0, 2),
),
 ],
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // cardtitle row: left handicaptypename / right **cantapswitchbutton** (user requirement: opening odds/early odds ↔ early odds/live)
 Row(
 children: [
 Text(
 _oddsSel.fullTitle,
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w800,
 color: BMColors.textPrimary,
),
),
 const Spacer(),
 // user requirement: top-right cornerlivehandicapbuttoncantapswitch 2 linedisplay
 GestureDetector(
 onTap: () => setState(() => _oddsShowIniPre = !_oddsShowIniPre),
 behavior: HitTestBehavior.opaque,
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: _oddsShowIniPre
 ? BMColors.pitch700.withValues(alpha: 0.5)
: BMColors.bright.withValues(alpha: 0.14),
 borderRadius: BorderRadius.circular(999),
 border: Border.all(
 color: _oddsShowIniPre
 ? BMColors.pitch700.withValues(alpha: 0.6)
: BMColors.bright.withValues(alpha: 0.5),
),
),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Container(
 width: 7,
 height: 7,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: _oddsShowIniPre ? BMColors.textTertiary: BMColors.bright,
 boxShadow: _oddsShowIniPre
 ? null
: [const BoxShadow(color: BMColors.bright, blurRadius: 6)],
),
),
 const SizedBox(width: 5),
 Text(
 // true: opening odds+early oddsmodulestyle buttontext "early odds+live" (canpast)
 // false: currentshowearly odds+live, buttontext "opening odds+early odds" (canback)
 _oddsShowIniPre ? 'early odds+live' : 'opening odds+early odds',
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.w700,
 color: _oddsShowIniPre ? BMColors.textTertiary: BMColors.bright,
),
),
 ],
),
),
),
 ],
),
 const SizedBox(height: 10),
 // tableheader(column 70pxwidth + sectiontagcolumn 40pxwidth + 3 or 4 bar Expanded tableheader)
 _oddsTableHeader(is1x2: is1x2),
 const SizedBox(height: 4),
 // each **onlyshow 2 linedata**
 // true (default) → opening odds(ini) + early (pre)
 // false () → early (pre) + live(spot)
...companies.map((c) => _oddsCompanyRow(c, is1x2)),
 ],
),
),
),
 const SizedBox(height: 14),
 ],
);
 }

 /// tableheaderline(Bookmaker / sectiontagplaceholder + 3~4 bartableheader)
 Widget _oddsTableHeader({required bool is1x2}) {
 final hdrs = _oddsSel.headers;
 return Container(
 padding: const EdgeInsets.symmetric(vertical: 7),
 decoration: BoxDecoration(
 color: BMColors.pitch800.withValues(alpha: 0.85),
 borderRadius: BorderRadius.circular(6),
),
 child: Row(
 children: [
 // Bookmaker columnwidth 70
 const SizedBox(
 width: 70,
 child: Text(
 '',
 style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: BMColors.textTertiary),
),
),
 // sectiontagplaceholder 40 (correspondinglowerplane rows of section label columnwidth)
 const SizedBox(width: 40),
 // 3~4 bar Expanded tableheader(1X2 4bar;AH/OU/Corners 3bar)
...hdrs.asMap().entries.map((e) => Expanded(
 child: Text(
 e.value,
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: BMColors.textSecondary),
),
)),
 ],
),
);
 }

 /// single of line(left sidenamecolumn + **onlyshow 2 line** odds rows + rightarrow)
 /// user requirement: defaultshowopening odds(ini)+early (pre); pointtop-right cornerbuttonto early (pre)+live(spot)
 Widget _oddsCompanyRow(BMCompanyOdds company, bool is1x2) {
 final hasIni = company.ini != null;
 final hasPre = company.pre != null;
 final hasSpot = company.spot != null;
 final List<Widget> rows = [];
 if (_oddsShowIniPre) {
 // defaultmodulestyle: opening odds + early odds (2 line, has 2 line; missing 1 itemsdisplaystore of items; not >2)
 if (hasIni) {
 rows.add(_oddsStageRow(company.ini!,
 stageLabel: 'opening odds', color: BMColors.textTertiary, is1x2: is1x2));
        rows.add(const SizedBox(height: 8));
      }
      if (hasPre) {
        rows.add(_oddsStageRow(company.pre!,
            stageLabel: 'early odds', color: const Color(0xFF3B82F6), is1x2: is1x2));
 }
 } else {
 // switchmodulestyle: early odds + live (2 line)
 if (hasPre) {
 rows.add(_oddsStageRow(company.pre!,
 stageLabel: 'early odds', color: const Color(0xFF3B82F6), is1x2: is1x2));
        rows.add(const SizedBox(height: 8));
      }
      if (hasSpot) {
        rows.add(_oddsStageRow(company.spot!,
            stageLabel: 'live', color: BMColors.bright, is1x2: is1x2));
 }
 }
 return GestureDetector(
 onTap: () => _gotoOddsHistory(company),
 behavior: HitTestBehavior.opaque,
 child: Container(
 padding: const EdgeInsets.symmetric(vertical: 10),
 decoration: BoxDecoration(
 border: Border(bottom: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.4))),
),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // name 70px width 2 line
 SizedBox(
 width: 70,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 if (company.companyLogo != null && company.companyLogo!.isNotEmpty)
 Padding(
 padding: const EdgeInsets.only(bottom: 3),
 child: ClipRRect(
 borderRadius: BorderRadius.circular(2),
 child: Image.network(
 company.companyLogo!,
 width: 16,
 height: 16,
 fit: BoxFit.cover,
 errorBuilder: (_, __, ___) => const SizedBox.shrink(),
),
),
),
 Text(
 company.companyName ?? 'ID:${company.companyId}',
 style: const TextStyle(
 color: BMColors.textPrimary,
 fontSize: 11.5,
 fontWeight: FontWeight.w800,
),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
),
 ],
),
),
 // sectionoddscolumn (onlyincludes 2 line)
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: rows,
),
),
 // rightarrow
 Padding(
 padding: const EdgeInsets.only(left: 6, top: 16),
 child:
 Icon(Icons.chevron_right, size: 16, color: BMColors.pitch700.withValues(alpha: 0.9)),
),
 ],
),
),
);
 }

 /// singlesection of oddsline(tag 40px width + Expanded 3~4 columnoddsvalue)
 Widget _oddsStageRow(BMCompanyOddsDetail d, {required String stageLabel, required Color color, required bool is1x2}) {
 return Row(
 children: [
 // sectiontag 40 width
 SizedBox(
 width: 40,
 child: Text(
 stageLabel,
 style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800),
),
),
 // No. 1 column: home (home win / home win / over)
 Expanded(
 child: _oddsStageCell(d.home, color),
),
 if (is1x2)...[
 // No. 2 column: Dgame (only 1X2 has,backgroundhighlightcolor 18%)
 Expanded(
 child: Container(
 margin: const EdgeInsets.symmetric(horizontal: 3),
 padding: const EdgeInsets.symmetric(vertical: 4),
 decoration: BoxDecoration(
 color: BMColors.bright.withValues(alpha: 0.08),
 borderRadius: BorderRadius.circular(5),
),
 child: Text(
 d.draw ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: BMColors.textPrimary, fontFamily: 'monospace'),
),
),
),
 ] else...[
 // No. 2 column: handicap handicap (AH/OU/Corners:displaymiddlecolor + 16% backgroundpill)
 Expanded(
 child: Container(
 margin: const EdgeInsets.symmetric(horizontal: 3),
 padding: const EdgeInsets.symmetric(vertical: 4),
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(5),
 border: Border.all(color: BMColors.bright.withValues(alpha: 0.3)),
),
 child: Text(
 d.handicap ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: BMColors.bright, fontFamily: 'monospace'),
),
),
),
 ],
 // lateronecolumn: away (away win / away win / small ball)
 Expanded(
 child: _oddsStageCell(d.away, color, isAway: true),
),
 ],
);
 }

 /// oddscell (value + color + alignment)
 Widget _oddsStageCell(String? v, Color c, {bool isAway = false}) {
 return Text(
 v ?? '-',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: c,
        fontFamily: 'monospace',
 letterSpacing: 0.2,
),
);
 }

 /// navigatetooddshistorydetailpage(inputchange aslevelobject,keepnavigateflow) - oldsign,upperplanehomemethodmakeuse
 // emptyimplement: home _gotoOddsHistory buildBody firstplane,fullgameuse

 // =========== Lineup Tab (alignment hanklive match_detail_lineup_tab.dart) ===========

 /// lineup Tab tapplayer → bottompopplayerinfo Sheet (user requirement)
 /// : 1. validate playerId (0 orempty return)
 /// 2. showModalBottomSheet (Loading state)
 /// 3. request GET /api/livespeed/football/match/player-info?player_id=&match_id=
 /// 4. setState refresh Bottom Sheet → datastate / emptystate
 void _navigateToLineupPlayerDetail(BMMatchLineupPlayer player) {
 final idStr = player.playerId;
 final pid = (idStr != null && idStr.isNotEmpty) ? int.tryParse(idStr): null;
 // alignment hanklive: playerId == 0 return
 if (pid == null || pid == 0) return;
 final matchId = int.tryParse(widget.match.matchId) ?? 0;
 if (matchId == 0) return;
 _loadAndShowPlayerSheet(playerId: pid, matchId: matchId, fallbackName: player.playerName);
 }

 /// core: pop Bottom Sheet + asyncrequestplayerinfo(userto of API/argument/returnsstructure)
 Future<void> _loadAndShowPlayerSheet({
 required int playerId,
 required int matchId,
 String? fallbackName,
 }) async {
 // innerpart ValueNotifier make Loading/data/emptystate (not setState page, onlyrefresh Sheet)
 final loadingVN = ValueNotifier<bool>(true);
 final infoVN = ValueNotifier<BMPlayerInfo?>(null);
 showModalBottomSheet(
 context: context,
 isScrollControlled: true,
 backgroundColor: Colors.transparent,
 barrierColor: Colors.black.withValues(alpha: 0.55),
 builder: (sheetCtx) {
 // asyncrequest (independent Future, not Sheet pop)
 Future.microtask(() async {
 final info = await BMMatchDetailApiService().fetchPlayerInfo(
 playerId: playerId,
 matchId: matchId,
);
 loadingVN.value = false;
 infoVN.value = info;
 });
 return ValueListenableBuilder<bool>(
 valueListenable: loadingVN,
 builder: (_, loading, __) {
 return ValueListenableBuilder<BMPlayerInfo?>(
 valueListenable: infoVN,
 builder: (_, info, ___) {
 return Container(
 constraints: BoxConstraints(
 maxHeight: MediaQuery.of(context).size.height * 0.62,
),
 padding: EdgeInsets.only(
 left: 14,
 right: 14,
 top: 12,
 bottom: 14 + MediaQuery.of(context).padding.bottom,
),
 decoration: BoxDecoration(
 color: BMColors.pitch900,
 borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 // topdrag
 Container(
 width: 38,
 height: 4,
 decoration: BoxDecoration(
 color: BMColors.pitch700,
 borderRadius: BorderRadius.circular(4),
),
),
 const SizedBox(height: 14),
 // title + close
 Row(
 children: const [
 Icon(Icons.person, size: 15, color: BMColors.bright),
 SizedBox(width: 6),
 Text(
 'playerinfo',
 style: TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w800,
 color: BMColors.textPrimary,
),
),
 ],
),
 const SizedBox(height: 14),
 if (loading)
 Padding(
 padding: const EdgeInsets.symmetric(vertical: 24),
 child: Center(
 child: SizedBox(
 width: 22,
 height: 22,
 child: CircularProgressIndicator(
 strokeWidth: 2.2,
 valueColor: AlwaysStoppedAnimation<Color>(BMColors.bright),
),
),
),
)
 else if (info == null)
 _playerSheetEmpty(fallbackName)
 else
 Flexible(child: _playerSheetContent(info)),
 const SizedBox(height: 12),
 ],
),
);
 },
);
 },
);
 },
);
 }

 /// player Sheet: request failure / nonedataemptystate
 Widget _playerSheetEmpty(String? fallbackName) {
 return Container(
 margin: const EdgeInsets.symmetric(vertical: 12),
 padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(12),
),
 child: Column(
 children: [
 Icon(Icons.person_off, size: 30, color: BMColors.pitch700.withValues(alpha: 0.9)),
 const SizedBox(height: 8),
 Text(
 fallbackName?.isNotEmpty == true ? 'No  $fallbackName of detail info' : 'No theplayer of detail info',
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w600,
 color: BMColors.textTertiary,
),
),
 ],
),
);
 }

 /// player Sheet: successdatastate (8 itemsfield 2 column grid + tophomeinfoline)
 Widget _playerSheetContent(BMPlayerInfo info) {
 final name = (info.playerName?.isNotEmpty ?? false) ? info.playerName!: 'not yetknowplayer';
 final shirt = info.shirtNumber ?? 0;
 return SingleChildScrollView(
 physics: const BouncingScrollPhysics(),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 // tophomecard: avatar + jerseynumber + nametext + position + 
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: Row(
 children: [
 // avatar 60x60
 ClipOval(
 child: Container(
 width: 60,
 height: 60,
 color: BMColors.pitch700.withValues(alpha: 0.7),
 child: (info.playerLogo != null && info.playerLogo!.isNotEmpty)
 ? Image.network(
 info.playerLogo!,
 fit: BoxFit.cover,
 errorBuilder: (_, __, ___) => _playerAvatarFallback(name, shirt),
)
: _playerAvatarFallback(name, shirt),
),
),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 // jerseyNo.badge
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: BMColors.bright.withValues(alpha: 0.18),
 borderRadius: BorderRadius.circular(6),
 border: Border.all(color: BMColors.bright.withValues(alpha: 0.5)),
),
 child: Text(
 shirt > 0 ? '#$shirt' : '-',
 style: const TextStyle(
 fontSize: 10.5,
 fontWeight: FontWeight.w800,
 color: BMColors.bright,
 letterSpacing: 0.4,
),
),
),
 const SizedBox(width: 8),
 Flexible(
 child: Text(
 name,
 maxLines: 2,
 softWrap: true,
 style: const TextStyle(
 fontSize: 15.5,
 fontWeight: FontWeight.w800,
 color: BMColors.textPrimary,
 height: 1.2,
),
),
),
 ],
),
 const SizedBox(height: 8),
 // position + 
 Row(
 children: [
 // position Chip
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
 decoration: BoxDecoration(
 color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
 borderRadius: BorderRadius.circular(6),
),
 child: Text(
 info.positionFullLabel,
 style: const TextStyle(
 fontSize: 10.5,
 fontWeight: FontWeight.w700,
 color: Color(0xFF3B82F6),
),
),
),
 const SizedBox(width: 8),
 if (info.countryName != null && info.countryName!.isNotEmpty)...[
 if (info.countryLogo != null && info.countryLogo!.isNotEmpty)
 Padding(
 padding: const EdgeInsets.only(right: 5),
 child: ClipRRect(
 borderRadius: BorderRadius.circular(2),
 child: Image.network(
 info.countryLogo!,
 width: 16,
 height: 12,
 fit: BoxFit.cover,
 errorBuilder: (_, __, ___) =>
 const SizedBox(width: 0, height: 0),
),
),
),
 Flexible(
 child: Text(
 info.countryName!,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w600,
 color: BMColors.textSecondary,
),
),
),
 ],
 ],
),
 ],
),
),
 ],
),
),
 const SizedBox(height: 12),
 // lowerdirectionfield 2x2 Grid: height / weight / market value / positionabbreviation
 Container(
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: Column(
 children: [
 _playerInfoRow(Icons.height, 'height', info.heightLabel, Icons.fitness_center, 'weight', info.weightLabel),
                Container(height: 0.5, color: BMColors.pitch700.withValues(alpha: 0.6)),
                _playerInfoRow(Icons.attach_money, 'market value', info.marketValueLabel, Icons.flag_circle, 'position', info.position ?? '-'),
 ],
),
),
 ],
),
);
 }

 /// avatarLoad Failed fallback: text + numberbottom
 Widget _playerAvatarFallback(String name, int shirt) {
 final first = (name.isNotEmpty) ? name.trim().characters.first.toUpperCase(): '?';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            first,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: BMColors.bright,
            ),
          ),
          if (shirt > 0)
            Text(
              '$shirt',
 style: const TextStyle(
 fontSize: 10,
 color: BMColors.textTertiary,
 fontWeight: FontWeight.w600,
),
),
 ],
),
);
 }

 /// 2 columnonelinefield (left: icon/label/value + right: icon/label/value)
 Widget _playerInfoRow(
 IconData li, String ll, String lv, IconData ri, String rl, String rv) {
 return Padding(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
 child: Row(
 children: [
 Expanded(
 child: Row(
 children: [
 Icon(li, size: 15, color: BMColors.textTertiary),
 const SizedBox(width: 6),
 Text(
 '$ll  ',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: BMColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    lv,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BMColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 0.5,
            height: 18,
            color: BMColors.pitch700.withValues(alpha: 0.8),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(ri, size: 15, color: BMColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  '$rl  ',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: BMColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    rv,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BMColors.textPrimary,
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

  Widget _buildLineupTab() {
    if (_loadingLineup) return _buildLoading(BMColors.bright);
    final data = _lineupData;
    if (data == null || (data.homeFirst.isEmpty && data.awayFirst.isEmpty)) {
      return _buildLineupEmpty();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLineupHeader(data),
          const SizedBox(height: 16),
          _buildLineupPitch(data),
          const SizedBox(height: 16),
          _buildLineupSubSection(data),
          const SizedBox(height: 16),
          _buildLineupInjurySection(data),
        ],
      ),
    );
  }

  Widget _buildLineupEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: BMColors.textTertiary.withValues(alpha: 0.8)),
            const SizedBox(height: 12),
            const Text('No lineupdata', style: TextStyle(fontSize: 14, color: BMColors.textTertiary)),
 ],
),
),
);
 }

 /// formationheader: homeformationname VS awayformationname (user requirement: formation LOGO remove)
 /// lowerdirectionkeephome/awaycoachname + icon (alignmenttrueactuallaterside home_coach / away_coach field)
 Widget _buildLineupHeader(BMLineupData data) {
 final hCoachName = data.homeCoach?.name ?? data.home.coach?.name;
 final aCoachName = data.awayCoach?.name ?? data.away.coach?.name;
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
),
 child: Column(
 children: [
 // No. 1 line: 4-3-3 VS 4-2-3-1 (removehome/away team logo, user requirement)
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Flexible(
 child: Text(
 data.homeFormation ?? '',
                  maxLines: 2,
                  softWrap: true,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: BMColors.textPrimary,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BMColors.textTertiary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  data.awayFormation ?? '',
 maxLines: 2,
 softWrap: true,
 textAlign: TextAlign.right,
 style: const TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w800,
 color: BMColors.textPrimary,
),
),
),
 ],
),
 // No. 2 line: coachname (hasnametextdisplay, keep, not)
 if ((hCoachName != null && hCoachName.isNotEmpty) ||
 (aCoachName != null && aCoachName.isNotEmpty))...[
 const SizedBox(height: 10),
 Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 const Icon(
 Icons.coffee_outlined,
 size: 12,
 color: BMColors.bright,
),
 const SizedBox(width: 4),
 Flexible(
 child: Text(
 hCoachName ?? '',
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontSize: 11,
                            color: BMColors.bright.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          aCoachName ?? '',
 maxLines: 2,
 softWrap: true,
 overflow: TextOverflow.visible,
 textAlign: TextAlign.right,
 style: const TextStyle(
 fontSize: 11,
 color: Color(0xFF3B82F6),
 fontWeight: FontWeight.w600,
),
),
),
 const SizedBox(width: 4),
 const Icon(
 Icons.coffee_outlined,
 size: 12,
 color: Color(0xFF3B82F6),
),
 ],
),
),
 ],
),
 ],
 ],
),
);
 }

 /// 2.5D tacticalballcourt (LayoutBuilder + tagPosition alignment hanklive _buildPitch)
 Widget _buildLineupPitch(BMLineupData data) {
 return LayoutBuilder(
 builder: (context, constraints) {
 final totalWidth = constraints.maxWidth;
 final itemHeight = 420.0;
 const itemWidth = 36.0;
 return Container(
 height: itemHeight,
 decoration: BoxDecoration(
 gradient: const LinearGradient(
 begin: Alignment.topCenter,
 end: Alignment.bottomCenter,
 colors: [Color(0xFF103820), Color(0xFF0D2E1A)],
),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: const Color(0x4D12FF80)),
 boxShadow: const [
 BoxShadow(
 color: Color(0x1A000000),
 blurRadius: 16,
 offset: Offset(0, 8),
),
 ],
),
 child: Stack(
 clipBehavior: Clip.none,
 children: [
 Positioned.fill(
 child: CustomPaint(painter: _BMPitchLinePainter()),
),
 // Away away team (upperhalf, tagconvert: (100-x), (100-y)/2 + h/2)
...data.awayFirst.map((player) {
 final x = player.x ?? 50.0;
 final y = player.y ?? 50.0;
 final centerX = (100 - x) / 100.0 * totalWidth;
 final centerY = (100 - y) / 100.0 * itemHeight / 2 + itemHeight / 2;
 final clampedY = centerY.clamp(12.0, itemHeight - 50);
 return Positioned(
 left: centerX - itemWidth / 2,
 top: clampedY,
 child: _buildLineupPlayerNode(player, isHome: false),
);
 }),
 // Home home team (lowerhalf, tagcenterdirection: x/100*w, y/100*h/2)
...data.homeFirst.map((player) {
 final x = player.x ?? 50.0;
 final y = player.y ?? 50.0;
 final centerX = x / 100.0 * totalWidth;
 final centerY = y / 100.0 * itemHeight / 2;
 final clampedY = centerY.clamp(12.0, itemHeight - 50);
 return Positioned(
 left: centerX - itemWidth / 2,
 top: clampedY,
 child: _buildLineupPlayerNode(player, isHome: true),
);
 }),
 ],
),
);
 },
);
 }

 /// playersectionpoint (avatar+number+eventtag, user requirement: starternametext Chip remove, onlykeeppositionavatar)
 /// tapjumpplayerdetailpage (alignment hanklive _navigateToPlayerDetail)
 Widget _buildLineupPlayerNode(BMMatchLineupPlayer player, {required bool isHome}) {
 final teamColor = isHome ? const Color(0xFFE11D48): const Color(0xFF3B82F6);
 final shirtNum = player.shirtNumber ?? 0;
 return GestureDetector(
 behavior: HitTestBehavior.opaque,
 onTap: () => _navigateToLineupPlayerDetail(player),
 child: SizedBox(
 width: 36,
 height: 40,
 child: Stack(
 clipBehavior: Clip.none,
 alignment: Alignment.topCenter,
 children: [
 Container(
 width: 36,
 height: 36,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 border: Border.all(color: teamColor, width: 2),
),
 child: ClipOval(
 child: (player.playerLogo != null && player.playerLogo!.isNotEmpty)
 ? Image.network(
 player.playerLogo!,
 fit: BoxFit.cover,
 errorBuilder: (c, e, s) => Container(
 color: teamColor.withValues(alpha: 0.3),
 child: Center(
 child: Text(
 '$shirtNum',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: teamColor.withValues(alpha: 0.3),
                        child: Center(
                          child: Text(
                            '$shirtNum',
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w700,
 color: Colors.white,
),
),
),
),
),
),
 if (player.incidents.isNotEmpty)
 Positioned(
 right: -2,
 top: -2,
 child: _buildLineupIncidentBadge(player.incidents),
),
 ],
),
),
);
 }

 /// eventtag (goal⚽ yellow card🟨 red card🟥)
 Widget _buildLineupIncidentBadge(List<BMLineupIncident> incidents) {
 final type = incidents.first.type;
 Color badgeColor;
 String label;
 switch (type) {
 case 1:
 badgeColor = const Color(0xFF10B981);
 label = '⚽';
        break;
      case 2:
        badgeColor = const Color(0xFFFBBF24);
        label = '🟨';
        break;
      case 3:
        badgeColor = const Color(0xFFEF4444);
        label = '🟥';
        break;
      default:
        badgeColor = BMColors.bright;
        label = '';
 }
 return Container(
 width: 14,
 height: 14,
 decoration: BoxDecoration(
 color: badgeColor,
 shape: BoxShape.circle,
 border: Border.all(color: Colors.white, width: 1),
),
 child: Center(
 child: Text(label, style: const TextStyle(fontSize: 8)),
),
);
 }

 /// substitutezone (Home + Away, user requirement: leftrightcolumn, eachline2player, left home team / right away team)
 Widget _buildLineupSubSection(BMLineupData data) {
 final homeList = data.homeSub;
 final awayList = data.awaySub;
 if (homeList.isEmpty && awayList.isEmpty) {
 return const SizedBox.shrink();
 }
 final maxLen = homeList.length > awayList.length ? homeList.length: awayList.length;
 return Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
 boxShadow: [
 BoxShadow(
 color: BMColors.bright.withValues(alpha: 0.06),
 blurRadius: 8,
 offset: const Offset(0, 2),
),
 ],
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // title row + home/awaysmalltag (leftrightside)
 Row(
 children: [
 const Icon(Icons.chair, size: 14, color: BMColors.bright),
 const SizedBox(width: 8),
 const Text(
 'substitute',
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w700,
 color: BMColors.textPrimary,
),
),
 const Spacer(),
 // home teamsmall ball
 Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle)),
 const SizedBox(width: 3),
 const Text('home', style: TextStyle(fontSize: 10, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
 const SizedBox(width: 10),
 // away teamsmall ball
 Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
 const SizedBox(width: 3),
 const Text('away', style: TextStyle(fontSize: 10, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
 ],
),
 const SizedBox(height: 8),
 // eachline: left Expanded home teamplayer / right Expanded away teamplayer (edgeeachoneposition → 2 positionplayer/line)
...List.generate(maxLen, (i) {
 final hPlayer = i < homeList.length ? homeList[i]: null;
 final aPlayer = i < awayList.length ? awayList[i]: null;
 return Padding(
 padding: const EdgeInsets.only(bottom: 8),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Expanded(
 child: hPlayer != null
 ? _buildLineupSubPlayerChip(hPlayer)
: const SizedBox.shrink(),
),
 const SizedBox(width: 10),
 Expanded(
 child: aPlayer != null
 ? _buildLineupSubPlayerChip(aPlayer)
: const SizedBox.shrink(),
),
 ],
),
);
 }),
 ],
),
);
 }

 /// substituteplayerline: number + Logo + Name (alignment hanklive _buildSubPlayerChip)
 /// tapjumpplayerdetailpage (alignment hanklive onTap)
 Widget _buildLineupSubPlayerChip(BMMatchLineupPlayer player) {
 final shirtNum = player.shirtNumber ?? 0;
 return GestureDetector(
 behavior: HitTestBehavior.opaque,
 onTap: () => _navigateToLineupPlayerDetail(player),
 child: Container(
 margin: const EdgeInsets.only(bottom: 8),
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
 decoration: BoxDecoration(
 color: BMColors.pitch900,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
),
 child: Row(
 children: [
 Text(
 '$shirtNum',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: BMColors.bright,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: BMColors.pitch700,
                shape: BoxShape.circle,
              ),
              child: (player.playerLogo != null && player.playerLogo!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        player.playerLogo!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.person, size: 12, color: BMColors.textTertiary),
                      ),
                    )
                  : const Icon(Icons.person, size: 12, color: BMColors.textTertiary),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                player.playerName ?? '',
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 fontSize: 11,
 color: BMColors.textPrimary,
),
),
),
 ],
),
),
);
 }

 /// injuryzone (Home + Away, user requirement: leftrightcolumn, eachline2player, left home team / right away team)
 Widget _buildLineupInjurySection(BMLineupData data) {
 final homeList = data.homeInjury;
 final awayList = data.awayInjury;
 if (homeList.isEmpty && awayList.isEmpty) {
 return const SizedBox.shrink();
 }
 final maxLen = homeList.length > awayList.length ? homeList.length: awayList.length;
 return Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: const Color(0xFF7F1D1D).withValues(alpha: 0.5)),
 boxShadow: const [
 BoxShadow(
 color: Color(0x0FEF4444),
 blurRadius: 8,
 offset: Offset(0, 2),
),
 ],
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // title row + home/awaysmalltag (leftrightside)
 Row(
 children: [
 const Icon(Icons.local_hospital, size: 14, color: Color(0xFFF87171)),
 const SizedBox(width: 8),
 const Text(
 'injury',
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w700,
 color: BMColors.textPrimary,
),
),
 const Spacer(),
 // home teamsmall ball
 Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle)),
 const SizedBox(width: 3),
 const Text('home', style: TextStyle(fontSize: 10, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
 const SizedBox(width: 10),
 // away teamsmall ball
 Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
 const SizedBox(width: 3),
 const Text('away', style: TextStyle(fontSize: 10, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
 ],
),
 const SizedBox(height: 8),
 // eachline: left Expanded home team / right Expanded away team (eachline 2 positionplayer, user requirement)
...List.generate(maxLen, (i) {
 final hPlayer = i < homeList.length ? homeList[i]: null;
 final aPlayer = i < awayList.length ? awayList[i]: null;
 return Padding(
 padding: const EdgeInsets.only(bottom: 8),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Expanded(
 child: hPlayer != null
 ? _buildLineupInjuryPlayerChip(hPlayer)
: const SizedBox.shrink(),
),
 const SizedBox(width: 10),
 Expanded(
 child: aPlayer != null
 ? _buildLineupInjuryPlayerChip(aPlayer)
: const SizedBox.shrink(),
),
 ],
),
);
 }),
 ],
),
);
 }

 Widget _buildLineupInjuryPlayerChip(BMMatchLineupPlayer player) {
 return GestureDetector(
 onTap: () => _navigateToLineupPlayerDetail(player),
 behavior: HitTestBehavior.opaque,
 child: Container(
 margin: const EdgeInsets.only(bottom: 6),
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
 decoration: BoxDecoration(
 color: const Color(0xFF2B0E0E),
 borderRadius: BorderRadius.circular(8),
),
 child: Row(
 children: [
 if (player.playerLogo != null && player.playerLogo!.isNotEmpty)
 ClipOval(
 child: Image.network(
 player.playerLogo!,
 width: 24,
 height: 24,
 fit: BoxFit.cover,
 errorBuilder: (c, e, s) => Container(
 width: 24,
 height: 24,
 color: const Color(0xFF7F1D1D),
),
),
)
 else
 Container(
 width: 24,
 height: 24,
 decoration: const BoxDecoration(
 color: Color(0xFF7F1D1D),
 shape: BoxShape.circle,
),
 child: const Icon(Icons.person, size: 14, color: Color(0xFFF87171)),
),
 const SizedBox(width: 8),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 player.playerName ?? '',
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w600,
 color: BMColors.textPrimary,
),
),
 // injuryreason (HankLineupInjuryPlayer.reason alignment, prioritydisplay; missing reason displayposition fallback)
 if (player.reason != null && player.reason!.isNotEmpty)
 Text(
 player.reason!,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 fontSize: 10,
 color: Color(0xFFF87171),
),
)
 else if (player.position != null && player.position!.isNotEmpty)
 Text(
 player.position!,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 fontSize: 10,
 color: Color(0xFFF87171),
),
),
 ],
),
),
 ],
),
),
);
 }

 // =========== H2H Tab (100% alignment hanklive logic: WDL + filterdevice + WLcoloritemscard) ===========
 Widget _buildH2HTab() {
 _ensureH2H();
 final homeName = widget.match.homeTeamName.isNotEmpty
 ? widget.match.homeTeamName
: widget.match.homeTeam?.teamName ?? 'home team';
    final awayName = widget.match.awayTeamName.isNotEmpty
        ? widget.match.awayTeamName
        : widget.match.awayTeam?.teamName ?? 'away team';
 // currenthome team of teamId (from BMMatchTeam.teamId take String -> int, failurethen -1)
 final curHomeTeamId = int.tryParse(widget.match.homeTeam?.teamId ?? '') ?? -1;
    final curAwayTeamId = int.tryParse(widget.match.awayTeam?.teamId ?? '') ?? -2;

    if (_loadingH2H && _h2hHomeList.isEmpty && _h2hAwayList.isEmpty) {
      return _buildLoading(BMColors.bright);
    }
    final hasAny = _h2hHomeList.isNotEmpty || _h2hAwayList.isNotEmpty;
    if (!hasAny) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: Text('No encountershistory', style: TextStyle(color: BMColors.textTertiary, fontSize: 12))),
);
 }
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const SizedBox(height: 4),
 // ============ home teamsection ============
 if (_h2hHomeList.isNotEmpty)...[
 _buildH2HSectionHeader(
 title: homeName.isEmpty ? 'home teamrecent match' : '$homeName · recent match',
 color: BMColors.bright,
 icon: Icons.shield_rounded,
),
 const SizedBox(height: 8),
 _h2hHomeSection(
 list: _h2hHomeList,
 currentTeamId: curHomeTeamId,
 opponentTeamId: curAwayTeamId,
 sideColor: BMColors.bright,
 limit: _h2hHomeLimit,
 sameSide: _h2hHomeSameSide,
 leagueOnly: _h2hHomeLeagueOnly,
 onLimitChanged: (v) => setState(() => _h2hHomeLimit = v),
 onSameSideChanged: (v) => setState(() => _h2hHomeSameSide = v),
 onLeagueOnlyChanged: (v) => setState(() => _h2hHomeLeagueOnly = v),
 isHomeSection: true,
),
 const SizedBox(height: 18),
 ],
 // ============ away teamsection ============
 if (_h2hAwayList.isNotEmpty)...[
 _buildH2HSectionHeader(
 title: awayName.isEmpty ? 'away teamrecent match' : '$awayName · recent match',
 color: const Color(0xFF3B82F6),
 icon: Icons.travel_explore_rounded,
),
 const SizedBox(height: 8),
 _h2hHomeSection(
 list: _h2hAwayList,
 currentTeamId: curAwayTeamId,
 opponentTeamId: curHomeTeamId,
 sideColor: const Color(0xFF3B82F6),
 limit: _h2hAwayLimit,
 sameSide: _h2hAwaySameSide,
 leagueOnly: _h2hAwayLeagueOnly,
 onLimitChanged: (v) => setState(() => _h2hAwayLimit = v),
 onSameSideChanged: (v) => setState(() => _h2hAwaySameSide = v),
 onLeagueOnlyChanged: (v) => setState(() => _h2hAwayLeagueOnly = v),
 isHomeSection: false,
),
 const SizedBox(height: 16),
 ],
 ],
);
 }

 /// encountersminsection Header (vertical items + icon + title)
 Widget _buildH2HSectionHeader({required String title, required Color color, required IconData icon}) {
 return Padding(
 padding: const EdgeInsets.symmetric(horizontal: 14),
 child: Row(
 children: [
 Container(
 width: 3,
 height: 16,
 decoration: BoxDecoration(
 color: color,
 borderRadius: BorderRadius.circular(999),
),
),
 const SizedBox(width: 8),
 Icon(icon, size: 15, color: color),
 const SizedBox(width: 5),
 Expanded(
 child: Text(
 title,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 13,
 fontWeight: FontWeight.w800,
 color: color,
 letterSpacing: 0.3,
),
),
),
 ],
),
);
 }

 /// singlesectioncompleteencounterszone (filterdevice + cardlist) — user requirement: remove WDL ratioexampleitemszone
 Widget _h2hHomeSection({
 required List<BMH2HMatch> list,
 required int currentTeamId,
 required int opponentTeamId,
 required Color sideColor,
 required int limit,
 required bool sameSide,
 required bool leagueOnly,
 required ValueChanged<int> onLimitChanged,
 required ValueChanged<bool> onSameSideChanged,
 required ValueChanged<bool> onLeagueOnlyChanged,
 required bool isHomeSection,
 }) {
 // === filterdevicelogic (1:1 alignment hanklive _filteredMatches) ===
 var filtered = list.toList();
 if (sameSide) {
 filtered = filtered.where((m) =>
 (m.homeTeamId == currentTeamId && m.awayTeamId == opponentTeamId) ||
 (m.awayTeamId == currentTeamId && m.homeTeamId == opponentTeamId)).toList();
 }
 if (leagueOnly) {
 filtered = filtered.where((m) {
 final ln = m.leagueName ?? '';
        return !ln.toLowerCase().contains('cup');
 }).toList();
 }
 final display = filtered.take(limit).toList();

 return Padding(
 padding: const EdgeInsets.symmetric(horizontal: 14),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // ① filterdevicepill (alignment hanklive _buildFilterChips)
 _buildFilterRow(
 sideColor: sideColor,
 limit: limit,
 sameSide: sameSide,
 leagueOnly: leagueOnly,
 onLimitChanged: onLimitChanged,
 onSameSideChanged: onSameSideChanged,
 onLeagueOnlyChanged: onLeagueOnlyChanged,
),
 const SizedBox(height: 14),
 // ② cardlist (alignment hanklive...displayMatches.map)
 if (display.isEmpty)
 const Padding(
 padding: EdgeInsets.symmetric(vertical: 20),
 child: Center(
 child: Text('No data after filter', style: TextStyle(fontSize: 12, color: BMColors.textTertiary)),
),
)
 else
...display.map((m) => _buildH2HMatchCard(m, currentTeamId, sideColor, isHomeSection)),
 ],
),
);
 }

 /// filterdevicepillline (alignment hanklive Last 10/Last 6/HomeAway/LeagueOnly)
 Widget _buildFilterRow({
 required Color sideColor,
 required int limit,
 required bool sameSide,
 required bool leagueOnly,
 required ValueChanged<int> onLimitChanged,
 required ValueChanged<bool> onSameSideChanged,
 required ValueChanged<bool> onLeagueOnlyChanged,
 }) {
 return SizedBox(
 height: 34,
 child: ListView(
 scrollDirection: Axis.horizontal,
 physics: const BouncingScrollPhysics(),
 children: [
 _h2hChip('near 10 court', limit == 10, sideColor, () => onLimitChanged(10)),
          _h2hChip('near 6 court', limit == 6, sideColor, () => onLimitChanged(6)),
          _h2hChip('correct double direction', sameSide, sideColor, () => onSameSideChanged(!sameSide)),
          _h2hChip('onlyleague', leagueOnly, sideColor, () => onLeagueOnlyChanged(!leagueOnly)),
 ],
),
);
 }

 /// singlefilterpill
 Widget _h2hChip(String label, bool selected, Color sideColor, VoidCallback onTap) {
 return GestureDetector(
 onTap: onTap,
 behavior: HitTestBehavior.opaque,
 child: Container(
 margin: const EdgeInsets.only(right: 8),
 padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
 decoration: BoxDecoration(
 color: selected ? sideColor.withValues(alpha: 0.18): BMColors.pitch800,
 borderRadius: BorderRadius.circular(999),
 border: Border.all(
 color: selected ? sideColor.withValues(alpha: 0.65): BMColors.pitch700.withValues(alpha: 0.5),
 width: selected ? 1.1: 0.8,
),
),
 child: Center(
 child: Text(
 label,
 style: TextStyle(
 fontSize: 11.5,
 fontWeight: selected ? FontWeight.w800: FontWeight.w600,
 color: selected ? sideColor: BMColors.textSecondary,
),
),
),
),
);
 }

 /// encountersmatch card (1:1 alignment hanklive: left side 4px WLcoloritems + TopRow + ScoreRow)
 Widget _buildH2HMatchCard(BMH2HMatch m, int currentTeamId, Color sideColor, bool isHomeSection) {
 final homeIsCur = m.homeTeamId == currentTeamId;
 final awayIsCur = m.awayTeamId == currentTeamId;
 final hs = m.homeNormalScore ?? m.homeScore;
 final as = m.awayNormalScore ?? m.awayScore;

 // left side 4px WLcoloritems (W sidecolor / L / D )
 Color barColor;
 if (hs != null && as != null) {
 final curWin = (homeIsCur && hs > as) || (awayIsCur && as > hs);
 final curLose = (homeIsCur && hs < as) || (awayIsCur && as < hs);
 if (curWin) {
 barColor = sideColor;
 } else if (curLose) {
 barColor = const Color(0xFFEF4444);
 } else {
 barColor = const Color(0xFFF59E0B);
 }
 } else {
 barColor = BMColors.pitch700;
 }

 return GestureDetector(
 onTap: () {
 Navigator.push(
 context,
 MaterialPageRoute(builder: (_) => BMFootballDetailPage(match: m.toMatchModel)),
);
 },
 behavior: HitTestBehavior.opaque,
 child: Container(
 margin: const EdgeInsets.only(bottom: 12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.45), width: 0.9),
),
 clipBehavior: Clip.antiAlias,
 child: Row(
 children: [
 // left sideWLcoloritems
 Container(width: 4, height: 96, color: barColor),
 // content
 Expanded(
 child: Padding(
 padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
 child: Column(
 children: [
 // Row1: leagueLogo + league name + date / HT score
 _h2hCardTopRow(m),
 const SizedBox(height: 10),
 // Row2: home team | scorebadge | away team
 _h2hCardScoreRow(m, homeIsCur, awayIsCur, sideColor, hs, as, isHomeSection),
 ],
),
),
),
 ],
),
),
);
 }

 /// H2H card TopRow (leagueLogo+name+date / HT score)
 Widget _h2hCardTopRow(BMH2HMatch m) {
 return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: [
 if (m.leagueLogo != null && m.leagueLogo!.isNotEmpty)
 ClipRRect(
 borderRadius: BorderRadius.circular(2),
 child: Image.network(
 m.leagueLogo!,
 width: 14,
 height: 14,
 fit: BoxFit.cover,
 errorBuilder: (_, __, ___) => const SizedBox.shrink(),
),
)
 else
 const Icon(Icons.emoji_events, size: 14, color: BMColors.textTertiary),
 const SizedBox(width: 6),
 Text(
 m.leagueName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: BMColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              m.displayMatchTime,
              style: const TextStyle(fontSize: 11, color: BMColors.textTertiary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        if (m.homeHalfScore != null && m.awayHalfScore != null)
          Text(
            'halfcourt ${m.homeHalfScore} - ${m.awayHalfScore}',
 style: const TextStyle(fontSize: 10.5, color: BMColors.textTertiary, fontWeight: FontWeight.w600),
),
 ],
);
 }

 /// H2H cardscoreline (home team Logo+name left aligned | middlescorebadge | away teamname+Logo right aligned)
 Widget _h2hCardScoreRow(BMH2HMatch m, bool homeIsCur, bool awayIsCur, Color sideColor, int? hs, int? as, bool isHomeSection) {
 final homeWin = hs != null && as != null && hs > as;
 final awayWin = hs != null && as != null && as > hs;
 return Row(
 children: [
 // home team: left aligned Logo+Name
 Expanded(
 flex: 5,
 child: Row(
 children: [
 _h2hLogo(m.homeTeamLogo, sideColor),
 const SizedBox(width: 7),
 Expanded(
 child: Text(
 m.homeTeamName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: homeIsCur ? FontWeight.w800 : FontWeight.w600,
                    color: homeIsCur
                        ? sideColor
                        : homeWin
                            ? BMColors.textPrimary
                            : BMColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // middlescorebadge (alignment hanklive _buildScoreBadge)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: BMColors.pitch900.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sideColor.withValues(alpha: 0.3), width: 0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${hs ?? '-'}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: homeWin ? sideColor : BMColors.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 4),
              const Text('-', style: TextStyle(fontSize: 12, color: BMColors.textTertiary)),
              const SizedBox(width: 4),
              Text(
                '${as ?? '-'}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: awayWin ? const Color(0xFFEF4444) : BMColors.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        // away team: right aligned Name+Logo
        Expanded(
          flex: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  m.awayTeamName ?? '',
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 textAlign: TextAlign.right,
 style: TextStyle(
 fontSize: 12.5,
 fontWeight: awayIsCur ? FontWeight.w800: FontWeight.w600,
 color: awayIsCur
 ? (isHomeSection ? const Color(0xFF3B82F6): sideColor)
: BMColors.textPrimary,
),
),
),
 const SizedBox(width: 7),
 _h2hLogo(m.awayTeamLogo, const Color(0xFF3B82F6)),
 ],
),
),
 ],
);
 }

 /// H2H Logo (24x24 rounded cornerdirection)
 Widget _h2hLogo(String? logo, Color placeholderColor) {
 if (logo != null && logo.isNotEmpty) {
 return ClipRRect(
 borderRadius: BorderRadius.circular(4),
 child: Image.network(
 logo,
 width: 24,
 height: 24,
 fit: BoxFit.cover,
 errorBuilder: (_, __, ___) => Container(
 width: 24,
 height: 24,
 decoration: BoxDecoration(
 color: placeholderColor.withValues(alpha: 0.14),
 borderRadius: BorderRadius.circular(4),
),
 child: Icon(Icons.sports_soccer, size: 13, color: placeholderColor),
),
),
);
 }
 return Container(
 width: 24,
 height: 24,
 decoration: BoxDecoration(
 color: placeholderColor.withValues(alpha: 0.14),
 borderRadius: BorderRadius.circular(4),
),
 child: Icon(Icons.sports_soccer, size: 13, color: placeholderColor),
);
 }

 void _snack(String msg) {
 if (!mounted) return;
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(msg, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
 backgroundColor: BMColors.pitch850,
 behavior: SnackBarBehavior.floating,
 duration: const Duration(milliseconds: 1200),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
),
);
 }
}

/// BMH2HMatch expanded: displaytime
extension on BMH2HMatch {
 String get displayMatchTime {
 if (matchTime == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(matchTime! * 1000);
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
 }
}

/// _BMPitchLinePainter - ballcourtline (halfway line/center circle/upperlowerforbiddenzone, alignment hanklive _PitchLinePainter)
class _BMPitchLinePainter extends CustomPainter {
 @override
 void paint(Canvas canvas, Size size) {
 final paint = Paint()
..color = Colors.white.withValues(alpha: 0.15)
..style = PaintingStyle.stroke
..strokeWidth = 1;

 // halfway line
 canvas.drawLine(
 Offset(16, size.height / 2),
 Offset(size.width - 16, size.height / 2),
 paint,
);

 // center circle (40half, alignmenthanklive)
 canvas.drawCircle(
 Offset(size.width / 2, size.height / 2),
 40,
 paint,
);

 // upperpartforbiddenzone (upperhalfaway teamdirection)
 canvas.drawRRect(
 RRect.fromRectAndCorners(
 Rect.fromCenter(
 center: Offset(size.width / 2, 0),
 width: 120,
 height: 48,
),
 bottomLeft: const Radius.circular(8),
 bottomRight: const Radius.circular(8),
),
 paint,
);

 // lowerpartforbiddenzone (lowerhalfhome teamdirection)
 canvas.drawRRect(
 RRect.fromRectAndCorners(
 Rect.fromCenter(
 center: Offset(size.width / 2, size.height),
 width: 120,
 height: 48,
),
 topLeft: const Radius.circular(8),
 topRight: const Radius.circular(8),
),
 paint,
);
 }

 @override
 bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
