import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_odds_model.dart';
import '../../services/bm_match_detail_api_service.dart';

/// BMOddsHistoryPage - indexhistorydetailpage
/// completefullreference hanklive odds_history_page (API GET /api/livespeed/football/match/odd-histories)
/// differentiation UI (vs hanklive purple): dark green pitch900 background + bright greenhomecolor + timecard
class BMOddsHistoryPage extends BMBasePage {
 /// matchID (int type, required)
 final int matchId;
 /// ID (String type, required)
 final String companyId;
 /// name (String? type, topshow)
 final String? companyName;
 /// handicaptype (BMOddsType, show handicap/1X2/sizeball/corner)
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
 /// historydata (BMOddsHistoryData? type)
 BMOddsHistoryData? _history;

 /// loadingstate
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
 return _history?.asia ?? [];
 case BMOddsType.matchResult:
 return _history?.eu ?? [];
 case BMOddsType.overUnder:
 return _history?.bs ?? [];
 case BMOddsType.corners:
 return _history?.cr ?? [];
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
 '${widget.companyName ?? 'oddshistory'} · ${widget.oddsType.shortLabel}',
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
      return const Center(child: Text('No historyodds', style: TextStyle(color: BMColors.textTertiary, fontSize: 12)));
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
                  Expanded(child: _cell(p.detail.home, BMColors.bright)),
                  if (p.detail.handicap != null && p.detail.handicap!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(8)),
                      child: Text(p.detail.handicap!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (showDraw) Expanded(child: _cell(p.detail.draw, BMColors.textSecondary, label: 'D')),
                  Expanded(child: _cell(p.detail.away, const Color(0xFF3B82F6))),
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
