import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_match_api_model.dart';
import '../../models/bm_basketball_match_model.dart';
import '../../viewmodels/home/bm_home_view_model.dart' show BMSportType;
import '../../services/bm_match_api_service.dart';
import '../../services/bm_match_detail_api_service.dart';
import '../../utils/bm_auth_manager.dart';
import '../login/bm_login_page.dart';
import 'bm_football_detail_page.dart';
import 'bm_basketball_detail_page.dart';

/// _MatchPageState - singlegroup（sport+tab+timestamp）independentpaginationcachestate
/// purpose: per item (sport, tab, timestamp) groupmergesaveown of list/paginationstate, footballbasketballnotimpact
class _MatchPageState {
  /// matchlist (List<BMMatchModel> type)
  List<BMMatchModel> list = [];

  /// current page (int type, starting from 1)
  int page = 1;

  /// whethertobottom (bool type)
  bool hasNoMore = false;

  /// request (bool type, heavyinput)
  bool isFetching = false;

  /// pull downrefreshorfirst screenLoadingin (bool type)
  bool isRefreshing = true;

  /// pull uploadingin (bool type)
  bool isLoadingMore = false;

  /// servicesidereturns of total (int? type, forcheckhasNoMore)
  int? serverTotal;
}

/// BMMatchTabPage - bottomnavigation competition Tab page
/// feature: football/basketballindependentswitch + statefilter(0/1/2/3) + fastdateitems + byleaguegrouplist + pull downrefresh/pull uploading + moredegreecache
class BMMatchTabPage extends BMBasePage {
  const BMMatchTabPage({super.key});

  @override
  State<BMMatchTabPage> createState() => _BMMatchTabPageState();
}

class _BMMatchTabPageState extends BMBasePageState<BMMatchTabPage> {
  /// currentsport type (BMSportType enum, defaultfootball)
  BMSportType _currentSport = BMSportType.football;

  /// per itemsport typecurrentselected of statetab (Map<BMSportType, int> type, 0/1/2/3 = all/in progress/i.e.willopenmatch/FTrepeatodds, footballbasketballindependent)
  final Map<BMSportType, int> _currentTabs = {
    BMSportType.football: 0,
    BMSportType.basketball: 0,
  };

  /// per itemsport typecurrentselected of fastdateindex (Map<BMSportType, int> type, footballbasketballindependent, default1=today)
  final Map<BMSportType, int> _selectedDateIndices = {
    BMSportType.football: 1,
    BMSportType.basketball: 1,
  };

  /// statefilterdevicedisplaytext (and tabvalue0/1/2/3corresponding, 0=follow(APIinputmodifypass4))
  final List<(int, String)> _filterLabels = const [
    (0, 'Follow'),
    (1, 'In progress'),
    (2, 'UnStart'),
    (3, 'Finished'),
  ];

  /// API serviceinstance (BMMatchApiService type)
  final BMMatchApiService _apiService = BMMatchApiService();

  /// detail API service (BMMatchDetailApiService type, follow/Take effectfollowAPI)
  final BMMatchDetailApiService _detailApiService = BMMatchDetailApiService();

  /// localfollowstatecache (Map<String, bool> type, key=matchId, APIlistreturnslatersync/buttontaplaterupdate)
  final Map<String, bool> _followStates = {};

  /// listscrollcontroller (ScrollController type, pull uploadinglistener)
  late final ScrollController _scrollController;

  /// per pagecount (int type, fixed20)
  final int _size = 20;

  /// paginationcache (Map<String, _MatchPageState> type, key='{sportIndex}_{tab}_{timestamp(second)}')
  final Map<String, _MatchPageState> _cachePool = {};

  /// takecurrent sport + current tab + current timestamp corresponding of paginationstate (nohasthenNew)
  _MatchPageState _currentState() {
    final tab = _currentTabs[_currentSport] ?? 0;
    final ts = _currentTimestamp();
    final key = _cacheKey(_currentSport, tab, ts);
    return _cachePool.putIfAbsent(key, () => _MatchPageState());
  }

