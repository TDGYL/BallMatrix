import 'dart:math';
import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_competition_model.dart';
import '../../models/bm_competition_season_model.dart';
import '../../models/bm_player_ability_model.dart';
import '../../models/bm_player_rank_model.dart';
import '../../services/bm_match_api_service.dart';
import '../../services/bm_player_ability_store.dart';
import 'bm_tactical_board_page.dart';
import 'bm_fan_goods_page.dart';
import 'bm_notes_page.dart';
import 'bm_dictionary_page.dart';

/// BMToolPage - calctoolpage
/// feature: showheightcompute、、analysistoolcard
/// architecture: MVVM Viewlayer
/// purposescope: bottomnavigationNo. threeitemsTab
class BMToolPage extends BMBasePage {
 const BMToolPage({super.key});

 @override
 State<BMToolPage> createState() => _BMToolPageState();
}

class _BMToolPageState extends BMBasePageState<BMToolPage> {
 /// home team(playerA)selectindex (int type, starting from 0, correspondingplayerrankingboardarrayindex)
 int _teamAIndex = 0;

 /// away team(playerB)selectindex (int type, starting from 0, correspondingplayerrankingboardarrayindex)
 int _teamBIndex = 1;

 /// leaguefilterindex (int type, starting from 0, selected of trueactualleague of arrayindex)
 int _selectedLeagueIndex = 0;

 /// leagueselectwhetherexpand (bool type, true=expanddisplay4line, false=collapseonlydisplay1line)
 bool _leagueExpanded = false;

 /// leaguetrueactualdataloadinginmarker (bool type, prevent duplicate requests)
 bool _leaguesLoading = false;

 /// leaguetrueactualdataLoad Failedmarker (bool type, zonemin『APIfailure』and『APIsuccessemptyarray』kindemptystate)
 bool _leagueLoadFailed = false;

 /// leaguetrueactualdatalist (List<BMCompetitionModel> type, fetch from API, initializeempty)
 List<BMCompetitionModel> _leagues = [];

 /// singlelineleaguechipzoneheight (double type, estimatecalcforcollapsestate1line, includes spacing)
 final double _oneLeagueRowHeight = 52;

 /// expandstatemaxdisplaylinecount (int type, byrequirementfixed=4)
 final int _maxLeagueRows = 4;

 /// seasonlistloadinginmarker (bool type, prevent duplicate requests)
 bool _seasonsLoading = false;

 /// seasonlistLoad Failedmarker (bool type)
 bool _seasonsLoadFailed = false;

 /// currentleaguelower of seasonlist (List<BMCompetitionSeasonModel> type, fetch from API, initializeempty)
 List<BMCompetitionSeasonModel> _seasons = [];

 /// currentselected of season ID (int type, defaulttakeseasonlistitems seasonId, forrequestplayerboard)
 int _currentSeasonId = 0;

 /// playerrankingboardloadinginmarker (bool type, prevent duplicate requests)
 bool _playerRanksLoading = false;

 /// playerrankingboardLoad Failedmarker (bool type, zonemin『APIfailure』and『APIsuccessemptyarray』)
 bool _playerRankLoadFailed = false;

 /// currentleague+seasonlower of playerrankingdata (List<BMPlayerRankModel> type, fetch from API, initializeempty)
 List<BMPlayerRankModel> _playerRanks = [];

 /// leftlistplayerselectindex (int type, starting from 0, correspondingplayerrankingboardin of arrayindex, defaultselectedNo. 1name)
 int _selectedPlayerLeftIndex = 0;

 /// rightlistplayerselectindex (int type, starting from 0, correspondingplayerrankingboardin of arrayindex, defaultselectedNo. 2name)
 int _selectedPlayerRightIndex = 1;

 /// matchAPIserviceinstance (BMMatchApiService type, singletonreuse)
 final BMMatchApiService _apiService = BMMatchApiService();

 /// whethercomputein (bool type)
 bool _isCalculating = false;

 /// computeresulttext (String type)
 String? _resultText;

 /// home teamoption (List<BMPlayerRankModel> type, requirement: playerlistdataoriginal of teamshow)
 List<BMPlayerRankModel> get _teamAOptions => _playerRanks;

 /// away teamoption (List<BMPlayerRankModel> type, requirement: playerlistdataoriginal of teamshow)
 List<BMPlayerRankModel> get _teamBOptions => _playerRanks;

 /// left side(Player A=bluecolor)playerabilitypowerdata (BMPlayerAbilityModel? type, tapgenerate ability reportstringlinerequestfirstAagainB, No. onevalue)
 BMPlayerAbilityModel? _playerLeftAbility;

 /// right side(Player B=color)playerabilitypowerdata (BMPlayerAbilityModel? type, AsuccesslateragainrequestB, No. twovalue)
 BMPlayerAbilityModel? _playerRightAbility;

 /// playerabilitypowerrequestinmarker (bool type, duplicatetapgenerate ability report)
 bool _abilitiesLoading = false;

 /// playerabilitypowerrequest failuremarker (bool type, showfailuretoast)
 bool _abilitiesLoadFailed = false;

 @override
 void initState() {
 super.initState();
 // pageinitializewhenhometaketrueactualleaguelist, onlyrequestonetimenotduplicate
 _loadCompetitionList();
 }

