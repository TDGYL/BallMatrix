import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../viewmodels/home/bm_home_view_model.dart' show BMSportType;
import '../../widgets/home/bm_match_spotlight_card.dart';

/// BMMatchListPage - 赛事列表页 (首页「查看全部」push 进来, 替换原bm_match_page)
/// 功能: mock数据 + 复用首页第一段焦点卡片 + 下拉刷新 + 上拉加载
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

  /// 每页条数 (int 类型, mock默认第一页2条, 第二页1条用于演示上拉加载)
  final int _size = 10;

  /// 列表滚动控制器 (ScrollController 类型, 上拉加载监听)
  late final ScrollController _scrollController;

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

  /// 获取 mock 数据 (按运动类型 + 分页)
  /// [page] 页码: 第1页2条, 第2页1条, 第3页起空
  List<BMMatchModel> _mockData(int page) {
    if (page >= 3) return const [];
    final isFootball = widget.sportType == BMSportType.football;
    if (page == 1) {
      return isFootball ? _mockFootballPage1() : _mockBasketballPage1();
    } else {
      return isFootball ? _mockFootballPage2() : _mockBasketballPage2();
    }
  }

  /// 足球第1页: 2条 (LIVE + 未开赛)
  List<BMMatchModel> _mockFootballPage1() {
    return [
      BMMatchModel(
        matchId: '1001',
        leagueName: '英超联赛',
        leagueColor: BMColors.orange.toARGB32(),
        status: BMMatchStatus.live,
        statusId: 2,
        statusName: '直播中',
        sportType: BMMatchSportType.football,
        matchTime: '21:00',
        liveMinute: "68'",
        halfTimeScore: 'half 1-0',
        isFeatured: true,
        homeScore: 2,
        awayScore: 1,
        homeTeam: BMTeamModel(
          teamId: '1',
          teamName: '曼彻斯特联',
          teamShort: 'MUN',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=Manchester%20United%20FC%20football%20club%20logo%20red%20devil%20icon%20simple%20flat%20design&image_size=square_hd',
        ),
        awayTeam: BMTeamModel(
          teamId: '2',
          teamName: '利物浦',
          teamShort: 'LIV',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=Liverpool%20FC%20football%20club%20logo%20red%20bird%20liverbird%20icon%20simple%20flat%20design&image_size=square_hd',
        ),
      ),
      BMMatchModel(
        matchId: '1002',
        leagueName: '西甲联赛',
        leagueColor: BMColors.amber.toARGB32(),
        status: BMMatchStatus.upcoming,
        statusId: 1,
        statusName: '未开始',
        sportType: BMMatchSportType.football,
        matchTime: '03:00',
        isFeatured: true,
        homeScore: null,
        awayScore: null,
        homeTeam: BMTeamModel(
          teamId: '3',
          teamName: '皇家马德里',
          teamShort: 'RMA',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=Real%20Madrid%20CF%20football%20club%20logo%20white%20purple%20crown%20icon%20simple%20flat&image_size=square_hd',
        ),
        awayTeam: BMTeamModel(
          teamId: '4',
          teamName: '巴塞罗那',
          teamShort: 'BAR',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=FC%20Barcelona%20football%20club%20logo%20bla%20grana%20blue%20claret%20stripes%20icon%20simple%20flat&image_size=square_hd',
        ),
      ),
    ];
  }

  /// 足球第2页: 1条 (已结束)
  List<BMMatchModel> _mockFootballPage2() {
    return [
      BMMatchModel(
        matchId: '1003',
        leagueName: '欧冠联赛',
        leagueColor: BMColors.purple.toARGB32(),
        status: BMMatchStatus.ended,
        statusId: 8,
        statusName: '已结束',
        sportType: BMMatchSportType.football,
        matchTime: '05:00',
        isFeatured: true,
        homeScore: 3,
        awayScore: 2,
        homeTeam: BMTeamModel(
          teamId: '5',
          teamName: '拜仁慕尼黑',
          teamShort: 'BAY',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=Bayern%20Munich%20FC%20football%20club%20logo%20red%20icon%20simple%20flat%20design&image_size=square_hd',
        ),
        awayTeam: BMTeamModel(
          teamId: '6',
          teamName: '巴黎圣日耳曼',
          teamShort: 'PSG',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=Paris%20Saint%20Germain%20PSG%20football%20club%20logo%20blue%20red%20eiffel%20tower%20icon%20simple%20flat&image_size=square_hd',
        ),
      ),
    ];
  }

  /// 篮球第1页: 2条 (Q3 进行中 + 未开赛)
  List<BMMatchModel> _mockBasketballPage1() {
    return [
      BMMatchModel(
        matchId: '2001',
        leagueName: 'NBA',
        leagueColor: BMColors.orange.toARGB32(),
        status: BMMatchStatus.live,
        statusId: 5,
        statusName: 'Q3 进行中',
        sportType: BMMatchSportType.basketball,
        matchTime: '10:30',
        liveMinute: 'Q3 04:21',
        isFeatured: true,
        homeScore: 82,
        awayScore: 75,
        homeTeam: BMTeamModel(
          teamId: '21',
          teamName: '洛杉矶湖人',
          teamShort: 'LAL',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=Los%20Angeles%20Lakers%20basketball%20team%20logo%20purple%20gold%20icon%20simple%20flat&image_size=square_hd',
        ),
        awayTeam: BMTeamModel(
          teamId: '22',
          teamName: '金州勇士',
          teamShort: 'GSW',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=Golden%20State%20Warriors%20basketball%20team%20logo%20blue%20golden%20gate%20bridge%20icon%20simple%20flat&image_size=square_hd',
        ),
      ),
      BMMatchModel(
        matchId: '2002',
        leagueName: 'CBA',
        leagueColor: BMColors.cyan.toARGB32(),
        status: BMMatchStatus.upcoming,
        statusId: 1,
        statusName: '未开始',
        sportType: BMMatchSportType.basketball,
        matchTime: '19:35',
        isFeatured: true,
        homeScore: null,
        awayScore: null,
        homeTeam: BMTeamModel(
          teamId: '23',
          teamName: '广东宏远',
          teamShort: 'GD',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=Guangdong%20Tigers%20CBA%20basketball%20team%20logo%20tiger%20red%20icon%20simple%20flat&image_size=square_hd',
        ),
        awayTeam: BMTeamModel(
          teamId: '24',
          teamName: '辽宁本钢',
          teamShort: 'LN',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=Liaoning%20Flying%20Leopards%20CBA%20basketball%20team%20logo%20leopard%20blue%20icon%20simple%20flat&image_size=square_hd',
        ),
      ),
    ];
  }

  /// 篮球第2页: 1条 (已结束)
  List<BMMatchModel> _mockBasketballPage2() {
    return [
      BMMatchModel(
        matchId: '2003',
        leagueName: 'EuroLeague',
        leagueColor: BMColors.purple.toARGB32(),
        status: BMMatchStatus.ended,
        statusId: 11,
        statusName: '已结束',
        sportType: BMMatchSportType.basketball,
        matchTime: '02:45',
        isFeatured: true,
        homeScore: 94,
        awayScore: 88,
        homeTeam: BMTeamModel(
          teamId: '25',
          teamName: '皇家马德里',
          teamShort: 'RMA',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=Real%20Madrid%20basketball%20team%20logo%20white%20purple%20icon%20simple%20flat&image_size=square_hd',
        ),
        awayTeam: BMTeamModel(
          teamId: '26',
          teamName: '巴塞罗那',
          teamShort: 'BAR',
          logoUrl:
              'https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=FC%20Barcelona%20basketball%20team%20logo%20bla%20grana%20icon%20simple%20flat&image_size=square_hd',
        ),
      ),
    ];
  }

  /// 请求比赛列表 (mock 模式, 模拟异步延迟)
  /// [isRefresh] - true=重置page=1 / false=加载更多 page+1
  Future<void> _fetchMatches({required bool isRefresh}) async {
    if (_isFetching) return;
    if (!isRefresh && _hasNoMore) return;
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

    // 模拟异步请求延迟 600ms
    List<BMMatchModel> result = [];
    await Future.delayed(const Duration(milliseconds: 600));
    result = _mockData(requestPage);

    if (!mounted) { _isFetching = false; return; }
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
      if (result.length < _size) {
        _hasNoMore = true;
      }
      _isFetching = false;
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

  /// 自定义导航栏 (返回 + 标题)
  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
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
          const SizedBox(width: 40),
        ],
      ),
    );
  }

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
            child: BMMatchSpotlightCard(match: match),
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
