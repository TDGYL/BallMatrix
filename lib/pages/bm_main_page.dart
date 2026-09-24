import 'package:flutter/material.dart';

import '../theme/bm_colors.dart';
import 'home/bm_home_page.dart';
import 'match/bm_match_tab_page.dart';
import 'tool/bm_tool_page.dart';
import 'mine/bm_mine_page.dart';
import '../viewmodels/home/bm_home_view_model.dart';

/// BMMainPage - 主框架页面
/// 功能: 底部导航Tab框架, 管理首页/赛事/工具/我的四个Tab页面
/// 架构: MVVM View层, 持有全局 ViewModel
class BMMainPage extends StatefulWidget {
  const BMMainPage({super.key});

  @override
  State<BMMainPage> createState() => _BMMainPageState();
}

class _BMMainPageState extends State<BMMainPage> {
  /// 当前选中的Tab索引 - ValueNotifier (便于子页面监听Tab切换事件)
  ///   作用: 当 _currentIndex=3 切换到"我的"页面时, BMMinePage 监听到后可刷新个人信息
  final ValueNotifier<int> currentTabNotifier = ValueNotifier<int>(0);

  /// 当前选中的Tab索引 (int 类型, 0-3)
  int get _currentIndex => currentTabNotifier.value;

  /// 首页ViewModel (BMHomeViewModel 类型, 懒加载)
  late final BMHomeViewModel _homeViewModel;

  /// 页面列表 (List<Widget> 类型, 懒加载)
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 懒加载初始化ViewModel
    _homeViewModel = BMHomeViewModel();
    // 懒加载初始化页面: BMMinePage 接收 currentTabNotifier
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

  /// 构建底部导航栏
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
          _buildNavItem(0, Icons.stadium, '首页'),
          _buildNavItem(1, Icons.flag_outlined, '赛事'),
          _buildCenterNavItem(),
          _buildNavItem(3, Icons.manage_accounts_outlined, '我的'),
        ],
      ),
    );
  }

  /// 构建普通导航项
  /// 参数: [index] 索引, [icon] 图标, [label] 文本
  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        // 优先更新 ValueNotifier (子页面如 BMMinePage 能第一时间监听 Tab 切换事件)
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

  /// 构建中间凸起导航项 (智算工具)
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
            '藏宝盒',
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