 /// initializeloadingleaguelist (trueactual API: GET /api/livespeed/football/competition/list)
 /// flow: leaguesuccess → defaultselected idx=0 → requestseasonlist(_loadSeasonList) → seasonid → requestplayerlist(_loadPlayerRanks, key=k_shots_on)
 Future<void> _loadCompetitionList() async {
 if (_leaguesLoading) return;
 setState(() {
 _leaguesLoading = true;
 _leagueLoadFailed = false;
 });
 try {
 debugPrint('🌐 BMToolPage step1/3: requestfootballleaguelist');
      final list = await _apiService.fetchCompetitionList();
      if (!mounted) return;
      setState(() {
        _leagues = list;
        // ⭐️ defaultselectedfirstleague (idx=0)
        _selectedLeagueIndex = list.isEmpty ? 0 : 0;
        _leagueLoadFailed = list.isEmpty;
      });
      debugPrint('✅ BMToolPage step1/3: leaguelistshouldusesuccess: ${_leagues.length}items, defaultselectedidx=$_selectedLeagueIndex');
 // ⭐️ step2: leagueloadingdonelater, requesttheleague of seasonlist
 if (_leagues.isNotEmpty) {
 await _loadSeasonList(_leagues[_selectedLeagueIndex].id);
 }
 } catch (e) {
 debugPrint('❌ BMToolPage step1/3: leaguelistrequestexception: $e');
 if (mounted) setState(() => _leagueLoadFailed = true);
 } finally {
 if (mounted) setState(() => _leaguesLoading = false);
 }
 }

 /// loadingspecified league of seasonlist (step2/3: trueactual API GET /api/livespeed/football/competition/season-list)
 /// [competitionId] - leagueuniqueID
 /// successlater: takeitemsseason seasonId (servicesidealreadyby isCurrent=1 priorityorderNo. one) → step3 requestplayerboard key=k_shots_on
 Future<void> _loadSeasonList(int competitionId) async {
 if (_seasonsLoading) return;
 setState(() {
 _seasonsLoading = true;
 _seasonsLoadFailed = false;
 _seasons = [];
 _currentSeasonId = 0;
 });
 try {
 debugPrint('🌐 BMToolPage step2/3: requestleague[$competitionId]seasonlist');
 final list = await _apiService.fetchSeasonList(competitionId: competitionId);
 if (!mounted) return;
 setState(() {
 _seasons = list;
 // ⭐️ requirement: selectseason of firstid (service layeralreadyby isCurrent=1 sort, allwithfirstyescurrentseason)
 _currentSeasonId = list.isEmpty ? 0: list.first.seasonId;
 _seasonsLoadFailed = list.isEmpty;
 });
 debugPrint('✅ BMToolPage step2/3: seasonlistsuccess: ${_seasons.length}items, seasonid=$_currentSeasonId');
 // ⭐️ step3: seasonidlater, requestplayerboard key=k_shots_on (centercountorderline)
 if (_currentSeasonId > 0) {
 await _loadPlayerRanks(
 competitionId: competitionId,
 seasonId: _currentSeasonId,
 rankKey: 'k_shots_on',
        );
      }
    } catch (e) {
      debugPrint('❌ BMToolPage step2/3: seasonlistrequestexception: $e');
 if (mounted) setState(() => _seasonsLoadFailed = true);
 } finally {
 if (mounted) setState(() => _seasonsLoading = false);
 }
 }

 /// loadingspecified league+season of playerrankingboard (step3/3: trueactual API GET /api/livespeed/football/competition/player-rank)
 /// [competitionId] - leagueuniqueID
 /// [seasonId] - season ID (fromseasonlistitemgettake)
 /// [rankKey] - datadegree: k_shots_on=center(this pagedefault), k_goals=goal, waitwait
 /// successlater: left=playerAdefault idx=0 No. 1name, right=playerBdefault idx=1 No. 2name, teampicker_teamAIndex/_teamBIndex sync; boundaryfallback
 Future<void> _loadPlayerRanks({
 required int competitionId,
 required int seasonId,
 String rankKey = 'k_shots_on',
  }) async {
    if (_playerRanksLoading) return;
    setState(() {
      _playerRanksLoading = true;
      _playerRankLoadFailed = false;
    });
    try {
      debugPrint('🌐 BMToolPage step3/3: requestleague[$competitionId]season[$seasonId]playerranking key=$rankKey');
 final list = await _apiService.fetchPlayerRank(
 competitionId: competitionId,
 seasonId: seasonId,
 key: rankKey,
);
 if (!mounted) return;
 setState(() {
 _playerRanks = list;
 // doubleplayercompare + teampicker syncdefaultselected
 _selectedPlayerLeftIndex = list.isEmpty ? 0: 0;
 _selectedPlayerRightIndex = list.length < 2 ? (list.isEmpty ? 0: list.length - 1): 1;
 // ⭐️ requirementNo. 3point: _teamAOptions/_teamBOptions useplayerlistteamshow
 _teamAIndex = list.isEmpty ? 0: 0;
 _teamBIndex = list.length < 2 ? (list.isEmpty ? 0: list.length - 1): 1;
 _playerRankLoadFailed = list.isEmpty;
 });
 debugPrint('✅ BMToolPage step3/3: playerrankingsuccess: ${_playerRanks.length}items, '
          'leftidx=$_selectedPlayerLeftIndex, rightidx=$_selectedPlayerRightIndex, '
          'playerAidx=$_teamAIndex, playerBidx=$_teamBIndex');
    } catch (e) {
      debugPrint('❌ BMToolPage step3/3: playerrankingrequestexception: $e');
 if (mounted) setState(() => _playerRankLoadFailed = true);
 } finally {
 if (mounted) setState(() => _playerRanksLoading = false);
 }
 }


