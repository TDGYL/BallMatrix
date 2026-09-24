import 'package:flutter/material.dart';

import '../../models/bm_basketball_live_model.dart';
import '../../models/bm_basketball_vote_model.dart';
import '../../services/bm_match_detail_api_service.dart';
import '../../theme/bm_colors.dart';
import '../../utils/bm_auth_manager.dart';
import '../login/bm_login_page.dart';

/// BMBasketballLiveTab - 篮球详情页「实况」Tab
/// 数据源: GET /api/livespeed/basketball/match/process -> data.tlive
///   [{ period_name: 'Q1', tlives: [{ time, score, event, position }] }]
///   position: 0=中立 1=主队 2=客队
/// 对齐 basketball_match_detail.html TAB 2: PLAY-BY-PLAY 效果:
///   1. 事件筛选 Chips: 全部事件 / 仅得分 / 犯规暂停 (本地过滤)
///   2. 按节分组时间线: 节标题 + 事件卡 (左时间等宽 + 轴点 + 左边框主客色 + 事件描述 + 实时比分)
///   3. 投票比例模块: GET api/livespeed/basketball/match/vote-info
///      主客双向比例条 + 投票数 + 点击主/客投票按钮 (vote_status 高亮已投侧)
/// 架构: StatefulWidget (内部维护筛选/投票状态), 单类单文件
class BMBasketballLiveTab extends StatefulWidget {
  /// 按节实况分组 (List<BMBasketballLivePeriod> 类型, process 接口 data.tlive)
  final List<BMBasketballLivePeriod> periods;

  /// 主队名 (String 类型, 图例展示)
  final String homeName;

  /// 客队名 (String 类型)
  final String awayName;

  /// 篮球比赛ID (int 类型, 投票接口参数, 0 则不请求)
  final int matchId;

  /// 比赛状态ID (int? 类型, 投票前置校验: 1|13 未开始可投, 其他状态 toast 提示)
  final int? statusId;

  /// 数据加载中 (bool 类型)
  final bool loading;

  const BMBasketballLiveTab({
    super.key,
    required this.periods,
    required this.homeName,
    required this.awayName,
    this.matchId = 0,
    this.statusId,
    this.loading = false,
  });

  @override
  State<BMBasketballLiveTab> createState() => _BMBasketballLiveTabState();
}

class _BMBasketballLiveTabState extends State<BMBasketballLiveTab> {
  /// API Service 单例 (投票接口服务)
  final BMMatchDetailApiService _apiService = BMMatchDetailApiService();

  /// 筛选索引 (int 类型, 0=全部 1=仅得分 2=犯规/暂停)
  int _filterIndex = 0;

  /// 投票信息 (BMBasketballVoteInfo? 类型, null=未加载/失败)
  BMBasketballVoteInfo? _voteInfo;

  /// 投票加载中 (bool 类型)
  bool _voteLoading = true;

  /// 筛选标签 (List<String> 类型, 对齐 html: 全部事件/仅得分/三分球/犯规暂停)
  static const List<String> _filterLabels = ['全部事件', '仅得分', '犯规/暂停'];

  /// 主队主题色 (Color 类型, 亮绿)
  static const Color _homeColor = BMColors.bright;

