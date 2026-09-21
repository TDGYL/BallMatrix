import 'package:flutter/material.dart';
import '../../theme/bm_colors.dart';

/// BMHomeHeader - 首页顶部头部组件
/// 功能: 展示App Logo、标题、副标题及搜索按钮
/// 作用范围: 首页顶部
class BMHomeHeader extends StatelessWidget {
  /// 搜索按钮点击回调 (VoidCallback 类型, 可空)
  final VoidCallback? onSearchTap;

  const BMHomeHeader({
    super.key,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          _buildLogo(),
          const SizedBox(width: 12),
          Expanded(child: _buildTitleSection()),
          _buildSearchButton(),
        ],
      ),
    );
  }

  /// 构建Logo图标
  Widget _buildLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BMColors.accent, Color(0xFF6EE7B7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: BMColors.accent.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.sports_soccer,
        color: BMColors.pitch950,
        size: 20,
      ),
    );
  }

  /// 构建标题区域
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '绿场智算',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: BMColors.accent.withValues(alpha: 0.2),
                border: Border.all(color: BMColors.accent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: BMColors.bright,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          '实时 AI 赛况预测与高阶建模',
          style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
        ),
      ],
    );
  }

  /// 构建搜索按钮
  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: onSearchTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: BMColors.pitch850,
          border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.search,
          color: BMColors.textSecondary,
          size: 18,
        ),
      ),
    );
  }
}