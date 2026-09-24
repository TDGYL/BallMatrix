import 'package:flutter/material.dart';

import '../../models/bm_basketball_live_model.dart';
import '../../models/bm_basketball_vote_model.dart';
import '../../services/bm_match_detail_api_service.dart';
import '../../theme/bm_colors.dart';
import '../../utils/bm_auth_manager.dart';
import '../login/bm_login_page.dart';

/// BMBasketballLiveTab - basketball detailpage「live」Tab
/// data source: GET /api/livespeed/basketball/match/process -> data.tlive
/// [{ period_name: 'Q1', tlives: [{ time, score, event, position }] }]
/// position: 0=ininstantly 1=home team 2=away team
/// alignment basketball_match_detail.html TAB 2: PLAY-BY-PLAY effect:
/// 1. eventfilter Chips: allevent / score only / foulpaused (localfilter)
/// 2. bysectiongrouptimeline: sectiontitle + eventcard (lefttimemonospace + point + leftborderhome/awaycolor + eventdescription + live score)
/// 3. voteratioexamplemodule: GET api/livespeed/basketball/match/vote-info
/// home/awaydoubledirectionratioexampleitems + vote count + taphome/awayvotebutton (vote_status highlightalreadyside)
/// architecture: StatefulWidget (innerpartfilter/vote state), one class per file
class BMBasketballLiveTab extends StatefulWidget {
 /// bysectionlivegroup (List<BMBasketballLivePeriod> type, process API data.tlive)
 final List<BMBasketballLivePeriod> periods;

 /// home teamname (String type, exampleshow)
 final String homeName;

 /// away teamname (String type)
 final String awayName;

 /// basketball match ID (int type, voteAPIargument, 0 thennotrequest)
 final int matchId;

 /// matchstateID (int? type, votefirstplacevalidate: 1|13 NScan, othersstate toast toast)
 final int? statusId;

 /// dataloadingin (bool type)
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
 /// API Service singleton (voteAPIservice)
 final BMMatchDetailApiService _apiService = BMMatchDetailApiService();

 /// filterindex (int type, 0=all 1=score only 2=foul/paused)
 int _filterIndex = 0;

 /// vote info (BMBasketballVoteInfo? type, null=not yetloading/failure)
 BMBasketballVoteInfo? _voteInfo;

 /// voteloadingin (bool type)
 bool _voteLoading = true;

 /// filtertag (List<String> type, alignment html: allevent/score only/threeminball/foulpaused)
 static const List<String> _filterLabels = ['allevent', 'score only', 'foul/paused'];

 /// home teamaccent color (Color type, bright green)
 static const Color _homeColor = BMColors.bright;

 /// away teamaccent color (Color type, blue)
 static const Color _awayColor = Color(0xFF3B82F6);

 @override
 void initState() {
 super.initState();
 _fetchVoteInfo();
 }

 /// gettakevote info (GET api/livespeed/basketball/match/vote-info)
 /// home/awayvote count + currentuservote state (0=not voted 1=home 2=away)
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

