import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../models/bm_process_model.dart';
import '../../services/bm_match_detail_api_service.dart';
import '../../utils/bm_auth_manager.dart';
import '../login/bm_login_page.dart';

/// BMBasketballDetailPage - 篮球比赛详情页
/// 功能: 篮球比赛详情展示, 下方菜单只保留「事件」单Tab
/// 接口: GET /api/v1/livespeed/match/detail?match_id= (篮球比赛ID)
/// UI: 深绿主题差异化, 复用足球详情页 AppBar + Scoreboard 风格
/// 架构: 单类单文件, 继承 BMBasePage
class BMBasketballDetailPage extends BMBasePage {
  /// 比赛模型 (BMMatchModel 类型, 列表页/首页传过来, 包含matchId/队伍名/比分等)
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

  /// 事件列表 (List<BMIncident> 类型, 复用BMIncident解析)
  List<BMIncident> _incidents = [];

  /// 事件加载中 (bool 类型)
  bool _loadingIncidents = true;

  /// 是否已订阅 (bool 类型, GET detail -> subscribed 字段)
  bool _isSubscribed = false;

  /// 主队总分 (int? 类型, 用于比分板)
  int? _homeTotal;

  /// 客队总分 (int? 类型, 用于比分板)
  int? _awayTotal;

  @override
  void initState() {
    super.initState();
    final matchId = int.tryParse(widget.match.matchId) ?? 0;
    _fetchBasketballDetail(matchId);
  }

