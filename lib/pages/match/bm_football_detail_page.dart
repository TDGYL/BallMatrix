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

  /// H2H 交锋列表
  List<BMH2HMatch> _h2hMatches = [];

  /// 是否加载中 H2H
  bool _loadingH2H = false;

  /// 是否已加载过 H2H (懒加载)
  bool _fetchedH2H = false;

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

  /// 懒加载 H2H
  Future<void> _ensureH2H() async {
    if (_fetchedH2H || _loadingH2H) return;
    final matchId = int.tryParse(widget.match.matchId) ?? 0;
    if (matchId == 0) return;
    setState(() => _loadingH2H = true);
    final List<BMH2HMatch> list = await _apiService.fetchH2HData(matchId: matchId);
    if (!mounted) return;
    setState(() {
      _h2hMatches = list;
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

  /// 指数历史跳转 (完全参考 hanklive odds_history_page)
  void _gotoOddsHistory(String companyId, String companyName, BMOddsType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BMOddsHistoryPage(
          matchId: int.tryParse(widget.match.matchId) ?? 0,
          companyId: companyId,
          companyName: companyName,
          oddsType: type,
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
            children: [
              Expanded(
                child: _teamColumn(homeLogo, homeName),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.match.homeScore?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.05,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(':', style: TextStyle(fontSize: 22, color: Color(0xFF6B7280))),
                        ),
                        Text(
                          widget.match.awayScore?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.05,
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
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Expanded(child: _teamColumn(awayLogo, awayName, isHome: false)),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _teamColumn(String? logo, String name, {bool isHome = true}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isHome ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      textDirection: isHome ? TextDirection.ltr : TextDirection.rtl,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: BMColors.pitch800,
            shape: BoxShape.circle,
            border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
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
        const SizedBox(height: 7),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
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

  // =========== Odds Tab ===========
  BMOddsType _oddsSel = BMOddsType.asianHandicap;

  Widget _buildOddsTab() {
    _ensureOdds();
    List<BMCompanyOdds> list;
    switch (_oddsSel) {
      case BMOddsType.asianHandicap:
        list = _oddsData?.asianHandicap ?? [];
        break;
      case BMOddsType.matchResult:
        list = _oddsData?.matchResult ?? [];
        break;
      case BMOddsType.overUnder:
        list = _oddsData?.overUnder ?? [];
        break;
      case BMOddsType.corners:
        list = _oddsData?.corners ?? [];
        break;
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: BMOddsType.values.map((t) {
              final sel = _oddsSel == t;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _oddsSel = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? BMColors.bright.withValues(alpha: 0.14) : BMColors.pitch850,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: sel ? BMColors.bright.withValues(alpha: 0.6) : BMColors.pitch700.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    t.label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: sel ? BMColors.bright : BMColors.textSecondary),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (_loadingOdds && list.isEmpty)
          _buildLoading(BMColors.bright)
        else if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text('暂无赔率数据', style: TextStyle(color: BMColors.textTertiary, fontSize: 12))),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: List.generate(list.length, (i) {
                final co = list[i];
                final needDraw = _oddsSel == BMOddsType.matchResult;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _gotoOddsHistory(co.companyId, co.companyName ?? '博彩公司', _oddsSel),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: BMColors.pitch850,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                co.companyName ?? '公司 ID:${co.companyId}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: BMColors.textTertiary),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _oddsCell(co.home ?? '--', _oddsSel != BMOddsType.matchResult)),
                            if (co.handicap != null && co.handicap!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(8)),
                                child: Text(co.handicap!, style: const TextStyle(color: BMColors.bright, fontSize: 12, fontWeight: FontWeight.w800)),
                              ),
                            if (needDraw) Expanded(child: _oddsCell(co.draw ?? '--', false, isCenter: true)),
                            Expanded(child: _oddsCell(co.away ?? '--', _oddsSel != BMOddsType.matchResult, isAway: true)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _oddsCell(String v, bool colored, {bool isCenter = false, bool isAway = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(
        v,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: colored ? (isAway ? const Color(0xFF3B82F6) : BMColors.bright) : Colors.white,
        ),
      ),
    );
  }

  // =========== Lineup Tab (对齐 hanklive match_detail_lineup_tab.dart) ===========

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
  Widget _buildLineupHeader(BMLineupData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
      ),
      child: Row(
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
  Widget _buildLineupPlayerNode(BMMatchLineupPlayer player, {required bool isHome}) {
    final teamColor = isHome ? const Color(0xFFE11D48) : const Color(0xFF3B82F6);
    final shirtNum = player.shirtNumber ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: BMColors.pitch850.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              player.playerName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                color: BMColors.textPrimary,
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
  Widget _buildLineupSubPlayerChip(BMMatchLineupPlayer player) {
    final shirtNum = player.shirtNumber ?? 0;
    return Container(
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
                if (player.position != null && player.position!.isNotEmpty)
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

  // =========== H2H Tab ===========
  Widget _buildH2HTab() {
    _ensureH2H();
    final homeName = widget.match.homeTeamName.isNotEmpty
        ? widget.match.homeTeamName
        : widget.match.homeTeam?.teamName ?? '';
    final awayName = widget.match.awayTeamName.isNotEmpty
        ? widget.match.awayTeamName
        : widget.match.awayTeam?.teamName ?? '';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(homeName, style: const TextStyle(color: BMColors.bright, fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: BMColors.pitch850, borderRadius: BorderRadius.circular(10), border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5))),
                child: const Text('历史交锋', style: TextStyle(color: BMColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              Expanded(child: Text(awayName, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingH2H && _h2hMatches.isEmpty)
          _buildLoading(BMColors.bright)
        else if (_h2hMatches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text('暂无交锋历史', style: TextStyle(color: BMColors.textTertiary, fontSize: 12))),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: List.generate(_h2hMatches.length, (i) {
                final h = _h2hMatches[i];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BMFootballDetailPage(match: h.toMatchModel),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BMColors.pitch850,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (h.leagueName != null && h.leagueName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(6)),
                            child: Text(h.leagueName!, style: const TextStyle(fontSize: 10, color: BMColors.textTertiary, fontWeight: FontWeight.w700)),
                          ),
                        Row(
                          children: [
                            Expanded(child: _miniTeam(h.homeTeamLogo, h.homeTeamName, BMColors.bright, TextAlign.right)),
                            const SizedBox(width: 12),
                            Text(
                              "${h.homeScore ?? '-'} : ${h.awayScore ?? '-'}",
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _miniTeam(h.awayTeamLogo, h.awayTeamName, const Color(0xFF3B82F6), TextAlign.left)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(h.displayMatchTime, style: const TextStyle(fontSize: 10, color: BMColors.textTertiary)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _miniTeam(String? logo, String? name, Color c, TextAlign align) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: BMColors.pitch800, shape: BoxShape.circle, border: Border.all(color: c.withValues(alpha: 0.35))),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: (logo != null && logo.isNotEmpty)
              ? Image.network(logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.sports_soccer, size: 14, color: c))
              : Icon(Icons.sports_soccer, size: 14, color: c),
        ),
        const SizedBox(height: 4),
        Text(
          name ?? '',
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.2),
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