 @override
 Widget buildBody(BuildContext context) {
 return SingleChildScrollView(
 padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 _buildHeader(),
 const SizedBox(height: 16),
 _buildRadarSection(),
 const SizedBox(height: 16),
 _buildToolGrid(),
 ],
),
);
 }

 /// buildpageheader
 Widget _buildHeader() {
 return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Icon(Icons.memory, size: 12, color: BMColors.bright),
 const SizedBox(width: 4),
 const Text(
 'exclusive height compute',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BMColors.bright,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'calc data analysis actual',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: BMColors.pitch800,
            border: Border.all(color: BMColors.pitch700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'modelversion v4.2',
 style: TextStyle(fontSize: 10, color: BMColors.textSecondary),
),
),
 ],
);
 }

 /// buildzone
 Widget _buildRadarSection() {
 return Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 _buildRadarHeader(),
 const SizedBox(height: 12),
 _buildLeagueLabel(),
 const SizedBox(height: 8),
 _buildLeagueFilter(),
 const SizedBox(height: 14),
 _buildTeamSelectors(),
 const SizedBox(height: 14),
 _buildRadarPlaceholder(),
 const SizedBox(height: 14),
 _buildCalculateButton(),
 ],
),
);
 }

 /// buildleaguefiltertitletag (right side「expand/collapse」button, chevronstate0.5rotateanimation)
 Widget _buildLeagueLabel() {
 return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: const [
 Icon(
 Icons.emoji_events_outlined,
 size: 12,
 color: BMColors.textSecondary,
),
 SizedBox(width: 4),
 Text(
 'select league',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: BMColors.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => setState(() => _leagueExpanded = !_leagueExpanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: _leagueExpanded ? 0.5 : 0,
                  curve: Curves.easeOut,
                  child: const Icon(Icons.expand_more, size: 15, color: BMColors.bright),
                ),
                const SizedBox(width: 2),
                Text(
                  _leagueExpanded ? 'collapse' : 'expand',
 style: const TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w600,
 color: BMColors.bright,
),
),
 ],
),
),
),
 ],
);
 }

 /// buildleaguefilterlist (cancollapsethreestatecompletefullmergerequirement)
 /// collapsestate: AnimatedContainer maxHeight = 1line(_oneLeagueRowHeight) + NeverScrollableScrollPhysics
 /// -> onlydisplayNo. oneline, redundantchipbyClip.antiAliasinvisible, notcandragscroll
 /// expandstate: maxHeight = 4line(_oneLeagueRowHeight * _maxLeagueRows) + AlwaysScrollableScrollPhysics
 /// -> ifleaguecount > 4line, exceedpartialcanupperlowerscroll; if<=4linethendisplayall
 Widget _buildLeagueFilter() {
 final maxH = _leagueExpanded
 ? _oneLeagueRowHeight * _maxLeagueRows
: _oneLeagueRowHeight;
 return AnimatedContainer(
 duration: const Duration(milliseconds: 260),
 curve: Curves.easeInOutCubic,
 constraints: BoxConstraints(maxHeight: maxH),
 clipBehavior: Clip.antiAlias,
 decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
 child: SingleChildScrollView(
 physics: _leagueExpanded
 ? const AlwaysScrollableScrollPhysics()
: const NeverScrollableScrollPhysics(),
 child: _buildLeagueChipList(),
),
);
 }

 /// generateleaguechip of children list (unifiedinput loading/fallback/trueactualthreestateswitch)
 /// 1) _leaguesLoading=true: displaycolorloadingplaceholder
 /// 2) _leagues.isEmpty: display「No leaguedata」fallback (emptywhiteorboundary)
 /// 3) hastrueactualdata: makeuse BMCompetitionModel.name/cap/main render, main=1 quotaouteradd「home」tag
 Widget _buildLeagueChipList() {
 if (_leaguesLoading) {
 return Wrap(
 spacing: 8,
 runSpacing: 8,
 alignment: WrapAlignment.start,
 crossAxisAlignment: WrapCrossAlignment.center,
 children: List.generate(5, (_) {
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
 decoration: BoxDecoration(
 color: BMColors.pitch900.withValues(alpha: 0.7),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Container(
 width: 14,
 height: 14,
 decoration: BoxDecoration(
 color: BMColors.pitch700.withValues(alpha: 0.6),
 shape: BoxShape.circle,
),
),
 const SizedBox(width: 8),
 Container(
 width: 58,
 height: 10,
 decoration: BoxDecoration(
 color: BMColors.pitch700.withValues(alpha: 0.5),
 borderRadius: BorderRadius.circular(4),
),
),
 const SizedBox(width: 10),
 Container(
 width: 38,
 height: 8,
 decoration: BoxDecoration(
 color: BMColors.pitch800.withValues(alpha: 0.7),
 borderRadius: BorderRadius.circular(3),
),
),
 ],
),
);
 }),
);
 }
 if (_leagues.isEmpty) {
 final icon = _leagueLoadFailed ? Icons.refresh: Icons.info_outline;
 final text = _leagueLoadFailed ? 'leagueLoad Failed，tapretry' : 'No leaguedata';
 return GestureDetector(
 onTap: () => _loadCompetitionList(),
 behavior: HitTestBehavior.opaque,
 child: Wrap(
 spacing: 8,
 runSpacing: 8,
 children: [
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 decoration: BoxDecoration(
 color: BMColors.pitch900.withValues(alpha: 0.7),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(icon, size: 14, color: BMColors.textTertiary),
 const SizedBox(width: 6),
 Text(
 text,
 style: const TextStyle(fontSize: 12, color: BMColors.textTertiary),
),
 ],
),
),
 ],
),
);
 }
 return Wrap(
 spacing: 8,
 runSpacing: 8,
 alignment: WrapAlignment.start,
 crossAxisAlignment: WrapCrossAlignment.center,
 children: _leagues.asMap().entries.map((entry) {
 final idx = entry.key;
 final lg = entry.value;
 final isSelected = _selectedLeagueIndex == idx;
 final isMain = lg.main == 1;
 return GestureDetector(
 onTap: () async {
 setState(() => _selectedLeagueIndex = idx);
 // ⭐️ switchleaguewhen: heavy step2→step3 flow (season→player)
 if (_leagues.isNotEmpty && idx < _leagues.length) {
 await _loadSeasonList(_leagues[idx].id);
 }
 },
 behavior: HitTestBehavior.opaque,
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 180),
 curve: Curves.easeOut,
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 decoration: BoxDecoration(
 color: isSelected
 ? BMColors.bright.withValues(alpha: 0.15)
: BMColors.pitch900.withValues(alpha: 0.6),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(
 color: isSelected
 ? BMColors.bright
: BMColors.pitch700.withValues(alpha: 0.6),
 width: isSelected ? 1.2: 0.6,
),
),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 Container(
 width: 18,
 height: 18,
 alignment: Alignment.center,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: isSelected
 ? BMColors.bright.withValues(alpha: 0.25)
: BMColors.pitch800,
),
 child: Text(
 lg.cap.isEmpty ? '·': lg.cap.substring(0, 1).toUpperCase(),
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.w900,
 color: isSelected ? BMColors.bright: BMColors.textSecondary,
),
),
),
 const SizedBox(width: 6),
 Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(
 lg.name,
 style: TextStyle(
 fontSize: 12,
 fontWeight: isSelected ? FontWeight.w700: FontWeight.w600,
 color: isSelected ? BMColors.bright: BMColors.textPrimary,
),
),
 if (isMain)...[
 const SizedBox(width: 4),
 const Icon(Icons.star, size: 10, color: Color(0xFFFBBF24)),
 ],
 ],
),
 ],
),
),
);
 }).toList(),
);
 }

 /// buildzonetitle
 Widget _buildRadarHeader() {
 return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: [
 const Icon(
 Icons.pie_chart_outline,
 size: 14,
 color: BMColors.bright,
),
 const SizedBox(width: 6),
 const Text(
 'playerMore ability models',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
        const Text(
          'actual when compute in',
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
 color: BMColors.bright,
),
),
 ],
);
 }

 /// buildteam(player)picker
 /// ⭐️ requirementNo. 3point: original of team Mock showchange asplayerlistshow (_teamAOptions/_teamBOptions = _playerRanks)
 Widget _buildTeamSelectors() {
 return Row(
 children: [
 Expanded(
 child: _buildTeamSelector(
 'Player A',
            const Color(0xFF60A5FA),
            _teamAOptions,
            _teamAIndex,
            (v) => setState(() => _teamAIndex = v),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTeamSelector(
            'Player B',
 const Color(0xFFF472B6),
 _teamBOptions,
 _teamBIndex,
 (v) => setState(() => _teamBIndex = v),
),
),
 ],
);
 }

 /// buildsingleitemsteam(player)picker
 /// ⭐️ argumenttypefrom List<String> change as List<BMPlayerRankModel>, display rank+avatar+name+team+datavalue
 /// [label] - tag Player A / Player B
 /// [sideColor] - sidecolor (A=blue / B=)
 /// [options] - playerlist = _playerRanks (getter: _teamAOptions/_teamBOptions)
 /// [selectedIndex] - selectedindex
 /// [onChanged] - selectedcallback idx
 Widget _buildTeamSelector(
 String label,
 Color sideColor,
 List<BMPlayerRankModel> options,
 int selectedIndex,
 ValueChanged<int> onChanged,
) {
 final hasData = options.isNotEmpty && selectedIndex < options.length;
 return Container(
 padding: const EdgeInsets.all(8),
 decoration: BoxDecoration(
 color: BMColors.pitch950,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: BMColors.pitch700),
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 label,
 style: TextStyle(fontSize: 10, color: sideColor, fontWeight: FontWeight.w700),
),
 const SizedBox(height: 4),
 if (_playerRanksLoading)
 _buildTeamSelectorLoading(sideColor)
 else if (!hasData)
 _buildTeamSelectorEmpty(sideColor)
 else
 DropdownButtonHideUnderline(
 child: DropdownButton<int>(
 value: selectedIndex,
 isExpanded: true,
 itemHeight: 60,
 dropdownColor: BMColors.pitch900,
 icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: sideColor),
 borderRadius: BorderRadius.circular(12),
 items: options.asMap().entries.map((e) {
 final idx = e.key;
 final p = e.value;
 return DropdownMenuItem<int>(
 value: idx,
 child: _buildTeamSelectorItem(
 p: p,
 sideColor: sideColor,
 isSelected: idx == selectedIndex,
),
);
 }).toList(),
 selectedItemBuilder: (ctx) {
 return options.asMap().entries.map((e) {
 final idx = e.key;
 final p = e.value;
 return _buildTeamSelectorItem(
 p: p,
 sideColor: sideColor,
 isSelected: idx == selectedIndex,
 compact: true,
);
 }).toList();
 },
 onChanged: (v) => onChanged(v ?? 0),
),
),
 ],
),
);
 }

 /// team(player)pickerloadingplaceholder
 Widget _buildTeamSelectorLoading(Color sideColor) {
 return Padding(
 padding: const EdgeInsets.symmetric(vertical: 6),
 child: Row(
 children: [
 Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: BMColors.pitch800)),
 const SizedBox(width: 8),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Container(height: 12, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(3))),
 const SizedBox(height: 5),
 Container(width: 90, height: 9, decoration: BoxDecoration(color: BMColors.pitch800.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(3))),
 ],
),
),
 const SizedBox(width: 8),
 Icon(Icons.hourglass_top_rounded, size: 14, color: sideColor.withValues(alpha: 0.7)),
 ],
),
);
 }

 /// team(player)pickeremptystate/failureplaceholder
 Widget _buildTeamSelectorEmpty(Color sideColor) {
 // priority level: seasonloadingin > seasonfailure > playerloadingin (upperlayeralreadyhandle) > playerfailure > emptydata
 IconData icon;
 String text;
 VoidCallback? onTap;
 if (_seasonsLoading) {
 icon = Icons.hourglass_top_rounded;
 text = 'seasonloadingin...';
 onTap = null;
 } else if (_seasonsLoadFailed) {
 // ⭐️ input _seasonsLoadFailed, msgdiv unused warning
 icon = Icons.refresh_rounded;
 text = 'seasonLoad Failedtapretry';
      onTap = _leagues.isNotEmpty
          ? () => _loadSeasonList(_leagues[_selectedLeagueIndex].id)
          : null;
    } else if (_playerRankLoadFailed && _leagues.isNotEmpty && _currentSeasonId > 0) {
      icon = Icons.refresh_rounded;
      text = 'Load Failedtapretry';
      onTap = () => _loadPlayerRanks(
            competitionId: _leagues[_selectedLeagueIndex].id,
            seasonId: _currentSeasonId,
            rankKey: 'k_shots_on',
          );
    } else {
      icon = Icons.info_outline_rounded;
      text = 'No playerdata';
 onTap = null;
 }
 return GestureDetector(
 onTap: onTap,
 behavior: HitTestBehavior.opaque,
 child: Padding(
 padding: const EdgeInsets.symmetric(vertical: 10),
 child: Row(
 children: [
 Icon(icon, size: 14, color: sideColor.withValues(alpha: 0.75)),
 const SizedBox(width: 6),
 Expanded(
 child: Text(
 text,
 style: TextStyle(
 fontSize: 11,
 color: (_seasonsLoadFailed || _playerRankLoadFailed)
 ? sideColor.withValues(alpha: 0.85)
: BMColors.textTertiary.withValues(alpha: 0.9),
),
),
),
 ],
),
),
);
 }

 /// singleplayeritem (DropdownMenuItem / collapseselectedstate reuse)
 Widget _buildTeamSelectorItem({
 required BMPlayerRankModel p,
 required Color sideColor,
 required bool isSelected,
 bool compact = false,
 }) {
 final rankColor = p.position == 1
 ? const Color(0xFFFBBF24)
: p.position == 2
 ? const Color(0xFF94A3B8)
: p.position == 3
 ? const Color(0xFFD97706)
: BMColors.textTertiary;
 return Padding(
 padding: EdgeInsets.symmetric(vertical: compact ? 2: 4),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 SizedBox(
 width: 22,
 child: Text(
 '${p.position}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: rankColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? sideColor : BMColors.pitch700.withValues(alpha: 0.8),
                width: isSelected ? 1.4 : 0.6,
              ),
              color: BMColors.pitch800,
            ),
            clipBehavior: Clip.antiAlias,
            child: p.playerLogo.isNotEmpty
                ? Image.network(
                    p.playerLogo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        p.playerName.isEmpty ? '·' : p.playerName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? sideColor : BMColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      p.playerName.isEmpty ? '·' : p.playerName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? sideColor : BMColors.textSecondary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? sideColor : BMColors.textPrimary,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: BMColors.textTertiary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${p.total}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: sideColor,
                  fontFamily: 'monospace',
),
),
 Text(
 p.rankName,
 style: TextStyle(
 fontSize: 9,
 color: BMColors.textTertiary.withValues(alpha: 0.8),
),
),
 ],
),
 ],
),
);
 }

 /// build 6 edgeshapeMore ability models
 /// reference: MERadarChartView.m (6toppoint=ATT/TEC/STA/DEF/POW/SPD, 4momentdegree)
 /// paint 2 groupdata（Player A bluecolor + Player B color）
 Widget _buildRadarPlaceholder() {
 const labels = BMPlayerAbilityModel.dimensionLabels;
 const leftColor = Color(0xFF60A5FA);
 const rightColor = Color(0xFFF472B6);
 return Container(
 padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
 decoration: BoxDecoration(
 color: BMColors.pitch950.withValues(alpha: 0.5),
 borderRadius: BorderRadius.circular(12),
),
 child: Column(
 children: [
 if (_abilitiesLoading)
 Padding(
 padding: const EdgeInsets.only(bottom: 6),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: const [
 SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: BMColors.bright)),
 SizedBox(width: 6),
 Text('powerdatatakein...', style: TextStyle(fontSize: 10, color: BMColors.textSecondary)),
                ],
              ),
            )
          else if (_abilitiesLoadFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: _startCalculation,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.refresh_rounded, size: 12, color: BMColors.bright),
                    SizedBox(width: 6),
                    Text('Ability data failed, tap to retry', style: TextStyle(fontSize: 10, color: BMColors.bright)),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.radar_rounded, size: 12, color: BMColors.bright),
                  SizedBox(width: 4),
                  Text('More ability models', style: TextStyle(fontSize: 10, color: BMColors.textSecondary)),
 ],
),
),
 // homezone：grid 220x220 centerdirectionshape ➔ Stack 6 items Label + CustomPaint
 SizedBox(
 width: 220,
 height: 220,
 child: Stack(
 alignment: Alignment.center,
 children: [
 // background CustomPaint = momentdegree + 6line + 2group（Player Bbottom / Player Atop）moreedgeshape
 Positioned.fill(
 child: CustomPaint(
 painter: _BMRadarPainter(
 labelsCount: labels.length,
 rings: 4,
 leftValues: _playerLeftAbility?.normalizedValues,
 rightValues: _playerRightAbility?.normalizedValues,
 leftColor: leftColor,
 rightColor: rightColor,
),
),
),
 // 6 itemscorner Label: ATT(i=0) keeplower100px, others5corner(TEC/STA/DEF/POW/SPD) againquotaouterunifieddirectionlowerposition100px
...List.generate(labels.length, (i) {
 // ATT(i=0): cornerdegreedirection -100 (centergooddirectionlower100)
 // TEC/STA/DEF/POW/SPD(i!=0): toppoint of upper, tagsystem y+=100 directionlower100px
 final ePx = i == 0 ? -100.0: 0.0;
 final eDy = i == 0 ? 0.0: 100.0;
 return Positioned.fill(
 child: IgnorePointer(
 child: CustomSingleChildLayout(
 delegate: _BMOffsetLayoutDelegate(
 index: i,
 count: labels.length,
 extraPx: ePx,
 extraDy: eDy,
),
 child: Text(
 labels[i],
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w800,
 fontFamily: 'monospace',
 color: BMColors.bright.withValues(alpha: 0.9),
),
 textAlign: TextAlign.center,
),
),
),
);
 }),
 ],
),
),
 // e.g.: leftblue / right
 Padding(
 padding: const EdgeInsets.only(top: 4),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
 children: [
 _buildRadarLegend(leftColor, _playerLeftAbility?.playerName ?? 'Player A'),
                _buildRadarLegend(rightColor, _playerRightAbility?.playerName ?? 'Player B'),
 ],
),
),
 ],
),
);
 }

 /// singleitemsexample (color block + playername)
 Widget _buildRadarLegend(Color color, String name) {
 return Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Container(
 width: 12,
 height: 12,
 decoration: BoxDecoration(
 color: color.withValues(alpha: 0.35),
 borderRadius: BorderRadius.circular(3),
 border: Border.all(color: color.withValues(alpha: 0.9), width: 1),
),
),
 const SizedBox(width: 5),
 SizedBox(
 width: 110,
 child: Text(
 name,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.w600,
 color: color.withValues(alpha: 0.95),
),
),
),
 ],
);
 }

 /// buildcomputebutton
 Widget _buildCalculateButton() {
 return GestureDetector(
 onTap: _isCalculating ? null: _startCalculation,
 child: Container(
 width: double.infinity,
 padding: const EdgeInsets.symmetric(vertical: 10),
 decoration: BoxDecoration(
 gradient: const LinearGradient(
 colors: [BMColors.accent, Color(0xFF2DD4BF)],
),
 borderRadius: BorderRadius.circular(12),
 boxShadow: [
 BoxShadow(
 color: BMColors.accent.withValues(alpha: 0.2),
 blurRadius: 20,
),
 ],
),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 if (_isCalculating)
 const SizedBox(
 width: 14,
 height: 14,
 child: CircularProgressIndicator(
 strokeWidth: 2,
 color: BMColors.pitch950,
),
)
 else
 const Icon(Icons.play_arrow, size: 14, color: BMColors.pitch950),
 const SizedBox(width: 6),
 Text(
 _resultText ?? 'generate ability report',
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w900,
 color: BMColors.pitch950,
),
),
 ],
),
),
);
 }

 /// launchpowergenerate = doubleplayergettakesixdata（firstlocalcache → not yethit ingeneratecountandwritebacklocal）→ paintdoubleplayer
 /// flow (requirement 2026-09-23 modifymake, notagainrequestplayerdetailAPI):
 /// 1. validateselectedplayerlegal
 /// 2. player: BMPlayerAbilityStore.load local → hit inuse
 /// → not yethit in BMPlayerAbilityGenerator.generate byptsgeneratesixitem(1~100) → BMPlayerAbilityStore.save writebacklocal
 /// 3. doubleplayersixmodel → setState senddoublepaint
 /// : ptstakeplayerrankingboard total field (e.g.: A=27min, B=19min → A sixitemmerge B)
 Future<void> _startCalculation() async {
 // 1. validate: playerlistcomplete + doubleselectindexlegal
 if (_playerRanks.isEmpty ||
 _teamAIndex >= _playerRanks.length ||
 _teamBIndex >= _playerRanks.length) {
 setState(() {
 _abilitiesLoadFailed = true;
 _resultText = 'Select players to compare first';
      });
      return;
    }
    if (_abilitiesLoading || _isCalculating) return;
    final playerA = _playerRanks[_teamAIndex];
    final playerB = _playerRanks[_teamBIndex];
    setState(() {
      _isCalculating = true;
      _abilitiesLoading = true;
      _abilitiesLoadFailed = false;
      _playerLeftAbility = null;
      _playerRightAbility = null;
      _resultText = 'generateplayerApowerdatain (1/2)...';
    });
    try {
      debugPrint(
        '🚀 BMToolPage local/doubleplayerpower: A=${playerA.playerId}(${playerA.playerName}, pts${playerA.total}) '
        'vs B=${playerB.playerId}(${playerB.playerName}, pts${playerB.total})',
);

 /// gettakesingleplayersixpower: firstlocalcache, nonethenbyptsgeneratecountandwritebacklocal
 /// [p] - playerrankingmodel (BMPlayerRankModel type)
 /// returns: BMPlayerAbilityModel? (exceptionreturns null)
 Future<BMPlayerAbilityModel?> resolveAbility(BMPlayerRankModel p) async {
 // === 2a. firstlocalcache ===
 final cached = await BMPlayerAbilityStore.load(
 playerId: p.playerId,
 playerName: p.playerName,
);
 if (cached != null) return cached;
 // === 2b. localnot yethit in: byptsgeneratesixitem(1~100, ptsheightmerge) ===
 final generated = BMPlayerAbilityGenerator.generate(
 playerId: p.playerId,
 playerName: p.playerName,
 score: p.total,
);
 // === 2c. writebacklocal, lowertimereadcache ===
 await BMPlayerAbilityStore.save(generated);
 return generated;
 }

 // === 3. No. 1: player A (left sidebluecolor) ===
 final abA = await resolveAbility(playerA);
 if (!mounted) return;
 if (abA == null) {
 setState(() {
 _abilitiesLoadFailed = true;
 _playerLeftAbility = null;
 _playerRightAbility = null;
 _resultText = 'playerApowerdatageneratefailure';
        });
        return;
      }
      setState(() {
        _playerLeftAbility = abA;
        _resultText = 'generateplayerBpowerdatain (2/2)...';
 });
 // === 4. No. 2: player B (right sidecolor) ===
 final abB = await resolveAbility(playerB);
 if (!mounted) return;
 if (abB == null) {
 setState(() {
 _abilitiesLoadFailed = true;
 // A success B failure，keep A toastfailure
 _playerRightAbility = null;
 _resultText = 'playerBpowerdatageneratefailure';
 });
 return;
 }
 // === 5. doubleplayersuccess，valuesenddoublepaint ===
 setState(() {
 _playerLeftAbility = abA;
 _playerRightAbility = abB;
 _abilitiesLoadFailed = false;
 final avgA =
 ((abA.att + abA.tec + abA.sta + abA.def + abA.pow + abA.spd) / 6)
.toStringAsFixed(1);
 final avgB =
 ((abB.att + abB.tec + abB.sta + abB.def + abB.pow + abB.spd) / 6)
.toStringAsFixed(1);
 _resultText = 'powercompare: ${abA.playerName} $avgA vs ${abB.playerName} $avgB';
      });
      debugPrint(
        '✅ BMToolPage doubleplayerpower: A=${abA.playerName} [${abA.att},${abA.tec},${abA.sta},${abA.def},${abA.pow},${abA.spd}], '
        'B=${abB.playerName} [${abB.att},${abB.tec},${abB.sta},${abB.def},${abB.pow},${abB.spd}]',
      );
    } catch (e) {
      debugPrint('❌ BMToolPage playerpowergenerateexception: $e');
      if (mounted) {
        setState(() {
          _abilitiesLoadFailed = true;
          _resultText = 'powerdataexception，retry';
 });
 }
 } finally {
 if (mounted) {
 setState(() {
 _isCalculating = false;
 _abilitiesLoading = false;
 });
 }
 }
 }

 /// buildtoolcardgrid
 /// buildquick access gridtoolgridcardlist (4items: Tactical Board / Notes / Verbal Trick Dictionary / Fan Goods)
 Widget _buildToolGrid() {
 final tools = <(String, String, IconData, Color, VoidCallback)>[
 (
 'Tactical Board',
        'footbasketballtactical: directioncourt, dragplayer/arrow/annotation',
        Icons.sports_soccer_outlined,
        BMColors.cyan,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BMTacticalBoardPage(),
            ),
          );
        },
      ),
      (
        'Notes',
        'match//morenote, localencryptstorage',
        Icons.edit_note_outlined,
        BMColors.purple,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BMNotesPage(),
            ),
          );
        },
      ),
      (
        'Verbal Trick Dictionary',
        '//commonsplit classesCopy',
        Icons.record_voice_over_outlined,
        BMColors.amber,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BMDictionaryPage(),
            ),
          );
        },
      ),
      (
        'Fan Goods',
        'Fan Goodsmerchandisefavorite: jersey/boots/creative merchandiseone',
 Icons.shopping_bag_outlined,
 const Color(0xFFF97316),
 () {
 Navigator.push(
 context,
 MaterialPageRoute(
 builder: (_) => const BMFanGoodsPage(),
),
);
 },
),
 ];
 return GridView.builder(
 shrinkWrap: true,
 physics: const NeverScrollableScrollPhysics(),
 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
 crossAxisCount: 2,
 mainAxisSpacing: 12,
 crossAxisSpacing: 12,
 childAspectRatio: 1.35,
),
 itemCount: tools.length,
 itemBuilder: (context, index) {
 final tool = tools[index];
 return _buildToolCard(tool.$1, tool.$2, tool.$3, tool.$4, tool.$5);
 },
);
 }

 /// buildsingleitemstoolcard (argumentcompletetypecomment)
 /// [title] hometitle (String type, topbolddisplay)
 /// [desc] copytitledescription (String type, colorsmalltextline)
 /// [icon] icon (IconData type, 28x28 rounded cornercontainerinnerdisplay)
 /// [color] homecolor (Color type, icon+containercolor)
 /// [onTap] tap callback (VoidCallback type, push entersubpage)
 Widget _buildToolCard(
 String title,
 String desc,
 IconData icon,
 Color color,
 VoidCallback onTap,
) {
 return GestureDetector(
 onTap: onTap,
 behavior: HitTestBehavior.opaque,
 child: Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Container(
 width: 28,
 height: 28,
 decoration: BoxDecoration(
 color: color.withValues(alpha: 0.2),
 borderRadius: BorderRadius.circular(8),
),
 child: Icon(icon, size: 14, color: color),
),
 const SizedBox(height: 8),
 Text(
 title,
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.bold,
 color: BMColors.textPrimary,
 height: 1.2,
),
),
 const SizedBox(height: 4),
 Text(
 desc,
 maxLines: 3,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 fontSize: 10,
 height: 1.3,
 color: BMColors.textSecondary,
),
),
 ],
),
),
);
 }
}

