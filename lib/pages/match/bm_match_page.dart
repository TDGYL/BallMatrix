import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../viewmodels/home/bm_home_view_model.dart' show BMSportType;
import '../../services/bm_match_api_service.dart';
import 'bm_football_detail_page.dart';
import 'bm_basketball_detail_page.dart';

///////-matchlist------- of textfile---cardtime，aiownsolvenotissue--usematchList
class BMMatchPage extends BMBasePage {
 /// sport type (BMSportType type, football/basketball)
 final BMSportType sportType;

 const BMMatchPage({super.key, required this.sportType});

 @override
 State<BMMatchPage> createState() => _BMMatchPageState();
}

class _BMMatchPageState extends BMBasePageState<BMMatchPage> {
 /// matchlistdata (Listtype, elementasBMMatchModel)
 List<BMMatchModel> _matchList = [];

 /// first timeloadingorpull downrefreshin (bool type, onlymakeUI Loading)
 bool _isRefreshing = true;

 /// pull upload morein (bool type, onlymakeUI footer Loading)
 bool _isLoadingMore = false;

 /// requestre-entry lock (bool type, true=hasrequestcenter, returnduplicaterequest, independentUI Loadingflag)
 bool _isFetching = false;

 /// has next page (bool type, true=cancontinuepull up)
 bool _hasNoMore = false;

 /// current pagecode (int type, starting from 1)
 int _page = 1;

 /// per pagecount (int type, default10, alignmenthanklive All tab)
 final int _size = 10;

 /// currentdatetimestamp (int type, secondlevel, defaulttoday0point)
 int _currentTimestamp = 0;

 /// currentselected of DateTime (fordatedialoghighlight)
 DateTime _selectedDate = DateTime.now();

 /// listscrollcontroller (ScrollController type, forpull upload morelistener)
 late final ScrollController _scrollController;

 /// API serviceinstance
 final BMMatchApiService _apiService = BMMatchApiService();

 @override
 void initState() {
 super.initState();
 final now = DateTime.now();
 _selectedDate = DateTime(now.year, now.month, now.day);
 _currentTimestamp = _selectedDate.millisecondsSinceEpoch ~/ 1000;
 _scrollController = ScrollController()..addListener(_onScroll);
 _fetchMatches(isRefresh: true);
 }

 @override
 void dispose() {
 _scrollController.dispose();
 super.dispose();
 }

 /// scrolllistener: bottom100pxinnerandhasmorepageandnonloadingin, sendpull uploading (alignmenthanklive)
 void _onScroll() {
 if (_scrollController.position.pixels >=
 _scrollController.position.maxScrollExtent - 100) {
 if (!_isLoadingMore && !_isRefreshing && !_hasNoMore) {
 _fetchMatches(isRefresh: false);
 }
 }
 }

 /// gettakecurrentselecteddate of timestamp (secondlevel)
 int _getSelectedTimestamp() {
 return _currentTimestamp;
 }

