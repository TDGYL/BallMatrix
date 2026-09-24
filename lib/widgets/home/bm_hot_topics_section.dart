import 'package:flutter/material.dart';
import '../../models/bm_topic_model.dart';
import '../../models/bm_match_model.dart';
import '../../theme/bm_colors.dart';

/// TopicPostCard - singletopicindependentcard (homethird section + topiclistpageshared)
/// reference hanklive PostCard 5layerstructure: userheader -> tag -> content -> innermatch -> dobar
class TopicPostCard extends StatelessWidget {
 /// topicdata (BMTopicModel type)
 final BMTopicModel topic;

 /// tapcardcallback (VoidCallback type, can be empty)
 final VoidCallback? onTap;

 /// tapinnermatchcardcallback (VoidCallback type, can be empty, by sport typenavigatecorrespondingmatchdetail)
 final VoidCallback? onMatchTap;

 /// moredocallback (action as 'block'/'report', topicId astopicID)
 final void Function(String action, String topicId)? onMoreAction;

 const TopicPostCard({
 super.key,
 required this.topic,
 this.onTap,
 this.onMatchTap,
 this.onMoreAction,
 });

 @override
 Widget build(BuildContext context) {
 return GestureDetector(
 onTap: onTap,
 behavior: HitTestBehavior.opaque,
 child: Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: BMColors.pitch850,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 _buildUserHeader(context),
 // image asemptywhennotshowtopicpill
 if (topic.hashtags.isNotEmpty)...[
 const SizedBox(height: 10),
 _buildHashtagWrap(),
 ],
 const SizedBox(height: 8),
 _buildContentText(),
 if (topic.embeddedMatch != null)...[
 const SizedBox(height: 10),
 // innermatchcard (tapby sport typenavigatecorrespondingmatchdetail, andoutercardtapleave)
 GestureDetector(
 onTap: onMatchTap,
 behavior: HitTestBehavior.opaque,
 child: _buildEmbeddedMatch(topic.embeddedMatch!),
),
 ],
 const SizedBox(height: 10),
 _buildActionBar(),
 ],
),
),
);
 }

 /// builduseravatarheaderline
 Widget _buildUserHeader(BuildContext context) {
 return Row(
 children: [
 _buildUserAvatar(),
 const SizedBox(width: 8),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 (topic.authorName != null && topic.authorName!.isNotEmpty)
 ? topic.authorName!
: 'pitch user',
 style: const TextStyle(
 fontSize: 13,
 fontWeight: FontWeight.w700,
 color: BMColors.textPrimary,
),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
),
 const SizedBox(height: 2),
 Text(
 (topic.publishTimeDesc != null &&
 topic.publishTimeDesc!.isNotEmpty)
 ? topic.publishTimeDesc!
: topic.categoryTag,
 style: const TextStyle(
 fontSize: 10,
 color: Color(0xFF94A3B8),
),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
),
 ],
),
),
 _buildMoreButton(context),
 ],
);
 }

 /// builduseravatar (priority authorAvatarUrl trueactual, otherwise thendefaultplaceholder)
 Widget _buildUserAvatar() {
 final avatar = topic.authorAvatarUrl;
 if (avatar != null && avatar.isNotEmpty) {
 return CircleAvatar(
 radius: 16,
 backgroundColor: BMColors.pitch700,
 backgroundImage: NetworkImage(avatar),
 onBackgroundImageError: (_, __) {},
);
 }
 return CircleAvatar(
 radius: 16,
 backgroundColor: BMColors.pitch700,
 child: const Icon(
 Icons.person_outline,
 size: 18,
 color: BMColors.textSecondary,
),
);
 }

 /// morebutton(threeitemspoint) + tappopmenu block/report
 Widget _buildMoreButton(BuildContext context) {
 return Builder(
 builder: (btnCtx) {
 return GestureDetector(
 onTap: () {
 _showMoreMenu(btnCtx);
 },
 child: Container(
 padding: const EdgeInsets.all(6),
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(8),
),
 child: const Icon(
 Icons.more_horiz,
 size: 16,
 color: BMColors.textSecondary,
),
),
);
 },
);
 }

 /// popmoremenu - morebuttonbottom-left corner
 void _showMoreMenu(BuildContext btnCtx) {
 final renderBox = btnCtx.findRenderObject() as RenderBox?;
 final overlay = Overlay.of(btnCtx).context.findRenderObject() as RenderBox?;
 RelativeRect position;
 if (renderBox != null && overlay != null) {
 final btnSize = renderBox.size;
 final btnOffset =
 renderBox.localToGlobal(Offset.zero, ancestor: overlay);
 position = RelativeRect.fromLTRB(
 btnOffset.dx,
 btnOffset.dy + btnSize.height,
 btnOffset.dx + btnSize.width,
 btnOffset.dy + btnSize.height + 300,
);
 } else {
 position = const RelativeRect.fromLTRB(16, 16, 16, 0);
 }
 showMenu<String>(
 context: btnCtx,
 position: position,
 color: BMColors.pitch850,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 side: BorderSide(color: BMColors.pitch700.withValues(alpha: 0.5)),
),
 items: <PopupMenuEntry<String>>[
 const PopupMenuItem<String>(
 value: 'block',
          child: Row(
            children: [
              Icon(Icons.block, size: 16, color: BMColors.textSecondary),
              SizedBox(width: 10),
              Text(
                'block',
                style: TextStyle(fontSize: 13, color: BMColors.textPrimary),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.report_outlined,
                  size: 16, color: BMColors.textSecondary),
              SizedBox(width: 10),
              Text(
                'report',
 style: TextStyle(fontSize: 13, color: BMColors.textPrimary),
),
 ],
),
),
 ],
).then((String? value) {
 if (value == null) return;
 onMoreAction?.call(value, topic.topicId);
 // report: toast toastReported (block toast bycalldirectionhandle: APIsuccesslaterdelete locally)
 if (value == 'report') {
        ScaffoldMessenger.of(btnCtx).showSnackBar(
          SnackBar(
            content: const Text(
              'Reported',
 style: TextStyle(color: Colors.white),
),
 duration: const Duration(seconds: 1),
 backgroundColor: BMColors.pitch800,
 behavior: SnackBarBehavior.floating,
),
);
 }
 });
 }

 /// buildtopictag (multiple #topic pill, data source image comma split)
 Widget _buildHashtagWrap() {
 return Wrap(
 spacing: 8,
 runSpacing: 8,
 children: topic.hashtags
.where((t) => t.isNotEmpty)
.map((tag) => Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 10,
 vertical: 4,
),
 decoration: BoxDecoration(
 color: Color(topic.categoryBgColor).withValues(alpha: 0.15),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: Color(topic.categoryBgColor).withValues(alpha: 0.3),
),
),
 child: Text(
 '# $tag',
 style: TextStyle(
 color: Color(topic.categoryBgColor),
 fontSize: 12,
 fontWeight: FontWeight.w600,
),
),
))
.toList(),
);
 }

 /// buildcontenttext (AI)
 Widget _buildContentText() {
 return Text(
 topic.aiInsight,
 style: const TextStyle(
 fontSize: 12,
 height: 1.6,
 color: BMColors.textSecondary,
),
);
 }

 /// buildinnermatchcard (league nametop-left corner + logoleft+team name vs logoright+team name + statepill)
 Widget _buildEmbeddedMatch(BMMatchModel match) {
 // league namepriority competitionName, fallback leagueName (topiclistdata source leagueName)
 final String leagueName = ((match.competitionName != null && match.competitionName!.isNotEmpty)
 ? match.competitionName!
: match.leagueName)
.trim();
 return Container(
 padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
 decoration: BoxDecoration(
 color: BMColors.pitch800,
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // No. oneline: top-left cornerleague name + rightstatepill
 Row(
 children: [
 if (leagueName.isNotEmpty)...[
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: Color(match.leagueColor).withValues(alpha: 0.15),
 borderRadius: BorderRadius.circular(4),
),
 child: Text(
 leagueName,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 9,
 fontWeight: FontWeight.w600,
 color: Color(match.leagueColor),
),
),
),
 ],
 const Spacer(),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: _matchStatusBg(match.status),
 borderRadius: BorderRadius.circular(4),
),
 child: Text(
 _matchStatusLabel(match),
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.w600,
 color: _matchStatusText(match.status),
),
),
),
 ],
),
 const SizedBox(height: 8),
 // No. twoline: home team logo + team name vs away team logo + team name
 Row(
 children: [
 // home teamzone: logo left + team name right
 _buildTeamLogo(
 logoUrl: match.homeTeam?.logoUrl ?? match.homeTeamLogo,
 teamShort: match.homeTeam?.teamShort ?? match.homeTeamName,
 fallbackIcon: _teamFallbackIcon(match.sportType),
),
 const SizedBox(width: 6),
 Expanded(
 child: Text(
 match.homeTeamName,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 textAlign: TextAlign.left,
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w700,
 color: BMColors.bright,
),
),
),
 const SizedBox(width: 6),
 const Text(
 'vs',
 style: TextStyle(
 fontSize: 10,
 color: BMColors.textTertiary,
 fontWeight: FontWeight.w600,
),
),
 const SizedBox(width: 6),
 // away teamzone: team name left + logo right
 Expanded(
 child: Text(
 match.awayTeamName,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 textAlign: TextAlign.right,
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w700,
 color: BMColors.bright,
),
),
),
 const SizedBox(width: 6),
 _buildTeamLogo(
 logoUrl: match.awayTeam?.logoUrl ?? match.awayTeamLogo,
 teamShort: match.awayTeam?.teamShort ?? match.awayTeamName,
 fallbackIcon: _teamFallbackIcon(match.sportType),
),
 ],
),
 ],
),
);
 }

 /// buildsingleteam logo circle (16px, Load Faileddisplayteam nameabbreviationtextoricon)
 Widget _buildTeamLogo({
 required String? logoUrl,
 required String teamShort,
 required IconData fallbackIcon,
 }) {
 final String url = logoUrl ?? '';
    final String label = (teamShort.isNotEmpty && teamShort.length <= 3)
        ? teamShort
        : (teamShort.isNotEmpty ? teamShort.substring(0, 2).toUpperCase() : '');
 if (url.isNotEmpty) {
 return ClipOval(
 child: SizedBox(
 width: 16,
 height: 16,
 child: Image.network(
 url,
 fit: BoxFit.cover,
 errorBuilder: (_, __, ___) {
 if (label.isNotEmpty) {
 return Container(
 color: BMColors.pitch900,
 alignment: Alignment.center,
 child: Text(
 label,
 style: const TextStyle(
 fontSize: 7,
 fontWeight: FontWeight.w700,
 color: BMColors.textSecondary,
),
),
);
 }
 return Container(
 color: BMColors.pitch900,
 alignment: Alignment.center,
 child: Icon(fallbackIcon, size: 10, color: BMColors.textTertiary),
);
 },
),
),
);
 }
 // none logo fallback
 if (label.isNotEmpty) {
 return Container(
 width: 16,
 height: 16,
 decoration: BoxDecoration(
 color: BMColors.pitch900,
 shape: BoxShape.circle,
 border: Border.all(color: BMColors.pitch700, width: 0.5),
),
 alignment: Alignment.center,
 child: Text(
 label,
 style: const TextStyle(
 fontSize: 7,
 fontWeight: FontWeight.w700,
 color: BMColors.textSecondary,
),
),
);
 }
 return Container(
 width: 16,
 height: 16,
 decoration: const BoxDecoration(
 color: BMColors.pitch900,
 shape: BoxShape.circle,
),
 alignment: Alignment.center,
 child: Icon(fallbackIcon, size: 10, color: BMColors.textTertiary),
);
 }

 /// datasport typetakefallbackicon (football/basketball)
 IconData _teamFallbackIcon(BMMatchSportType sport) {
 if (sport == BMMatchSportType.basketball) {
 return Icons.sports_basketball_outlined;
 }
 return Icons.sports_soccer_outlined;
 }

 Color _matchStatusBg(BMMatchStatus s) {
 switch (s) {
 case BMMatchStatus.live:
 return const Color(0xFFDC2626).withValues(alpha: 0.2);
 case BMMatchStatus.upcoming:
 return const Color(0xFF22D3EE).withValues(alpha: 0.2);
 case BMMatchStatus.ended:
 return const Color(0xFF64748B).withValues(alpha: 0.25);
 case BMMatchStatus.tbd:
 return const Color(0xFFF59E0B).withValues(alpha: 0.2);
 }
 }

 Color _matchStatusText(BMMatchStatus s) {
 switch (s) {
 case BMMatchStatus.live:
 return const Color(0xFFEF4444);
 case BMMatchStatus.upcoming:
 return const Color(0xFF22D3EE);
 case BMMatchStatus.ended:
 return const Color(0xFF94A3B8);
 case BMMatchStatus.tbd:
 return const Color(0xFFF59E0B);
 }
 }

 String _matchStatusLabel(BMMatchModel m) {
 // priority statusId + sportType rule (reference BMMatchModel.displayStatusLabel)
 final String byId = m.displayStatusLabel;
 if (byId != '-') return byId;
 // fallback: status enum
 switch (m.status) {
 case BMMatchStatus.live:
 return 'LIVE';
      case BMMatchStatus.upcoming:
        return m.matchTime.isNotEmpty ? m.matchTime : 'NS';
      case BMMatchStatus.ended:
        return 'FT';
      case BMMatchStatus.tbd:
        return 'TBD';
 }
 }

 /// dobar (leftcommentcount + rightlikecount/whetherlike, both sidessymmetric)
 Widget _buildActionBar() {
 return Container(
 padding: const EdgeInsets.only(top: 10),
 decoration: const BoxDecoration(
 border: Border(
 top: BorderSide(color: BMColors.pitch700, width: 0.5),
),
),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 // left side: commentcount
 Row(
 children: [
 const Icon(
 Icons.chat_bubble_outline,
 size: 14,
 color: BMColors.textTertiary,
),
 const SizedBox(width: 5),
 Text(
 '${topic.commentCount}',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
 color: BMColors.textTertiary,
),
),
 ],
),
 // right side: likecount + whetherlikehighlight
 Row(
 children: [
 Icon(
 topic.isLiked ? Icons.favorite: Icons.favorite_border,
 size: 14,
 color: topic.isLiked
 ? const Color(0xFFDC2626)
: BMColors.textTertiary,
),
 const SizedBox(width: 5),
 Text(
 '${topic.likeCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
 color: topic.isLiked
 ? const Color(0xFFDC2626)
: BMColors.textTertiary,
),
),
 ],
),
 ],
),
);
 }
}