// ============================================================================
// tagstatictool (0 error margin: _BMRadarPainter and _BMOffsetLayoutDelegate usage)
// - 1:1 corresponding MERadarChartView.m line 124-127 toppointstyle
// ============================================================================

/// trueactualhalfconstant (double type, toppointtoindistanceleave = centerdirectionshapeedge * 0.36)
const double _kRadarRadiusRatio = 0.36;

/// 【uniquetruevalue function】computemoreedgeshapetoppointtag (and Label useone, 0 error margin)
/// [size] centerdirectionshapesize (220x220)
/// [index] 0..count-1 toppointindex (0=ATTtop, 3=DEFbottom)
/// [count] toppointtotal (fixed 6)
/// [extraPx] quotaoutersamedirectionouterpx (0 = taginpointgoodtoppoint)
Offset _radarVertexPoint(Size size, int index, int count, double extraPx) {
 final cx = size.width / 2;
 final cy = size.height / 2;
 final maxR = min(size.width, size.height) * _kRadarRadiusRatio;
 final r = maxR + extraPx;
 // toppointcornerdegreestyle: -pi/2(centerupperdirection) + 2pi*i/count (when)
 final angle = (-pi / 2) + (2 * pi * index / count);
 return Offset(cx + r * cos(angle), cy + r * sin(angle));
}

