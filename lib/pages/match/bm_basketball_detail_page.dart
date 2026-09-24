import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_basketball_quarter_model.dart';
import '../../models/bm_basketball_live_model.dart';
import '../../services/bm_match_detail_api_service.dart';
import '../../utils/bm_auth_manager.dart';
import '../login/bm_login_page.dart';
import 'bm_basketball_overview_tab.dart';
import 'bm_basketball_live_tab.dart';

/// BMBasketballDetailPage - 篮球比赛详情页
/// 功能: 对齐 basketball_match_detail.html 效果
///   1. 顶部 Hero 记分卡: 状态胶囊 + 主客队 Logo/名称/比分 + Q1~Q4 分节比分表格 + 实时胜率条
///   2. 下方菜单只保留 2 Tab: 总览(overview) + 实况(playbyplay), iOS 分段控件样式
/// 接口: GET /api/livespeed/basketball/match/detail?match_id= (订阅/事件/分节比分)
/// 架构: MVVM View 层, 单类单文件, 继承 BMBasePage
class BMBasketballDetailPage extends BMBasePage {
  /// 比赛模型 (BMMatchModel 类型, 列表页/首页传入, 含 matchId/队伍名/比分等)
  final BMMatchModel match;

  const BMBasketballDetailPage({
    super.key,
    required this.match,
  });

  @override
  State<BMBasketballDetailPage> createState() => _BMBasketballDetailPageState();
}

class _BMBasketballDetailPageState extends BMBasePageState<BMBasketballDetailPage> {
  /// API Service 单例 (比赛详情接口服务)
  final BMMatchDetailApiService _apiService = BMMatchDetailApiService();

  /// 事件加载中 (bool 类型)
  bool _loadingIncidents = true;

  /// 是否已订阅 (bool 类型, GET detail -> subscribed 字段)
  bool _isSubscribed = false;

  /// 主队总分 (int? 类型, 覆盖 Hero 比分显示)
  int? _homeTotal;

  /// 客队总分 (int? 类型)
  int? _awayTotal;

  /// 分节比分矩阵 (BMBasketballQuarterScore 类型, Q1~Q4+加时)
  BMBasketballQuarterScore _quarters = const BMBasketballQuarterScore();

  /// 详情原始 data (Map<String,dynamic>? 类型, 总览 Tab 统计/走势兜底用)
  Map<String, dynamic>? _detailData;

  /// 篮球技术统计 (List<Map<String,dynamic>> 类型, process 接口 data.stats)
  List<Map<String, dynamic>> _processStats = const [];

  /// 实况按节分组 (List<BMBasketballLivePeriod> 类型, process 接口 data.tlive)
  List<BMBasketballLivePeriod> _livePeriods = const [];

  /// 比赛模型可变副本 (BMMatchModel 类型, detail 返回后 refreshedWith 刷新顶部卡片)
  late BMMatchModel _match;

