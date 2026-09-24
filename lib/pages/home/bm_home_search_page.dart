import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/bm_match_model.dart';
import '../../models/bm_search_match_model.dart';
import '../../services/bm_community_api_service.dart';
import '../../theme/bm_colors.dart';
import '../bm_base_page.dart';
import '../match/bm_basketball_detail_page.dart';
import '../match/bm_football_detail_page.dart';

/// BMHomeSearchPage - homesearchpage
/// feature: homenavigationtop-right cornersearchbutton push enter
/// - keysearch: GET /api/livespeed/index/search (text=key, take matches group)
/// - hot matches: GET /api/livespeed/index/search/match/hot
/// - search history: SharedPreferences localcachenear 10 itemskeytext
/// - tapmatch card push to the corresponding sport typematch detail page (categoryId=2 basketball / othersfootball)
/// UI and BMPostTopicMatchSearchPage keep consistent of darkpitch green theme
class BMHomeSearchPage extends BMBasePage {
  const BMHomeSearchPage({super.key});

  @override
  State<BMHomeSearchPage> createState() => _BMHomeSearchPageState();
}

class _BMHomeSearchPageState extends BMBasePageState<BMHomeSearchPage> {
  /// search historylocalcache Key (String type, SharedPreferences)
  static const String _kHistoryKey = 'bm_home_search_history_v1';

  /// search historymaxcachecount (int type)
  static const int _kMaxHistory = 10;

  /// community API service (BMCommunityApiService type, search/API)
  final BMCommunityApiService _apiService = BMCommunityApiService();

  /// search fieldcontroller (TextEditingController type)
  final TextEditingController _searchController = TextEditingController();

  /// currentsearch keyword (String type, non-nullwhenshowsearch resultszone)
  String _keyword = '';

  /// search historylist (List<String> type, latestfirst, more 10 items)
  List<String> _history = [];

  /// search results - football list (List<BMSearchMatch> type, category=1)
  List<BMSearchMatch> _footballSearch = [];

  /// search results - basketball list (List<BMSearchMatch> type, category=2)
  List<BMSearchMatch> _basketballSearch = [];

  /// hot matches - football list (List<BMSearchMatch> type, category=1)
  List<BMSearchMatch> _footballHot = [];

  /// hot matches - basketball list (List<BMSearchMatch> type, category=2)
  List<BMSearchMatch> _basketballHot = [];

  /// currentselected of sport Tab (int type, 1=football 2=basketball)
  int _currentCategory = 1;

  /// searchloadingin (bool type)
  bool _searchLoading = false;

