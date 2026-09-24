import 'package:flutter/material.dart';

import '../../models/bm_match_model.dart';
import '../../models/bm_basketball_quarter_model.dart';
import '../../theme/bm_colors.dart';
import '../../widgets/match/bm_basketball_flow_chart_painter.dart';

/// BMBasketballOverviewTab - 篮球详情页「总览」Tab
/// 对齐 basketball_match_detail.html TAB 1: OVERVIEW 效果
///   1. 本场 MVP 对决卡 (Leaders): 主客队最佳球员 3 项数据对比
///   2. 比赛走势与分差矩阵: 各节累计分差柱状图 (Chart.js line 的 Flutter 简化实现)
///   3. 关键技术统计对比: 双向对比条 (数据来自详情接口 stats, 无数据时展示分节得分对比)
/// 架构: StatelessWidget, 单类单文件
class BMBasketballOverviewTab extends StatelessWidget {
  /// 比赛模型 (BMMatchModel 类型)
  final BMMatchModel match;

  /// 分节比分矩阵 (BMBasketballQuarterScore 类型, 走势图数据源)
  final BMBasketballQuarterScore quarters;

  /// 详情接口原始 data (Map<String,dynamic>? 类型, stats/leaders 兜底)
  final Map<String, dynamic>? detailData;

  /// 篮球技术统计 (List<Map<String,dynamic>> 类型, process 接口 data.stats, [{type,home,away,name}])
  final List<Map<String, dynamic>> processStats;

  /// 数据加载中 (bool 类型)
  final bool loading;

  const BMBasketballOverviewTab({
    super.key,
    required this.match,
    required this.quarters,
    this.detailData,
    this.processStats = const [],
    this.loading = false,
  });