// ============================================================================
// 6 corner Label locatedevice
// ============================================================================

/// Label taglocatedevice (callfunction _radarVertexPoint, 0 error margin)
/// ⚠️ Dart not supported class in class, allwithtextfiletop level
class _BMOffsetLayoutDelegate extends SingleChildLayoutDelegate {
 /// toppointindex (int type, 0..count-1, 0=ATTcenterupperdirection, 3=DEFcenterlowerdirection)
 final int index;

 /// toppointtotal (int type, fixed 6)
 final int count;

 /// quotaouterouterpx (double type, toppointcornerdegreedirection, >0directionouter, <0directioninner; ATT i=0 when -100 centergooddirectionlower100)
 final double extraPx;

 /// quotaoutertagsystem dy offset (double type, y directiondirectionlowerascenter, for TEC~SPD 5 itemsunifieddirectionlower 100)
 final double extraDy;

 _BMOffsetLayoutDelegate({
 required this.index,
 required this.count,
 required this.extraPx,
 required this.extraDy,
 });

 @override
 Offset getPositionForChild(Size size, Size childSize) {
 // ⭐️ uniquetruevalue function _radarVertexPoint
 final vertex = _radarVertexPoint(size, index, count, extraPx);
 return Offset(
 vertex.dx - childSize.width / 2,
 vertex.dy - childSize.height / 2 + extraDy, // ⭐️ add extraDy (directionlower +)
);
 }

