import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_process_model.dart';
import '../../models/bm_odds_model.dart';
import '../../models/bm_h2h_model.dart';
import '../../models/bm_lineup_model.dart';
import '../../services/bm_match_detail_api_service.dart';
import '../../network/bm_network_manager.dart';
import '../../utils/bm_auth_manager.dart';
import '../login/bm_login_page.dart';
import 'bm_odds_history_page.dart';

/// BMFootballDetailTab - 详情 Tab 枚举 (事件 / 阵容 / 指数 / 交锋)
enum BMFootballDetailTab {
  /// 比赛事件 / Live Timeline + 顶部技术统计
  live,
  /// 首发阵容 / Lineup
  lineup,
  /// 指数赔率 / Odds (AH/1X2/O/U/Corners)
  odds,
  /// 历史交锋 / H2H
  h2h,
}

/// BMFootballDetailPage - 足球比赛详情页
/// 功能/接口 1:1 参考 hanklive MatchDetailPage (接口路径完全相同, 替身实现)
/// 差异化 UI (vs 紫色hanklive):
///   - 主题: 深绿 pitch900/pitch850/pitch700 (替换 violet50/violet700)
///   - AppBar: 方形圆角返回 + 联赛名胶囊(亮绿12%+1.2px描边, 和话题页发布按钮同风格) vs 紫色圆形+violet100
///   - Scoreboard: 渐变深绿背景 + 亮绿 LIVE 标签 vs 白色卡片
///   - TabBar: 滚动式胶囊 Tab(BouncingScrollPhysics) + 选中亮绿实心胶囊, 未选中 pitch800 文字灰
///   - 事件列表: 主侧亮绿色块/客侧天蓝色块(vs 紫色事件点)
///   - 指数 Odds Tab: 4个胶囊类型段 (vs hanklive 直接列表)
///   - H2H Tab: 单条卡片 pitch850, 点击 push 比赛列表页
/// 架构: 单类单文件, 继承 BMBasePage
class BMFootballDetailPage extends BMBasePage {
  /// 比赛模型 (BMMatchModel 类型, 列表页/首页传过来)
  final BMMatchModel match;

  const BMFootballDetailPage({
    super.key,
    required this.match,
  });

  @override
  State<BMFootballDetailPage> createState() => _BMFootballDetailPageState();
}

class _BMFootballDetailPageState extends BMBasePageState<BMFootballDetailPage> {
  /// 当前选中 Tab (BMFootballDetailTab 类型)
  BMFootballDetailTab _currentTab = BMFootballDetailTab.live;

  /// API Service (比赛详情接口，路径与hanklive 100%相同)
  final BMMatchDetailApiService _apiService = BMMatchDetailApiService();

  /// 比赛进程 (incidents事件 + stats统计, 复用)
  BMProcessData? _processData;

  /// 是否加载中 进程/事件
  bool _loadingProcess = true;

  /// 指数数据 (4种盘口)
  BMOddsData? _oddsData;

  /// 是否加载中 Odds
  bool _loadingOdds = false;

  /// 主队近期交锋列表
  List<BMH2HMatch> _h2hHomeList = [];

  /// 客队近期交锋列表
  List<BMH2HMatch> _h2hAwayList = [];

  /// 是否加载中 H2H
  bool _loadingH2H = false;

  /// 是否已加载过 H2H (懒加载)
  bool _fetchedH2H = false;

  // ======== H2H 主队段过滤器 ========
  /// 主队近期比赛 - 显示数量限制 (10 / 6)
  int _h2hHomeLimit = 10;
  /// 主队近期比赛 - 是否只保留 当前主队是 home 且 当前客队是 away (同主客)
  bool _h2hHomeSameSide = false;
  /// 主队近期比赛 - 是否只保留联赛 (过滤杯赛 name 含 cup/Cup)
  bool _h2hHomeLeagueOnly = false;

  // ======== H2H 客队段过滤器 ========
  /// 客队近期比赛 - 显示数量限制 (10 / 6)
  int _h2hAwayLimit = 10;
  /// 客队近期比赛 - 是否只保留同主客侧
  bool _h2hAwaySameSide = false;
  /// 客队近期比赛 - 是否只保留联赛
  bool _h2hAwayLeagueOnly = false;

  /// 阵容数据 (lineup)
  BMLineupData? _lineupData;

  /// 是否加载中 阵容
  bool _loadingLineup = false;

  /// 是否已加载过 阵容 (懒加载)
  bool _fetchedLineup = false;