 // =========== UI: wholelayout ===========
 @override
 Widget build(BuildContext context) {
 final filtered = _filteredPeriods();
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // ---- No. 1 section: eventfilter + bysectiontimeline ----
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
 // ---- No. 2 section: home/awayvoteratioexamplemodule (vote-info API) ----
 _buildVoteCard(),
 ],
);
 }

 /// byfilterconditionfiltereachsectionevent
 /// returns: List<BMBasketballLivePeriod> filterlater of sectionlist (emptysectiondiv)
 List<BMBasketballLivePeriod> _filteredPeriods() {
 final result = <BMBasketballLivePeriod>[];
 for (final p in widget.periods) {
 List<BMBasketballLiveEvent> events;
 switch (_filterIndex) {
 case 1: // score only
 events = p.events.where((e) => e.isScoreEvent).toList();
 break;
 case 2: // foul/paused
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

 /// eventdescriptionwhetherfoul/pausedclass (bool type)
 /// [text] - eventdescription (String type)
 bool _isFoulEvent(String text) {
 return text.contains('foul') ||
        text.contains('paused') ||
        text.contains('') ||
        text.contains('example') ||
        text.contains('ball') ||
        text.contains('foul');
 }

 // =========== 1. eventfilter Chips ===========
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
 margin: EdgeInsets.only(right: i == _filterLabels.length - 1 ? 0: 8),
 padding: const EdgeInsets.symmetric(horizontal: 12),
 alignment: Alignment.center,
 decoration: BoxDecoration(
 color: selected ? BMColors.bright: BMColors.pitch900.withValues(alpha: 0.85),
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
 fontWeight: selected ? FontWeight.w800: FontWeight.w600,
 color: selected ? BMColors.pitch950: BMColors.textSecondary,
),
),
),
);
 }),
),
);
 }

 // =========== 2. singlesectionzoneblock (sectiontitle + thesectiontimeline) ===========
 /// [period] - sectiongroup (BMBasketballLivePeriod type)
 Widget _buildPeriodSection(BMBasketballLivePeriod period) {
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // sectiontitlepill (Q1 / No. 1section)
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
 decoration: BoxDecoration(
 color: BMColors.pitch900.withValues(alpha: 0.9),
 borderRadius: BorderRadius.circular(999),
 border: Border.all(color: BMColors.pitch800.withValues(alpha: 0.7)),
),
 child: Text(
 period.periodName.isNotEmpty ? period.periodName: 'section',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
 color: BMColors.textPrimary,
),
),
),
 const SizedBox(height: 10),
 // thesectiontimeline (reverse order: latestfirst)