  /// loadingin (bool type)
  bool _hotLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _fetchHotMatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// fromlocal SharedPreferences loadingsearch history
  Future<void> _loadHistory() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final raw = pref.getString(_kHistoryKey);
      if (raw != null && raw.isNotEmpty) {
        final arr = jsonDecode(raw);
        if (arr is List) {
          setState(() {
            _history = arr.whereType<String>().take(_kMaxHistory).toList();
          });
        }
      }
    } catch (_) {}
  }

  /// savesearch historytolocal SharedPreferences (latestfirst, exceed 10 itemsbreak)
  Future<void> _saveHistory() async {
    try {
      final pref = await SharedPreferences.getInstance();
      await pref.setString(
        _kHistoryKey,
        jsonEncode(_history.take(_kMaxHistory).toList()),
      );
    } catch (_) {}
  }

  /// recordonetimesearch keyword (deduplicatelatertofirst, morekeep 10 items)
  /// [keyword] - search keyword (String type)
  void _recordHistory(String keyword) {
    final kw = keyword.trim();
    if (kw.isEmpty) return;
    setState(() {
      _history.remove(kw);
      _history.insert(0, kw);
      if (_history.length > _kMaxHistory) {
        _history = _history.sublist(0, _kMaxHistory);
      }
    });
    _saveHistory();
  }

  /// clearsearch history
  void _clearHistory() {
    setState(() {
      _history = [];
    });
    _saveHistory();
  }

  /// requesthot matches (GET /api/livespeed/index/search/match/hot)
  /// by category split by: football (1) add to array 1, basketball (2) add to array 2
  Future<void> _fetchHotMatches() async {
    final result = await _apiService.fetchHotMatches();
    if (!mounted) return;
    setState(() {
      final football = <BMSearchMatch>[];
      final basketball = <BMSearchMatch>[];
      for (final m in result) {
        if (m.categoryId == 2) {
          basketball.add(m);
        } else {
          football.add(m);
        }
      }
      _footballHot = football;
      _basketballHot = basketball;
      _hotLoading = false;
    });
  }

  /// keysearch match (GET /api/livespeed/index/search)
  /// filter data.matches arraysport typesplit by: football (1) add to array 1, basketball (2) add to array 2
  /// [text] - search keyword (String type, team name)
  Future<void> _doSearch(String text) async {
    final kw = text.trim();
    if (kw.isEmpty) {
      setState(() {
        _footballSearch = [];
        _basketballSearch = [];
        _keyword = '';
      });
      return;
    }
    setState(() {
      _keyword = kw;
      _searchLoading = true;
    });
    _recordHistory(kw);
    final result = await _apiService.fetchSearchResults(text: kw);
    if (!mounted) return;
    setState(() {
      final football = <BMSearchMatch>[];
      final basketball = <BMSearchMatch>[];
      for (final m in (result?.matches ?? [])) {
        if (m.categoryId == 2) {
          basketball.add(m);
        } else {
          football.add(m);
        }
      }
      _footballSearch = football;
      _basketballSearch = basketball;
      _searchLoading = false;
    });
  }

  /// taphistorykeytextsendsearch
  /// [keyword] - historykeytext (String type)
  void _onHistoryTap(String keyword) {
    _searchController.text = keyword;
    _doSearch(keyword);
  }

  /// removesinglehistorykeytext
  /// [keyword] - goalkeytext (String type)
  void _onRemoveHistory(String keyword) {
    setState(() {
      _history.remove(keyword);
    });
    _saveHistory();
  }

  /// switchsport Tab
  /// [category] - goaltype (int type, 1=football 2=basketball)
  void _switchCategory(int category) {
    if (_currentCategory == category) return;
    setState(() {
      _currentCategory = category;
    });
  }

  /// current Tab corresponding of datalist (haskeytakesearch results, otherwise thentake)
  List<BMSearchMatch> get _currentList {
    final searching = _keyword.isNotEmpty;
    if (_currentCategory == 2) {
      return searching ? _basketballSearch : _basketballHot;
    }
    return searching ? _footballSearch : _footballHot;
  }

  /// tapmatch card push to the corresponding sport typematch detail page
  /// [m] - search resultsmatch (BMSearchMatch type)
  void _onMatchTap(BMSearchMatch m) {
    final model = _buildMatchModel(m);
    Navigator.push(
      context,
      MaterialPageRoute(
        // sport typesplit by: categoryId=2 -> basketball detail, others -> football detail
        builder: (_) => (m.categoryId == 2)
            ? BMBasketballDetailPage(match: model)
            : BMFootballDetailPage(match: model),
      ),
    );
  }

  /// BMSearchMatch convert BMMatchModel (navigatematch detail pageusage)
  /// [m] - search resultsmatch (BMSearchMatch type)
  /// returns: BMMatchModel
  BMMatchModel _buildMatchModel(BMSearchMatch m) {
    final sport = (m.categoryId == 2)
        ? BMMatchSportType.basketball
        : BMMatchSportType.football;
    // kickoff timeformat (secondlevel timestamp -> HH:mm)
    String matchTime = '';
    final int? startTs = m.matchTime;
    if (startTs != null && startTs > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(startTs * 1000);
      matchTime =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return BMMatchModel(
      matchId: m.matchId?.toString() ?? '',
      leagueName: m.competitionName ?? '',
      status: BMMatchStatus.tbd,
      sportType: sport,
      matchTime: matchTime,
      homeTeam: BMTeamModel(
        teamId: m.homeTeamId?.toString() ?? '',
        teamName: m.homeTeamName ?? '',
        teamShort: '',
        logoUrl: m.homeTeamLogo,
      ),
      awayTeam: BMTeamModel(
        teamId: m.awayTeamId?.toString() ?? '',
        teamName: m.awayTeamName ?? '',
        teamShort: '',
        logoUrl: m.awayTeamLogo,
      ),
      homeScore: m.homeTeamScore,
      awayScore: m.awayTeamScore,
      isFeatured: false,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Container(
      color: BMColors.pitch950,
      child: Column(
        children: [
          _buildNavBar(),
          _buildSearchField(),
          _buildCategoryTabs(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// topnavigation (returns + title)
  Widget _buildNavBar() {
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: BMColors.textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Expanded(
            child: Text(
              'search match',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// search input field (darkrounded corner + bright greensearchicon)
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: BMColors.bright),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13, color: BMColors.textPrimary),
              textInputAction: TextInputAction.search,
              onSubmitted: _doSearch,
              onChanged: (v) {
                if (v.isEmpty) _doSearch('');
              },
              decoration: const InputDecoration(
                isCollapsed: true,
                hintText: 'search team namename',
                hintStyle: TextStyle(
                  color: BMColors.textTertiary,
                  fontSize: 13,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// sport Tab menu (football/basketball, Row+Expanded equally dividedwidth)
  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          Expanded(child: _buildCategoryTab('football', 1)),
          const SizedBox(width: 10),
          Expanded(child: _buildCategoryTab('basketball', 2)),
        ],
      ),
    );
  }

  /// singleitemssport Tab (selectedbright greenstroke, unselectedinstroke)
  /// [label] - Tab text (String type)
  /// [category] - Tab type (int type, 1=football 2=basketball)
  Widget _buildCategoryTab(String label, int category) {
    final bool selected = _currentCategory == category;
    return GestureDetector(
      onTap: () => _switchCategory(category),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? BMColors.bright.withValues(alpha: 0.12)
              : BMColors.pitch900,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? BMColors.bright : BMColors.pitch800,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? BMColors.bright : BMColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// main content (haskey=search results / nonekey=history+hot matches)
  Widget _buildBody() {
    final searching = _keyword.isNotEmpty;
    return ListView(
      key: ValueKey('body-$_currentCategory-$searching-$_keyword'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      children: [
        if (!searching && _history.isNotEmpty) ...[
          _buildHistorySection(),
          const SizedBox(height: 12),
        ],
        _buildSectionTitle(searching ? 'search results' : 'hot matches'),
        if (searching && _searchLoading)
          _buildLoading()
        else if (!searching && _hotLoading)
          _buildLoading()
        else if (_currentList.isEmpty)
          _buildEmpty(searching ? 'not yettorelatedmatch' : 'no hot matches')
        else
          ..._currentList.map(_buildMatchItem),
      ],
    );
  }

  /// search historyminzone (title + clearbutton + keytextpill Wrap)
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('search history'),
            GestureDetector(
              onTap: _clearHistory,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 13,
                      color: BMColors.textTertiary,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'clear',
                      style: TextStyle(
                        fontSize: 11,
                        color: BMColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _history.map(_buildHistoryChip).toList(),
        ),
      ],
    );
  }

  /// singleitemshistorykeytextpill (tapsearch, right side x removesingleitems)
  /// [keyword] - historykeytext (String type)
  Widget _buildHistoryChip(String keyword) {
    return GestureDetector(
      onTap: () => _onHistoryTap(keyword),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: BMColors.pitch900,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BMColors.pitch800),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              keyword,
              style: const TextStyle(
                fontSize: 12,
                color: BMColors.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: () => _onRemoveHistory(keyword),
              behavior: HitTestBehavior.opaque,
              child: const Icon(
                Icons.close,
                size: 12,
                color: BMColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// zone title (left sidebright greenvertical items + text)
  /// [title] - zone titletext (String type)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: BMColors.bright,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: BMColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// loadingplaceholder
  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: BMColors.bright,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  /// emptystateplaceholder
  /// [text] - emptystatetext (String type)
  Widget _buildEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: BMColors.textTertiary),
        ),
      ),
    );
  }

  /// singlecourtmatchitemsitem (darkcard: league nametop + leftrightteam name/team logo + middlescore)
  /// tap push to the corresponding sport typematch detail page
  /// [m] - search resultsmatch (BMSearchMatch type)
  /// formatmatch timeas yyyy/MM/dd
  /// [matchTime] - secondlevel timestamp (int? type)
  /// returns: formatdatestring, nonetimereturnsemptystring (notrender)
  String _formatMatchDate(int? matchTime) {
    if (matchTime == null || matchTime <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(matchTime * 1000);
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildMatchItem(BMSearchMatch m) {
    return GestureDetector(
      onTap: () => _onMatchTap(m),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: BMColors.pitch900.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // topline: top-left cornermatch time + right league name (vertically centered, timeandhome teamavatarleft aligned)
            if (_formatMatchDate(m.matchTime).isNotEmpty ||
                (m.competitionName ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // top-left cornermatch time (yyyy/MM/dd)
                    Text(
                      _formatMatchDate(m.matchTime),
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: BMColors.textTertiary,
                      ),
                    ),
                    // right league name
                    if ((m.competitionName ?? '').isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.competitionName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            color: BMColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            // home team + score + away team
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTeamLogo(m.homeTeamLogo, 26),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          m.homeTeamName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BMColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${m.homeTeamScore ?? 0} - ${m.awayTeamScore ?? 0}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: BMColors.bright,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          m.awayTeamName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BMColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      _buildTeamLogo(m.awayTeamLogo, 26),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// team logo (dark circle background + network Logo + failurefallbackshield icon)
  /// [url] - Logo URL (String? type)
  /// [size] - size (double type)
  Widget _buildTeamLogo(String? url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: BMColors.pitch800,
      ),
      child: ClipOval(
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(size),
              )
            : _fallbackIcon(size),
      ),
    );
  }

  /// team logofallbackicon (shield)
  /// [size] - size (double type)
  Widget _fallbackIcon(double size) {
    return Icon(Icons.shield, size: size * 0.55, color: BMColors.textTertiary);
  }
}
