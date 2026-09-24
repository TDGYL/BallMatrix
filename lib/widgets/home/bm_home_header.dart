import 'package:flutter/material.dart';

import '../../theme/bm_colors.dart';

/// BMHomeHeader - hometopheaderwidget
/// feature: showApp Logo、title、copytitleandsearchbutton
/// purposescope: hometop
class BMHomeHeader extends StatelessWidget {
  /// searchbuttontap callback (VoidCallback type, can be empty)
  final VoidCallback? onSearchTap;

  const BMHomeHeader({super.key, this.onSearchTap});

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

  /// buildLogoicon
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

  /// buildtitlezone
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'pitch intelligence',
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
                border: Border.all(
                  color: BMColors.accent.withValues(alpha: 0.3),
                ),
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
          'actual build module',
          style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
        ),
      ],
    );
  }

  /// buildsearchbutton
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
