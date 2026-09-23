import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../viewmodels/home/bm_home_view_model.dart' show BMSportType;
import '../../widgets/home/bm_match_spotlight_card.dart';
import '../../services/bm_match_api_service.dart';
import 'bm_football_detail_page.dart';
import 'bm_basketball_detail_page.dart';

/// BMMatchListPage - 赛事列表页 (首页「查看全部」push 进来)
/// 功能: 真实POST接口请求(tab=0/当天timestamp) + 复用首页卡片 + 下拉刷新 + 上拉加载
class BMMatchListPage extends BMBasePage {
  /// 运动类型 (BMSportType 类型, football/basketball)
  final BMSportType sportType;

  const BMMatchListPage({
    super.key,
    required this.sportType,
  });

  @override
  State<BMMatchListPage> createState() => _BMMatchListPageState();
}

class _BMMatchListPageState extends BMBasePageState<BMMatchListPage> {
  /// 比赛列表数据 (List类型, 元素为BMMatchModel)
  List<BMMatchModel> _matchList = [];

  /// 下拉刷新或首次加载中 (bool 类型, 仅控制UI全屏Loading)
  bool _isRefreshing = true;

  /// 上拉加载更多中 (bool 类型, 控制底部footer Loading)
  bool _isLoadingMore = false;

  /// 请求重入锁 (bool 类型, true=有请求在飞, 防止重复发)
  bool _isFetching = false;

  /// 是否还有下一页 (bool 类型, true=可继续上拉)
  bool _hasNoMore = false;

  /// 当前页码 (int 类型, 从1开始)
  int _page = 1;

  /// 每页条数 (int 类型, 默认10, 对齐hanklive)
  final int _size = 10;

  /// 当前选中的日期时间戳 (int 类型, 秒级, 默认今天0点)
  int _currentTimestamp = 0;

  /// 列表滚动控制器 (ScrollController 类型, 上拉加载监听)
  late final ScrollController _scrollController;

  /// API 服务实例 (BMMatchApiService 类型)
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

  /// 滚动监听: 触底100px内触发上拉加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isFetching && !_isRefreshing && !_hasNoMore) {
        _fetchMatches(isRefresh: false);
      }
    }
  }

  /// 获取当天0点秒级时间戳 (若用户未选择日期, 取默认今天0点)
  int _getSelectedTimestamp() {
    if (_currentTimestamp > 0) return _currentTimestamp;
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return d.millisecondsSinceEpoch ~/ 1000;
  }

  /// 请求比赛列表 (真实POST接口, tab=0 + 当天时间戳 + 分页)
  /// [isRefresh] - true=重置page=1 / false=加载更多 page+1
  Future<void> _fetchMatches({required bool isRefresh}) async {
    if (_isFetching) {
      debugPrint('🔒 BMMatchListPage 请求被挡(重入): isRefresh=$isRefresh, _page=$_page');
      return;
    }
    if (!isRefresh && _hasNoMore) {
      debugPrint('🔒 BMMatchListPage 加载更多被挡: _hasNoMore=true');
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
    debugPrint('🌐 BMMatchListPage 真实请求发起: sport=${widget.sportType.name}, tab=0, page=$requestPage, size=$_size, timestamp=$timestamp');
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
      debugPrint('✅ BMMatchListPage 真实请求成功: 本次返回 ${result.length} 条');
    } catch (e) {
      debugPrint('❌ BMMatchListPage 真实请求异常(isRefresh=$isRefresh, page=$requestPage): $e');
      result = [];
    } finally {
      _isFetching = false; // 无论成功失败强制释放请求锁
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
      // 返回条数 < 每页数量, 标记没有更多页 (对齐hanklive)
      if (result.length < _size) {
        _hasNoMore = true;
        debugPrint('🛑 BMMatchListPage 无更多页, 本页 ${result.length} < size=$_size');
      }
    });
  }

  /// 下拉刷新回调
  Future<void> _onRefresh() {
    return _fetchMatches(isRefresh: true);
  }

  /// 导航标题 (FootBall List / BasketBall List)
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

  /// 自定义导航栏 (返回 + 标题 + 日历按钮 + 选中日期小文字)
  Widget _buildNavBar(BuildContext context) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final selectedMidnight = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = selectedMidnight.difference(todayMidnight).inDays;
    String dateLabel;
    if (diff == 0) {
      dateLabel = '今天';
    } else if (diff == 1) {
      dateLabel = '明天';
    } else if (diff == -1) {
      dateLabel = '昨天';
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
              debugPrint('👈 导航栏返回按钮点击');
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
              debugPrint('📅 日历点击手势触发');
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
                          diff == 0 ? FontWeight.w600 : FontWeight.normal,
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

  /// 弹出日期选择器 (球场深绿主题)，选中后用该天0点时间戳刷新列表
  Future<void> _showDatePicker(BuildContext context) async {
    debugPrint('📅 _showDatePicker 开始执行');
    final now = DateTime.now();
    final initialDate = _currentTimestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(_currentTimestamp * 1000)
        : DateTime(now.year, now.month, now.day);
    debugPrint('📅 initialDate = $initialDate, firstDate=${now.year - 2}, lastDate=${now.year + 1}');
    DateTime? picked;
    try {
      debugPrint('📅 await showDatePicker 进入前');
      picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(now.year - 2),
        lastDate: DateTime(now.year + 1, now.month + 3),
        locale: const Locale('zh', 'CN'),
        builder: (ctx, child) {
          debugPrint('📅 showDatePicker builder 进入');
          if (child == null) {
            debugPrint('⚠️  showDatePicker builder child是null, 返回空占位');
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
      debugPrint('📅 await showDatePicker 返回 picked=$picked');
    } catch (e, s) {
      debugPrint('❌ showDatePicker 抛出异常: $e');
      debugPrint('❌ 调用栈: $s');
      picked = null;
    }
    if (picked == null) {
      debugPrint('📅 用户取消选择日期');
      return;
    }
    final ts = DateTime(picked.year, picked.month, picked.day)
            .millisecondsSinceEpoch ~/
        1000;
    _currentTimestamp = ts;
    _selectedDate = DateTime(picked.year, picked.month, picked.day);
    debugPrint(
        '📅 BMMatchListPage 选中日期: ${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}  timestamp=$ts, 准备刷新');
    await _fetchMatches(isRefresh: true);
    debugPrint('📅 列表刷新完成');
  }

  /// 当前选中的 DateTime (用于日期弹窗高亮 + 导航栏显示"今天/昨天/MM-DD"小标签)
  DateTime _selectedDate = DateTime.now();

  /// 比赛列表区 (含首屏Loading/空态/下拉刷新/上拉加载)
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
                '当日暂无比赛',
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

  /// 底部加载指示器
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
              '—— 到底啦 ——',
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
            Text('加载中...',
                style: TextStyle(fontSize: 12, color: BMColors.textSecondary)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
