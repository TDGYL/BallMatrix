import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_match_api_model.dart';
import '../../models/bm_basketball_match_model.dart';
import '../../viewmodels/home/bm_home_view_model.dart' show BMSportType;
import '../../services/bm_match_api_service.dart';
import 'bm_football_detail_page.dart';
import 'bm_basketball_detail_page.dart';

/// _MatchPageState - 单组（sport+tab+timestamp）独立分页缓存状态
/// 作用: 每个 (sport, tab, timestamp) 组合保存自己的列表/分页状态, 足球篮球互不影响
class _MatchPageState {
  /// 比赛列表 (List<BMMatchModel> 类型)
  List<BMMatchModel> list = [];

  /// 当前页 (int 类型, 从1开始)
  int page = 1;

  /// 是否到底 (bool 类型)
  bool hasNoMore = false;

  /// 请求锁 (bool 类型, 防重入)
  bool isFetching = false;

  /// 下拉刷新或首屏Loading中 (bool 类型)
  bool isRefreshing = true;

  /// 上拉加载中 (bool 类型)
  bool isLoadingMore = false;

  /// 服务端返回的总数 (int? 类型, 用于精准判断hasNoMore)
  int? serverTotal;
}

/// BMMatchTabPage - 底部导航 赛事 Tab 页
/// 功能: 足球/篮球独立切换 + 状态过滤(0/1/2/3) + 快捷日期条 + 按联赛分组列表 + 下拉刷新/上拉加载 + 多维度缓存
class BMMatchTabPage extends BMBasePage {
  const BMMatchTabPage({super.key});

  @override
  State<BMMatchTabPage> createState() => _BMMatchTabPageState();
}

class _BMMatchTabPageState extends BMBasePageState<BMMatchTabPage> {
  /// 当前运动类型 (BMSportType 枚举, 默认足球)
  BMSportType _currentSport = BMSportType.football;

  /// 每个运动类型当前选中的状态tab (Map<BMSportType, int> 类型, 0/1/2/3 = 全部/进行中/即将开赛/完场复盘, 足球篮球独立)
  final Map<BMSportType, int> _currentTabs = {
    BMSportType.football: 0,
    BMSportType.basketball: 0,
  };

  /// 每个运动类型当前选中的快捷日期索引 (Map<BMSportType, int> 类型, 足球篮球独立, 默认1=今天)
  final Map<BMSportType, int> _selectedDateIndices = {
    BMSportType.football: 1,
    BMSportType.basketball: 1,
  };

  /// 状态过滤器显示文字 (与 tab值0/1/2/3对应)
  final List<(int, String)> _filterLabels = const [
    (0, '全部'),
    (1, '进行中'),
    (2, '即将开赛'),
    (3, '完场复盘'),
  ];

  /// API 服务实例 (BMMatchApiService 类型)
  final BMMatchApiService _apiService = BMMatchApiService();

  /// 列表滚动控制器 (ScrollController 类型, 上拉加载监听)
  late final ScrollController _scrollController;

  /// 每页条数 (int 类型, 固定20)
  final int _size = 20;

  /// 分页缓存池 (Map<String, _MatchPageState> 类型,  key='{sportIndex}_{tab}_{timestamp(秒)}')
  final Map<String, _MatchPageState> _cachePool = {};

  /// 取当前 sport + 当前 tab + 当前 timestamp 对应的分页状态 (没有则新建)
  _MatchPageState _currentState() {
    final tab = _currentTabs[_currentSport] ?? 0;
    final ts = _currentTimestamp();
    final key = _cacheKey(_currentSport, tab, ts);
    return _cachePool.putIfAbsent(key, () => _MatchPageState());
  }

  /// 构造缓存key
  String _cacheKey(BMSportType sport, int tab, int ts) =>
      '${sport.index}_${tab}_${ts}_${_todayZeroKey(sport)}';