 @override
 bool shouldRelayout(_BMOffsetLayoutDelegate oldDelegate) {
 return index != oldDelegate.index ||
 count != oldDelegate.count ||
 extraPx != oldDelegate.extraPx ||
 extraDy != oldDelegate.extraDy;
 }
}

// ============================================================================
// CustomPainter (callfunction _radarVertexPoint, 0 error margin)
// paintorder: 4 momentdegree -> 6 itemsline -> Player B color(bottom) -> Player A bluecolor(top)
// ============================================================================

/// paintdevice (momentdegree=4 , MERadarChartView.m line 49)
/// ⚠️ Dart not supported class in class, allwithtextfiletop level
class _BMRadarPainter extends CustomPainter {
 final int labelsCount;
 final int rings;
 final List<double>? leftValues;
 final List<double>? rightValues;
 final Color leftColor;
 final Color rightColor;

 _BMRadarPainter({
 required this.labelsCount,
 required this.rings,
 required this.leftValues,
 required this.rightValues,
 required this.leftColor,
 required this.rightColor,
 });

 @override
 void paint(Canvas canvas, Size size) {
 final cx = size.width / 2;
 final cy = size.height / 2;
 final maxR = min(size.width, size.height) * _kRadarRadiusRatio;

 // === 1. Grid 4 6 edgeshapemomentdegree (MERadarChartView line 49) ===
 final gridPaint = Paint()
..color = BMColors.bright.withValues(alpha: 0.22)
..strokeWidth = 0.8
..style = PaintingStyle.stroke;
 for (int r = 1; r <= rings; r++) {
 final rr = maxR * r / rings;
 final path = Path();
 for (int i = 0; i < labelsCount; i++) {
 // ⭐️ uniquetruevalue function _radarVertexPoint (extraPx = rr - maxR, as maxR yes r=rings of half)
 final p = _radarVertexPoint(size, i, labelsCount, rr - maxR);
 if (i == 0) {
 path.moveTo(p.dx, p.dy);
 } else {
 path.lineTo(p.dx, p.dy);
 }
 }
 path.close();
 canvas.drawPath(path, gridPaint);
 }

 // === 2. 6 itemsline (in -> toppoint) ===
 final axisPaint = Paint()
..color = BMColors.bright.withValues(alpha: 0.18)
..strokeWidth = 0.8
..style = PaintingStyle.stroke;
 for (int i = 0; i < labelsCount; i++) {
 final vertex = _radarVertexPoint(size, i, labelsCount, 0);
 canvas.drawLine(Offset(cx, cy), vertex, axisPaint);
 }

 // === 3. doublegroupabilitypowermoreedgeshape (Player B bottom, Player A top) ===
 void drawData(List<double> vals, Color color, double fillAlpha, double strokeAlpha) {
 if (vals.length != labelsCount) return;
 final path = Path();
 for (int i = 0; i < labelsCount; i++) {
 final v = vals[i].clamp(0.0, 1.0);
 // v=0 -> in, v=1 -> toppoint (maxR), output extraPx = v*maxR - maxR
 final extraAtRatio = maxR * (v - 1.0);
 final p = _radarVertexPoint(size, i, labelsCount, extraAtRatio);
 if (i == 0) {
 path.moveTo(p.dx, p.dy);
 } else {
 path.lineTo(p.dx, p.dy);
 }
 }
 path.close();
 final fillPaint = Paint()
..color = color.withValues(alpha: fillAlpha)
..style = PaintingStyle.fill;
 canvas.drawPath(path, fillPaint);
 final strokePaint = Paint()
..color = color.withValues(alpha: strokeAlpha)
..strokeWidth = 1.4
..style = PaintingStyle.stroke
..strokeJoin = StrokeJoin.round;
 canvas.drawPath(path, strokePaint);
 final dotPaint = Paint()
..color = color.withValues(alpha: strokeAlpha)
..style = PaintingStyle.fill;
 for (int i = 0; i < labelsCount; i++) {
 final v = vals[i].clamp(0.0, 1.0);
 final extraAtRatio = maxR * (v - 1.0);
 final p = _radarVertexPoint(size, i, labelsCount, extraAtRatio);
 canvas.drawCircle(p, 2.2, dotPaint);
 }
 }

 if (rightValues != null) {
 drawData(rightValues!, rightColor, 0.18, 0.82);
 }
 if (leftValues != null) {
 drawData(leftValues!, leftColor, 0.24, 0.94);
 }
 }

 @override
 bool shouldRepaint(_BMRadarPainter oldDelegate) {
 return oldDelegate.leftValues != leftValues ||
 oldDelegate.rightValues != rightValues ||
 oldDelegate.labelsCount != labelsCount ||
 oldDelegate.rings != rings ||
 oldDelegate.leftColor != leftColor ||
 oldDelegate.rightColor != rightColor;
 }
}
