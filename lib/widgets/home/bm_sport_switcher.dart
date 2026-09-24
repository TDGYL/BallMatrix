import 'package:flutter/material.dart';
import '../../theme/bm_colors.dart';
import '../../viewmodels/home/bm_home_view_model.dart';

/// BMSportSwitcher - sport typeswitchdevice
/// feature: football/Basketballswitch
/// purposescope: home
class BMSportSwitcher extends StatelessWidget {
 /// currentselectedsport type (BMSportType enum)
 final BMSportType currentSport;

 /// sport typeswitchcallback (ValueChanged<BMSportType> type)
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
 label: 'Football',
          ),
          _buildButton(
            sport: BMSportType.basketball,
            icon: Icons.sports_basketball,
            label: 'Basketball',
),
 ],
),
);
 }

 /// buildswitchbutton
 /// argument: [sport] sport type, [icon] icon, [label] text
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
 color: isSelected ? BMColors.accent: Colors.transparent,
 borderRadius: BorderRadius.circular(8),
 boxShadow: isSelected
 ? [BoxShadow(color: BMColors.accent.withValues(alpha: 0.3), blurRadius: 8)]
: null,
),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(icon, size: 14, color: isSelected ? BMColors.pitch950: BMColors.textSecondary),
 const SizedBox(width: 4),
 Text(
 label,
 style: TextStyle(
 fontSize: 12,
 fontWeight: isSelected ? FontWeight.bold: FontWeight.w600,
 color: isSelected ? BMColors.pitch950: BMColors.textSecondary,
),
),
 ],
),
),
),
);
 }
}