import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../viewmodels/home/bm_home_view_model.dart' show BMSportType;
import '../../widgets/home/bm_match_spotlight_card.dart';
import '../../services/bm_match_api_service.dart';
import 'bm_football_detail_page.dart';
import 'bm_basketball_detail_page.dart';

/// BMMatchListPage - competitionlistpage (home「view all」push enter)
/// feature: trueactualPOSTAPI request(tab=0/whendaytimestamp) + reusehomecard + pull downrefresh + pull uploading
class BMMatchListPage extends BMBasePage {
 /// sport type (BMSportType type, football/basketball)
 final BMSportType sportType;

 const BMMatchListPage({
 super.key,
 required this.sportType,
 });

 @override
 State<BMMatchListPage> createState() => _BMMatchListPageState();
}

class _BMMatchListPageState extends BMBasePageState<BMMatchListPage> {
 /// matchlistdata (Listtype, elementasBMMatchModel)
 List<BMMatchModel> _matchList = [];

 /// pull downrefreshor first loading (bool type, onlymakeUIfullLoading)
 bool _isRefreshing = true;

 /// pull upload morein (bool type, control bottom footer Loading)
 bool _isLoadingMore = false;

 /// requestre-entry lock (bool type, true=hasrequest, duplicatesend)
 bool _isFetching = false;

 /// has next page (bool type, true=cancontinuepull up)
 bool _hasNoMore = false;

 /// current pagecode (int type, starting from 1)
 int _page = 1;

 /// per pagecount (int type, default10, alignmenthanklive)
 final int _size = 10;

 /// currentselected of datetimestamp (int type, secondlevel, defaulttoday0point)
 int _currentTimestamp = 0;

 /// listscrollcontroller (ScrollController type, pull uploadinglistener)
 late final ScrollController _scrollController;

 /// API serviceinstance (BMMatchApiService type)
 final BMMatchApiService _apiService = BMMatchApiService();

 @override
 void initState() {
 super.initState();
 _scrollController = ScrollController()..addListener(_onScroll);
 _fetchMatches(isRefresh: true);
 }

 @override
 void dispose() {
 _scrollController.dispose();
 super.dispose();
 }

 /// scrolllistener: trigger pull within 100px of bottom upload more
 void _onScroll() {
 if (_scrollController.position.pixels >=
 _scrollController.position.maxScrollExtent - 100) {
 if (!_isFetching && !_isRefreshing && !_hasNoMore) {
 _fetchMatches(isRefresh: false);
 }
 }
 }

 /// gettakewhenday0pointsecondlevel timestamp (ifusernot yetselectdate, takedefaulttoday0point)
 int _getSelectedTimestamp() {
 if (_currentTimestamp > 0) return _currentTimestamp;
 final now = DateTime.now();
 final d = DateTime(now.year, now.month, now.day);
 return d.millisecondsSinceEpoch ~/ 1000;
 }