  // =========== UI: 整体布局 (用户要求: 删除本场 MVP 对决模块) ===========
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGameFlowCard(),
        const SizedBox(height: 12),
        _buildStatsCompareCard(),
      ],
    );
  }

  // =========== 1. 比赛走势与分差矩阵 (Game Flow, html: Chart.js gameFlowChart) ===========
  Widget _buildGameFlowCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart, size: 13, color: BMColors.bright),
                  SizedBox(width: 5),
                  Text(
                    '比赛走势与分差矩阵',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BMColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Text(
                '全场比分变动',
                style: TextStyle(fontSize: 10, color: BMColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFlowChart(),
        ],
      ),
    );
  }

  /// 分差走势折线图 (对齐 html: <canvas id="gameFlowChart"> 双曲线分差)
  /// 数据: home_scores/away_scores 各节累计分差, 主队亮绿带点 / 客队蓝无点
  Widget _buildFlowChart() {
    if (!quarters.hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '暂无各节比分数据',
            style: TextStyle(color: BMColors.textTertiary, fontSize: 11),
          ),
        ),
      );
    }
    const homeColor = BMColors.bright;
    const awayColor = Color(0xFF3B82F6);
    // 各节累计分差序列 (html: data: [0, -2, 3, 5, 2, -1, 2, 4] 同构)
    final homeDiffs = _cumulativeDiffs(isHome: true);
    final awayDiffs = homeDiffs.map((d) => -d).toList();
    final labels = _flowLabels();
    return Column(
      children: [
        // 图表画布 (html: h-40)
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(
            painter: BMBasketballFlowChartPainter(
              homeDiffs: homeDiffs,
              awayDiffs: awayDiffs,
              homeColor: homeColor,
              awayColor: awayColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // 底部节标签 (html: Q1 Q2 Q3 Q4(当前), 最后一节主题色高亮)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(labels.length, (i) {
              final isLast = i == labels.length - 1;
              return Text(
                labels[i],
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: isLast ? FontWeight.w800 : FontWeight.w500,
                  color: isLast ? BMColors.bright : BMColors.textTertiary,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        // 图例 (html legend 不显示, 自定义色块+队名)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _flowLegend(homeColor, match.homeTeamName),
            const SizedBox(width: 14),
            _flowLegend(awayColor, match.awayTeamName),
          ],
        ),
      ],
    );
  }

  /// 计算单侧各节累计分差序列
  /// [isHome] - 是否主队 (bool 类型)
  /// 返回: List<int> 例: home 23,21 vs away 18,25 → [5, 1]
  List<int> _cumulativeDiffs({required bool isHome}) {
    final mine = isHome ? quarters.homeQuarters : quarters.awayQuarters;
    final other = isHome ? quarters.awayQuarters : quarters.homeQuarters;
    final n = mine.length > other.length ? mine.length : other.length;
    int accMine = 0;
    int accOther = 0;
    final result = <int>[];
    for (int i = 0; i < n; i++) {
      accMine += i < mine.length ? mine[i] : 0;
      accOther += i < other.length ? other[i] : 0;
      result.add(accMine - accOther);
    }
    return result;
  }

  /// 走势图底部节标签列表 (String 类型, Q1..Q4 + OT, 尾节显示 "Q4 (当前)")
  List<String> _flowLabels() {
    final labels = quarters.quarterLabels;
    if (labels.isEmpty) return const [];
    final last = labels.length - 1;
    return [
      for (int i = 0; i < labels.length; i++)
        i == last ? '${labels[i]} (当前)' : labels[i],
    ];
  }

  /// 走势图图例 (色块 + 队名)
  Widget _flowLegend(Color color, String name) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          name,
          style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.95)),
        ),
      ],
    );
  }

  // =========== 3. 关键技术统计对比 (Stat Bars) ===========
  Widget _buildStatsCompareCard() {
    final statRows = _readStatRows();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x33244739), width: 0.6)),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune, size: 13, color: BMColors.bright),
                SizedBox(width: 5),
                Text(
                  '关键技术统计对比',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: BMColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (statRows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '暂无技术统计数据',
                  style: TextStyle(color: BMColors.textTertiary, fontSize: 11),
                ),
              ),
            )
          else
            ...statRows.map((r) => _buildStatBar(r)),
        ],
      ),
    );
  }

  /// 读取技术统计行 (优先级: process 接口 stats > 详情 data.stats)
  /// process 接口: GET /api/livespeed/basketball/match/process -> data.stats [{type,home,away,name}]
  /// 返回: List<_StatPair> (主值/标签/客值)
  List<_StatPair> _readStatRows() {
    final rows = <_StatPair>[];
    // 1. 优先: process 接口 stats
    for (final s in processStats) {
      final name = s['name'];
      if (name == null || name.toString().isEmpty) continue;
      rows.add(_StatPair(
        home: _statValueText(s['home']),
        label: name.toString(),
        away: _statValueText(s['away']),
      ));
    }
    // 2. 兜底: 详情 data 里的 stats
    if (rows.isEmpty && detailData != null) {
      final rawStats = detailData!['stats'] ?? detailData!['statistics'];
      if (rawStats is List) {
        for (final s in rawStats) {
          if (s is Map) {
            final label = s['label'] ?? s['name'];
            if (label == null) continue;
            rows.add(_StatPair(
              home: _statValueText(s['home']),
              label: label.toString(),
              away: _statValueText(s['away']),
            ));
          }
        }
      }
    }
    return rows;
  }

  /// 统计数值转展示文本 (null→'-', num→去小数点尾零)
  /// [v] - 原始值 (dynamic 类型, num/String/null)
  /// 返回: String 展示文本
  String _statValueText(dynamic v) {
    if (v == null) return '-';
    if (v is num) {
      return v.toInt() == v ? v.toInt().toString() : v.toString();
    }
    final s = v.toString();
    return s.isEmpty ? '-' : s;
  }

  /// 单条双向对比条 (html: Stat Bar, 主左亮绿 客右蓝)
  /// [row] - 统计项 (StatPair 类型)
  Widget _buildStatBar(_StatPair row) {
    final homeNum = double.tryParse(row.home);
    final awayNum = double.tryParse(row.away);
    // 主客占比 (数值非法时 50:50)
    double homeRatio = 0.5;
    if (homeNum != null && awayNum != null) {
      final sum = homeNum + awayNum;
      homeRatio = sum > 0 ? homeNum / sum : 0.5;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                row.home,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  color: BMColors.bright,
                ),
              ),
              Text(
                row.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: BMColors.textSecondary,
                ),
              ),
              Text(
                row.away,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: (homeRatio * 1000).round().clamp(1, 999),
                  child: Container(
                    decoration: BoxDecoration(
                      color: BMColors.bright.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - homeRatio) * 1000).round().clamp(1, 999),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
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
}

/// _StatPair - 单条统计对比项 (私有辅助类)
class _StatPair {
  /// 主队数值 (String 类型)
  final String home;

  /// 统计标签 (String 类型, 例: '投篮命中率')
  final String label;

  /// 客队数值 (String 类型)
  final String away;

  _StatPair({required this.home, required this.label, required this.away});
}