  /// 当前选中的 Tab 索引 (int 类型, 0=总览, 1=实况)
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    final matchId = int.tryParse(widget.match.matchId) ?? 0;
    _fetchBasketballDetail(matchId);
    _fetchProcessData(matchId);
  }

  /// 获取篮球进程数据 (GET /api/livespeed/basketball/match/process)
  /// 一次取回: stats 技术统计 (总览 Tab) + tlive 按节实况 (实况 Tab)
  /// [matchId] - 篮球比赛ID (int 类型, 必传)
  Future<void> _fetchProcessData(int matchId) async {
    if (matchId == 0) return;
    final data = await _apiService.fetchBasketballProcess(matchId: matchId);
    if (!mounted || data == null) return;
    // 解析 stats
    final rawStats = data['stats'];
    final stats = rawStats is List
        ? rawStats.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    // 解析 tlive (按节分组)
    final rawTlive = data['tlive'];
    final periods = <BMBasketballLivePeriod>[];
    if (rawTlive is List) {
      for (final p in rawTlive) {
        if (p is Map<String, dynamic>) {
          periods.add(BMBasketballLivePeriod.fromJson(p));
        }
      }
    }
    setState(() {
      if (stats.isNotEmpty) _processStats = stats;
      if (periods.isNotEmpty) _livePeriods = periods;
    });
  }

  /// 获取篮球详情 (GET /api/livespeed/basketball/match/detail?match_id=)
  /// 一次性取回 订阅状态 + 事件列表 + 实时总分 + 分节比分
  /// [matchId] - 篮球比赛ID (int 类型, 必传)
  Future<void> _fetchBasketballDetail(int matchId) async {
    if (matchId == 0) {
      if (!mounted) return;
      setState(() => _loadingIncidents = false);
      return;
    }
    final Map<String, dynamic>? data =
        await _apiService.fetchBasketballDetail(matchId: matchId);
    if (!mounted) return;
    bool subscribed = false;
    int? hTotal;
    int? aTotal;
    BMBasketballQuarterScore quarters = const BMBasketballQuarterScore();
    if (data != null) {
      subscribed = data['subscribed'] == true || data['is_subscribed'] == true;
      quarters = BMBasketballQuarterScore.fromDetailMap(data);
      if (quarters.hasData) {
        hTotal = quarters.homeTotal;
        aTotal = quarters.awayTotal;
      } else {
        // 兜底: home_score/away_score 单值形式
        final homeScoreMap = data['home_score'] ?? data['homeScores'];
        final awayScoreMap = data['away_score'] ?? data['awayScores'];
        if (homeScoreMap is Map) {
          final s = homeScoreMap['total'] ?? homeScoreMap['current'];
          if (s is num) hTotal = s.toInt();
        } else if (homeScoreMap is num) {
          hTotal = homeScoreMap.toInt();
        }
        if (awayScoreMap is Map) {
          final s = awayScoreMap['total'] ?? awayScoreMap['current'];
          if (s is num) aTotal = s.toInt();
        } else if (awayScoreMap is num) {
          aTotal = awayScoreMap.toInt();
        }
      }
    }
    setState(() {
      _isSubscribed = subscribed;
      _homeTotal = hTotal ?? widget.match.homeScore;
      _awayTotal = aTotal ?? widget.match.awayScore;
      _quarters = quarters;
      _detailData = data;
      // detail 返回后合并刷新顶部卡片 (队名/Logo/比分/状态/联赛, 新值优先)
      // 手动指定 categoryId=2 (篮球), 保证状态显示走篮球分支规则
      if (data != null) {
        _match = _match.refreshedWith(
          BMMatchModel.fromMap(data),
          categoryId: 2,
        );
      }
      _loadingIncidents = false;
    });
  }

  /// 切换关注状态 (未登录先跳登录页)
  ///   subscribe:   POST /api/livespeed/basketball/match/subscribe     data:{match_id}
  ///   unsubscribe: POST /api/livespeed/basketball/match/unsubscribe   data:{match_id}
  Future<void> _toggleSubscribe() async {
    if (!BMAuthManager().isLoggedIn) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const BMLoginPage()),
      );
      if (ok != true) return;
    }
    final matchId = int.tryParse(_match.matchId) ?? 0;
    if (matchId == 0) return;
    final willSub = !_isSubscribed;
    final bool success = willSub
        ? await _apiService.subscribeBasketballMatch(matchId: matchId)
        : await _apiService.unsubscribeBasketballMatch(matchId: matchId);
    if (!mounted) return;
    if (success) {
      setState(() => _isSubscribed = willSub);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (willSub ? '已关注' : '已取消关注')
              : '操作失败, 请重试',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: BMColors.pitch800,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========== UI: 整体布局 ===========
  @override
  Widget buildBody(BuildContext context) {
    return Container(
      color: BMColors.pitch950,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildNavBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                child: Column(
                  children: [
                    _buildHeroScoreboard(),
                    const SizedBox(height: 12),
                    _buildSegmentedTabs(),
                    const SizedBox(height: 12),
                    if (_currentTabIndex == 0)
                      BMBasketballOverviewTab(
                        match: widget.match,
                        quarters: _quarters,
                        detailData: _detailData,
                        processStats: _processStats,
                        loading: _loadingIncidents,
                      )
                    else
                      BMBasketballLiveTab(
                        periods: _livePeriods,
                        homeName: _match.homeTeamName,
                        awayName: _match.awayTeamName,
                        matchId: int.tryParse(_match.matchId) ?? 0,
                        statusId: _match.statusId,
                        loading: _loadingIncidents,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 估算左侧状态胶囊宽度 (用于右侧占位, 保证联赛名真正居中于卡片)
  /// [isLive] - 是否进行中 (bool 类型, LIVE 时多一个 6px 红点)
  /// [label] - 状态文案 (String 类型, 例: "LIVE 75'" / "完场")
  /// 返回: double 胶囊预估宽度
  double _statusChipWidth(bool isLive, String label) {
    // 文案宽度估算: 中文字符≈11px/字, 英文数字≈6.2px/字 (11px 字号)
    double textWidth = 0;
    for (final ch in label.runes) {
      textWidth += ch > 0x2E7F ? 11.0 : 6.2;
    }
    // padding 水平 10*2 + 边框 1*2 + LIVE 红点 6+5
    final dot = isLive ? 11.0 : 0.0;
    return textWidth + 20.0 + 2.0 + dot;
  }

  // =========== UI: 顶部导航栏 (返回 + 订阅, 用户要求: 删除中间联赛标题) ===========
  Widget _buildNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      color: BMColors.pitch950,
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: BMColors.pitch850,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: BMColors.textPrimary),
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleSubscribe,
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: BMColors.pitch850,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
              ),
              child: Icon(
                _isSubscribed ? Icons.notifications : Icons.notifications_none,
                size: 18,
                color: _isSubscribed ? BMColors.bright : BMColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========== UI: Hero 记分卡 (对齐 html glass-panel-accent 模块) ===========
  Widget _buildHeroScoreboard() {
    final m = _match; // detail 刷新后的可变模型副本
    final homeName = m.homeTeamName.isNotEmpty ? m.homeTeamName : 'Home';
    final awayName = m.awayTeamName.isNotEmpty ? m.awayTeamName : 'Away';
    final statusLabel = m.displayStatusLabel;
    // 篮球进行中判断 (statusId 2~9 进行时, 用户要求规则)
    final sid = m.statusId;
    final isLive = (sid != null && sid >= 2 && sid <= 9) ||
        (sid == null && m.status == BMMatchStatus.live);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF153B2F), Color(0xFF0B251C)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BMColors.bright.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: BMColors.accent.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          // ---- 第 1 行: 【左】状态胶囊 + 【中】联赛名 (垂直居中) ----
          // 用户要求: 联赛名放卡片中央, 与左边状态胶囊垂直居中
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                      : BMColors.pitch850,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isLive
                        ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                        : BMColors.pitch700,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) ...[
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF87171),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isLive ? const Color(0xFFF87171) : BMColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 联赛名: 占据剩余空间水平居中, 行内垂直居中, 主题色高亮
              Expanded(
                child: Center(
                  child: Text(
                    m.leagueName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BMColors.bright,  // 主题色 (亮绿)
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              // 占位: 与左侧状态胶囊等宽, 保证联赛名真正居中于卡片
              SizedBox(
                width: _statusChipWidth(isLive, statusLabel),
                height: 1,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ---- 第 2 行: 主队 Logo/名 + 中间大比分 + 客队 (html: Teams Score Display 7列栅格) ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(
                      m.homeTeamLogo ?? m.homeTeam?.logoUrl,
                      true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      homeName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BMColors.bright,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Text(
                      _homeTotal == null ? '-' : _homeTotal.toString(),
                      style: const TextStyle(
                        color: BMColors.bright,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: BMColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      _awayTotal == null ? '-' : _awayTotal.toString(),
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(
                      m.awayTeamLogo ?? m.awayTeam?.logoUrl,
                      false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      awayName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ---- 第 3 行: Q1~Q4(+加时) 分节比分表格 (html: Quarter Scores Matrix Table) ----
          if (_quarters.hasData) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x33244739), width: 0.6)),
              ),
              child: _buildQuarterMatrix(),
            ),
          ],
        ],
      ),
    );
  }

  /// 分节比分矩阵表格 (表头: 球队 Q1..Q4 总分 / 两行数据)
  Widget _buildQuarterMatrix() {
    final labels = _quarters.quarterLabels;
    final homeName = _match.homeTeamName.isNotEmpty
        ? _match.homeTeamName
        : '主队';
    final awayName = _match.awayTeamName.isNotEmpty
        ? _match.awayTeamName
        : '客队';
    Widget cell(String text, {Color? color, bool bold = false, double fontSize = 11}) {
      return Expanded(
        child: Center(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color ?? BMColors.textSecondary,
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    }

    Widget row({
      required String name,
      required Color nameColor,
      required List<int> scores,
      required int total,
      required bool showTopDivider,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: showTopDivider
            ? const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0x2E244739), width: 0.5),
                ),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: nameColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...List.generate(labels.length, (i) {
              return cell(
                i < scores.length ? scores[i].toString() : '-',
              );
            }),
            cell(
              total.toString(),
              color: nameColor,
              bold: true,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 表头
        Row(
          children: [
            const Expanded(
              flex: 2,
              child: Text(
                '球队',
                style: TextStyle(
                  color: BMColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...labels.map((l) => cell(l, color: BMColors.textTertiary, fontSize: 10)),
            const Expanded(
              child: Center(
                child: Text(
                  '总分',
                  style: TextStyle(
                    color: BMColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        row(
          name: homeName,
          nameColor: BMColors.bright,
          scores: _quarters.homeQuarters,
          total: _quarters.homeTotal,
          showTopDivider: false,
        ),
        row(
          name: awayName,
          nameColor: const Color(0xFF3B82F6),
          scores: _quarters.awayQuarters,
          total: _quarters.awayTotal,
          showTopDivider: true,
        ),
      ],
    );
  }

  /// 球队 Logo 容器 (52x52 圆角, 主队金边/客队蓝边, 内容垂直水平居中)
  /// [url] - Logo URL (String? 类型, 为空显示篮球兜底图标)
  /// [isHome] - 是否主队 (bool 类型)
  Widget _buildTeamLogo(String? url, bool isHome) {
    final borderColor = isHome
        ? BMColors.bright.withValues(alpha: 0.6)
        : const Color(0x4D3B82F6);
    final iconColor = isHome ? BMColors.bright : const Color(0xFF3B82F6);
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,  // ⭐️ 内容垂直水平居中 (修复 Icon 贴左上角)
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Center(
          child: (url == null || url.isEmpty)
              ? Icon(Icons.sports_basketball, size: 26, color: iconColor)
              : Image.network(
                  url,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.sports_basketball, size: 26, color: iconColor),
                ),
        ),
      ),
    );
  }

  // =========== UI: iOS 分段控件 Tab (总览 | 实况) ===========
  Widget _buildSegmentedTabs() {
    const tabs = ['总览', '实况'];
    const icons = [Icons.pie_chart_outline, Icons.format_list_numbered];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _currentTabIndex == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _currentTabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? BMColors.pitch800 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[i],
                      size: 13,
                      color: selected ? BMColors.bright : BMColors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? BMColors.bright : BMColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
