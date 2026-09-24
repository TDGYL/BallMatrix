import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/bm_match_model.dart';
import '../../theme/bm_colors.dart';

/// BMMatchSpotlightCard - focus competitioncard
/// feature: showpointmatchinfo, team、score、AIWrate、actualwhenmakepower
/// purposescope: homeNo. onesection
/// modifypoint1: cardheaderright sideadd "View All" button, cannavigatematchlistpage
class BMMatchSpotlightCard extends StatelessWidget {
 /// pointmatchdata (BMMatchModel type)
 final BMMatchModel match;

 /// cardtap callback (VoidCallback type, can be empty)
 final VoidCallback? onTap;

 const BMMatchSpotlightCard({
 super.key,
 required this.match,
 this.onTap,
 });

 @override
 Widget build(BuildContext context) {
 // ⭐️ tapscopeoptimize: GestureDetector wrapwholeitemscard(includesfourweekpadding+header+scorezone)
 // behavior=opaque letemptywhitezonealsoresponsetap, originalonly _buildTeamsAndScore onelinefourweeknoneresponse
 return GestureDetector(
 onTap: onTap,
 behavior: HitTestBehavior.opaque,
 child: Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: const Color(0x0D10B981),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: BMColors.pitch600.withValues(alpha: 0.4)),
 boxShadow: [
 BoxShadow(
 color: BMColors.accent.withValues(alpha: 0.15),
 blurRadius: 15,
),
 ],
),
 child: Stack(
 children: [
 _buildGlowEffect(),
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 _buildHeader(),
 const SizedBox(height: 12),
 _buildTeamsAndScore(),
 ],
),
 ],
),
),
);
 }

 /// buildbackgroundeffect
 Widget _buildGlowEffect() {
 return Positioned(
 right: -30,
 bottom: -30,
 child: Container(
 width: 120,
 height: 120,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: BMColors.accent.withValues(alpha: 0.1),
),
 child: BackdropFilter(
 filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
 child: const SizedBox(),
),
),
);
 }

 /// buildcardheader (bystatusId+sport typecheckstate)
 Widget _buildHeader() {
 final statusInfo = _resolveStatusDisplay();
 return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Row(
 children: [
 _buildLiveDot(showLive: statusInfo.isLive),
 const SizedBox(width: 6),
 Flexible(
 child: Text(
 '${match.leagueName} · ${match.round}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: BMColors.bright,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusInfo.bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusInfo.borderColor),
              ),
              child: Text(
                '${statusInfo.label} ${statusInfo.timeSuffix}',
 style: TextStyle(fontSize: 11, color: statusInfo.textColor),
),
),
 ],
),
 ],
);
 }

 /// stateshowplace
 _StatusDisplay _resolveStatusDisplay() {
 final hasStatusId = match.statusId != null;
 final sid = match.statusId ?? 0;
 final sport = match.sportType;
 BMMatchStatus resolvedStatus;
 String label;
 String timeSuffix;
 Color bgColor;
 Color textColor;
 Color borderColor;

 if (hasStatusId) {
 if (sport == BMMatchSportType.football) {
 switch (sid) {
 case 1:
 resolvedStatus = BMMatchStatus.upcoming;
 break;
 case 2:
 case 3:
 case 4:
 case 5:
 case 7:
 resolvedStatus = BMMatchStatus.live;
 break;
 case 8:
 resolvedStatus = BMMatchStatus.ended;
 break;
 default:
 resolvedStatus = BMMatchStatus.tbd;
 }
 } else {
 switch (sid) {
 case 1:
 case 13:
 resolvedStatus = BMMatchStatus.upcoming;
 break;
 case 2:
 case 3:
 case 4:
 case 5:
 case 6:
 case 7:
 case 8:
 case 9:
 resolvedStatus = BMMatchStatus.live;
 break;
 case 10:
 case 11:
 resolvedStatus = BMMatchStatus.ended;
 break;
 default:
 resolvedStatus = BMMatchStatus.tbd;
 }
 }
 } else {
 resolvedStatus = match.status;
 }

 switch (resolvedStatus) {
 case BMMatchStatus.live:
 label = match.statusName != null && match.statusName!.isNotEmpty ? match.statusName!: 'in progress';
        timeSuffix = (match.liveMinute != null && match.liveMinute!.isNotEmpty)
            ? match.liveMinute!
            : match.matchTime;
        bgColor = BMColors.accent.withValues(alpha: 0.12);
        textColor = BMColors.bright;
        borderColor = BMColors.accent.withValues(alpha: 0.35);
        break;
      case BMMatchStatus.upcoming:
        label = match.statusName != null && match.statusName!.isNotEmpty ? match.statusName! : 'NS';
        timeSuffix = match.matchTime;
        bgColor = BMColors.cyan.withValues(alpha: 0.12);
        textColor = BMColors.cyan;
        borderColor = BMColors.cyan.withValues(alpha: 0.35);
        break;
      case BMMatchStatus.ended:
        label = match.statusName != null && match.statusName!.isNotEmpty ? match.statusName! : 'FT';
        timeSuffix = match.matchTime;
        bgColor = BMColors.pitch700.withValues(alpha: 0.8);
        textColor = BMColors.textSecondary;
        borderColor = BMColors.pitch700;
        break;
      case BMMatchStatus.tbd:
        label = 'TBD';
 timeSuffix = match.matchTime;
 bgColor = BMColors.purple.withValues(alpha: 0.12);
 textColor = BMColors.purple;
 borderColor = BMColors.purple.withValues(alpha: 0.35);
 break;
 }

 return _StatusDisplay(
 label: label,
 timeSuffix: timeSuffix,
 isLive: resolvedStatus == BMMatchStatus.live,
 bgColor: bgColor,
 textColor: textColor,
 borderColor: borderColor,
);
 }

 /// buildactualwhenjumppoint
 Widget _buildLiveDot({bool showLive = true}) {
 return Container(
 width: 8,
 height: 8,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: showLive ? BMColors.bright: BMColors.textTertiary,
 boxShadow: [
 BoxShadow(color: BMColors.bright.withValues(alpha: 0.5), blurRadius: 6),
 ],
),
);
 }

 /// buildteamandscorezone (tapgesturealreadyuppertowholecard build layer, onlyLlayout)
 Widget _buildTeamsAndScore() {
 return Row(
 children: [
 Expanded(child: _buildTeamInfo(match.homeTeamName, match.homeTeam?.logoUrl ?? match.homeTeamLogo, true)),
 _buildScoreCenter(),
 Expanded(child: _buildTeamInfo(match.awayTeamName, match.awayTeam?.logoUrl ?? match.awayTeamLogo, false)),
 ],
);
 }

 /// buildsingleitemsteaminfo (showteamLogo, removehome/awaycourttext)
 Widget _buildTeamInfo(String name, String? logoUrl, bool isHome) {
 return Column(
 children: [
 Container(
 width: 48,
 height: 48,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 border: Border.all(
 color: isHome ? BMColors.accent.withValues(alpha: 0.5): BMColors.pitch700,
 width: 2,
),
 color: BMColors.pitch800,
),
 child: ClipOval(
 child: logoUrl != null && logoUrl.isNotEmpty
 ? Image.network(
 logoUrl,
 width: 48,
 height: 48,
 fit: BoxFit.cover,
 errorBuilder: (_, _, _) => _buildDefaultTeamIcon(isHome),
)
: _buildDefaultTeamIcon(isHome),
),
),
 const SizedBox(height: 6),
 Text(
 name,
 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BMColors.textPrimary),
 textAlign: TextAlign.center,
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
),
 ],
);
 }

 /// builddefaultteamicon (LogoLoad Failedornone)
 Widget _buildDefaultTeamIcon(bool isHome) {
 return Icon(
 isHome ? Icons.sports_soccer: Icons.shield,
 size: 22,
 color: isHome ? BMColors.bright: BMColors.textSecondary,
);
 }

 /// buildscorein (removeAIWratecalc)
 Widget _buildScoreCenter() {
 return Column(
 children: [
 RichText(
 text: TextSpan(
 children: [
 TextSpan(
 text: '${match.homeScore ?? 0}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: BMColors.bright,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
              const TextSpan(
                text: ' : ',
                style: TextStyle(
                  fontSize: 20,
                  color: BMColors.bright,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '${match.awayScore ?? 0}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: BMColors.bright,
                  fontFamily: 'monospace',
 letterSpacing: 2,
),
),
 ],
),
),
 ],
);
 }
}

/// _StatusDisplay - stateshowauxiliaryplace (usage)
class _StatusDisplay {
 /// stateintexttag (String type)
 final String label;

 /// timelater (String type, in progress=liveMinute, others=matchTime)
 final String timeSuffix;

 /// whetherin progress (bool type, makejumppoint)
 final bool isLive;

 /// pillbackground color (Color type)
 final Color bgColor;

 /// text color (Color type)
 final Color textColor;

 /// bordercolor (Color type)
 final Color borderColor;

 _StatusDisplay({
 required this.label,
 required this.timeSuffix,
 required this.isLive,
 required this.bgColor,
 required this.textColor,
 required this.borderColor,
 });
}