  /// 用于避免 sport 切换导致 timestamp 在同一天下不同 sport 实例也一致, 加 sport-specific 日期key
  int _todayZeroKey(BMSportType sport) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return (d.millisecondsSinceEpoch ~/ 1000) + sport.index;
  }

  /// 获取当前 sport 选中快捷日期的时间戳 (秒级, 日期0点)
  /// 说明: 依赖当前 tab 动态计算日期范围, tab=0/1(全部/进行中)默认使用今天
  int _currentTimestamp() {
    final tab = _currentTabs[_currentSport] ?? 0;
    final idx = _selectedDateIndices[_currentSport] ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final offset = _dateOffsetForIndex(tab, idx);
    final targetDay = today.add(Duration(days: offset));
    return targetDay.millisecondsSinceEpoch ~/ 1000;
  }

  /// 根据 tab 和 index 返回相对今天的 day 偏移量
  /// tab=2(即将开赛): idx 0..5 -> offset 0..5 (今天..T+5)
  /// tab=3(完场复盘): idx 0..5 -> offset -5..0 (T-5..今天)
  /// tab=0/1(全部/进行中): 永远 0(今天)
  int _dateOffsetForIndex(int tab, int idx) {
    if (tab == 2) return idx.clamp(0, 5);
    if (tab == 3) return (idx.clamp(0, 5)) - 5;
    return 0;
  }

  /// 生成指定 sport+tab 对应的快捷日期项
  /// tab=0(全部)/tab=1(进行中): 返回空列表 (UI隐藏)
  /// tab=2(即将开赛): 今天 + 后5天(共6天)
  /// tab=3(完场复盘): 前5天 + 今天(共6天), 选中最后一天=今天
  List<(String, String, int)> _dateListForTab(int tab) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<(String, String, int)> out = [];
    if (tab == 2) {
      for (int i = 0; i < 6; i++) {
        final d = today.add(Duration(days: i));
        String day;
        if (i == 0) {
          day = '今天';
        } else if (i == 1) {
          day = '明天';
        } else {
          final wd = d.weekday;
          const wk = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
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
          day = '今天';
        } else if (i == -1) {
          day = '昨天';
        } else if (i == -2) {
          day = '前天';
        } else {
          final wd = d.weekday;
          const wk = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
          day = wk[wd - 1];
        }
        final date =
            '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        // 相对索引: 0..5 (0=T-5, 5=今天)
        out.add((day, date, i + 5));
      }
      return out;
    }
    return out;
  }

  /// 生成快捷日期数据 (兼容历史接口: 始终返回 tab=2 的格式方便UI通用)
  List<(String, String)> _dateList() {
    final tab = _currentTabs[_currentSport] ?? 0;
    return _dateListForTab(tab).map((e) => (e.$1, e.$2)).toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // 首屏触发一次当前 (football + tab=0 + 今天) 的请求
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrent(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听: 触底100px内触发上拉加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final s = _currentState();
      if (!s.isFetching && !s.isRefreshing && !s.hasNoMore) {
        _fetchCurrent(isRefresh: false);
      }
    }
  }

  /// 切换运动类型 (足球 <-> 篮球)
  /// 说明: 不发新请求, 直接取该 sport 对应 tab+日期的缓存展示
  void _switchSport(BMSportType next) {
    if (next == _currentSport) return;
    setState(() {
      _currentSport = next;
    });
    // 切到新sport, 如果这组缓存还没请求过( isRefreshing=true 且 list空 ), 触发请求
    final s = _currentState();
    if (s.list.isEmpty && s.isRefreshing && !s.isFetching) {
      _fetchCurrent(isRefresh: true);
    }
  }

  /// 切换状态过滤器 (全部/进行中/即将开赛/完场复盘)
  /// 说明: 切换 tab 时按规则重置默认日期, 并强制刷新(切换日期一定会触发刷新)
  void _switchTab(int tab) {
    if ((_currentTabs[_currentSport] ?? 0) == tab) return;
    int defaultDateIdx = 0;
    if (tab == 2) {
      // 即将开赛: 选中第一天(今天, idx=0)
      defaultDateIdx = 0;
    } else if (tab == 3) {
      // 完场复盘: 选中最后一天(今天, 在T-5..今天共6天中最后1个, idx=5)
      defaultDateIdx = 5;
    } else {
      // 全部/进行中: 内部记录 idx=0 (不影响 timestamp 默认今天)
      defaultDateIdx = 0;
    }
    setState(() {
      _currentTabs[_currentSport] = tab;
      _selectedDateIndices[_currentSport] = defaultDateIdx;
    });
    // 切换 tab 按需求规则重置并强制刷新
    final s = _currentState();
    s.list = [];
    s.page = 1;
    s.hasNoMore = false;
    s.serverTotal = null;
    _fetchCurrent(isRefresh: true);
  }

  /// 切换快捷日期
  /// 说明: 根据需求, 点中不同的时间必须重新加载新数据 (即使缓存有也强制刷新)
  void _switchDate(int idx) {
    if ((_selectedDateIndices[_currentSport] ?? 1) == idx) return;
    setState(() {
      _selectedDateIndices[_currentSport] = idx;
    });
    // 需求: 切换日期必须重新加载新数据 => 强制重置并刷新
    final s = _currentState();
    s.list = [];
    s.page = 1;
    s.hasNoMore = false;
    s.serverTotal = null;
    _fetchCurrent(isRefresh: true);
  }

  /// 请求当前 (sport + tab + timestamp) 组合的数据
  /// [isRefresh] true=下拉/首屏重置page=1; false=上拉 page+1
  Future<void> _fetchCurrent({required bool isRefresh}) async {
    final s = _currentState();
    final tab = _currentTabs[_currentSport] ?? 0;
    final timestamp = _currentTimestamp();
    final BMSportType sport = _currentSport;

    if (s.isFetching) {
      debugPrint('🔒 BMMatchTabPage 请求被挡(重入): sport=$sport tab=$tab ts=$timestamp isRefresh=$isRefresh');
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
      '🌐 BMMatchTabPage 真实请求发起: sport=$sport, tab=$tab, page=$requestPageInt, size=$_size, ts=$timestamp',
    );
    List<BMMatchModel> result = [];
    int? serverTotal;
    try {
      if (sport == BMSportType.football) {
        final data = await _apiService.fetchFootballMatches(
          tab: tab,
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
              debugPrint('BMMatchTabPage 足球单条转换跳过: $e');
            }
          }
        }
      } else {
        final data = await _apiService.fetchBasketballMatches(
          tab: tab,
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
              debugPrint('BMMatchTabPage 篮球单条转换跳过: $e');
            }
          }
        }
      }
      debugPrint(
        '✅ BMMatchTabPage 真实请求成功: 本次返回 ${result.length} 条, 服务端总条数=$serverTotal',
      );
    } catch (e) {
      debugPrint(
        '❌ BMMatchTabPage 请求异常(sport=$sport tab=$tab isRefresh=$isRefresh page=$requestPageInt): $e',
      );
      result = [];
    } finally {
      s.isFetching = false;
    }

    if (!mounted) return;
    setState(() {
      // 防御: 若用户在 await 期间切换了 sport/tab/date, 本次结果归还给发起请求时那组缓存
      final curTab = _currentTabs[sport] ?? 0;
      final curTs = _currentTimestampForSport(sport);
      final curKey = _cacheKey(sport, curTab, curTs);
      final origKey = _cacheKey(sport, tab, timestamp);
      final targetS = (curKey == origKey) ? s : _cachePool.putIfAbsent(origKey, () => s);

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
    });
  }

  /// 取指定 sport 当前选中日期的时间戳 (用于异步回调前后一致性判断)
  int _currentTimestampForSport(BMSportType sport) {
    final idx = _selectedDateIndices[sport] ?? 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = today.add(Duration(days: idx - 1));
    return targetDay.millisecondsSinceEpoch ~/ 1000;
  }

  /// 单条 BMMatchItem -> BMMatchModel (对齐 BMMatchApiService._convertFootballMatch)
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

  /// 按OC语法累加篮球各节比分 (split逗号遍历求和)
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

  /// 单条 BMBasketballMatchItem -> BMMatchModel (对齐 BMMatchApiService._convertBasketballMatch)
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
    // 按OC语法: 逗号分隔各节比分累加
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

  /// 格式化比赛时间戳 -> HH:mm
  String _formatMatchTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 队名取前3字母大写
  String _extractShort(String? name) {
    if (name == null || name.isEmpty) return '';
    if (name.length <= 3) return name.toUpperCase();
    return name.substring(0, 3).toUpperCase();
  }

  /// 下拉刷新回调
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

  /// 构建顶部标题栏 + 足/篮切换
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '赛程与历史数据库',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary),
          ),
          _buildSportToggle(),
        ],
      ),
    );
  }

  /// 构建足球/篮球切换
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
          _buildToggleBtn('足球', _currentSport == BMSportType.football, () {
            _switchSport(BMSportType.football);
          }),
          _buildToggleBtn('篮球', _currentSport == BMSportType.basketball, () {
            _switchSport(BMSportType.basketball);
          }),
        ],
      ),
    );
  }

  /// 构建切换按钮
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

  /// 构建状态过滤器 (横向, 0全部/1进行中/2即将开赛/3完场复盘)
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? BMColors.bright : BMColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建日期选择条 (7天: 前天..大后天, 真实月日, 横向滚动防溢出)
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

  /// 构建日期项
  Widget _buildDateItem(
      String day, String date, bool isSelected, VoidCallback onTap) {
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
                color:
                    isSelected ? BMColors.pitch950 : BMColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建比赛列表 (含首屏Loading/空态/下拉刷新/上拉加载Footer + 按联赛分组)
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
                '暂无比赛',
                style:
                    TextStyle(fontSize: 13, color: BMColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    // 有数据: 按联赛分组后展平 + Footer 放最后
    final Map<String, List<BMMatchModel>> grouped = {};
    for (final m in s.list) {
      final league = (m.leagueName.isNotEmpty) ? m.leagueName : '其他赛事';
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
              flatGroups[index].key, flatGroups[index].value);
        },
      ),
    );
  }

  /// 底部加载指示器
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
              '—— 到底啦 ——',
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
              '加载中...',
              style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// 构建联赛分组 (标题 + 赛事行列表)
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
                    const Icon(Icons.emoji_events,
                        size: 14, color: BMColors.amber),
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
                  '${matches.length} 场对局',
                  style:
                      const TextStyle(fontSize: 12, color: BMColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...matches.map((match) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMatchRow(match),
              )),
        ],
      ),
    );
  }

  /// 构建单行比赛卡片 (背景色与 TopicPostCard 完全一致)
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
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BMColors.pitch850,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
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
    );
  }

  /// 构建比赛时间 / LIVE 状态
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
                  ? '未开赛'
                  : (match.round.isNotEmpty ? match.round : '已结束'),
              style: const TextStyle(fontSize: 9, color: BMColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建比赛队伍 + 比分 (两行: 主队 比分 / 客队 比分)
  Widget _buildMatchTeams(BMMatchModel match) {
    final homeName = match.homeTeam?.teamName.isNotEmpty == true
        ? match.homeTeam!.teamName
        : match.homeTeamName;
    final awayName = match.awayTeam?.teamName.isNotEmpty == true
        ? match.awayTeam!.teamName
        : match.awayTeamName;
    return Column(
      children: [
        _buildTeamScoreRow(homeName, match.homeScore,
            match.status == BMMatchStatus.live, match.homeTeam?.logoUrl),
        const SizedBox(height: 4),
        _buildTeamScoreRow(awayName, match.awayScore, false, match.awayTeam?.logoUrl),
      ],
    );
  }

  /// 构建单行队伍比分 (logo(24px) + 队名 + 比分)
  Widget _buildTeamScoreRow(String name, int? score, bool highlight, String? logoUrl) {
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

  /// 构建球队 logo 圆形 (24px, 失败占位灰底)
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

  /// 构建比赛附加信息 (右侧角球盘口等)
  Widget _buildMatchExtra(BMMatchModel match) {
    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (match.status == BMMatchStatus.live) ...[
            const Text(
              '数据实时',
              style: TextStyle(fontSize: 10, color: BMColors.textSecondary),
            ),
          ] else if (match.status == BMMatchStatus.upcoming) ...[
            const Text(
              '指数参考',
              style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: BMColors.textSecondary),
            ),
            const SizedBox(height: 2),
            const Text(
              'AI预警',
              style: TextStyle(fontSize: 10, color: BMColors.bright),
            ),
          ] else ...[
            const Text(
              '赛果归档',
              style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: BMColors.bright),
            ),
            const SizedBox(height: 2),
            const Text(
              '复盘完结',
              style: TextStyle(fontSize: 10, color: BMColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