  /// 客队主题色 (Color 类型, 蓝)
  static const Color _awayColor = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _fetchVoteInfo();
  }

  /// 获取投票信息 (GET api/livespeed/basketball/match/vote-info)
  /// 主客投票数 + 当前用户投票状态 (0=未投 1=主 2=客)
  Future<void> _fetchVoteInfo() async {
    if (widget.matchId <= 0) {
      setState(() => _voteLoading = false);
      return;
    }
    final info =
        await _apiService.fetchBasketballVoteInfo(matchId: widget.matchId);
    if (!mounted) return;
    setState(() {
      _voteInfo = info;
      _voteLoading = false;
    });
  }

  // =========== UI: 整体布局 ===========
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPeriods();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- 第 1 段: 事件筛选 + 按节时间线 ----
        _buildFilterChips(),
        const SizedBox(height: 12),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: BMColors.bright, strokeWidth: 2),
              ),
            ),
          )
        else if (filtered.isEmpty)
          _buildEmpty()
        else
          ...filtered.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildPeriodSection(p),
              )),
        const SizedBox(height: 6),
        // ---- 第 2 段: 主客投票比例模块 (vote-info 接口) ----
        _buildVoteCard(),
      ],
    );
  }

  /// 按筛选条件过滤各节事件
  /// 返回: List<BMBasketballLivePeriod> 过滤后的节列表 (空节剔除)
  List<BMBasketballLivePeriod> _filteredPeriods() {
    final result = <BMBasketballLivePeriod>[];
    for (final p in widget.periods) {
      List<BMBasketballLiveEvent> events;
      switch (_filterIndex) {
        case 1: // 仅得分
          events = p.events.where((e) => e.isScoreEvent).toList();
          break;
        case 2: // 犯规/暂停
          events = p.events
              .where((e) => _isFoulEvent(e.event))
              .toList();
          break;
        default:
          events = p.events;
      }
      if (events.isNotEmpty) {
        result.add(BMBasketballLivePeriod(periodName: p.periodName, events: events));
      }
    }
    return result;
  }

  /// 事件描述是否犯规/暂停类 (bool 类型)
  /// [text] - 事件描述 (String 类型)
  bool _isFoulEvent(String text) {
    return text.contains('犯规') ||
        text.contains('暂停') ||
        text.contains('失误') ||
        text.contains('违例') ||
        text.contains('争球') ||
        text.contains('技术犯规');
  }

  // =========== 1. 事件筛选 Chips ===========
  Widget _buildFilterChips() {
    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(_filterLabels.length, (i) {
          final selected = _filterIndex == i;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _filterIndex = i),
            child: Container(
              margin: EdgeInsets.only(right: i == _filterLabels.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? BMColors.bright : BMColors.pitch900.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? BMColors.bright
                      : BMColors.pitch800.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                _filterLabels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? BMColors.pitch950 : BMColors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // =========== 2. 单节区块 (节标题 + 该节时间线) ===========
  /// [period] - 节分组 (BMBasketballLivePeriod 类型)
  Widget _buildPeriodSection(BMBasketballLivePeriod period) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 节标题胶囊 (Q1 / 第1节)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: BMColors.pitch900.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.7)),
          ),
          child: Text(
            period.periodName.isNotEmpty ? period.periodName : '节',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: BMColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 该节时间线 (倒序: 最新在前)
        ...period.events.reversed.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTimelineItem(e),
            )),
      ],
    );
  }

  // =========== 3. 单条时间线事件 (html: Event item) ===========
  /// [e] - 实况事件 (BMBasketballLiveEvent 类型)
  Widget _buildTimelineItem(BMBasketballLiveEvent e) {
    // 主客中立配色 (html: amber-400 主 / purple-500 客 / slate-600 中立)
    final sideColor = e.isNeutral
        ? BMColors.textTertiary
        : (e.isHome ? _homeColor : _awayColor);
    final isScore = e.isScoreEvent;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左侧时间 (html: w-12 text-cyan-400 font-mono)
          SizedBox(
            width: 44,
            child: Text(
              e.time.isNotEmpty ? e.time : '--:--',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: isScore ? FontWeight.w800 : FontWeight.w600,
                color: isScore ? BMColors.bright : BMColors.textTertiary,
              ),
            ),
          ),
          // 中间时间轴圆点 + 竖线
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sideColor,
                    border: Border.all(color: BMColors.pitch950, width: 2),
                    boxShadow: isScore
                        ? [BoxShadow(color: sideColor.withValues(alpha: 0.5), blurRadius: 5)]
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: BMColors.pitch800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // 右侧事件卡 (html: glass-panel p-2.5 rounded-xl border-l-2)
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: BMColors.pitch900.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: e.isNeutral
                    ? Border.all(color: BMColors.pitch800.withValues(alpha: 0.5))
                    : Border(
                        top: BorderSide(color: BMColors.pitch800.withValues(alpha: 0.5)),
                        bottom: BorderSide(color: BMColors.pitch800.withValues(alpha: 0.5)),
                        right: BorderSide(color: BMColors.pitch800.withValues(alpha: 0.5)),
                        left: BorderSide(color: sideColor, width: 2),
                      ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 事件描述 (html: font-bold text-amber-400)
                  Expanded(
                    child: Text(
                      e.event.isNotEmpty ? e.event : '比赛事件',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: e.isNeutral ? BMColors.textSecondary : sideColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                  // 实时比分 (html: font-mono font-bold text-cyan-400)
                  if (e.score.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      e.score,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: isScore ? sideColor : BMColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 空态
  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.6)),
      ),
      child: const Column(
        children: [
          Icon(Icons.sports_basketball, size: 32, color: BMColors.textTertiary),
          SizedBox(height: 10),
          Text(
            '暂无比赛实况',
            style: TextStyle(color: BMColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // =========== 4. 投票比例模块 (GET vote-info: home_votes/away_votes/vote_status) ===========
  Widget _buildVoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.7)),
      ),
      child: _voteLoading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(color: BMColors.bright, strokeWidth: 2),
              ),
            )
          : _buildVoteContent(),
    );
  }

  /// 投票模块内容态 (标题 + 比例条 + 两队投票按钮)
  Widget _buildVoteContent() {
    final info = _voteInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行: 本场支持率 + 总投票数
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.how_to_vote, size: 13, color: BMColors.bright),
                SizedBox(width: 5),
                Text(
                  '本场支持率',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: BMColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              '${info?.totalVotes ?? 0} 人参与',
              style: const TextStyle(
                fontSize: 10,
                color: BMColors.textTertiary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // 主客双向比例条 (左主队亮绿 右客队蓝)
        _buildVoteBar(info),
        const SizedBox(height: 8),
        // 百分比行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              info?.homePercentLabel ?? '--',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: _homeColor,
              ),
            ),
            Text(
              info?.awayPercentLabel ?? '--',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: _awayColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 两队投票按钮行
        Row(
          children: [
            Expanded(
              child: _buildVoteButton(
                label: widget.homeName,
                votes: info?.homeVotes ?? 0,
                color: _homeColor,
                voted: info?.votedHome ?? false,
                dimmed: info != null && info.votedAway,
                onTap: () => _onVote(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildVoteButton(
                label: widget.awayName,
                votes: info?.awayVotes ?? 0,
                color: _awayColor,
                voted: info?.votedAway ?? false,
                dimmed: info != null && info.votedHome,
                onTap: () => _onVote(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 双向比例条 (左主队 / 右客队, 两侧圆角)
  /// [info] - 投票信息 (BMBasketballVoteInfo? 类型)
  Widget _buildVoteBar(BMBasketballVoteInfo? info) {
    final homePct = info?.homePercent ?? 0.5;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            // 主队段
            Expanded(
              flex: (homePct * 1000).clamp(1, 999).round(),
              child: Container(color: _homeColor),
            ),
            // 客队段
            Expanded(
              flex: ((1 - homePct) * 1000).clamp(1, 999).round(),
              child: Container(color: _awayColor),
            ),
          ],
        ),
      ),
    );
  }

  /// 单侧投票按钮 (点击投票, 已投侧高亮描边, 未投侧点击有效)
  /// [label] - 队名 (String 类型)
  /// [votes] - 投票数 (int 类型)
  /// [color] - 侧色 (Color 类型)
  /// [voted] - 用户是否已投该侧 (bool 类型)
  /// [dimmed] - 是否已投对侧 (bool 类型, 置灰)
  /// [onTap] - 点击回调 (VoidCallback? 类型)
  Widget _buildVoteButton({
    required String label,
    required int votes,
    required Color color,
    required bool voted,
    required bool dimmed,
    VoidCallback? onTap,
  }) {
    final canVote = !dimmed; // 已投对侧则本侧禁点
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canVote ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: voted ? color.withValues(alpha: 0.18) : BMColors.pitch950.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: voted ? color : BMColors.pitch800.withValues(alpha: 0.7),
            width: voted ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: dimmed && !voted ? BMColors.textTertiary : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  voted ? Icons.check_circle : Icons.how_to_vote,
                  size: 10,
                  color: voted ? color : BMColors.textTertiary,
                ),
                const SizedBox(width: 3),
                Text(
                  '$votes',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: voted ? color : BMColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 点击投票 (vote_status=0 时可点)
  /// 链路: 先校验比赛状态(未开始可投) → 未登录跳登录页 → POST /api/livespeed/basketball/match/vote → 成功重新拉取 vote-info 刷新比例图
  /// [side] - 投票侧 (int 类型, 1=主队 2=客队)
  Future<void> _onVote(int side) async {
    // 0. 前置校验: 只有未开始的比赛才可以投票 (篮球规则 statusId=1|13)
    final sid = widget.statusId;
    if (sid != null && sid != 1 && sid != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('比赛已开始, 无法投票'), duration: Duration(seconds: 2)),
      );
      return;
    }
    final info = _voteInfo;
    if (info == null || info.voteStatus != 0) return; // 已投过则不再投
    // 1. 未登录先去登录, 登录成功继续投票
    if (!BMAuthManager().isLoggedIn) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const BMLoginPage()),
      );
      if (ok != true) return;
    }
    // 2. 提交投票
    final okVote = await _apiService.submitBasketballVote(
      matchId: widget.matchId,
      team: side,
    );
    if (!mounted) return;
    if (!okVote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投票失败, 请重试'), duration: Duration(seconds: 2)),
      );
      return;
    }
    // 3. 成功后重新拉取投票数据刷新比例图
    setState(() => _voteLoading = true);
    await _fetchVoteInfo();
  }
}
