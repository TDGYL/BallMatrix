import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_match_model.dart';
import '../../viewmodels/home/bm_home_view_model.dart' show BMSportType;

/// BMMatchTabPage - 底部导航 赛事 Tab 页
/// 功能: 足球/篮球切换 + 状态过滤 + 日期条 + 按联赛分组比赛列表
/// 作用范围: 底部导航 index=1, 与首页push进来的BMMatchPage(单运动列表)区分
class BMMatchTabPage extends BMBasePage {
  const BMMatchTabPage({super.key});

  @override
  State<BMMatchTabPage> createState() => _BMMatchTabPageState();
}

class _BMMatchTabPageState extends BMBasePageState<BMMatchTabPage> {
  /// 当前运动类型 (BMSportType 枚举, 默认足球)
  BMSportType _currentSport = BMSportType.football;

  /// 当前过滤状态 (String 类型, 'all' / 'live' / 'upcoming' / 'ended')
  String _filterStatus = 'all';

  /// 当前选中快捷日期索引 (int 类型, 默认1=今天)
  int _selectedDateIndex = 1;

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
          _buildToggleBtn('足球', _currentSport == BMSportType.football, () {
            setState(() => _currentSport = BMSportType.football);
          }),
          _buildToggleBtn('篮球', _currentSport == BMSportType.basketball, () {
            setState(() => _currentSport = BMSportType.basketball);
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
      ('昨天', '04-18'),
      ('今天', '04-19'),
      ('明天', '04-20'),
      ('周日', '04-21'),
      ('周一', '04-22'),
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
        children: dates.asMap().entries.map((entry) {
          final idx = entry.key;
          final d = entry.value;
          final isSelected = _selectedDateIndex == idx;
          return _buildDateItem(d.$1, d.$2, isSelected, () {
            setState(() => _selectedDateIndex = idx);
          });
        }).toList(),
      ),
    );
  }

  /// 构建日期项
  Widget _buildDateItem(String day, String date, bool isSelected, VoidCallback onTap) {
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
                color: isSelected ? BMColors.pitch950 : BMColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建比赛列表 (Mock数据)
  Widget _buildMatchList() {
    final matches = _mockMatchList();
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
  Widget _buildMatchTime(BMMatchModel match) {
    final bool isLive = match.status == BMMatchStatus.live;
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          if (isLive) ...[
            Text(
              (match.liveMinute != null && match.liveMinute!.isNotEmpty) ? match.liveMinute! : "68'",
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
              match.status == BMMatchStatus.upcoming ? '未开赛' : match.round,
              style: const TextStyle(fontSize: 9, color: BMColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建比赛队伍比分
  Widget _buildMatchTeams(BMMatchModel match) {
    return Column(
      children: [
        _buildTeamScoreRow(match.homeTeamName, match.homeScore ?? 0, match.status == BMMatchStatus.live),
        const SizedBox(height: 4),
        _buildTeamScoreRow(match.awayTeamName, match.awayScore ?? 0, false),
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

  /// Mock比赛列表数据
  List<BMMatchModel> _mockMatchList() {
    return [
      BMMatchModel(
        matchId: '1',
        leagueName: '英超联赛',
        leagueColor: 0xFF3B82F6,
        homeTeamName: '曼城',
        awayTeamName: '阿森纳',
        homeScore: 2,
        awayScore: 1,
        status: BMMatchStatus.live,
        statusId: 2,
        statusName: '下半场',
        matchTime: "68'",
        round: 'Round 32',
        liveMinute: "68'",
      ),
      BMMatchModel(
        matchId: '2',
        leagueName: '英超联赛',
        leagueColor: 0xFF3B82F6,
        homeTeamName: '利物浦',
        awayTeamName: '切尔西',
        homeScore: 0,
        awayScore: 0,
        status: BMMatchStatus.upcoming,
        statusId: 1,
        statusName: '未开始',
        matchTime: '20:30',
        round: 'Round 32',
      ),
      BMMatchModel(
        matchId: '3',
        leagueName: '西甲联赛',
        leagueColor: 0xFFE11D48,
        homeTeamName: '皇家马德里',
        awayTeamName: '巴塞罗那',
        homeScore: 3,
        awayScore: 2,
        status: BMMatchStatus.ended,
        statusId: 8,
        statusName: '已结束',
        matchTime: 'FT',
        round: 'El Clásico',
      ),
      BMMatchModel(
        matchId: '4',
        leagueName: 'NBA 常规赛',
        leagueColor: 0xFFF97316,
        homeTeamName: '湖人',
        awayTeamName: '勇士',
        homeScore: 98,
        awayScore: 102,
        status: BMMatchStatus.live,
        statusId: 4,
        statusName: 'Q3',
        sportType: BMMatchSportType.basketball,
        matchTime: 'Q3 8:42',
        round: 'West Conf',
        liveMinute: 'Q3',
      ),
    ];
  }
}