 /// requestmatchlist (trueactualPOSTAPI, tab=0 + whendaytimestamp + pagination)
 /// [isRefresh] - true=reset page=1 / false=load more page+1
 Future<void> _fetchMatches({required bool isRefresh}) async {
 if (_isFetching) {
 debugPrint('🔒 BMMatchListPage requestblocked (re-entry): isRefresh=$isRefresh, _page=$_page');
      return;
    }
    if (!isRefresh && _hasNoMore) {
      debugPrint('🔒 BMMatchListPage load moreby: _hasNoMore=true');
      return;
    }
    _isFetching = true;

    final int requestPage;
    if (isRefresh) {
      if (!mounted) { _isFetching = false; return; }
      setState(() {
        _isRefreshing = true;
        _page = 1;
        _hasNoMore = false;
      });
      requestPage = 1;
    } else {
      if (!mounted) { _isFetching = false; return; }
      setState(() {
        _isLoadingMore = true;
      });
      requestPage = _page + 1;
    }

    final timestamp = _getSelectedTimestamp();
    debugPrint('🌐 BMMatchListPage trueactual request start: sport=${widget.sportType.name}, tab=0, page=$requestPage, size=$_size, timestamp=$timestamp');
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
      debugPrint('✅ BMMatchListPage trueactual request success: this returns ${result.length} items');
    } catch (e) {
      debugPrint('❌ BMMatchListPage trueactual requestexception(isRefresh=$isRefresh, page=$requestPage): $e');
 result = [];
 } finally {
 _isFetching = false; // nonesuccessfailuremakereleaserequest
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
 // returnscount < per pagecount, markerno more datapage (alignmenthanklive)
 if (result.length < _size) {
 _hasNoMore = true;
 debugPrint('🛑 BMMatchListPage nonemorepage, this page ${result.length} < size=$_size');
 }
 });
 }

 /// pull downrefreshcallback
 Future<void> _onRefresh() {
 return _fetchMatches(isRefresh: true);
 }

 /// navigationtitle (FootBall List / BasketBall List)
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

 /// custom app bar (returns + title + daybutton + selecteddatesmalltext)
 Widget _buildNavBar(BuildContext context) {
 final now = DateTime.now();
 final todayMidnight = DateTime(now.year, now.month, now.day);
 final selectedMidnight = DateTime(
 _selectedDate.year, _selectedDate.month, _selectedDate.day);
 final diff = selectedMidnight.difference(todayMidnight).inDays;
 String dateLabel;
 if (diff == 0) {
 dateLabel = 'today';
    } else if (diff == 1) {
      dateLabel = 'tomorrow';
    } else if (diff == -1) {
      dateLabel = 'yesterday';
    } else {
      dateLabel =
          '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        border: Border(
          bottom: BorderSide(color: BMColors.pitch800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              debugPrint('👈 app barback buttontap');
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_ios,
                size: 18, color: BMColors.textPrimary),
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
          GestureDetector(
            onTap: () {
              debugPrint('📅 daytapgesturesend');
 _showDatePicker(context);
 },
 behavior: HitTestBehavior.opaque,
 child: SizedBox(
 width: 60,
 height: 40,
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 const Icon(Icons.calendar_month_outlined,
 size: 20, color: BMColors.bright),
 const SizedBox(height: 1),
 Text(
 dateLabel,
 style: TextStyle(
 fontSize: 9,
 color: diff == 0
 ? BMColors.bright
: BMColors.textSecondary,
 fontWeight:
 diff == 0 ? FontWeight.w600: FontWeight.normal,
),
),
 ],
),
),
),
 ],
),
);
 }

 /// popdatepicker (ballcourtdark greentheme)，selectedlaterusetheday0pointtimestamprefreshlist
 Future<void> _showDatePicker(BuildContext context) async {
 debugPrint('📅 _showDatePicker startline');
    final now = DateTime.now();
    final initialDate = _currentTimestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(_currentTimestamp * 1000)
        : DateTime(now.year, now.month, now.day);
    debugPrint('📅 initialDate = $initialDate, firstDate=${now.year - 2}, lastDate=${now.year + 1}');
    DateTime? picked;
    try {
      debugPrint('📅 await showDatePicker enterfirst');
      picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(now.year - 2),
        lastDate: DateTime(now.year + 1, now.month + 3),
        locale: const Locale('zh', 'CN'),
        builder: (ctx, child) {
          debugPrint('📅 showDatePicker builder enter');
          if (child == null) {
            debugPrint('⚠️ showDatePicker builder childyesnull, returnsemptyplaceholder');
            return const SizedBox.shrink();
          }
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: BMColors.bright,
                onPrimary: BMColors.pitch950,
                surface: BMColors.pitch900,
                onSurface: BMColors.textPrimary,
              ),
              scaffoldBackgroundColor: BMColors.pitch950,
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF0E2620),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: BMColors.bright,
                ),
              ),
            ),
            child: child,
          );
        },
      );
      debugPrint('📅 await showDatePicker returns picked=$picked');
    } catch (e, s) {
      debugPrint('❌ showDatePicker throwexception: $e');
      debugPrint('❌ call: $s');
      picked = null;
    }
    if (picked == null) {
      debugPrint('📅 userTake effectselectdate');
      return;
    }
    final ts = DateTime(picked.year, picked.month, picked.day)
            .millisecondsSinceEpoch ~/
        1000;
    _currentTimestamp = ts;
    _selectedDate = DateTime(picked.year, picked.month, picked.day);
    debugPrint(
        '📅 BMMatchListPage selecteddate: ${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')} timestamp=$ts, backuprefresh');
    await _fetchMatches(isRefresh: true);
    debugPrint('📅 listrefreshdone');
 }

 /// currentselected of DateTime (fordatedialoghighlight + app bardisplay"today/yesterday/MM-DD"smalltag)
 DateTime _selectedDate = DateTime.now();

 /// matchlistzone (includesfirst screenLoading/emptystate/pull downrefresh/pull uploading)
 Widget _buildMatchList() {
 if (_isRefreshing && _matchList.isEmpty) {
 return const Center(
 child: CircularProgressIndicator(
 color: BMColors.bright, strokeWidth: 2),
);
 }
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
 child: Icon(Icons.sports_soccer_outlined,
 size: 48, color: BMColors.textTertiary),
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
    return RefreshIndicator(
      color: BMColors.bright,
      backgroundColor: BMColors.pitch850,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: _matchList.length + 1,
        itemBuilder: (ctx, index) {
          if (index == _matchList.length) return _buildFooter();
          final match = _matchList[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BMMatchSpotlightCard(
              match: match,
              onTap: () {
                if (widget.sportType == BMSportType.football) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BMFootballDetailPage(match: match),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BMBasketballDetailPage(match: match),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  /// bottomloadingindicator
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
                  color: BMColors.bright, strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('loadingin...',
                style: TextStyle(fontSize: 12, color: BMColors.textSecondary)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
