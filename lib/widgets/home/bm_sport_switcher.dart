import 'package:flutter/material.dart';
import '../../theme/bm_colors.dart';
import '../../viewmodels/home/bm_home_view_model.dart';

/// BMSportSwitcher - 运动类型切换器
/// 功能: 足球/篮球赛事切换
/// 作用范围: 首页
class BMSportSwitcher extends StatelessWidget {
  /// 当前选中的运动类型 (BMSportType 枚举)
  final BMSportType currentSport;

  /// 运动类型切换回调 (ValueChanged<BMSportType> 类型)
  final ValueChanged<BMSportType> onSportChanged;

  const BMSportSwitcher({
    super.key,
    required this.currentSport,
    required this.onSportChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BMColors.pitch950.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: Row(
        children: [
          _buildButton(
            sport: BMSportType.football,
            icon: Icons.sports_soccer,
            label: '足球赛事',
          ),
          _buildButton(
            sport: BMSportType.basketball,
            icon: Icons.sports_basketball,
            label: '篮球赛事',
          ),
        ],
      ),
    );
  }

  /// 构建切换按钮
  /// 参数: [sport] 运动类型, [icon] 图标, [label] 文本
  Widget _buildButton({
    required BMSportType sport,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = currentSport == sport;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSportChanged(sport),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? BMColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: BMColors.accent.withValues(alpha: 0.3), blurRadius: 8)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? BMColors.pitch950 : BMColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? BMColors.pitch950 : BMColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}