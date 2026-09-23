import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_odds_model.dart';
import '../../services/bm_match_detail_api_service.dart';

/// BMOddsHistoryPage - 指数历史详情页
/// 完全参考 hanklive odds_history_page (API GET /api/livespeed/football/match/odd-histories)
/// 差异化 UI (vs hanklive 紫色): 深绿 pitch900 背景 + 亮绿主色 + 时间轴卡片
class BMOddsHistoryPage extends BMBasePage {
  /// 比赛ID (int 类型, 必传)
  final int matchId;
  /// 博彩公司ID (String 类型, 必传)
  final String companyId;
  /// 博彩公司名 (String? 类型, 顶部展示)
  final String? companyName;
  /// 盘口类型 (BMOddsType, 展示 让球/胜平负/大小球/角球)
  final BMOddsType oddsType;

  const BMOddsHistoryPage({
    super.key,
    required this.matchId,
    required this.companyId,
    this.companyName,
    required this.oddsType,
  });

  @override
  State<BMOddsHistoryPage> createState() => _BMOddsHistoryPageState();
}

class _BMOddsHistoryPageState extends BMBasePageState<BMOddsHistoryPage> {
  /// 历史数据 (BMOddsHistoryData? 类型)
  BMOddsHistoryData? _history;

  /// 加载状态
  bool _loading = true;

  final BMMatchDetailApiService _api = BMMatchDetailApiService();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final d = await _api.fetchOddsHistory(matchId: widget.matchId, companyId: widget.companyId);
    if (!mounted) return;
    setState(() {
      _history = d;
      _loading = false;
    });
  }

  List<BMOddsHistoryPoint> _points() {
    switch (widget.oddsType) {
      case BMOddsType.asianHandicap:
        return _history?.asianHandicap ?? [];
      case BMOddsType.matchResult:
        return _history?.matchResult ?? [];
      case BMOddsType.overUnder:
        return _history?.overUnder ?? [];
      case BMOddsType.corners:
        return _history?.corners ?? [];
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

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
              child: Text(
                '${widget.companyName ?? '赔率历史'} · ${widget.oddsType.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            const SizedBox(width: 34),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(40), child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: BMColors.bright, strokeWidth: 2))));
    }
    final list = _points();
    if (list.isEmpty) {
      return const Center(child: Text('暂无历史赔率', style: TextStyle(color: BMColors.textTertiary, fontSize: 12)));
    }
    final showDraw = widget.oddsType == BMOddsType.matchResult;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final p = list[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: BMColors.pitch850,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: BMColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(_fmt(p.timestamp), style: const TextStyle(fontSize: 11, color: BMColors.textTertiary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _cell(p.home, BMColors.bright)),
                  if (p.handicap != null && p.handicap!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(8)),
                      child: Text(p.handicap!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (showDraw) Expanded(child: _cell(p.draw, BMColors.textSecondary, label: '平')),
                  Expanded(child: _cell(p.away, const Color(0xFF3B82F6))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cell(String? v, Color c, {String? label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          if (label != null) Text(label, style: const TextStyle(fontSize: 9, color: BMColors.textTertiary, fontWeight: FontWeight.w700)),
          if (label != null) const SizedBox(height: 2),
          Text(v ?? '--', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c)),
        ],
      ),
    );
  }

  String _fmt(int? ts) {
    if (ts == null) return '--';
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
