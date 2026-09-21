import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/bm_match_model.dart';
import '../../theme/bm_colors.dart';

/// BMMatchSpotlightCard - 焦点赛事卡片
/// 功能: 展示焦点比赛信息, 包括队伍、比分、AI胜率、实时压制力
/// 作用范围: 首页第一段
/// 修改点1: 在卡片头部右侧添加 "View All" 按钮, 可跳转比赛列表页
class BMMatchSpotlightCard extends StatelessWidget {
  /// 焦点比赛数据 (BMMatchModel 类型)
  final BMMatchModel match;

  /// 卡片点击回调 (VoidCallback 类型, 可空)
  final VoidCallback? onTap;

  const BMMatchSpotlightCard({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x0D10B981), Color(0xF00E261E)],
        ),
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
    );
  }

  /// 构建背景光晕效果
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

  /// 构建卡片头部 (按statusId+运动类型判断状态)
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

  /// 状态展示配置
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
        label = match.statusName != null && match.statusName!.isNotEmpty ? match.statusName! : '进行中';
        timeSuffix = (match.liveMinute != null && match.liveMinute!.isNotEmpty)
            ? match.liveMinute!
            : match.matchTime;
        bgColor = BMColors.accent.withValues(alpha: 0.12);
        textColor = BMColors.bright;
        borderColor = BMColors.accent.withValues(alpha: 0.35);
        break;
      case BMMatchStatus.upcoming:
        label = match.statusName != null && match.statusName!.isNotEmpty ? match.statusName! : '未开始';
        timeSuffix = match.matchTime;
        bgColor = BMColors.cyan.withValues(alpha: 0.12);
        textColor = BMColors.cyan;
        borderColor = BMColors.cyan.withValues(alpha: 0.35);
        break;
      case BMMatchStatus.ended:
        label = match.statusName != null && match.statusName!.isNotEmpty ? match.statusName! : '已结束';
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

  /// 构建实时心跳点
  Widget _buildLiveDot({bool showLive = true}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: showLive ? BMColors.bright : BMColors.textTertiary,
        boxShadow: [
          BoxShadow(color: BMColors.bright.withValues(alpha: 0.5), blurRadius: 6),
        ],
      ),
    );
  }

  /// 构建队伍与比分区域
  Widget _buildTeamsAndScore() {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: _buildTeamInfo(match.homeTeamName, match.homeTeam?.logoUrl ?? match.homeTeamLogo, true)),
          _buildScoreCenter(),
          Expanded(child: _buildTeamInfo(match.awayTeamName, match.awayTeam?.logoUrl ?? match.awayTeamLogo, false)),
        ],
      ),
    );
  }

  /// 构建单个队伍信息 (展示球队Logo, 删除主客场文案)
  Widget _buildTeamInfo(String name, String? logoUrl, bool isHome) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isHome ? BMColors.accent.withValues(alpha: 0.5) : BMColors.pitch700,
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
                    errorBuilder: (_, __, ___) => _buildDefaultTeamIcon(isHome),
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

  /// 构建默认球队图标 (Logo加载失败或无链接)
  Widget _buildDefaultTeamIcon(bool isHome) {
    return Icon(
      isHome ? Icons.sports_soccer : Icons.shield,
      size: 22,
      color: isHome ? BMColors.bright : BMColors.textSecondary,
    );
  }

  /// 构建比分中心 (删除AI胜率推算)
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

/// _StatusDisplay - 状态展示辅助配置 (私用)
class _StatusDisplay {
  /// 状态中文标签 (String 类型)
  final String label;

  /// 时间后缀 (String 类型, 进行中=liveMinute, 其他=matchTime)
  final String timeSuffix;

  /// 是否进行中 (bool 类型, 控制心跳点)
  final bool isLive;

  /// 胶囊背景色 (Color 类型)
  final Color bgColor;

  /// 文字颜色 (Color 类型)
  final Color textColor;

  /// 边框颜色 (Color 类型)
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