 /// requestmatchlistdata (alignment hanklive _fetchMatches)
 /// [isRefresh] - true=refresh（reset page=1,clearlist）；false=load more(page+1,append)
 Future<void> _fetchMatches({required bool isRefresh}) async {
 // --- Step 1: independentrequest _isFetching, and UI Loading _isRefreshing completefull ---
 if (_isFetching) {
 debugPrint(
 '🔒 BMMatchPage requestblocked (re-entry): isRefresh=$isRefresh, _page=$_page, _isFetching=true',
);
 return;
 }
 if (!isRefresh) {
 // load morewhenquotaouterchecknonemorepage
 if (_hasNoMore) {
 debugPrint('🔒 BMMatchPage load moreby: _hasNoMore=true');
        return;
      }
    }
    _isFetching = true;
    debugPrint(
      '🌐 BMMatchPage startrequest: isRefresh=$isRefresh, sport=${widget.sportType}, page=${isRefresh ? 1: _page + 1}, timestamp=${_currentTimestamp == 0 ? '(todayday)' : _currentTimestamp}',
    );

    final int requestPage;
    if (isRefresh) {
      if (!mounted) {
        _isFetching = false;
        return;
      }
      setState(() {
        _isRefreshing = true;
        _page = 1;
        _hasNoMore = false;
      });
      requestPage = 1;
    } else {
      if (!mounted) {
        _isFetching = false;
        return;
      }
      setState(() {
        _isLoadingMore = true;
      });
      requestPage = _page + 1;
    }

    final timestamp = _getSelectedTimestamp();
    List<BMMatchModel> result = [];
    try {
      if (widget.sportType == BMSportType.football) {
        result = await _apiService.fetchFootballList(
          timestamp: timestamp,
          page: requestPage,
          size: _size,
        );
      } else {
        result = await _apiService.fetchBasketballList(
          timestamp: timestamp,
          page: requestPage,
          size: _size,
        );
      }
      debugPrint('✅ BMMatchPage request success: this returns ${result.length} items, size=$_size');
    } catch (e) {
      debugPrint(
        '❌ BMMatchPage requestexception(isRefresh=$isRefresh, page=$requestPage): $e',
);
 result = [];
 } finally {
 _isFetching = false; // nonesuccessfailure, releaserequest
 }

 if (!mounted) return;
 setState(() {
 if (isRefresh) {
 _matchList = result;
 _page = 1;
 _isRefreshing = false;
 } else {
 _matchList.addAll(result);
 _page = requestPage;
 _isLoadingMore = false;
 }
 // returnscountsmallper pagecount, markerno more datapage (alignmenthanklive)
 if (result.length < _size) {
 _hasNoMore = true;
 debugPrint(
 '🛑 BMMatchPage nonemorepage, this pagereturns ${result.length} < size=$_size, markerhasNoMore=true',
);
 }
 });
 }

 /// pull downrefreshcallback (RefreshIndicator)
 Future<void> _onRefresh() {
 return _fetchMatches(isRefresh: true);
 }

 /// navigationtitle
 String get _navTitle {
 return widget.sportType == BMSportType.football
 ? 'FootBall List'
        : 'BasketBall List';
 }

 @override
 Widget buildBody(BuildContext context) {
 return Column(
 children: [
 _buildNavBar(context),
 Expanded(child: _buildMatchList()),
 ],
);
 }

 /// buildcustom app bar (returns + title + top-right cornerdaybutton)
 Widget _buildNavBar(BuildContext context) {
 return Container(
 padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
 decoration: BoxDecoration(
 color: BMColors.pitch950,
 border: Border(
 bottom: BorderSide(color: BMColors.pitch800, width: 0.5),
),
),
 child: Row(
 children: [
 IconButton(
 onPressed: () => Navigator.of(context).pop(),
 icon: const Icon(
 Icons.arrow_back_ios,
 size: 18,
 color: BMColors.textPrimary,
),
 padding: EdgeInsets.zero,
 constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
),
 Expanded(
 child: Text(
 _navTitle,
 textAlign: TextAlign.center,
 style: const TextStyle(
 fontSize: 16,
 fontWeight: FontWeight.bold,
 color: BMColors.textPrimary,
),
),
),
 IconButton(
 onPressed: () => _showDatePickerSheet(context),
 icon: const Icon(
 Icons.calendar_today_outlined,
 size: 20,
 color: BMColors.bright,
),
 padding: EdgeInsets.zero,
 constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
),
 ],
),
);
 }

 /// matchlistzone（includesfirst screenLoading + emptystate + pull downrefresh + pull uploading）
 Widget _buildMatchList() {
 // first timeloading / pull downrefreshandlistasemptywhendisplayfullLoading
 if (_isRefreshing && _matchList.isEmpty) {
 return const Center(
 child: CircularProgressIndicator(
 color: BMColors.bright,
 strokeWidth: 2,
),
);
 }

 // emptystate
 if (_matchList.isEmpty) {
 return RefreshIndicator(
 color: BMColors.bright,
 backgroundColor: BMColors.pitch850,
 onRefresh: _onRefresh,
 child: ListView(
 physics: const AlwaysScrollableScrollPhysics(),
 children: const [
 SizedBox(height: 140),
 Center(
 child: Icon(
 Icons.sports_soccer_outlined,
 size: 48,
 color: BMColors.textTertiary,
),
),
 SizedBox(height: 12),
 Center(
 child: Text(
 'whendayNo match',
 style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
),
),
 ],
),
);
 }

 // centerlist(byleaguegroup) + pull downrefresh
 return _buildGroupedList();
 }