  /// constructorcachekey
  String _cacheKey(BMSportType sport, int tab, int ts) =>
      '${sport.index}_${tab}_${ts}_${_todayZeroKey(sport)}';

  /// for sport switch timestamp sameonedaylowernotsame sport instancealsoone, add sport-specific datekey
  int _todayZeroKey(BMSportType sport) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return (d.millisecondsSinceEpoch ~/ 1000) + sport.index;
  }

  /// gettakecurrent sport selectedfastdate of timestamp (secondlevel, date0point)
  /// description: depends oncurrent tab statecomputedatescope, tab=0/1(all/in progress)defaultmakeusetoday
  int _currentTimestamp() {
    final tab = _currentTabs[_currentSport] ?? 0;
    final idx = _selectedDateIndices[_currentSport] ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final offset = _dateOffsetForIndex(tab, idx);
    final targetDay = today.add(Duration(days: offset));
    return targetDay.millisecondsSinceEpoch ~/ 1000;
  }

  /// data tab and index returnscorrecttoday of day offsetvolume
  /// tab=2(i.e.willopenmatch): idx 0..5 -> offset 0..5 (today..T+5)
  /// tab=3(FTrepeatodds): idx 0..5 -> offset -5..0 (T-5..today)
  /// tab=0/1(all/in progress): far 0(today)
  int _dateOffsetForIndex(int tab, int idx) {
    if (tab == 2) return idx.clamp(0, 5);
    if (tab == 3) return (idx.clamp(0, 5)) - 5;
    return 0;
  }

  /// generatespecified sport+tab corresponding of fastdateitem
  /// tab=0(all)/tab=1(in progress): returnsemptylist (UIhide)
  /// tab=2(i.e.willopenmatch): today + later5day(6day)
  /// tab=3(FTrepeatodds): first5day + today(6day), selectedlateroneday=today
  List<(String, String, int)> _dateListForTab(int tab) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<(String, String, int)> out = [];
    if (tab == 2) {
      for (int i = 0; i < 6; i++) {
        final d = today.add(Duration(days: i));
        String day;
        if (i == 0) {
          day = 'today';
        } else if (i == 1) {
          day = 'tomorrow';
        } else {
          final wd = d.weekday;
          const wk = [
            'weekone',
            'weektwo',
            'weekthree',
            'weekfour',
            'weekfive',
            'weeksix',
            'weekday',
          ];
          day = wk[wd - 1];
        }
        final date =
            '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        out.add((day, date, i));
      }
      return out;
    }
    if (tab == 3) {
      for (int i = -5; i <= 0; i++) {
        final d = today.add(Duration(days: i));
        String day;
        if (i == 0) {
          day = 'today';
        } else if (i == -1) {
          day = 'yesterday';
        } else if (i == -2) {
          day = 'firstday';
        } else {
          final wd = d.weekday;
          const wk = [
            'weekone',
            'weektwo',
            'weekthree',
            'weekfour',
            'weekfive',
            'weeksix',
            'weekday',
          ];
          day = wk[wd - 1];
        }
        final date =
            '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        // correctindex: 0..5 (0=T-5, 5=today)
        out.add((day, date, i + 5));
      }
      return out;
    }
    return out;
  }

  /// generatefastdatedata (compatiblehistoryAPI: startfinalreturns tab=2 of formatdirectionUIcommon)
  List<(String, String)> _dateList() {
    final tab = _currentTabs[_currentSport] ?? 0;
    return _dateListForTab(tab).map((e) => (e.$1, e.$2)).toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // first screensendonetimecurrent (football + tab=0 + today) of request
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrent(isRefresh: true);
    });
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
      final s = _currentState();
      if (!s.isFetching && !s.isRefreshing && !s.hasNoMore) {
        _fetchCurrent(isRefresh: false);
      }
    }
  }

  /// switch sport type (football <-> basketball)
  /// description: notsendnewrequest, takethe sport corresponding tab+date of cacheshow
  void _switchSport(BMSportType next) {
    if (next == _currentSport) return;
    setState(() {
      _currentSport = next;
    });
    // tonewsport, likeresultgroupcachealsonorequest(isRefreshing=true and listempty), sendrequest
    final s = _currentState();
    if (s.list.isEmpty && s.isRefreshing && !s.isFetching) {
      _fetchCurrent(isRefresh: true);
    }
  }

  /// switchstatefilterdevice (all/in progress/i.e.willopenmatch/FTrepeatodds)
  /// description: switch tab whenbyruleheavyplacedefaultdate, andmakerefresh(switchdateonewillsendrefresh)
  void _switchTab(int tab) {
    if ((_currentTabs[_currentSport] ?? 0) == tab) return;
    int defaultDateIdx = 0;
    if (tab == 2) {
      // i.e.willopenmatch: selectedNo. oneday(today, idx=0)
      defaultDateIdx = 0;
    } else if (tab == 3) {
      // FTrepeatodds: selectedlateroneday(today, T-5..today6dayinlater1items, idx=5)
      defaultDateIdx = 5;
    } else {
      // all/in progress: innerpartrecord idx=0 (notimpact timestamp defaulttoday)
      defaultDateIdx = 0;
    }
    setState(() {
      _currentTabs[_currentSport] = tab;
      _selectedDateIndices[_currentSport] = defaultDateIdx;
    });
    // switch tab byrequirementruleheavyplaceandmakerefresh
    final s = _currentState();
    s.list = [];
    s.page = 1;
    s.hasNoMore = false;
    s.serverTotal = null;
    _fetchCurrent(isRefresh: true);
  }

  /// switchfastdate
  /// description: datarequirement, pointinnotsame of timemustheavynewloadingnewdata (i.e.makecachehasalsomakerefresh)
  void _switchDate(int idx) {
    if ((_selectedDateIndices[_currentSport] ?? 1) == idx) return;
    setState(() {
      _selectedDateIndices[_currentSport] = idx;
    });
    // requirement: switchdatemustheavynewloadingnewdata => makeheavyplaceandrefresh
    final s = _currentState();
    s.list = [];
    s.page = 1;
    s.hasNoMore = false;
    s.serverTotal = null;
    _fetchCurrent(isRefresh: true);
  }

  /// requestcurrent (sport + tab + timestamp) groupmerge of data
  /// [isRefresh] true=pull down/first screenreset page=1; false=pull up page+1
  Future<void> _fetchCurrent({required bool isRefresh}) async {
    final s = _currentState();
    final tab = _currentTabs[_currentSport] ?? 0;
    final timestamp = _currentTimestamp();
    final BMSportType sport = _currentSport;

    if (s.isFetching) {
      debugPrint(
        '🔒 BMMatchTabPage requestblocked (re-entry): sport=$sport tab=$tab ts=$timestamp isRefresh=$isRefresh',
      );
      return;
    }
    if (!isRefresh && s.hasNoMore) return;
    s.isFetching = true;

    final int requestPageInt;
    if (isRefresh) {
      if (!mounted) {
        s.isFetching = false;
        return;
      }
      setState(() {
        s.isRefreshing = true;
        s.page = 1;
        s.hasNoMore = false;
      });
      requestPageInt = 1;
    } else {
      if (!mounted) {
        s.isFetching = false;
        return;
      }
      setState(() {
        s.isLoadingMore = true;
      });
      requestPageInt = s.page + 1;
    }

    debugPrint(
      '🌐 BMMatchTabPage trueactual request start: sport=$sport, tab=$tab, page=$requestPageInt, size=$_size, ts=$timestamp',
    );
    // tab=0(follow) whenAPIinputfixedpass 4, itsremainingoriginalkindpass
    final int requestTab = tab == 0 ? 4 : tab;
    List<BMMatchModel> result = [];
    int? serverTotal;
    try {
      if (sport == BMSportType.football) {
        final data = await _apiService.fetchFootballMatches(
          tab: requestTab,
          page: requestPageInt,
          size: _size,
          timestamp: timestamp,
          competitionIds: const [],
        );
        serverTotal = data?.total;
        if (data != null && data.results.isNotEmpty) {
          for (final item in data.results) {
            try {
              result.add(_apiServiceConvertFootball(item));
            } catch (e) {
              debugPrint('BMMatchTabPage footballsingleconvertskip: $e');
            }
          }
        }
      } else {
        final data = await _apiService.fetchBasketballMatches(
          tab: requestTab,
          page: requestPageInt,
          size: _size,
          timestamp: timestamp,
          competitionIds: const [],
        );
        serverTotal = data?.total;
        if (data != null && data.results.isNotEmpty) {
          for (final item in data.results) {
            try {
              result.add(_apiServiceConvertBasketball(item));
            } catch (e) {
              debugPrint('BMMatchTabPage basketballsingleconvertskip: $e');
            }
          }
        }
      }
      debugPrint(
        '✅ BMMatchTabPage trueactual request success: this returns ${result.length} items, servicetotal count=$serverTotal',
      );
    } catch (e) {
      debugPrint(
        '❌ BMMatchTabPage requestexception(sport=$sport tab=$tab isRefresh=$isRefresh page=$requestPageInt): $e',
      );
      result = [];
    } finally {
      s.isFetching = false;
    }

    if (!mounted) return;
    setState(() {
      // : ifuser await duringswitch sport/tab/date, thistimeresultreturnalsotosendrequestwhengroupcache
      final curTab = _currentTabs[sport] ?? 0;
      final curTs = _currentTimestampForSport(sport);
      final curKey = _cacheKey(sport, curTab, curTs);
      final origKey = _cacheKey(sport, tab, timestamp);
      final targetS = (curKey == origKey)
          ? s
          : _cachePool.putIfAbsent(origKey, () => s);

      if (isRefresh) {
        targetS.list = result;
        targetS.page = 1;
        targetS.isRefreshing = false;
      } else {
        targetS.list.addAll(result);
        targetS.page = requestPageInt;
        targetS.isLoadingMore = false;
      }
      targetS.serverTotal = serverTotal;
      if (serverTotal != null) {
        targetS.hasNoMore = targetS.list.length >= serverTotal;
      } else {
        targetS.hasNoMore = result.length < _size;
      }
      // syncfollowstatecache (listper item matchId -> isFollowed)
      for (final m in targetS.list) {
        if (!_followStates.containsKey(m.matchId)) {
          _followStates[m.matchId] = m.isFollowed;
        }
      }
    });
  }

  /// cardtop-right cornerfollow buttontap (not logged infirstjumploginpage, anddetailpageone)
  /// football: POST /api/livespeed/football/match/subscribe|unsubscribe
  /// basketball: POST /api/livespeed/basketball/match/subscribe|unsubscribe
  /// [match] - goalmatch (BMMatchModel type)
  Future<void> _toggleFollow(BMMatchModel match) async {
    if (!BMAuthManager().isLoggedIn) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const BMLoginPage()),
      );
      if (ok != true) return;
    }
    final matchId = int.tryParse(match.matchId) ?? 0;
    if (matchId == 0) return;
    final willFollow = !(_followStates[match.matchId] ?? match.isFollowed);
    final bool success;
    if (match.sportType == BMMatchSportType.basketball) {
      success = willFollow
          ? await _detailApiService.subscribeBasketballMatch(matchId: matchId)
          : await _detailApiService.unsubscribeBasketballMatch(
              matchId: matchId,
            );
    } else {
      success = willFollow
          ? await _detailApiService.subscribeFootballMatch(matchId: matchId)
          : await _detailApiService.unsubscribeFootballMatch(matchId: matchId);
    }
    if (!mounted) return;
    if (success) {
      setState(() {
        _followStates[match.matchId] = willFollow;
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (willFollow ? 'followed' : 'Unfollowed')
                : 'operation failed, please retry',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: BMColors.pitch800,
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// takespecified sport currentselecteddate of timestamp (forasynccallbackfirstlateronecheck)
  int _currentTimestampForSport(BMSportType sport) {
    final idx = _selectedDateIndices[sport] ?? 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = today.add(Duration(days: idx - 1));
    return targetDay.millisecondsSinceEpoch ~/ 1000;
  }

  /// single BMMatchItem -> BMMatchModel (alignment BMMatchApiService._convertFootballMatch)
  BMMatchModel _apiServiceConvertFootball(BMMatchItem item) {
    int? safeInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? safeStr(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    BMMatchStatus status = BMMatchStatus.tbd;
    switch (safeInt(item.statusId)) {
      case 1:
        status = BMMatchStatus.upcoming;
        break;
      case 2:
      case 3:
      case 4:
      case 5:
      case 7:
        status = BMMatchStatus.live;
        break;
      case 8:
        status = BMMatchStatus.ended;
        break;
      default:
        status = BMMatchStatus.tbd;
    }
    final int? homeScore = item.homeNormalScore;
    final int? awayScore = item.awayNormalScore;
    final String timeStr;
    if (status == BMMatchStatus.live && (item.minutes ?? '').isNotEmpty) {
      timeStr = item.minutes!;
    } else {
      timeStr = _formatMatchTime(item.matchTime);
    }
    String? half;
    if (item.homeHalfScore != null || item.awayHalfScore != null) {
      half = 'half ${item.homeHalfScore ?? 0}-${item.awayHalfScore ?? 0}';
    }
    return BMMatchModel(
      matchId: item.matchId?.toString() ?? '',
      leagueName: item.competitionName ?? '',
      leagueColor: 0xFFF97316,
      homeTeam: BMTeamModel(
        teamId: item.homeTeamId?.toString(),
        teamName: item.homeTeamName ?? '',
        teamShort: _extractShort(item.homeTeamName),
        logoUrl: item.homeTeamLogo,
      ),
      awayTeam: BMTeamModel(
        teamId: item.awayTeamId?.toString(),
        teamName: item.awayTeamName ?? '',
        teamShort: _extractShort(item.awayTeamName),
        logoUrl: item.awayTeamLogo,
      ),
      homeScore: homeScore,
      awayScore: awayScore,
      matchTime: timeStr,
      status: status,
      statusId: item.statusId,
      statusName: item.statusName,
      sportType: BMMatchSportType.football,
      liveMinute: status == BMMatchStatus.live ? item.minutes : null,
      halfTimeScore: half,
      goalEvents: const [],
      isFeatured: status == BMMatchStatus.live,
      isFollowed: item.subscribed ?? false,
      homeWinRate: 0,
      drawRate: 0,
      awayWinRate: 0,
      matchTag: safeStr(item.stageName),
      round: safeStr(item.stageName),
    );
  }

  /// byOCaccumulatebasketballper-quarter score (splitcomma No.passsum)
  /// OC: NSArray *a=[str componentsSeparatedByString:@","]; for(NSString*s in a) count+=[s integerValue];
  int _sumBasketballScores(String? scoresStr) {
    if (scoresStr == null || scoresStr.isEmpty) return 0;
    final arr = scoresStr.split(',');
    int count = 0;
    for (final sub in arr) {
      final trimmed = sub.trim();
      if (trimmed.isEmpty) continue;
      count += int.tryParse(trimmed) ?? 0;
    }
    return count;
  }

  /// single BMBasketballMatchItem -> BMMatchModel (alignment BMMatchApiService._convertBasketballMatch)
  BMMatchModel _apiServiceConvertBasketball(BMBasketballMatchItem item) {
    int? safeInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? safeStr(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    BMMatchStatus status = BMMatchStatus.tbd;
    switch (safeInt(item.statusId)) {
      case 1:
      case 13:
        status = BMMatchStatus.upcoming;
        break;
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
        status = BMMatchStatus.live;
        break;
      case 10:
      case 11:
        status = BMMatchStatus.ended;
        break;
      default:
        status = BMMatchStatus.tbd;
    }
    // byOC: comma No.minper-quarter scoreaccumulate
    final int homeScore = _sumBasketballScores(item.homeScores);
    final int awayScore = _sumBasketballScores(item.awayScores);
    final String timeStr = _formatMatchTime(item.matchTime);
    return BMMatchModel(
      matchId: item.id?.toString() ?? '',
      leagueName: item.competitionName ?? '',
      leagueColor: 0xFFF97316,
      homeTeam: BMTeamModel(
        teamId: item.homeTeamId?.toString(),
        teamName: item.homeTeamName ?? '',
        teamShort: _extractShort(item.homeTeamName),
        logoUrl: item.homeTeamLogo,
      ),
      awayTeam: BMTeamModel(
        teamId: item.awayTeamId?.toString(),
        teamName: item.awayTeamName ?? '',
        teamShort: _extractShort(item.awayTeamName),
        logoUrl: item.awayTeamLogo,
      ),
      homeScore: homeScore,
      awayScore: awayScore,
      matchTime: timeStr,
      status: status,
      statusId: item.statusId,
      statusName: item.statusName,
      sportType: BMMatchSportType.basketball,
      liveMinute: status == BMMatchStatus.live ? item.stageName : null,
      halfTimeScore: null,
      goalEvents: const [],
      isFeatured: status == BMMatchStatus.live,
      isFollowed: item.subscribed ?? false,
      homeWinRate: 0,
      drawRate: 0,
      awayWinRate: 0,
      matchTag: safeStr(item.stageName),
      round: safeStr(item.stageName),
    );
  }

  /// formatmatch timestamp -> HH:mm
  String _formatMatchTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// team nametakefirst3textlargewrite
  String _extractShort(String? name) {
    if (name == null || name.isEmpty) return '';
    if (name.length <= 3) return name.toUpperCase();
    return name.substring(0, 3).toUpperCase();
  }

  /// pull downrefreshcallback
  Future<void> _onRefresh() {
    final s = _currentState();
    s.list = [];
    s.page = 1;
    s.hasNoMore = false;
    s.serverTotal = null;
    return _fetchCurrent(isRefresh: true);
  }

  @override
  Widget buildBody(BuildContext context) {
    final tab = _currentTabs[_currentSport] ?? 0;
    final showDatePicker = tab == 2 || tab == 3;
    return Column(
      children: [
        _buildTopBar(),
        _buildStatusFilter(),
        if (showDatePicker) _buildDatePicker(),
        Expanded(child: _buildMatchList()),
      ],
    );
  }

  /// buildtoptitlebar + foot/basketswitch
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'match list',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BMColors.textPrimary,
            ),
          ),
          _buildSportToggle(),
        ],
      ),
    );
  }

  /// buildfootball/basketballswitch
  Widget _buildSportToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch700),
      ),
      child: Row(
        children: [
          _buildToggleBtn(
            'football',
            _currentSport == BMSportType.football,
            () {
              _switchSport(BMSportType.football);
            },
          ),
          _buildToggleBtn(
            'basketball',
            _currentSport == BMSportType.basketball,
            () {
              _switchSport(BMSportType.basketball);
            },
          ),
        ],
      ),
    );
  }

  /// buildswitchbutton
  Widget _buildToggleBtn(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? BMColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? BMColors.pitch950 : BMColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// buildstatefilterdevice (direction, 0all/1in progress/2i.e.willopenmatch/3FTrepeatodds)
  Widget _buildStatusFilter() {
    final currentTab = _currentTabs[_currentSport] ?? 0;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterLabels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filterLabels[index];
          final isSelected = currentTab == filter.$1;
          return GestureDetector(
            onTap: () => _switchTab(filter.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? BMColors.pitch800 : BMColors.pitch950,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? BMColors.accent.withValues(alpha: 0.3)
                      : BMColors.pitch800,
                ),
              ),
              child: Center(
                child: Text(
                  filter.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? BMColors.bright
                        : BMColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// builddateselectitems (7day: firstday..largelaterday, trueactualmonthday, directionscrolloverflow)
  Widget _buildDatePicker() {
    final dates = _dateList();
    final idx = _selectedDateIndices[_currentSport] ?? 1;
    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: BMColors.pitch850.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, dIdx) {
          final d = dates[dIdx];
          final isSelected = idx == dIdx;
          return _buildDateItem(d.$1, d.$2, isSelected, () {
            _switchDate(dIdx);
          });
        },
      ),
    );
  }

  /// builddateitem
  Widget _buildDateItem(
    String day,
    String date,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? BMColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? BMColors.pitch950 : BMColors.textSecondary,
              ),
            ),
            Text(
              date,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? BMColors.pitch950 : BMColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// buildmatchlist (includesfirst screenLoading/emptystate/pull downrefresh/pull uploadingFooter + byleaguegroup)
  Widget _buildMatchList() {
    final s = _currentState();
    if (s.isRefreshing && s.list.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: BMColors.bright,
          strokeWidth: 2,
        ),
      );
    }
    if (s.list.isEmpty) {
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
                'No match',
                style: TextStyle(fontSize: 13, color: BMColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    // hasdata: byleaguegrouplaterD + Footer later
    final Map<String, List<BMMatchModel>> grouped = {};
    for (final m in s.list) {
      final league = (m.leagueName.isNotEmpty)
          ? m.leagueName
          : 'others competition';
      grouped.putIfAbsent(league, () => []).add(m);
    }
    final flatGroups = grouped.entries.toList();
    return RefreshIndicator(
      color: BMColors.bright,
      backgroundColor: BMColors.pitch850,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: flatGroups.length + 1,
        itemBuilder: (ctx, index) {
          if (index == flatGroups.length) return _buildFooter();
          return _buildLeagueGroup(
            flatGroups[index].key,
            flatGroups[index].value,
          );
        },
      ),
    );
  }

  /// bottomloadingindicator
  Widget _buildFooter() {
    final s = _currentState();
    if (s.hasNoMore) {
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
    if (s.isLoadingMore) {
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

  /// buildleaguegroup (title + competitionlinelist)
  Widget _buildLeagueGroup(String leagueName, List<BMMatchModel> matches) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 14,
                      color: BMColors.amber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      leagueName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: BMColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${matches.length} games',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BMColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...matches.map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildMatchRow(match),
            ),
          ),
        ],
      ),
    );
  }

  /// buildsinglelinematch card (background colorand TopicPostCard completefullone, top-right cornerfollow button)
  Widget _buildMatchRow(BMMatchModel match) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _currentSport == BMSportType.football
                ? BMFootballDetailPage(match: match)
                : BMBasketballDetailPage(match: match),
          ),
        );
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BMColors.pitch850,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BMColors.pitch700.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  _buildMatchTime(match),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMatchTeams(match)),
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0x601C4537)),
                      ),
                    ),
                    child: _buildMatchExtra(match),
                  ),
                ],
              ),
            ),
          ),
          Positioned(top: 24, right: 10, child: _buildFollowButton(match)),
        ],
      ),
    );
  }

  /// buildcardtop-right cornerfollowstatus button (anddetailpagenavigationsameclausestyle, tapfollow/Take effectfollowAPI)
  /// [match] - goalmatch (BMMatchModel type)
  Widget _buildFollowButton(BMMatchModel match) {
    final bool followed = _followStates[match.matchId] ?? match.isFollowed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleFollow(match),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: followed
              ? BMColors.bright.withValues(alpha: 0.15)
              : BMColors.pitch850,
          shape: BoxShape.circle,
          border: Border.all(
            color: followed ? BMColors.bright : BMColors.pitch700,
            width: 1,
          ),
        ),
        child: Icon(
          followed ? Icons.notifications : Icons.notifications_none,
          size: 10,
          color: followed ? BMColors.bright : BMColors.textTertiary,
        ),
      ),
    );
  }

  /// buildmatch time / LIVE state
  Widget _buildMatchTime(BMMatchModel match) {
    final bool isLive = match.status == BMMatchStatus.live;
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          if (isLive) ...[
            Text(
              (match.liveMinute != null && match.liveMinute!.isNotEmpty)
                  ? match.liveMinute!
                  : "68'",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: BMColors.bright,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: BMColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Live',
                style: TextStyle(fontSize: 9, color: BMColors.bright),
              ),
            ),
          ] else ...[
            Text(
              match.matchTime,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: match.status == BMMatchStatus.ended
                    ? BMColors.textSecondary
                    : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              match.status == BMMatchStatus.upcoming
                  ? 'not started'
                  : (match.round.isNotEmpty ? match.round : 'FT'),
              style: const TextStyle(fontSize: 9, color: BMColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  /// buildmatchteam + score (line: home team score / away team score)
  Widget _buildMatchTeams(BMMatchModel match) {
    final homeName = match.homeTeam?.teamName.isNotEmpty == true
        ? match.homeTeam!.teamName
        : match.homeTeamName;
    final awayName = match.awayTeam?.teamName.isNotEmpty == true
        ? match.awayTeam!.teamName
        : match.awayTeamName;
    return Column(
      children: [
        _buildTeamScoreRow(
          homeName,
          match.homeScore,
          match.status == BMMatchStatus.live,
          match.homeTeam?.logoUrl,
        ),
        const SizedBox(height: 4),
        _buildTeamScoreRow(
          awayName,
          match.awayScore,
          false,
          match.awayTeam?.logoUrl,
        ),
      ],
    );
  }

  /// buildsinglelineteamscore (logo(24px) + team name + score)
  Widget _buildTeamScoreRow(
    String name,
    int? score,
    bool highlight,
    String? logoUrl,
  ) {
    return Row(
      children: [
        _buildTeamLogo(logoUrl, name),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highlight ? BMColors.textPrimary : BMColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          score?.toString() ?? '-',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: highlight ? BMColors.bright : BMColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// buildteam logo circle (24px, failureplaceholderbottom)
  Widget _buildTeamLogo(String? logoUrl, String teamName) {
    final url = logoUrl ?? '';
    final label = (teamName.isNotEmpty && teamName.length <= 3)
        ? teamName.toUpperCase()
        : (teamName.isNotEmpty ? teamName.substring(0, 2).toUpperCase() : '');
    if (url.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 24,
          height: 24,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              if (label.isNotEmpty) {
                return Container(
                  color: BMColors.pitch800,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: BMColors.textSecondary,
                    ),
                  ),
                );
              }
              return Container(
                color: BMColors.pitch800,
                child: const Icon(
                  Icons.sports_soccer_outlined,
                  size: 14,
                  color: BMColors.textTertiary,
                ),
              );
            },
          ),
        ),
      );
    }
    if (label.isNotEmpty) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: BMColors.pitch800,
          shape: BoxShape.circle,
          border: Border.all(color: BMColors.pitch700, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: BMColors.textSecondary,
          ),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: BMColors.pitch800,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.sports_soccer_outlined,
        size: 14,
        color: BMColors.textTertiary,
      ),
    );
  }

  /// buildmatchaddinfo (right sidecornerhandicapetc)
  Widget _buildMatchExtra(BMMatchModel match) {
    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (match.status == BMMatchStatus.live) ...[
            const Text(
              'data actual',
              style: TextStyle(fontSize: 10, color: BMColors.textSecondary),
            ),
          ] else if (match.status == BMMatchStatus.upcoming) ...[
            const Text(
              'index reference',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: BMColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '',
              style: TextStyle(fontSize: 10, color: BMColors.bright),
            ),
          ] else ...[
            const Text(
              '',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: BMColors.bright,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'repeat odds complete end',
              style: TextStyle(fontSize: 10, color: BMColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
