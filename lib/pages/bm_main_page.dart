import 'package:flutter/material.dart';

import '../theme/bm_colors.dart';
import 'home/bm_home_page.dart';
import 'match/bm_match_tab_page.dart';
import 'tool/bm_tool_page.dart';
import 'mine/bm_mine_page.dart';
import '../viewmodels/home/bm_home_view_model.dart';

/// BMMainPage - homeframeworkpage
/// feature: bottomnavigationTabframework, home/competition/tool/my of fouritemsTabpage
/// architecture: MVVM Viewlayer, hasfullgame ViewModel
class BMMainPage extends StatefulWidget {
  const BMMainPage({super.key});

  @override
  State<BMMainPage> createState() => _BMMainPageState();
}

class _BMMainPageState extends State<BMMainPage> {
  /// currentselected of Tabindex - ValueNotifier (subpagelistenerTabswitchevent)
  /// purpose: when _currentIndex=3 switchto"my of "pagewhen, BMMinePage listenertolatercanrefreshprofileinfo
  final ValueNotifier<int> currentTabNotifier = ValueNotifier<int>(0);

  /// currentselected of Tabindex (int type, 0-3)
  int get _currentIndex => currentTabNotifier.value;

  /// homeViewModel (BMHomeViewModel type, lazy load)
  late final BMHomeViewModel _homeViewModel;

  /// pagelist (List<Widget> type, lazy load)
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // lazy loadinitializeViewModel
    _homeViewModel = BMHomeViewModel();
    // lazy loadinitializepage: BMMinePage receive currentTabNotifier
    _pages = [
      BMHomePage(viewModel: _homeViewModel),
      const BMMatchTabPage(),
      const BMToolPage(),
      BMMinePage(currentTabNotifier: currentTabNotifier),
    ];
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    currentTabNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// buildbottomapp bar
  Widget _buildBottomNav() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: BMColors.pitch950.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: Color(0x80143328))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.stadium, 'home'),
          _buildNavItem(1, Icons.flag_outlined, 'competition'),
          _buildCenterNavItem(),
          _buildNavItem(3, Icons.manage_accounts_outlined, 'mine'),
        ],
      ),
    );
  }

  /// buildgeneralcommonnavigationitem
  /// argument: [index] index, [icon] icon, [label] text
  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        // priorityupdate ValueNotifier (subpagelike BMMinePage abilityNo. onetimelistener Tab switchevent)
        currentTabNotifier.value = index;
        setState(() {});
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? BMColors.bright : BMColors.textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? BMColors.bright : BMColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// buildmiddlenavigationitem (calctool)
  Widget _buildCenterNavItem() {
    final bool isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () {
        currentTabNotifier.value = 2;
        setState(() {});
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [BMColors.accent, Color(0xFF5EEAD4)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BMColors.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
                border: Border.all(color: BMColors.pitch950, width: 4),
              ),
              child: const Icon(
                Icons.radar,
                size: 20,
                color: BMColors.pitch950,
              ),
            ),
          ),
          Text(
            '',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? BMColors.bright : BMColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