...period.events.reversed.map((e) => Padding(
 padding: const EdgeInsets.only(bottom: 10),
 child: _buildTimelineItem(e),
)),
 ],
);
 }

 // =========== 3. singletimelineevent (html: Event item) ===========
 /// [e] - liveevent (BMBasketballLiveEvent type)
 Widget _buildTimelineItem(BMBasketballLiveEvent e) {
 // home/awayininstantlycolor (html: amber-400 home / purple-500 away / slate-600 ininstantly)
 final sideColor = e.isNeutral
 ? BMColors.textTertiary
: (e.isHome ? _homeColor: _awayColor);
 final isScore = e.isScoreEvent;
 return IntrinsicHeight(
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 // left sidetime (html: w-12 text-cyan-400 font-mono)
 SizedBox(
 width: 44,
 child: Text(
 e.time.isNotEmpty ? e.time: '--:--',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
 fontWeight: isScore ? FontWeight.w800: FontWeight.w600,
 color: isScore ? BMColors.bright: BMColors.textTertiary,
),
),
),
 // middletimepoint + line
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
 // right sideeventcard (html: glass-panel p-2.5 rounded-xl border-l-2)
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
 // eventdescription (html: font-bold text-amber-400)
 Expanded(
 child: Text(
 e.event.isNotEmpty ? e.event: 'matchevent',
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w700,
 color: e.isNeutral ? BMColors.textSecondary: sideColor,
 height: 1.4,
),
),
),
 // live score (html: font-mono font-bold text-cyan-400)
 if (e.score.isNotEmpty)...[
 const SizedBox(width: 8),
 Text(
 e.score,
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w800,
 fontFamily: 'monospace',
 color: isScore ? sideColor: BMColors.textSecondary,
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

 /// emptystate
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
 'No matchlive',
 style: TextStyle(color: BMColors.textTertiary, fontSize: 12),
),
 ],
),
);
 }

 // =========== 4. voteratioexamplemodule (GET vote-info: home_votes/away_votes/vote_status) ===========
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

 /// votemodulecontentstate (title + ratioexampleitems + teamvotebutton)
 Widget _buildVoteContent() {
 final info = _voteInfo;
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // title row: Court support rate + vote count
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 const Row(
 children: [
 Icon(Icons.how_to_vote, size: 13, color: BMColors.bright),
 SizedBox(width: 5),
 Text(
 'Court support rate',
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
              '${info?.totalVotes ?? 0} peopleand',
              style: const TextStyle(
                fontSize: 10,
                color: BMColors.textTertiary,
                fontFamily: 'monospace',
),
),
 ],
),
 const SizedBox(height: 14),
 // home/awaydoubledirectionratioexampleitems (left home teambright green right away teamblue)
 _buildVoteBar(info),
 const SizedBox(height: 8),
 // percentline
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
 // teamvotebuttonline
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

 /// doubledirectionratioexampleitems (left home team / right away team, both sidesrounded corner)
 /// [info] - vote info (BMBasketballVoteInfo? type)
 Widget _buildVoteBar(BMBasketballVoteInfo? info) {
 final homePct = info?.homePercent ?? 0.5;
 return ClipRRect(
 borderRadius: BorderRadius.circular(999),
 child: SizedBox(
 height: 10,
 child: Row(
 children: [
 // home teamsection
 Expanded(
 flex: (homePct * 1000).clamp(1, 999).round(),
 child: Container(color: _homeColor),
),
 // away teamsection
 Expanded(
 flex: ((1 - homePct) * 1000).clamp(1, 999).round(),
 child: Container(color: _awayColor),
),
 ],
),
),
);
 }

 /// singlesidevotebutton (tapvote, alreadysidehighlightstroke, not votedsidetapvalid)
 /// [label] - team name (String type)
 /// [votes] - vote count (int type)
 /// [color] - sidecolor (Color type)
 /// [voted] - userwhetheralreadytheside (bool type)
 /// [dimmed] - whetheralreadycorrectside (bool type, grayed out)
 /// [onTap] - tap callback (VoidCallback? type)
 Widget _buildVoteButton({
 required String label,
 required int votes,
 required Color color,
 required bool voted,
 required bool dimmed,
 VoidCallback? onTap,
 }) {
 final canVote = !dimmed; // alreadycorrectsidethenthissideforbiddenpoint
 return GestureDetector(
 behavior: HitTestBehavior.opaque,
 onTap: canVote ? onTap: null,
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 200),
 padding: const EdgeInsets.symmetric(vertical: 9),
 alignment: Alignment.center,
 decoration: BoxDecoration(
 color: voted ? color.withValues(alpha: 0.18): BMColors.pitch950.withValues(alpha: 0.6),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: voted ? color: BMColors.pitch800.withValues(alpha: 0.7),
 width: voted ? 1.4: 1,
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
 color: dimmed && !voted ? BMColors.textTertiary: Colors.white,
),
),
 const SizedBox(height: 2),
 Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 voted ? Icons.check_circle: Icons.how_to_vote,
 size: 10,
 color: voted ? color: BMColors.textTertiary,
),
 const SizedBox(width: 3),
 Text(
 '$votes',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
 color: voted ? color: BMColors.textSecondary,
),
),
 ],
),
 ],
),
),
);
 }

 /// tapvote (vote_status=0 whencanpoint)
 /// flow: firstvalidatematchstate(NScan) → not logged injumploginpage → POST /api/livespeed/basketball/match/vote → successheavynewtake vote-info refreshratioexample
 /// [side] - voteside (int type, 1=home team 2=away team)
 Future<void> _onVote(int side) async {
 // 0. firstplacevalidate: onlyhasNSmatchcanwithvote (basketballrule statusId=1|13)
 final sid = widget.statusId;
 if (sid != null && sid != 1 && sid != 13) {
 ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(content: Text('Match started, voting closed'), duration: Duration(seconds: 2)),
);
 return;
 }
 final info = _voteInfo;
 if (info == null || info.voteStatus != 0) return; // alreadythennotagain
 // 1. not logged infirstlogin, loginsuccesscontinuevote
 if (!BMAuthManager().isLoggedIn) {
 final ok = await Navigator.push<bool>(
 context,
 MaterialPageRoute(builder: (_) => const BMLoginPage()),
);
 if (ok != true) return;
 }
 // 2. vote
 final okVote = await _apiService.submitBasketballVote(
 matchId: widget.matchId,
 team: side,
);
 if (!mounted) return;
 if (!okVote) {
 ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(content: Text('Vote failed, please retry'), duration: Duration(seconds: 2)),
);
 return;
 }
 // 3. successlaterheavynewtakevotedatarefreshratioexample
 setState(() => _voteLoading = true);
 await _fetchVoteInfo();
 }
}