/// BMHotTopicsSection - hot topic listzone (homethird sectionuse, use TopicPostCard groupmerge)
/// modifypoint3: swaporiginal"todaydayheavypointleavemodel"as"hot topic"
class BMHotTopicsSection extends StatelessWidget {
 /// hot topic list (List<BMTopicModel> type)
 final List<BMTopicModel> topicList;

 /// topictap callback (ValueChanged<BMTopicModel> type, can be empty)
 final ValueChanged<BMTopicModel>? onTopicTap;

 /// innermatchcardtap callback (ValueChanged<BMTopicModel> type, can be empty, by sport typenavigatematchdetail)
 final ValueChanged<BMTopicModel>? onMatchTap;

 /// moremenublockcallback (ValueChanged<BMTopicModel> type, can be empty)
 /// feature: calldirectionhandledouble confirmationdialog + blockAPI + delete locally
 final ValueChanged<BMTopicModel>? onBlockTopic;

 /// View Allbuttontap callback (VoidCallback type, can be empty)
 final VoidCallback? onViewAll;

 const BMHotTopicsSection({
 super.key,
 required this.topicList,
 this.onTopicTap,
 this.onMatchTap,
 this.onBlockTopic,
 this.onViewAll,
 });

 @override
 Widget build(BuildContext context) {
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
...topicList.map((topic) => Padding(
 padding: const EdgeInsets.only(bottom: 12),
 child: TopicPostCard(
 topic: topic,
 onTap: () => onTopicTap?.call(topic),
 onMatchTap: (topic.embeddedMatch != null)
 ? () => onMatchTap?.call(topic)
: null,
 onMoreAction: (action, topicId) {
 if (action == 'block') {
                    onBlockTopic?.call(topic);
                  }
                },
              ),
            )),
      ],
    );
  }
}
