import 'package:flutter/material.dart';

import '../../models/bm_search_match_model.dart';
import '../../services/bm_community_api_service.dart';
import '../../theme/bm_colors.dart';
import '../bm_base_page.dart';

/// BMPostTopicMatchSearchPage - post topic of related matchsearchpage
/// featurealigned with API hanklive HankPostMatchSearchPage:
/// - keysearch: GET /api/livespeed/index/search (text=key, take matches group)
/// - hot matches: GET /api/livespeed/index/search/match/hot
/// - tapanymatch card pop backpost pageand BMSearchMatch
/// UI differentiation: darkpitch green theme (pitch950 bottom + bright greenstrokecard + leftrightteam nameinnersidelayout),
/// referencepageaswhitebottomcard + center VS changepill, visually distinct
class BMPostTopicMatchSearchPage extends BMBasePage {
  const BMPostTopicMatchSearchPage({super.key});

  @override
  State<BMPostTopicMatchSearchPage> createState() =>
      _BMPostTopicMatchSearchPageState();
}

class _BMPostTopicMatchSearchPageState
    extends BMBasePageState<BMPostTopicMatchSearchPage> {
  /// community API service (BMCommunityApiService type, search/API)
  final BMCommunityApiService _apiService = BMCommunityApiService();

  /// search fieldcontroller (TextEditingController type)
  final TextEditingController _searchController = TextEditingController();

  /// currentsearch keyword (String type, non-nullwhenshowsearch resultszone)
  String _keyword = '';

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
    _fetchHotMatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              'select match',
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

  /// main content (bycurrent Tab showcorrespondingsplit bylist, haskey=search results / nonekey=hot matches)
  Widget _buildBody() {
    final list = _currentList;
    final searching = _keyword.isNotEmpty;
    return ListView(
      key: ValueKey('body-$_currentCategory-$searching-$_keyword'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      children: [
        _buildSectionTitle(searching ? 'search results' : 'hot matches'),
        if (searching && _searchLoading)
          _buildLoading()
        else if (!searching && _hotLoading)
          _buildLoading()
        else if (list.isEmpty)
          _buildEmpty(searching ? 'not yettorelatedmatch' : 'no hot matches')
        else
          ...list.map(_buildMatchItem),
      ],
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
  /// differentiation: referencepageaswhitebottomcenterlayout, this pageasdark + scorecenter VS pill
  /// [m] - search resultsmatch (BMSearchMatch type)
  /// formatmatch timeas yyyy/MM/dd
  /// [matchTime] - secondlevel timestamp (int? type)
  /// returns: formatdatestring, nonetimereturnsemptystring (notrender)
  String _formatMatchDate(int? matchTime) {
    if (matchTime == null || matchTime <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(matchTime * 1000);
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  /// buildsingleitemsmatch card (top-left cornertime + right league + home/away teamscoreline)
  /// [m] - search matchmodel (BMSearchMatch type)
  Widget _buildMatchItem(BMSearchMatch m) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, m),
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