  /// 是否已订阅 (bool, GET match.detail -> subscribed 字段)
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    final matchId = int.tryParse(widget.match.matchId) ?? 0;
    _fetchMatchDetail(matchId);
    _fetchProcess(matchId);
  }

  /// 获取订阅状态
  Future<void> _fetchMatchDetail(int matchId) async {
    if (matchId == 0) return;
    final Map<String, dynamic>? data = await _apiService.fetchMatchDetail(matchId: matchId);
    if (!mounted || data == null) return;
    setState(() {
      _isSubscribed = data['subscribed'] == true;
    });
  }

  /// 获取比赛进程(事件+统计)
  Future<void> _fetchProcess(int matchId) async {
    final d = matchId == 0 ? null : await _apiService.fetchMatchProcess(matchId: matchId);
    if (!mounted) return;
    setState(() {
      _processData = d;
      _loadingProcess = false;
    });
  }

  /// 切换订阅 (未登录先去登录)
  ///   subscribe: POST /api/livespeed/football/match/subscribe     data:{match_id}
  ///   unsub:     POST /api/livespeed/football/match/unsubscribe   data:{match_id}
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
    final String url = willSub
        ? '/api/livespeed/football/match/subscribe'
        : '/api/livespeed/football/match/unsubscribe';
    try {
      final resp = await BMNetworkManager().postRequest(url, data: {'match_id': matchId});
      if (!mounted) return;
      if (resp.isSuccess) {
        setState(() => _isSubscribed = willSub);
        _snack(willSub ? '已订阅' : '已取消订阅');
      } else {
        _snack(resp.message ?? '操作失败, 请重试');
      }
    } catch (_) {
      if (mounted) _snack('网络错误, 请重试');
    }
  }

  /// 懒加载指数
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

  /// 懒加载 H2H (拆分主队/客队两段)
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
      // 兼容兜底：如果接口没有 home/away 字段，但有 vs，把 vs 平均分/合并到两个列表里兜底显示
      if (_h2hHomeList.isEmpty && _h2hAwayList.isEmpty) {
        final vs = splited['vs'] ?? [];
        _h2hHomeList = vs;
        _h2hAwayList = vs;
      }
      _loadingH2H = false;
      _fetchedH2H = true;
    });
  }

  /// 懒加载 阵容 Lineup
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

  /// 指数历史跳转 (完全参考 hanklive odds_history_page - 新入参: BMCompanyOdds 公司级对象)
  void _gotoOddsHistory(BMCompanyOdds company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BMOddsHistoryPage(
          matchId: int.tryParse(widget.match.matchId) ?? 0,
          companyId: company.companyId,
          companyName: company.companyName ?? '博彩公司',
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
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: BMColors.bright.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BMColors.bright.withValues(alpha: 0.5), width: 1.2),
                ),
                child: Text(
                  widget.match.leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: BMColors.bright,
                    fontWeight: FontWeight.w700,
                  ),
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
                  _isSubscribed ? Icons.notifications : Icons.notifications_outlined,
                  size: 22,
                  color: _isSubscribed ? BMColors.bright : BMColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Scoreboard 比分板 ====================

  Widget _buildScoreboard() {
    final homeLogo = widget.match.homeTeamLogo ?? widget.match.homeTeam?.logoUrl;
    final awayLogo = widget.match.awayTeamLogo ?? widget.match.awayTeam?.logoUrl;
    final homeName = widget.match.homeTeamName.isNotEmpty
        ? widget.match.homeTeamName
        : widget.match.homeTeam?.teamName ?? '主队';
    final awayName = widget.match.awayTeamName.isNotEmpty
        ? widget.match.awayTeamName
        : widget.match.awayTeam?.teamName ?? '客队';
    final statusLabel = widget.match.displayStatusLabel;
    final bool live = widget.match.status == BMMatchStatus.live;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: live
                  ? BMColors.bright.withValues(alpha: 0.16)
                  : BMColors.pitch800,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: live ? BMColors.bright.withValues(alpha: 0.55) : BMColors.pitch700,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (live) ...[
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: BMColors.bright, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                ],
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: live ? BMColors.bright : BMColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主队: 左对齐 + Flex 5
              Expanded(
                flex: 5,
                child: _teamHomeColumn(homeLogo, homeName),
              ),
              // 中间比分: Flex 4 居中
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.match.homeScore?.toString() ?? '-',
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
                          widget.match.awayScore?.toString() ?? '-',
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
                    const SizedBox(height: 8),
                    if ((widget.match.round.isNotEmpty || widget.match.kickoffText.isNotEmpty))
                      Text(
                        widget.match.displayMatchTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: BMColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              // 客队: 右对齐 + Flex 5
              Expanded(
                flex: 5,
                child: _teamAwayColumn(awayLogo, awayName),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// 主队球队列: Logo + 名字, 左侧对齐
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

  /// 客队球队列: Logo + 名字, **右侧严格对齐** (用户需求点)
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

  // ==================== Tab Bar (胶囊式, 差异化) ====================

  Widget _buildTabBar() {
    return Container(
      height: 42,
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildTabChip(BMFootballDetailTab.live, '事件'),
          const SizedBox(width: 8),
          _buildTabChip(BMFootballDetailTab.lineup, '阵容'),
          const SizedBox(width: 8),
          _buildTabChip(BMFootballDetailTab.odds, '指数'),
          const SizedBox(width: 8),
          _buildTabChip(BMFootballDetailTab.h2h, '交锋'),
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
          color: selected ? BMColors.bright : BMColors.pitch850,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? BMColors.bright : BMColors.pitch700.withValues(alpha: 0.5),
            width: selected ? 1.2 : 0.6,
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
            color: selected ? BMColors.pitch900 : BMColors.textSecondary,
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
    // 顶部统计 Section + 分隔线 Header + 底部 Timeline 事件
    final eventHeight = (knownList.length * 120.0).clamp(0.0, 12000.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ============ 顶部: 技术统计数据 (搬迁自原 统计 Tab) ============
        if (stats.isNotEmpty) ...[
          _buildStatsTitleHeader(),
          _buildStatsSection(stats),
          const SizedBox(height: 16),
        ],
        // ============ 中间: 事件列表分隔线 Header ============
        if (knownList.isNotEmpty) ...[
          _buildEventListHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: SizedBox(
              height: eventHeight,
              child: _buildTimelineV2(knownList),
            ),
          ),
        ],
        // ============ 兜底: 无统计 & 无事件 ============
        if (stats.isEmpty && allList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text('暂无比赛事件', style: TextStyle(color: BMColors.textTertiary, fontSize: 12))),
          ),
        if (stats.isNotEmpty && knownList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('暂无比赛事件', style: TextStyle(color: BMColors.textTertiary, fontSize: 12))),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 技术统计标题 Header (带图标 + 亮绿竖条)
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
            '技术统计',
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

  /// 事件列表标题 Header (带图标 + 蓝绿渐变竖条)
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
            '比赛事件',
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

  /// 技术统计主体 (搬迁自原 _buildStatsTab)
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
                        flex: homePct > 0 ? homePct : 1,
                        child: Container(height: 6, decoration: BoxDecoration(color: BMColors.bright, borderRadius: BorderRadius.circular(999))),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: awayPct > 0 ? awayPct : 1,
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
      return ((first ? av : bv) * 100 / s).round();
    }
    try {
      double? ad = double.tryParse(a);
      double? bd = double.tryParse(b);
      if (ad != null && bd != null) {
        final s = ad + bd;
        if (s <= 0) return 50;
        return (((first ? ad : bd) / s) * 100).round();
      }
    } catch (_) {}
    return 50;
  }

  // ==================== 事件通用辅助 (V2 差异化也复用) ====================

  /// BMIncidentType -> 数字编号 (完全对齐 hanklive type 字段)
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

  /// 按事件类型/侧返回颜色 (对齐 hanklive: 主队=rose 客队=blue 进球统一亮绿 黄牌黄 红牌红 换人=neutral)
  Color _incidentColor(BMIncident inc) {
    final n = _incidentTypeNumber(inc.type);
    final isHome = inc.side == BMIncidentSide.home;
    // 进球类: 统一亮绿
    if (n == 1 || n == 8 || n == 17 || n == 29) return BMColors.bright;
    // 黄牌
    if (n == 3) return const Color(0xFFF59E0B);
    // 红牌 / 两黄变红
    if (n == 4 || n == 15) return const Color(0xFFEF4444);
    // 换人
    if (n == 9) return isHome ? BMColors.bright : const Color(0xFF3B82F6);
    // 其他按主客队
    return isHome ? BMColors.bright : const Color(0xFF3B82F6);
  }

  /// 事件类型中文名 (对齐 hanklive custTypeName)
  String _custTypeName(BMIncident inc) {
    switch (inc.type) {
      case BMIncidentType.goal:
        return '进球';
      case BMIncidentType.penalty:
        return '点球进球';
      case BMIncidentType.ownGoal:
        return '乌龙球';
      case BMIncidentType.yellowCard:
        return '黄牌';
      case BMIncidentType.redCard:
        return '红牌';
      case BMIncidentType.secondYellow:
        return '两黄变红';
      case BMIncidentType.substitution:
        return '换人';
      case BMIncidentType.injuryTime:
        return '伤停补时';
      case BMIncidentType.whistle:
        return '哨响';
      default:
        return inc.detail ?? '事件';
    }
  }

  String _custPlayerName(BMIncident inc) {
    if (inc.playerName != null && inc.playerName!.trim().isNotEmpty) {
      return inc.playerName!;
    }
    return '';
  }

  /// 时间格式化: 90' + 3'
  String _incidentTime(BMIncident inc) {
    if (inc.minute == null) return "0'";
    if (inc.addedTime != null && inc.addedTime! > 0) {
      return "${inc.minute}' +${inc.addedTime}'";
    }
    return "${inc.minute}'";
  }

  // ==================== 事件图标 & 类型名 (保留原方法，作为 fallback，上面 dotIcon 也用)
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

  // ================ V2 差异化事件列表 UI (区别于 hanklive 原版 + 懒加载修复卡死) ================

  /// V2 时间轴: 渐变竖线 + 懒加载 ListView.builder (修复长列表一次性构建卡死)
  Widget _buildTimelineV2(List<BMIncident> incidents) {
    final count = incidents.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 渐变时间轴竖线 (亮绿 → pitch700)
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

  /// V2 单条事件行: 左RRect圆角方点 + 中间时间胶囊 + 右卡片 (去掉Matrix4避免重绘过高)
  Widget _buildEventItemV2(BMIncident inc) {
    final color = _incidentColor(inc);
    final isHome = inc.side == BMIncidentSide.home;
    final sideStripeColor = isHome ? BMColors.bright : const Color(0xFF3B82F6);
    final n = _incidentTypeNumber(inc.type);
    final isGoal = n == 1 || n == 8 || n == 17 || n == 29;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =========== 左侧: 18x18 RRect 圆角方点 (去掉 Matrix4，减少 Transform 重绘开销) ===========
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
        // =========== 中间: 时间胶囊 (方形圆角) ===========
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
              color: isGoal ? color : BMColors.textSecondary,
              fontFamily: 'monospace',
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // =========== 右侧: 卡片 (主/客 彩色竖条) ===========
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
                width: isGoal ? 1.1 : 0.85,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 主/客 彩色竖条
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
                // 卡片内容区
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row1: 事件类型 Tag + 右侧 大号比分/主客标识
                        Row(
                          children: [
                            // 事件 Tag
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
                            // 比分 (大号加粗) 或 主客标签
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
                                  isHome ? '主队' : '客队',
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
                        // Row2: 球员/换人描述
                        _buildEventDescriptionV2(inc),
                        // Row3 (仅得分事件): 渐变底部比分条
                        if (isGoal && inc.homeScore != null && inc.awayScore != null) ...[
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
                                    '实时比分更新',
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

  /// V2 描述文本 (换人用箭头分隔上下两行, 其他加粗球员名)
  Widget _buildEventDescriptionV2(BMIncident inc) {
    final n = _incidentTypeNumber(inc.type);
    final isHome = inc.side == BMIncidentSide.home;
    final sideColor = isHome ? BMColors.bright : const Color(0xFF3B82F6);
    // 换人: 上下 下上 图标 + 两行 out/in 球员
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
                  '下场: ',
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
                  '上场: ',
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
              '换人调整',
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
    // 其他事件: 球员名 (大字) + detail 小字 (如果有)
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
        if (detail != null && detail.isNotEmpty && detail != _custTypeName(inc)) ...[
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

  // =========== Odds Tab (数据获取参照 hanklive match_detail_odds_tab.dart，UI 深绿差异化) ===========
  BMOddsType _oddsSel = BMOddsType.asianHandicap;

  Widget _buildOddsTab() {
    _ensureOdds();
    final companies = _oddsData?.listBy(_oddsSel) ?? [];
    final is1x2 = _oddsSel == BMOddsType.matchResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ① 4 段 selector (对齐 hanklive Row + Expanded 4 等分,不再 Wrap)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
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
            child: Row(
              children: BMOddsType.values.map((t) {
                final selected = _oddsSel == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _oddsSel = t),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? BMColors.bright.withValues(alpha: 0.16) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.shortLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected ? BMColors.bright : BMColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // ② Loading / 空态 / 赔率数据卡片
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
                        child: Text('暂无赔率数据', style: TextStyle(fontSize: 13, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
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
                          // 卡片标题行: 左 盘口类型名 / 右 LIVE 标识
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: BMColors.bright,
                                      boxShadow: [BoxShadow(color: BMColors.bright, blurRadius: 6)],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    '即时盘口',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: BMColors.bright),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // 表头(公司列 70px宽 + 阶段标签列 40px宽 + 3 或 4 栏 Expanded 表头)
                          _oddsTableHeader(is1x2: is1x2),
                          const SizedBox(height: 4),
                          // 每家公司 3 阶段行
                          ...companies.map((c) => _oddsCompanyRow(c, is1x2)),
                        ],
                      ),
                    ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  /// 表头行(Bookmaker / 阶段标签占位 + 3~4 栏表头)
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
          // Bookmaker 列宽 70
          const SizedBox(
            width: 70,
            child: Text(
              '博彩公司',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: BMColors.textTertiary),
            ),
          ),
          // 阶段标签占位 40 (对应下面 rows 的阶段 label 列宽)
          const SizedBox(width: 40),
          // 3~4 栏 Expanded 表头(1X2 4栏;AH/OU/Corners 3栏)
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

  /// 单家博彩公司的行(左侧公司名列 + 3 阶段 odds rows + 右箭头)
  Widget _oddsCompanyRow(BMCompanyOdds company, bool is1x2) {
    final hasIni = company.ini != null;
    final hasPre = company.pre != null;
    final hasSpot = company.spot != null;
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
            // 公司名 70px 宽 2 行
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
            // 阶段赔率列
            Expanded(
              child: Column(
                children: [
                  if (hasIni) ...[
                    _oddsStageRow(company.ini!, stageLabel: '初盘', color: BMColors.textTertiary, is1x2: is1x2),
                    const SizedBox(height: 8),
                  ],
                  if (hasPre) ...[
                    _oddsStageRow(company.pre!, stageLabel: '早盘', color: const Color(0xFF3B82F6), is1x2: is1x2),
                    const SizedBox(height: 8),
                  ],
                  if (hasSpot)
                    _oddsStageRow(company.spot!, stageLabel: '即时', color: BMColors.bright, is1x2: is1x2),
                ],
              ),
            ),
            // 右箭头
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 16),
              child: Icon(Icons.chevron_right, size: 16, color: BMColors.pitch700.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }

  /// 单阶段的赔率行(标签 40px 宽 + Expanded 3~4 列赔率值)
  Widget _oddsStageRow(BMCompanyOddsDetail d, {required String stageLabel, required Color color, required bool is1x2}) {
    return Row(
      children: [
        // 阶段标签 40 宽
        SizedBox(
          width: 40,
          child: Text(
            stageLabel,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800),
          ),
        ),
        // 第 1 列: home (主赢 / 主胜 / 大球)
        Expanded(
          child: _oddsStageCell(d.home, color),
        ),
        if (is1x2) ...[
          // 第 2 列: 平局 (仅 1X2 有,背景高亮色 18%)
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
        ] else ...[
          // 第 2 列: 盘口 handicap (AH/OU/Corners:显示中间色 + 16% 背景胶囊)
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
        // 最后一列: away (客赢 / 客胜 / 小球)
        Expanded(
          child: _oddsStageCell(d.away, color, isAway: true),
        ),
      ],
    );
  }

  /// 赔率单元格 (值 + 颜色 + 对齐)
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

  /// 跳转到赔率历史详情页(入参改为公司级对象,保持跳转链路) - 旧签名清理,上面主方法使用
  // 空实现: 主 _gotoOddsHistory 在 buildBody 前面定义,保证全局引用

  // =========== Lineup Tab (对齐 hanklive match_detail_lineup_tab.dart) ===========

  /// 阵容 Tab 跳球员详情 (对齐 hanklive _navigateToPlayerDetail)
  ///   - BallMatrix 当前暂无球员详情页,先 SnackBar 提示待开发,不中断用户
  ///   - 未来有 BMPlayerDetailPage 时直接替换 Navigator.push 即可
  void _navigateToLineupPlayerDetail(BMMatchLineupPlayer player) {
    final idStr = player.playerId;
    final pid = (idStr != null && idStr.isNotEmpty) ? int.tryParse(idStr) : null;
    // 对齐 hanklive: playerId == 0 直接 return
    if (pid == null || pid == 0) return;
    final name = player.playerName?.trim();
    if (name == null || name.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('球员详情开发中：$name'),
        backgroundColor: BMColors.pitch850,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 1),
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
            const Text('暂无阵容数据', style: TextStyle(fontSize: 14, color: BMColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  /// 阵型头部: HomeLogo+formation VS AwayLogo+formation (对齐 hanklive _buildLineupHeader)
  ///   新增: 下一行主/客教练名 + 图标帽 (对齐真实后端 home_coach / away_coach 字段)
  Widget _buildLineupHeader(BMLineupData data) {
    // 主客教练名 (优先 BMLineupData.homeCoach/awayCoach, fallback homeSide.coach)
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
          // 第 1 行: Logo + 阵型 VS Logo + 阵型 (对齐 Hank 原版)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildLineupTeamLogo(widget.match.homeTeamLogo),
                  const SizedBox(width: 6),
                  Text(
                    data.homeFormation ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BMColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Text(
                'VS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BMColors.textTertiary,
                ),
              ),
              Row(
                children: [
                  Text(
                    data.awayFormation ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BMColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildLineupTeamLogo(widget.match.awayTeamLogo),
                ],
              ),
            ],
          ),
          // 第 2 行: 教练名 (有名字才显示, 保持紧凑, 不突兀)
          if ((hCoachName != null && hCoachName.isNotEmpty) ||
              (aCoachName != null && aCoachName.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 主队教练: Icons.coffee (教练帽图标) + 名字, 左对齐
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
                // 中间占位, 不让主客教练重叠
                const SizedBox(width: 24),
                // 客队教练: Icons.coffee + 名字, 右对齐
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

  Widget _buildLineupTeamLogo(String? logoUrl) {
    if (logoUrl == null || logoUrl.isEmpty) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: BMColors.pitch700,
          shape: BoxShape.circle,
        ),
      );
    }
    return ClipOval(
      child: Image.network(
        logoUrl,
        width: 18,
        height: 18,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          width: 18,
          height: 18,
          color: BMColors.pitch700,
        ),
      ),
    );
  }

  /// 2.5D 战术球场 (LayoutBuilder + 坐标Position 对齐 hanklive _buildPitch)
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
              // Away 客队 (上半, 坐标翻转: (100-x), (100-y)/2 + h/2)
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
              // Home 主队 (下半, 坐标正向: x/100*w, y/100*h/2)
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

  /// 球员节点 (头像+号码+事件徽标+名字 Chip, 对齐 hanklive _buildPlayerNode)
  /// 点击跳球员详情页 (对齐 hanklive _navigateToPlayerDetail)
  Widget _buildLineupPlayerNode(BMMatchLineupPlayer player, {required bool isHome}) {
    final teamColor = isHome ? const Color(0xFFE11D48) : const Color(0xFF3B82F6);
    final shirtNum = player.shirtNumber ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _navigateToLineupPlayerDetail(player),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
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
          const SizedBox(height: 2),
          // 球员名 Chip: 对齐 hanklive 白 85% 半透明 + 黑字 (深绿草皮背景对比度高)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              player.playerName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 事件徽标 (进球⚽ 黄牌🟨 红牌🟥)
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

  /// 替补区 (Home + Away, 对齐 hanklive _buildSubSection)
  Widget _buildLineupSubSection(BMLineupData data) {
    if (data.homeSub.isEmpty && data.awaySub.isEmpty) {
      return const SizedBox.shrink();
    }
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
          Row(
            children: const [
              Icon(Icons.chair, size: 14, color: BMColors.bright),
              SizedBox(width: 8),
              Text(
                '替补',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BMColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (data.homeSub.isNotEmpty) ...[
            _buildLineupSubTeamTitle(widget.match.homeTeamName, isHome: true),
            const SizedBox(height: 4),
            ...data.homeSub.map((p) => _buildLineupSubPlayerChip(p)),
            const SizedBox(height: 12),
          ],
          if (data.awaySub.isNotEmpty) ...[
            _buildLineupSubTeamTitle(widget.match.awayTeamName, isHome: false),
            const SizedBox(height: 4),
            ...data.awaySub.map((p) => _buildLineupSubPlayerChip(p)),
          ],
        ],
      ),
    );
  }

  Widget _buildLineupSubTeamTitle(String name, {required bool isHome}) {
    final color = isHome ? const Color(0xFFE11D48) : const Color(0xFF3B82F6);
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BMColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 替补球员行: 号码 + Logo + Name (对齐 hanklive _buildSubPlayerChip)
  /// 点击跳球员详情页 (对齐 hanklive onTap)
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

  /// 伤停区 (Home + Away, 对齐 hanklive _buildInjurySection)
  Widget _buildLineupInjurySection(BMLineupData data) {
    if (data.homeInjury.isEmpty && data.awayInjury.isEmpty) {
      return const SizedBox.shrink();
    }
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
          Row(
            children: const [
              Icon(Icons.local_hospital, size: 14, color: Color(0xFFF87171)),
              SizedBox(width: 8),
              Text(
                '伤停',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BMColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (data.homeInjury.isNotEmpty) ...[
            _buildLineupInjuryTeamTitle(widget.match.homeTeamName),
            const SizedBox(height: 4),
            ...data.homeInjury.map((p) => _buildLineupInjuryPlayerChip(p)),
            const SizedBox(height: 12),
          ],
          if (data.awayInjury.isNotEmpty) ...[
            _buildLineupInjuryTeamTitle(widget.match.awayTeamName),
            const SizedBox(height: 4),
            ...data.awayInjury.map((p) => _buildLineupInjuryPlayerChip(p)),
          ],
        ],
      ),
    );
  }

  Widget _buildLineupInjuryTeamTitle(String name) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF87171), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BMColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLineupInjuryPlayerChip(BMMatchLineupPlayer player) {
    return Container(
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
                // 伤停原因 (HankLineupInjuryPlayer.reason 对齐, 优先显示; 缺 reason 才显示位置 fallback)
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
    );
  }

  // =========== H2H Tab (100% 对齐 hanklive 逻辑: WDL汇总 + 过滤器 + 胜负色条卡片) ===========
  Widget _buildH2HTab() {
    _ensureH2H();
    final homeName = widget.match.homeTeamName.isNotEmpty
        ? widget.match.homeTeamName
        : widget.match.homeTeam?.teamName ?? '主队';
    final awayName = widget.match.awayTeamName.isNotEmpty
        ? widget.match.awayTeamName
        : widget.match.awayTeam?.teamName ?? '客队';
    // 当前主队的 teamId (从 BMMatchTeam.teamId 取 String -> int, 失败则 -1)
    final curHomeTeamId = int.tryParse(widget.match.homeTeam?.teamId ?? '') ?? -1;
    final curAwayTeamId = int.tryParse(widget.match.awayTeam?.teamId ?? '') ?? -2;

    if (_loadingH2H && _h2hHomeList.isEmpty && _h2hAwayList.isEmpty) {
      return _buildLoading(BMColors.bright);
    }
    final hasAny = _h2hHomeList.isNotEmpty || _h2hAwayList.isNotEmpty;
    if (!hasAny) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: Text('暂无交锋历史', style: TextStyle(color: BMColors.textTertiary, fontSize: 12))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        // ============ 主队段 ============
        if (_h2hHomeList.isNotEmpty) ...[
          _buildH2HSectionHeader(
            title: homeName.isEmpty ? '主队近期比赛' : '$homeName · 近期比赛',
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
        // ============ 客队段 ============
        if (_h2hAwayList.isNotEmpty) ...[
          _buildH2HSectionHeader(
            title: awayName.isEmpty ? '客队近期比赛' : '$awayName · 近期比赛',
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

  /// 交锋分段 Header (竖条 + 图标 + 标题)
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

  /// 单段完整交锋区 (WDL汇总 + 过滤器 + 卡片列表) — 完全对齐 hanklive 逻辑
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
    // === 过滤器逻辑 (1:1 对齐 hanklive _filteredMatches) ===
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
          // ① WDL 汇总卡 (对齐 hanklive _buildWDLSummary)
          _buildWDLSummaryCard(display, currentTeamId, sideColor),
          const SizedBox(height: 12),
          // ② 过滤器胶囊 (对齐 hanklive _buildFilterChips)
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
          // ③ 卡片列表 (对齐 hanklive ...displayMatches.map)
          if (display.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('筛选后无数据', style: TextStyle(fontSize: 12, color: BMColors.textTertiary)),
              ),
            )
          else
            ...display.map((m) => _buildH2HMatchCard(m, currentTeamId, sideColor, isHomeSection)),
        ],
      ),
    );
  }

  /// WDL 汇总卡 (1:1 对齐 hanklive W/D/L 三栏 + 比例条 + 总进球/场均)
  Widget _buildWDLSummaryCard(List<BMH2HMatch> display, int currentTeamId, Color sideColor) {
    int curWin = 0;
    int draw = 0;
    int curLose = 0;
    int curGoals = 0;
    int oppGoals = 0;

    for (final m in display) {
      final hs = m.homeNormalScore ?? m.homeScore;
      final as = m.awayNormalScore ?? m.awayScore;
      if (hs == null || as == null) continue;
      final isCurHome = m.homeTeamId == currentTeamId;
      if (isCurHome) {
        curGoals += hs;
        oppGoals += as;
        if (hs > as) {
          curWin++;
        } else if (hs < as) {
          curLose++;
        } else {
          draw++;
        }
      } else {
        curGoals += as;
        oppGoals += hs;
        if (as > hs) {
          curWin++;
        } else if (as < hs) {
          curLose++;
        } else {
          draw++;
        }
      }
    }

    final total = display.length;
    final winPct = total > 0 ? curWin / total : 0.0;
    final drawPct = total > 0 ? draw / total : 0.0;
    final losePct = total > 0 ? curLose / total : 0.0;
    final avgGoals = total > 0 ? ((curGoals + oppGoals) / total).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sideColor.withValues(alpha: 0.3), width: 0.9),
      ),
      child: Column(
        children: [
          // Row1: W D L 三个数字
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$curWin W',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: sideColor,
                ),
              ),
              Text(
                '$draw D',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: BMColors.textTertiary,
                ),
              ),
              Text(
                '$curLose L',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row2: 三栏比例条 (Win 主队色 / D 灰 / L 红)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (winPct > 0)
                    Expanded(
                      flex: (winPct * 100).round() > 0 ? (winPct * 100).round() : 1,
                      child: Container(color: sideColor),
                    ),
                  if (drawPct > 0)
                    Expanded(
                      flex: (drawPct * 100).round() > 0 ? (drawPct * 100).round() : 1,
                      child: Container(color: BMColors.pitch700),
                    ),
                  if (losePct > 0)
                    Expanded(
                      flex: (losePct * 100).round() > 0 ? (losePct * 100).round() : 1,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Row3: 进球汇总
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.65))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '进球: $curGoals',
                  style: TextStyle(fontSize: 10, color: sideColor, fontWeight: FontWeight.w700),
                ),
                Text(
                  '场均进球: $avgGoals',
                  style: const TextStyle(fontSize: 10, color: BMColors.textTertiary, fontWeight: FontWeight.w600),
                ),
                Text(
                  '失球: $oppGoals',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 过滤器胶囊行 (对齐 hanklive Last 10/Last 6/HomeAway/LeagueOnly)
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
          _h2hChip('近 10 场', limit == 10, sideColor, () => onLimitChanged(10)),
          _h2hChip('近 6 场', limit == 6, sideColor, () => onLimitChanged(6)),
          _h2hChip('对阵双方', sameSide, sideColor, () => onSameSideChanged(!sameSide)),
          _h2hChip('仅联赛', leagueOnly, sideColor, () => onLeagueOnlyChanged(!leagueOnly)),
        ],
      ),
    );
  }

  /// 单颗过滤胶囊
  Widget _h2hChip(String label, bool selected, Color sideColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? sideColor.withValues(alpha: 0.18) : BMColors.pitch800,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? sideColor.withValues(alpha: 0.65) : BMColors.pitch700.withValues(alpha: 0.5),
            width: selected ? 1.1 : 0.8,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? sideColor : BMColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// 交锋比赛卡片 (1:1 对齐 hanklive: 左侧 4px 胜负色条 + TopRow + ScoreRow)
  Widget _buildH2HMatchCard(BMH2HMatch m, int currentTeamId, Color sideColor, bool isHomeSection) {
    final homeIsCur = m.homeTeamId == currentTeamId;
    final awayIsCur = m.awayTeamId == currentTeamId;
    final hs = m.homeNormalScore ?? m.homeScore;
    final as = m.awayNormalScore ?? m.awayScore;

    // 左侧 4px 胜负色条 (胜 side色 / 负 红 / 平 琥珀黄)
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
            // 左侧胜负色条
            Container(width: 4, height: 96, color: barColor),
            // 内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  children: [
                    // Row1: 联赛Logo + 联赛名 + 日期 / 半场比分
                    _h2hCardTopRow(m),
                    const SizedBox(height: 10),
                    // Row2: 主队 | 比分徽章 | 客队
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

  /// H2H 卡片 TopRow (联赛Logo+名+日期 / 半场比分)
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
            '半场 ${m.homeHalfScore} - ${m.awayHalfScore}',
            style: const TextStyle(fontSize: 10.5, color: BMColors.textTertiary, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }

  /// H2H 卡片比分行 (主队 Logo+名 左对齐 | 中间比分徽章 | 客队名+Logo 右对齐)
  Widget _h2hCardScoreRow(BMH2HMatch m, bool homeIsCur, bool awayIsCur, Color sideColor, int? hs, int? as, bool isHomeSection) {
    final homeWin = hs != null && as != null && hs > as;
    final awayWin = hs != null && as != null && as > hs;
    return Row(
      children: [
        // 主队: 左对齐 Logo+Name
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
        // 中间比分徽章 (对齐 hanklive _buildScoreBadge)
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
        // 客队: 右对齐 Name+Logo
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
                    fontWeight: awayIsCur ? FontWeight.w800 : FontWeight.w600,
                    color: awayIsCur
                        ? (isHomeSection ? const Color(0xFF3B82F6) : sideColor)
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

  /// H2H Logo (24x24 圆角方)
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

/// BMH2HMatch 扩展: 显示时间
extension on BMH2HMatch {
  String get displayMatchTime {
    if (matchTime == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(matchTime! * 1000);
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// _BMPitchLinePainter - 球场划线 (中线/中圈/上下禁区, 对齐 hanklive _PitchLinePainter)
class _BMPitchLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 中线
    canvas.drawLine(
      Offset(16, size.height / 2),
      Offset(size.width - 16, size.height / 2),
      paint,
    );

    // 中圈 (40半径, 对齐hanklive)
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      40,
      paint,
    );

    // 上部禁区 (上半客队进攻方向)
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

    // 下部禁区 (下半主队进攻方向)
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
