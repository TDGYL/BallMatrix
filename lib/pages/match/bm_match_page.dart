import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../viewmodels/home/bm_home_view_model.dart';
import '../../models/bm_match_model.dart';

/// BMMatchPage - 赛事列表页
/// 功能: 按联赛分组展示比赛列表, 支持状态过滤
/// 架构: MVVM View层, 复用 BMHomeViewModel 中的比赛数据
/// 跳转入口: 首页View All按钮 / 底部导航赛事Tab
class BMMatchPage extends BMBasePage {
  /// 首页ViewModel (BMHomeViewModel 类型, 提供比赛数据)
  final BMHomeViewModel viewModel;

  /// 是否从首页push进入 (bool 类型, 控制是否显示返回按钮)
  final bool isPushed;

  const BMMatchPage({
    super.key,
    required this.viewModel,
    this.isPushed = false,
  });

  @override
  State<BMMatchPage> createState() => _BMMatchPageState();
}

class _BMMatchPageState extends BMBasePageState<BMMatchPage> {
  /// 当前足球/篮球切换 (bool 类型, true=足球)
  bool _isFootball = true;

  /// 当前过滤状态 (String 类型, 'all' / 'live' / 'upcoming' / 'ended')
  String _filterStatus = 'all';

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        _buildStatusFilter(),
        _buildDatePicker(),
        Expanded(child: _buildMatchList()),
      ],
    );
  }

  /// 构建顶部标题栏
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.isPushed)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios, size: 18, color: BMColors.textPrimary),
            ),
          const Text(
            '赛程与历史数据库',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BMColors.textPrimary),
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
          _buildToggleBtn('足球', _isFootball, () => setState(() => _isFootball = true)),
          _buildToggleBtn('篮球', !_isFootball, () => setState(() => _isFootball = false)),
        ],
      ),
    );
  }

  /// 构建切换按钮
  /// 参数: [label] 文本, [selected] 是否选中, [onTap] 点击回调
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

  /// 构建状态过滤器
  Widget _buildStatusFilter() {
    final filters = [
      ('all', '全部 (24)'),
      ('live', '进行中 (5)'),
      ('upcoming', '即将开赛 (12)'),
      ('ended', '完场复盘 (7)'),
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filterStatus == filter.$1;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = filter.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? BMColors.pitch800 : BMColors.pitch950,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? BMColors.accent.withValues(alpha: 0.3) : BMColors.pitch800,
                ),
              ),
              child: Center(
                child: Text(
                  filter.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  /// 构建日期选择条
  Widget _buildDatePicker() {
    final dates = [
      ('昨天', '04-18', false),
      ('今天', '04-19', true),
      ('明天', '04-20', false),
      ('周日', '04-21', false),
      ('周一', '04-22', false),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BMColors.pitch850.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: dates.map((d) => _buildDateItem(d.$1, d.$2, d.$3)).toList(),
      ),
    );
  }

  /// 构建日期项
  /// 参数: [day] 星期, [date] 日期, [isSelected] 是否选中
  Widget _buildDateItem(String day, String date, bool isSelected) {
    return Container(
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
    );
  }

  /// 构建比赛列表
  Widget _buildMatchList() {
    final List<BMMatchModel> matches = widget.viewModel.matchList;
    // 按联赛分组
    final Map<String, List<BMMatchModel>> grouped = {};
    for (final match in matches) {
      grouped.putIfAbsent(match.leagueName, () => []).add(match);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: grouped.entries.map((entry) => _buildLeagueGroup(entry.key, entry.value)).toList(),
    );
  }

  /// 构建联赛分组
  /// 参数: [leagueName] 联赛名, [matches] 比赛列表
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
                    const Icon(Icons.emoji_events, size: 14, color: BMColors.amber),
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
                  style: const TextStyle(fontSize: 12, color: BMColors.textSecondary),
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

  /// 构建单行比赛
  /// 参数: [match] 比赛数据
  Widget _buildMatchRow(BMMatchModel match) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xD9143328), Color(0xF00E261E)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch600.withValues(alpha: 0.4)),
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
    );
  }

  /// 构建比赛时间
  /// 参数: [match] 比赛数据
  Widget _buildMatchTime(BMMatchModel match) {
    final bool isLive = match.status == BMMatchStatus.live;
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          if (isLive) ...[
            const Text(
              "68'",
              style: TextStyle(
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
              match.status == BMMatchStatus.upcoming ? '未开赛' : match.round,
              style: const TextStyle(fontSize: 9, color: BMColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建比赛队伍比分
  /// 参数: [match] 比赛数据
  Widget _buildMatchTeams(BMMatchModel match) {
    return Column(
      children: [
        _buildTeamScoreRow(match.homeTeamName, match.homeScore, match.status == BMMatchStatus.live),
        const SizedBox(height: 4),
        _buildTeamScoreRow(match.awayTeamName, match.awayScore, false),
      ],
    );
  }

  /// 构建单行队伍比分
  Widget _buildTeamScoreRow(String name, int? score, bool highlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: highlight ? BMColors.textPrimary : BMColors.textSecondary,
          ),
        ),
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

  /// 构建比赛附加信息
  /// 参数: [match] 比赛数据
  Widget _buildMatchExtra(BMMatchModel match) {
    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (match.status == BMMatchStatus.live) ...[
            Text(
              '胜率 ${match.aiWinRate.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: BMColors.amber,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '角球 6-4',
              style: TextStyle(fontSize: 10, color: BMColors.textSecondary),
            ),
          ] else if (match.status == BMMatchStatus.upcoming) ...[
            const Text(
              '平半盘',
              style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: BMColors.textSecondary),
            ),
            const SizedBox(height: 2),
            const Text(
              'AI指数预警',
              style: TextStyle(fontSize: 10, color: BMColors.bright),
            ),
          ] else ...[
            const Text(
              '大分命中',
              style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: BMColors.bright),
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