  /// 获取篮球详情 (GET /api/v1/livespeed/match/detail?match_id=)
  /// 一次性取回 订阅状态 + 事件列表 + 实时总分
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
    List<BMIncident> incs = [];
    bool subscribed = false;
    int? hTotal;
    int? aTotal;
    if (data != null) {
      subscribed = data['subscribed'] == true || data['is_subscribed'] == true;
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
      final rawi = data['incidents'] ??
          data['events'] ??
          data['timeline'] ??
          (data['data'] is Map ? (data['data'] as Map)['incidents'] : null) ??
          [];
      if (rawi is List) {
        for (final e in rawi) {
          if (e is Map<String, dynamic>) {
            try {
              incs.add(BMIncident.fromJson(e));
            } catch (_) {}
          }
        }
      }
    }
    setState(() {
      _isSubscribed = subscribed;
      _incidents = incs;
      _homeTotal = hTotal ?? widget.match.homeScore;
      _awayTotal = aTotal ?? widget.match.awayScore;
      _loadingIncidents = false;
    });
  }

  /// 切换订阅状态 (未登录先跳登录页)
  /// 订阅/取消 接口暂与足球路径区分, 后续后端对齐后可直接复用
  Future<void> _toggleSubscribe() async {
    if (!BMAuthManager().isLoggedIn) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const BMLoginPage()),
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    setState(() => _isSubscribed = !_isSubscribed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSubscribed ? '已订阅' : '已取消订阅',
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
            _buildScoreboard(),
            Expanded(child: _buildIncidentsTab()),
          ],
        ),
      ),
    );
  }

  // =========== UI: 顶部导航栏 ===========
  Widget _buildNavBar() {
    final leagueName = widget.match.leagueName.isNotEmpty
        ? widget.match.leagueName
        : 'Basketball';
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
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: BMColors.bright.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: BMColors.bright.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BMColors.bright,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
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

  // =========== UI: 比分板 Scoreboard ===========
  Widget _buildScoreboard() {
    final homeName = widget.match.homeTeamName.isNotEmpty
        ? widget.match.homeTeamName
        : 'Home';
    final awayName = widget.match.awayTeamName.isNotEmpty
        ? widget.match.awayTeamName
        : 'Away';
    final statusLabel = widget.match.displayStatusLabel;
    final isLive = widget.match.status == BMMatchStatus.live;
    final kickoff = widget.match.kickoffText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF153B2F), Color(0xFF0B251C)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: BMColors.accent.withValues(alpha: 0.1),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isLive
                    ? BMColors.bright.withValues(alpha: 0.14)
                    : BMColors.pitch850,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isLive
                      ? BMColors.bright.withValues(alpha: 0.7)
                      : BMColors.pitch700,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLive)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                        color: BMColors.bright,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isLive ? BMColors.bright : BMColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamLogo(widget.match.homeTeamLogo, true),
                      const SizedBox(height: 8),
                      Text(
                        homeName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BMColors.bright,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      Text(
                        kickoff.isNotEmpty ? kickoff : 'VS',
                        style: const TextStyle(
                          color: BMColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _homeTotal == null ? '-' : _homeTotal.toString(),
                            style: const TextStyle(
                              color: BMColors.bright,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              ':',
                              style: TextStyle(
                                color: BMColors.textTertiary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _awayTotal == null ? '-' : _awayTotal.toString(),
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamLogo(widget.match.awayTeamLogo, false),
                      const SizedBox(height: 8),
                      Text(
                        awayName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

  Widget _buildTeamLogo(String? url, bool isHome) {
    final placeholderColor =
        isHome ? BMColors.bright.withValues(alpha: 0.25) : const Color(0x253B82F6);
    final iconColor = isHome ? BMColors.bright : const Color(0xFF3B82F6);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: placeholderColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: (url == null || url.isEmpty)
            ? Icon(Icons.sports_basketball, size: 24, color: iconColor)
            : Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.sports_basketball, size: 24, color: iconColor),
              ),
      ),
    );
  }

  // =========== UI: 单Tab 事件列表 ===========
  Widget _buildIncidentsTab() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 14,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: BMColors.bright,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Text(
                  '事件',
                  style: TextStyle(
                    color: BMColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildIncidentsList()),
        ],
      ),
    );
  }

  Widget _buildIncidentsList() {
    if (_loadingIncidents) {
      return const Center(
        child: CircularProgressIndicator(color: BMColors.bright, strokeWidth: 2),
      );
    }
    if (_incidents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Text('暂无比赛事件',
              style: TextStyle(color: BMColors.textTertiary, fontSize: 12)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _incidents.length,
      itemBuilder: (ctx, idx) {
        final inc = _incidents[idx];
        final isHome = inc.side == BMIncidentSide.home;
        final sideColor = isHome ? BMColors.bright : const Color(0xFF3B82F6);
        final minText = inc.minute == null
            ? ''
            : (inc.addedTime == null
                ? "${inc.minute}'"
                : "${inc.minute}' +${inc.addedTime}'");
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: BMColors.pitch850,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sideColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sideColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  minText,
                  style: TextStyle(
                    color: sideColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_incidentIcon(inc.type), size: 14, color: sideColor),
                        const SizedBox(width: 5),
                        Text(
                          _incidentTitle(inc.type),
                          style: TextStyle(
                            color: sideColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (inc.playerName != null && inc.playerName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          inc.playerName!,
                          style: const TextStyle(
                            color: BMColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (inc.subPlayerName != null && inc.subPlayerName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '↳ ${inc.subPlayerName}',
                          style: const TextStyle(
                            color: BMColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (inc.detail != null && inc.detail!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          inc.detail!,
                          style: const TextStyle(
                            color: BMColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _incidentIcon(BMIncidentType t) {
    switch (t) {
      case BMIncidentType.goal:
      case BMIncidentType.penalty:
        return Icons.sports_basketball;
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

  String _incidentTitle(BMIncidentType t) {
    switch (t) {
      case BMIncidentType.goal:
        return '得分';
      case BMIncidentType.penalty:
        return '罚球';
      case BMIncidentType.ownGoal:
        return '乌龙';
      case BMIncidentType.yellowCard:
        return '黄牌';
      case BMIncidentType.redCard:
        return '红牌';
      case BMIncidentType.secondYellow:
        return '两黄变红';
      case BMIncidentType.substitution:
        return '换人';
      case BMIncidentType.injuryTime:
        return '暂停';
      case BMIncidentType.whistle:
        return '哨响';
      default:
        return '事件';
    }
  }
}
