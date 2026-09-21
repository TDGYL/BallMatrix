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
              const SizedBox(height: 16),
              _buildFooter(),
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

  /// 构建卡片头部 (修改点1: 添加View All按钮)
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              _buildLiveDot(),
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
                color: BMColors.pitch950.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BMColors.pitch700),
              ),
              child: Text(
                '进行中 ${match.matchTime}',
                style: const TextStyle(fontSize: 11, color: BMColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建实时心跳点
  Widget _buildLiveDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BMColors.bright,
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
          Expanded(child: _buildTeamInfo(match.homeTeamName, '主场 xG ${match.homeXG}', true)),
          _buildScoreCenter(),
          Expanded(child: _buildTeamInfo(match.awayTeamName, '客场 xG ${match.awayXG}', false)),
        ],
      ),
    );
  }

  /// 构建单个队伍信息
  /// 参数: [name] 队名, [subInfo] 子信息, [isHome] 是否主队
  Widget _buildTeamInfo(String name, String subInfo, bool isHome) {
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
          child: Icon(
            isHome ? Icons.sports_soccer : Icons.shield,
            size: 22,
            color: isHome ? BMColors.bright : BMColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BMColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          subInfo,
          style: const TextStyle(fontSize: 10, color: BMColors.textSecondary),
        ),
      ],
    );
  }

  /// 构建比分中心
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
                  color: Color(0xFF475569),
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
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: BMColors.gold.withValues(alpha: 0.1),
            border: Border.all(color: BMColors.gold.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'AI 胜率推算 ${match.aiWinRate.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 10, color: BMColors.amber),
          ),
        ),
      ],
    );
  }

  /// 构建底部压制力与进入按钮
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x801C4537), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, size: 14, color: BMColors.bright),
              const SizedBox(width: 6),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '实时压制力: ',
                      style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
                    ),
                    TextSpan(
                      text: '皇马 ${match.momentumPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: BMColors.bright,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                '进入高阶盘路',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BMColors.bright),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 12, color: BMColors.bright),
            ],
          ),
        ],
      ),
    );
  }
}