 /// bottomloadingindicator (alignmenthanklive _buildFooter)
 Widget _buildFooter() {
 if (_hasNoMore) {
 return Padding(
 padding: const EdgeInsets.symmetric(vertical: 20),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Container(width: 24, height: 1, color: BMColors.pitch700),
 const SizedBox(width: 8),
 const Text(
 '—— no more ——',
              style: TextStyle(fontSize: 11, color: BMColors.textTertiary),
            ),
            const SizedBox(width: 8),
            Container(width: 24, height: 1, color: BMColors.pitch700),
          ],
        ),
      );
    }
    if (_isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: BMColors.bright,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'loadingin...',
 style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
),
 ],
),
);
 }
 return const SizedBox.shrink();
 }

 /// buildbyleaguegrouplater of completelist (upperdirection ListView.builder temporarysolution)
 Widget _buildGroupedList() {
 final Map<String, List<BMMatchModel>> grouped = {};
 for (final match in _matchList) {
 grouped.putIfAbsent(match.leagueName, () => []).add(match);
 }
 final children = <Widget>[];
 for (final entry in grouped.entries) {
 children.add(_buildLeagueHeader(entry.key, entry.value.length));
 children.add(const SizedBox(height: 8));
 for (final m in entry.value) {
 children.add(_buildFlatMatchItem(m));
 children.add(const SizedBox(height: 8));
 }
 children.add(const SizedBox(height: 8));
 }
 children.add(_buildFooter());
 return RefreshIndicator(
 color: BMColors.bright,
 backgroundColor: BMColors.pitch850,
 onRefresh: _onRefresh,
 child: ListView(
 controller: _scrollController,
 physics: const AlwaysScrollableScrollPhysics(),
 padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
 children: children,
),
);
 }

 /// buildleaguegroupheader
 Widget _buildLeagueHeader(String leagueName, int count) {
 return Padding(
 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: [
 const Icon(Icons.emoji_events, size: 14, color: BMColors.amber),
 const SizedBox(width: 6),
 Flexible(
 child: Text(
 leagueName,
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w600,
 color: BMColors.textSecondary,
),
 overflow: TextOverflow.ellipsis,
),
),
 ],
),
 Text(
 '$count court',
 style: const TextStyle(fontSize: 12, color: BMColors.textSecondary),
),
 ],
),
);
 }

 /// buildsinglecourtmatchline (colorbackgroundcard + teamLogo + colorteam name + colorscoreNo.)
 Widget _buildFlatMatchItem(BMMatchModel match) {
 final homeLogo = match.homeTeam?.logoUrl ?? match.homeTeamLogo;
 final awayLogo = match.awayTeam?.logoUrl ?? match.awayTeamLogo;
 return GestureDetector(
 behavior: HitTestBehavior.opaque,
 onTap: () {
 Navigator.push(
 context,
 MaterialPageRoute(
 builder: (_) => widget.sportType == BMSportType.football
 ? BMFootballDetailPage(match: match)
: BMBasketballDetailPage(match: match),
),
);
 },
 child: Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: BMColors.pitch600.withValues(alpha: 0.4)),
),
 child: Row(
 children: [
 _buildMatchTimeOrStatus(match),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 children: [
 _buildTeamLine(
 homeLogo,
 match.homeTeamName,
 match.homeScore ?? 0,
 match.status == BMMatchStatus.live,
),
 const SizedBox(height: 6),
 _buildTeamLine(
 awayLogo,
 match.awayTeamName,
 match.awayScore ?? 0,
 false,
),
 ],
),
),
 const SizedBox(width: 8),
 _buildStatusChip(match),
 ],
),
),
);
 }

 /// buildtime/statecolumn (LIVEtagbright green, FINAL, TBD, not started)
 Widget _buildMatchTimeOrStatus(BMMatchModel match) {
 final isLive = match.status == BMMatchStatus.live;
 final isEnded = match.status == BMMatchStatus.ended;
 final isTbd = match.status == BMMatchStatus.tbd;
 return SizedBox(
 width: 44,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 if (isLive)...[
 Text(
 (match.liveMinute != null && match.liveMinute!.isNotEmpty)
 ? match.liveMinute!
: match.matchTime,
 style: const TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.bold,
 color: BMColors.bright,
),
),
 ] else...[
 Text(
 match.matchTime,
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w600,
 color: isEnded ? BMColors.textSecondary: BMColors.textPrimary,
),
),
 ],
 const SizedBox(height: 2),
 if (isTbd)
 const Text(
 'TBD',
              style: TextStyle(fontSize: 9, color: BMColors.purple),
            )
          else if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: BMColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 9,
                  color: BMColors.bright,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isEnded)
            const Text(
              'FINAL',
              style: TextStyle(fontSize: 9, color: BMColors.textTertiary),
            )
          else
            const Text(
              'not started',
 style: TextStyle(fontSize: 9, color: BMColors.cyan),
),
 ],
),
);
 }

 /// buildteam+scoresingleline (Logo + colorteam name + score)
 Widget _buildTeamLine(String? logo, String name, int score, bool highlight) {
 return Row(
 children: [
 Container(
 width: 20,
 height: 20,
 decoration: const BoxDecoration(
 shape: BoxShape.circle,
 color: BMColors.pitch800,
),
 child: ClipOval(
 child: (logo != null && logo.isNotEmpty)
 ? Image.network(
 logo,
 fit: BoxFit.cover,
 errorBuilder: (_, _, _) => const Icon(
 Icons.sports_soccer,
 size: 12,
 color: BMColors.textSecondary,
),
)
: Icon(
 widget.sportType == BMSportType.football
 ? Icons.sports_soccer
: Icons.sports_basketball,
 size: 12,
 color: BMColors.textSecondary,
),
),
),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 name,
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.bold,
 color: BMColors.bright,
),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
),
),
 const SizedBox(width: 8),
 Text(
 score.toString(),
 style: TextStyle(
 fontSize: 14,
 fontFamily: 'monospace',
 fontWeight: FontWeight.bold,
 color: highlight ? BMColors.bright: BMColors.textPrimary,
),
),
 ],
);
 }

 /// buildright sidestatepill (4kindcolor)
 Widget _buildStatusChip(BMMatchModel match) {
 final statusName = match.statusName;
 String text;
 Color bg;
 Color fg;
 switch (match.status) {
 case BMMatchStatus.live:
 text = statusName?.isNotEmpty == true ? statusName!: 'LIVE';
        bg = BMColors.accent.withValues(alpha: 0.12);
        fg = BMColors.bright;
        break;
      case BMMatchStatus.upcoming:
        text = statusName?.isNotEmpty == true ? statusName! : 'NS';
        bg = BMColors.cyan.withValues(alpha: 0.1);
        fg = BMColors.cyan;
        break;
      case BMMatchStatus.ended:
        text = statusName?.isNotEmpty == true ? statusName! : 'FT';
        bg = BMColors.pitch800;
        fg = BMColors.textSecondary;
        break;
      case BMMatchStatus.tbd:
        text = 'TBD';
 bg = BMColors.purple.withValues(alpha: 0.1);
 fg = BMColors.purple;
 break;
 }
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: bg,
 borderRadius: BorderRadius.circular(8),
),
 constraints: const BoxConstraints(minWidth: 48),
 child: Text(
 text,
 textAlign: TextAlign.center,
 style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600),
),
);
 }

 /// popbottomdateselectoptioncard
 void _showDatePickerSheet(BuildContext rootCtx) {
 showModalBottomSheet<DateTime>(
 context: rootCtx,
 backgroundColor: BMColors.pitch950,
 shape: const RoundedRectangleBorder(
 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
),
 builder: (sheetCtx) {
 return SafeArea(
 child: Padding(
 padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 _buildSheetHandle(),
 const SizedBox(height: 16),
 const Row(
 children: [
 Icon(
 Icons.calendar_month,
 size: 18,
 color: BMColors.bright,
),
 SizedBox(width: 8),
 Text(
 'selectdate',
 style: TextStyle(
 fontSize: 15,
 fontWeight: FontWeight.bold,
 color: BMColors.textPrimary,
),
),
 ],
),
 const SizedBox(height: 16),
 _buildQuickDatesRow(sheetCtx),
 const SizedBox(height: 16),
 _buildCalendarButton(sheetCtx),
 ],
),
),
);
 },
);
 }

 Widget _buildSheetHandle() {
 return Container(
 width: 40,
 height: 4,
 decoration: BoxDecoration(
 color: BMColors.pitch700,
 borderRadius: BorderRadius.circular(2),
),
);
 }

 /// fastdateline: yesterday / today / tomorrow / 3daylater / 7daylater
 Widget _buildQuickDatesRow(BuildContext sheetCtx) {
 final today = DateTime.now();
 final items = [
 ('yesterday', today.subtract(const Duration(days: 1))),
      ('today', today),
      ('tomorrow', today.add(const Duration(days: 1))),
      ('3daylater', today.add(const Duration(days: 3))),
      ('7daylater', today.add(const Duration(days: 7))),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) {
        final label = item.$1;
        final date = item.$2;
        final onlyDate = DateTime(date.year, date.month, date.day);
        final selected =
            onlyDate ==
            DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
            );
        return GestureDetector(
          onTap: () {
            Navigator.pop(sheetCtx);
            _onDateSelected(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? BMColors.accent : BMColors.pitch850,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? BMColors.accent.withValues(alpha: 0.4)
                    : BMColors.pitch700,
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? BMColors.pitch950 : BMColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.month}/${date.day}',
 style: TextStyle(
 fontSize: 10,
 color: selected
 ? BMColors.pitch950.withValues(alpha: 0.85)
: BMColors.textSecondary,
),
),
 ],
),
),
);
 }).toList(),
);
 }

 /// opensystemsystemdatepicker, supportanydate
 Widget _buildCalendarButton(BuildContext sheetCtx) {
 return SizedBox(
 width: double.infinity,
 child: ElevatedButton.icon(
 onPressed: () async {
 Navigator.pop(sheetCtx);
 final now = DateTime.now();
 final picked = await showDatePicker(
 context: sheetCtx,
 initialDate: _selectedDate,
 firstDate: DateTime(now.year - 1),
 lastDate: DateTime(now.year + 1),
 builder: (ctx, child) {
 return Theme(
 data: Theme.of(ctx).copyWith(
 colorScheme: const ColorScheme.dark(
 primary: BMColors.bright,
 onPrimary: Color(0xFF0E2620),
 surface: Color(0xFF0E2620),
 onSurface: Color(0xFFE2E8F0),
),
 dialogTheme: const DialogThemeData(
 backgroundColor: Color(0xFF0E2620),
),
),
 child: child!,
);
 },
);
 if (picked != null) {
 _onDateSelected(picked);
 }
 },
 style: ElevatedButton.styleFrom(
 backgroundColor: BMColors.pitch850,
 foregroundColor: BMColors.textPrimary,
 elevation: 0,
 padding: const EdgeInsets.symmetric(vertical: 12),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 side: BorderSide(color: BMColors.pitch700),
),
),
 icon: const Icon(
 Icons.date_range_outlined,
 size: 16,
 color: BMColors.bright,
),
 label: const Text(
 'date',
 style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
),
),
);
 }

 /// dateselectedcallback: updatetimestampandre-request (isRefresh=true)
 void _onDateSelected(DateTime date) {
 final onlyDate = DateTime(date.year, date.month, date.day);
 final ts = onlyDate.millisecondsSinceEpoch ~/ 1000;
 setState(() {
 _selectedDate = onlyDate;
 _currentTimestamp = ts;
 });
 _fetchMatches(isRefresh: true);
 }
}
