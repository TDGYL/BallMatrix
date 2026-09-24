import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_process_model.dart';
import '../../models/bm_odds_model.dart';
import '../../models/bm_h2h_model.dart';
import '../../models/bm_lineup_model.dart';
import '../../models/bm_player_info_model.dart';
import '../../models/bm_team_info_model.dart';
import '../../services/bm_match_detail_api_service.dart';
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

  /// 比赛模型可变副本 (BMMatchModel 类型, detail 返回后 refreshedWith 刷新顶部卡片)
  late BMMatchModel _match;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    final matchId = int.tryParse(widget.match.matchId) ?? 0;
    _fetchMatchDetail(matchId);
    _fetchProcess(matchId);
  }

  /// 获取订阅状态 + 刷新顶部卡片
  Future<void> _fetchMatchDetail(int matchId) async {
    if (matchId == 0) return;
    final Map<String, dynamic>? data = await _apiService.fetchMatchDetail(matchId: matchId);
    if (!mounted || data == null) return;
    setState(() {
      _isSubscribed = data['subscribed'] == true;
      // detail 返回后合并刷新顶部卡片 (队名/Logo/比分/状态/联赛, 新值优先)
      // 手动指定 categoryId=1 (足球), 保证状态显示走足球分支规则
      _match = _match.refreshedWith(
        BMMatchModel.fromMap(data),
        categoryId: 1,
      );
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

  /// 切换关注 (未登录先去登录)
  ///   subscribe:   POST /api/livespeed/football/match/subscribe     data:{match_id}
  ///   unsubscribe: POST /api/livespeed/football/match/unsubscribe   data:{match_id}
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
    final bool success = willSub
        ? await _apiService.subscribeFootballMatch(matchId: matchId)
        : await _apiService.unsubscribeFootballMatch(matchId: matchId);
    if (!mounted) return;
    if (success) {
      setState(() => _isSubscribed = willSub);
      _snack(willSub ? '已关注' : '已取消关注');
    } else {
      _snack('操作失败, 请重试');
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
            // 导航中间标题 (足球详情)
            const Expanded(
              child: Text(
                'Football Detail',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
    final m = _match; // detail 刷新后的可变模型副本
    final homeLogo = m.homeTeamLogo ?? m.homeTeam?.logoUrl;
    final awayLogo = m.awayTeamLogo ?? m.awayTeam?.logoUrl;
    final homeName = m.homeTeamName.isNotEmpty
        ? m.homeTeamName
        : m.homeTeam?.teamName ?? '主队';
    final awayName = m.awayTeamName.isNotEmpty
        ? m.awayTeamName
        : m.awayTeam?.teamName ?? '客队';
    final statusLabel = m.displayStatusLabel;
    final bool live = m.status == BMMatchStatus.live;
    final leagueName = m.leagueName;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 16), // 右 padding 改为 12 (用户要求联赛名距右边12px)
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
          // ========================================
          // 第 1 行: 【中】 联赛胶囊 (水平居中显示)
          // 用户要求: 顶部联赛水平居中 (原为右对齐, 距右 12px)
          // ========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,  // 水平居中
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,  // 胶囊背景透明
                  ),
                  child: Text(
                    leagueName,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: BMColors.bright,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 第 2 行: 【主队列】+【中间: 状态时间控件(比分上方) + 比分显示】+【客队列】
          // 用户要求: 把比分上面的状态时间控件 (原来的 LIVE 75' 胶囊) 放在比分显示的上方
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主队: 左对齐 + Flex 5
              Expanded(
                flex: 5,
                child: () {
                  // 兼容 2 种 teamId 取法: ① 顶层 homeTeamId (对齐 hanklive BMMatchModel 新字段) ② homeTeam.teamId String (老结构)
                  final idFromTop = m.homeTeamId;
                  final idFromTeam = m.homeTeam?.teamId;
                  int? teamId;
                  if (idFromTop != null && idFromTop != 0) {
                    teamId = idFromTop;
                  } else if (idFromTeam != null && idFromTeam.isNotEmpty) {
                    teamId = int.tryParse(idFromTeam);
                  }
                  return GestureDetector(
                    onTap: () {
                      final tId = teamId;
                      if (tId == null || tId <= 0) return;
                      _showTeamInfoSheet(
                        teamId: tId,
                        fallbackName: homeName,
                        fallbackLogo: homeLogo,
                        isHome: true,
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: _teamHomeColumn(homeLogo, homeName),
                  );
                }(),
              ),
              // 中间比分区: Flex 4 居中, 比分上方放状态时间控件 (用户要求)
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 10),
                    // 比分显示 (状态控件下方, 用户要求: 控件放在"比分上面" → 控件在上, 比分在下)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          m.homeScore?.toString() ?? '-',
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
                          m.awayScore?.toString() ?? '-',
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
                  ],
                ),
              ),
              // 客队: 右对齐 + Flex 5
              Expanded(
                flex: 5,
                child: () {
                  final idFromTop = m.awayTeamId;
                  final idFromTeam = m.awayTeam?.teamId;
                  int? teamId;
                  if (idFromTop != null && idFromTop != 0) {
                    teamId = idFromTop;
                  } else if (idFromTeam != null && idFromTeam.isNotEmpty) {
                    teamId = int.tryParse(idFromTeam);
                  }
                  return GestureDetector(
                    onTap: () {
                      final tId = teamId;
                      if (tId == null || tId <= 0) return;
                      _showTeamInfoSheet(
                        teamId: tId,
                        fallbackName: awayName,
                        fallbackLogo: awayLogo,
                        isHome: false,
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: _teamAwayColumn(awayLogo, awayName),
                  );
                }(),
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

  // =========== 球队信息 Bottom Sheet (点击顶部球队头像弹出, 用户要求) ===========

  /// 核心: 弹 Bottom Sheet + 异步请求 GET /api/livespeed/football/team/data?team_id=
  void _showTeamInfoSheet({
    required int teamId,
    required String fallbackName,
    String? fallbackLogo,
    required bool isHome,
  }) {
    if (teamId <= 0) return;
    final sideColor = isHome ? BMColors.bright : const Color(0xFF3B82F6);
    final loadingVN = ValueNotifier<bool>(true);
    final infoVN = ValueNotifier<BMTeamInfo?>(null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) {
        Future.microtask(() async {
          final info = await BMMatchDetailApiService().fetchTeamData(teamId: teamId);
          loadingVN.value = false;
          infoVN.value = info;
        });
        return ValueListenableBuilder<bool>(
          valueListenable: loadingVN,
          builder: (_, loading, __) {
            return ValueListenableBuilder<BMTeamInfo?>(
              valueListenable: infoVN,
              builder: (_, info, ___) {
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.68,
                  ),
                  padding: EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 12,
                    bottom: 14 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: BMColors.pitch900,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 顶部拖拽手柄
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: BMColors.pitch700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // 标题行: 图标 + 球队信息文字 + 主/客小色点
                      Row(
                        children: [
                          Icon(Icons.shield_rounded, size: 15, color: sideColor),
                          const SizedBox(width: 6),
                          const Text(
                            '球队信息',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: BMColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: sideColor, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(
                            isHome ? '主队' : '客队',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: sideColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (loading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(sideColor),
                              ),
                            ),
                          ),
                        )
                      else if (info == null)
                        _teamSheetEmpty(fallbackName, sideColor)
                      else
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: _teamSheetContent(info, sideColor, fallbackName, fallbackLogo),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 球队空态 (请求失败/无数据)
  Widget _teamSheetEmpty(String fallbackName, Color sideColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.holiday_village, size: 30, color: sideColor.withValues(alpha: 0.75)),
          const SizedBox(height: 8),
          Text(
            '暂无 $fallbackName 的详细信息',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BMColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// 球队数据态 (2 段卡片: 顶部主信息卡 + 2列6行详细信息卡)
  Widget _teamSheetContent(BMTeamInfo info, Color sideColor, String fbName, String? fbLogo) {
    final name = (info.name?.isNotEmpty ?? false) ? info.name! : fbName;
    final logo = (info.logo?.isNotEmpty ?? false) ? info.logo! : fbLogo;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ========== 卡片 1: 顶部主信息 (Logo 66x66 + 球队名 + 联赛 + 国家 + 订阅状态) ==========
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BMColors.pitch850,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sideColor.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              // 球队 Logo 66x66 圆
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BMColors.pitch700.withValues(alpha: 0.7),
                  border: Border.all(color: sideColor.withValues(alpha: 0.45), width: 1.1),
                ),
                clipBehavior: Clip.antiAlias,
                child: (logo != null && logo.isNotEmpty)
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.network(
                          logo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.shield_rounded, size: 28, color: sideColor),
                        ),
                      )
                    : Center(
                        child: Icon(Icons.shield_rounded, size: 32, color: sideColor),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 球队名 + 订阅状态(右上角)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 2,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: BMColors.textPrimary,
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (info.isSubscribe == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sideColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: sideColor.withValues(alpha: 0.5)),
                            ),
                            child: Icon(Icons.star_rounded, size: 11, color: sideColor),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 联赛 + 国旗/国家
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (info.competitionName?.isNotEmpty ?? false)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: sideColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              info.competitionName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: sideColor,
                              ),
                            ),
                          ),
                        if (info.countryName?.isNotEmpty ?? false)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (info.countryLogo?.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: Image.network(
                                      info.countryLogo!,
                                      width: 16,
                                      height: 12,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox(width: 0, height: 0),
                                    ),
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  info.countryName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: BMColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ========== 卡片 2: 2列6字段 详细信息 (成立/球场/容量/教练/身价/官网) ==========
        Container(
          decoration: BoxDecoration(
            color: BMColors.pitch850,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              _teamInfoRow(Icons.cake, '成立', info.foundationLabel, Icons.stadium, '主场', info.venueName ?? '-'),
              _teamInfoDivider(),
              _teamInfoRow(Icons.chair_alt, '容量', info.venueCapacityLabel, Icons.people, '教练', info.managerName ?? '-',
                  managerLogo: info.managerLogo),
              _teamInfoDivider(),
              _teamInfoRow(Icons.euro_symbol, '身价', info.marketValueLabel, Icons.public, '官网',
                  (info.website != null && info.website!.isNotEmpty) ? _shortUrl(info.website!) : '-'),
            ],
          ),
        ),
      ],
    );
  }

  /// 简化 URL 展示: http://www.mcfc.co.uk/ → mcfc.co.uk
  static String _shortUrl(String url) {
    try {
      final u = Uri.parse(url);
      String host = u.host;
      if (host.startsWith('www.')) host = host.substring(4);
      if (host.endsWith('/')) host = host.substring(0, host.length - 1);
      if (host.isEmpty) {
        if (url.length > 26) return '${url.substring(0, 24)}...';
        return url;
      }
      if (u.path.isNotEmpty && u.path != '/') {
        return '$host${u.path}';
      }
      return host;
    } catch (_) {
      if (url.length > 26) return '${url.substring(0, 24)}...';
      return url;
    }
  }

  /// 2列一行球队信息, 中间 0.5px 分隔线; 教练额外支持小头像 (managerLogo)
  Widget _teamInfoRow(
      IconData li, String ll, String lv, IconData ri, String rl, String rv, {String? managerLogo}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(li, size: 15, color: BMColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  '$ll  ',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: BMColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    lv,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BMColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 0.5,
            height: 20,
            color: BMColors.pitch700.withValues(alpha: 0.8),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Row(
              children: [
                // 教练字段优先显示 managerLogo 20x20
                if (rl == '教练' && managerLogo != null && managerLogo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ClipOval(
                      child: Image.network(
                        managerLogo,
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(ri, size: 15, color: BMColors.textTertiary),
                      ),
                    ),
                  )
                else
                  Icon(ri, size: 15, color: BMColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  '$rl  ',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: BMColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    rv,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BMColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 球队信息字段 0.5px 分隔线
  Widget _teamInfoDivider() => Container(
        height: 0.5,
        color: BMColors.pitch700.withValues(alpha: 0.6),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );

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

  /// 指数 Tab: 显示 2 行赔率的状态 (用户要求: 默认 true=初盘+早盘, 点击切换后 false=早盘+即时)
  bool _oddsShowIniPre = true;

  Widget _buildOddsTab() {
    _ensureOdds();
    final companies = _oddsData?.listBy(_oddsSel) ?? [];
    final is1x2 = _oddsSel == BMOddsType.matchResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ① 4 段 selector (样式改成顶部比赛详情 Tab 胶囊式一致: 选中 = 亮绿填充 + pitch900 深色字 + 阴影)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: BMOddsType.values.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                final selected = _oddsSel == t;
                return Padding(
                  padding: EdgeInsets.only(right: (i == BMOddsType.values.length - 1) ? 0 : 8),
                  child: GestureDetector(
                    onTap: () {
                      if (_oddsSel == t) return;
                      setState(() {
                        _oddsSel = t;
                        // 切换盘口类型时, 重置为默认初盘+早盘(用户约定)
                        _oddsShowIniPre = true;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? BMColors.bright : BMColors.pitch850,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? BMColors.bright
                              : BMColors.pitch700.withValues(alpha: 0.5),
                          width: selected ? 1.2 : 0.6,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: BMColors.bright.withValues(alpha: 0.22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t.shortLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected ? BMColors.pitch900 : BMColors.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
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
                        child: Text('暂无赔率数据',
                            style:
                                TextStyle(fontSize: 13, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
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
                          // 卡片标题行: 左 盘口类型名 / 右 **可点击切换按钮** (用户要求: 初盘/早盘 ↔ 早盘/即时)
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
                              // 用户要求: 右上角即时盘口按钮可点击切换 2 行显示
                              GestureDetector(
                                onTap: () => setState(() => _oddsShowIniPre = !_oddsShowIniPre),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _oddsShowIniPre
                                        ? BMColors.pitch700.withValues(alpha: 0.5)
                                        : BMColors.bright.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _oddsShowIniPre
                                          ? BMColors.pitch700.withValues(alpha: 0.6)
                                          : BMColors.bright.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _oddsShowIniPre ? BMColors.textTertiary : BMColors.bright,
                                          boxShadow: _oddsShowIniPre
                                              ? null
                                              : [const BoxShadow(color: BMColors.bright, blurRadius: 6)],
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        // true: 初盘+早盘模式 按钮文案 "早盘+即时" (可切过去)
                                        // false: 当前展示早盘+即时, 按钮文案 "初盘+早盘" (可切回来)
                                        _oddsShowIniPre ? '早盘+即时' : '初盘+早盘',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _oddsShowIniPre ? BMColors.textTertiary : BMColors.bright,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // 表头(公司列 70px宽 + 阶段标签列 40px宽 + 3 或 4 栏 Expanded 表头)
                          _oddsTableHeader(is1x2: is1x2),
                          const SizedBox(height: 4),
                          // 每家公司 **只展示 2 行数据**
                          //   true (默认) → 初盘(ini) + 早盘(pre)
                          //   false (切过) → 早盘(pre) + 即时(spot)
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

  /// 单家博彩公司的行(左侧公司名列 + **只展示 2 行** odds rows + 右箭头)
  /// 用户要求: 默认展示初盘(ini)+早盘(pre); 点右上角按钮切到 早盘(pre)+即时(spot)
  Widget _oddsCompanyRow(BMCompanyOdds company, bool is1x2) {
    final hasIni = company.ini != null;
    final hasPre = company.pre != null;
    final hasSpot = company.spot != null;
    final List<Widget> rows = [];
    if (_oddsShowIniPre) {
      // 默认模式: 初盘 + 早盘 (2 行, 都有就 2 行; 缺 1 个就显示存在的那个; 保证不 >2)
      if (hasIni) {
        rows.add(_oddsStageRow(company.ini!,
            stageLabel: '初盘', color: BMColors.textTertiary, is1x2: is1x2));
        rows.add(const SizedBox(height: 8));
      }
      if (hasPre) {
        rows.add(_oddsStageRow(company.pre!,
            stageLabel: '早盘', color: const Color(0xFF3B82F6), is1x2: is1x2));
      }
    } else {
      // 切换模式: 早盘 + 即时 (2 行)
      if (hasPre) {
        rows.add(_oddsStageRow(company.pre!,
            stageLabel: '早盘', color: const Color(0xFF3B82F6), is1x2: is1x2));
        rows.add(const SizedBox(height: 8));
      }
      if (hasSpot) {
        rows.add(_oddsStageRow(company.spot!,
            stageLabel: '即时', color: BMColors.bright, is1x2: is1x2));
      }
    }
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
            // 阶段赔率列 (只包含 2 行)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
            // 右箭头
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 16),
              child:
                  Icon(Icons.chevron_right, size: 16, color: BMColors.pitch700.withValues(alpha: 0.9)),
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

  /// 阵容 Tab 点击球员 → 底部弹出球员信息 Sheet (用户要求)
  ///   步骤: 1. 校验 playerId (0 或空直接 return)
  ///         2. showModalBottomSheet (Loading 态)
  ///         3. 请求 GET /api/livespeed/football/match/player-info?player_id=&match_id=
  ///         4. setState 刷新 Bottom Sheet → 数据态 / 空态
  void _navigateToLineupPlayerDetail(BMMatchLineupPlayer player) {
    final idStr = player.playerId;
    final pid = (idStr != null && idStr.isNotEmpty) ? int.tryParse(idStr) : null;
    // 对齐 hanklive: playerId == 0 直接 return
    if (pid == null || pid == 0) return;
    final matchId = int.tryParse(widget.match.matchId) ?? 0;
    if (matchId == 0) return;
    _loadAndShowPlayerSheet(playerId: pid, matchId: matchId, fallbackName: player.playerName);
  }

  /// 核心: 弹 Bottom Sheet + 异步请求球员信息(用户给的接口/参数/返回结构)
  Future<void> _loadAndShowPlayerSheet({
    required int playerId,
    required int matchId,
    String? fallbackName,
  }) async {
    // 内部 ValueNotifier 控制 Loading/数据/空态 (不 setState 页面, 只刷新 Sheet)
    final loadingVN = ValueNotifier<bool>(true);
    final infoVN = ValueNotifier<BMPlayerInfo?>(null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetCtx) {
        // 异步请求 (独立 Future, 不阻塞 Sheet 弹出)
        Future.microtask(() async {
          final info = await BMMatchDetailApiService().fetchPlayerInfo(
            playerId: playerId,
            matchId: matchId,
          );
          loadingVN.value = false;
          infoVN.value = info;
        });
        return ValueListenableBuilder<bool>(
          valueListenable: loadingVN,
          builder: (_, loading, __) {
            return ValueListenableBuilder<BMPlayerInfo?>(
              valueListenable: infoVN,
              builder: (_, info, ___) {
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.62,
                  ),
                  padding: EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 12,
                    bottom: 14 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: BMColors.pitch900,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 顶部拖拽手柄
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: BMColors.pitch700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // 标题 + 关闭
                      Row(
                        children: const [
                          Icon(Icons.person, size: 15, color: BMColors.bright),
                          SizedBox(width: 6),
                          Text(
                            '球员信息',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: BMColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (loading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(BMColors.bright),
                              ),
                            ),
                          ),
                        )
                      else if (info == null)
                        _playerSheetEmpty(fallbackName)
                      else
                        Flexible(child: _playerSheetContent(info)),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 球员 Sheet: 请求失败 / 无数据空态
  Widget _playerSheetEmpty(String? fallbackName) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.person_off, size: 30, color: BMColors.pitch700.withValues(alpha: 0.9)),
          const SizedBox(height: 8),
          Text(
            fallbackName?.isNotEmpty == true ? '暂无 $fallbackName 的详细信息' : '暂无该球员的详细信息',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BMColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// 球员 Sheet: 成功数据态 (8 个字段 2 列 grid + 顶部主信息行)
  Widget _playerSheetContent(BMPlayerInfo info) {
    final name = (info.playerName?.isNotEmpty ?? false) ? info.playerName! : '未知球员';
    final shirt = info.shirtNumber ?? 0;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部主卡片: 头像 + 球衣号码 + 名字 + 位置 + 国籍
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BMColors.pitch850,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                // 头像 60x60
                ClipOval(
                  child: Container(
                    width: 60,
                    height: 60,
                    color: BMColors.pitch700.withValues(alpha: 0.7),
                    child: (info.playerLogo != null && info.playerLogo!.isNotEmpty)
                        ? Image.network(
                            info.playerLogo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _playerAvatarFallback(name, shirt),
                          )
                        : _playerAvatarFallback(name, shirt),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 球衣号徽章
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: BMColors.bright.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: BMColors.bright.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              shirt > 0 ? '#$shirt' : '-',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: BMColors.bright,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 2,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: BMColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 位置 + 国籍
                      Row(
                        children: [
                          // 位置 Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              info.positionFullLabel,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (info.countryName != null && info.countryName!.isNotEmpty) ...[
                            if (info.countryLogo != null && info.countryLogo!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: Image.network(
                                    info.countryLogo!,
                                    width: 16,
                                    height: 12,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(width: 0, height: 0),
                                  ),
                                ),
                              ),
                            Flexible(
                              child: Text(
                                info.countryName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: BMColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 下方字段 2x2 Grid: 身高 / 体重 / 身价 / 位置缩写
          Container(
            decoration: BoxDecoration(
              color: BMColors.pitch850,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                _playerInfoRow(Icons.height, '身高', info.heightLabel, Icons.fitness_center, '体重', info.weightLabel),
                Container(height: 0.5, color: BMColors.pitch700.withValues(alpha: 0.6)),
                _playerInfoRow(Icons.attach_money, '身价', info.marketValueLabel, Icons.flag_circle, '位置', info.position ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 头像加载失败 fallback: 首字母 + 号码绿底
  Widget _playerAvatarFallback(String name, int shirt) {
    final first = (name.isNotEmpty) ? name.trim().characters.first.toUpperCase() : '?';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            first,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: BMColors.bright,
            ),
          ),
          if (shirt > 0)
            Text(
              '$shirt',
              style: const TextStyle(
                fontSize: 10,
                color: BMColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  /// 2 列一行字段 (左: icon/label/value + 右: icon/label/value)
  Widget _playerInfoRow(
      IconData li, String ll, String lv, IconData ri, String rl, String rv) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(li, size: 15, color: BMColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  '$ll  ',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: BMColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    lv,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BMColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 0.5,
            height: 18,
            color: BMColors.pitch700.withValues(alpha: 0.8),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(ri, size: 15, color: BMColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  '$rl  ',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: BMColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    rv,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BMColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  /// 阵型头部: 主阵型名 VS 客阵型名 (用户要求: 阵型旁 LOGO 删除)
  ///   下方保留主/客教练名 + 图标帽 (对齐真实后端 home_coach / away_coach 字段)
  Widget _buildLineupHeader(BMLineupData data) {
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
          // 第 1 行: 4-3-3 VS 4-2-3-1 (删除了主客队 logo, 用户要求)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  data.homeFormation ?? '',
                  maxLines: 2,
                  softWrap: true,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: BMColors.textPrimary,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BMColors.textTertiary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  data.awayFormation ?? '',
                  maxLines: 2,
                  softWrap: true,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: BMColors.textPrimary,
                  ),
                ),
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
                const SizedBox(width: 24),
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

  /// 球员节点 (头像+号码+事件徽标, 用户要求: 首发名字 Chip 删除, 只保留站位头像)
  /// 点击跳球员详情页 (对齐 hanklive _navigateToPlayerDetail)
  Widget _buildLineupPlayerNode(BMMatchLineupPlayer player, {required bool isHome}) {
    final teamColor = isHome ? const Color(0xFFE11D48) : const Color(0xFF3B82F6);
    final shirtNum = player.shirtNumber ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _navigateToLineupPlayerDetail(player),
      child: SizedBox(
        width: 36,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
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

  /// 替补区 (Home + Away, 用户要求: 左右两列, 每行2球员, 左主队 / 右客队)
  Widget _buildLineupSubSection(BMLineupData data) {
    final homeList = data.homeSub;
    final awayList = data.awaySub;
    if (homeList.isEmpty && awayList.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxLen = homeList.length > awayList.length ? homeList.length : awayList.length;
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
          // 标题行 + 主/客小标签 (左右两端)
          Row(
            children: [
              const Icon(Icons.chair, size: 14, color: BMColors.bright),
              const SizedBox(width: 8),
              const Text(
                '替补',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BMColors.textPrimary,
                ),
              ),
              const Spacer(),
              // 主队小球
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle)),
              const SizedBox(width: 3),
              const Text('主', style: TextStyle(fontSize: 10, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              // 客队小球
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
              const SizedBox(width: 3),
              const Text('客', style: TextStyle(fontSize: 10, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          // 每行: 左 Expanded 主队球员 / 右 Expanded 客队球员 (两边各一位 → 共 2 位球员/行)
          ...List.generate(maxLen, (i) {
            final hPlayer = i < homeList.length ? homeList[i] : null;
            final aPlayer = i < awayList.length ? awayList[i] : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: hPlayer != null
                        ? _buildLineupSubPlayerChip(hPlayer)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: aPlayer != null
                        ? _buildLineupSubPlayerChip(aPlayer)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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

  /// 伤停区 (Home + Away, 用户要求: 左右两列, 每行2球员, 左主队 / 右客队)
  Widget _buildLineupInjurySection(BMLineupData data) {
    final homeList = data.homeInjury;
    final awayList = data.awayInjury;
    if (homeList.isEmpty && awayList.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxLen = homeList.length > awayList.length ? homeList.length : awayList.length;
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
          // 标题行 + 主/客小标签 (左右两端)
          Row(
            children: [
              const Icon(Icons.local_hospital, size: 14, color: Color(0xFFF87171)),
              const SizedBox(width: 8),
              const Text(
                '伤停',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BMColors.textPrimary,
                ),
              ),
              const Spacer(),
              // 主队小球
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle)),
              const SizedBox(width: 3),
              const Text('主', style: TextStyle(fontSize: 10, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              // 客队小球
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
              const SizedBox(width: 3),
              const Text('客', style: TextStyle(fontSize: 10, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          // 每行: 左 Expanded 主队 / 右 Expanded 客队 (每行 2 位球员, 用户要求)
          ...List.generate(maxLen, (i) {
            final hPlayer = i < homeList.length ? homeList[i] : null;
            final aPlayer = i < awayList.length ? awayList[i] : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: hPlayer != null
                        ? _buildLineupInjuryPlayerChip(hPlayer)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: aPlayer != null
                        ? _buildLineupInjuryPlayerChip(aPlayer)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLineupInjuryPlayerChip(BMMatchLineupPlayer player) {
    return GestureDetector(
      onTap: () => _navigateToLineupPlayerDetail(player),
      behavior: HitTestBehavior.opaque,
      child: Container(
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

  /// 单段完整交锋区 (过滤器 + 卡片列表) — 用户要求: 删除 WDL 比例条区
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
          // ① 过滤器胶囊 (对齐 hanklive _buildFilterChips)
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
          // ② 卡片列表 (对齐 hanklive ...displayMatches.map)
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
