import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// BMApplyPlayerInfoPage - 球员信息申请表单页
/// 功能: 录入球员基本信息 + 擅长联赛 + 擅长位置 + 运动经历后提交
/// 架构: MVVM View层 (纯UI表单, 提交逻辑留占位)
/// 作用范围: 从「我的」页 push 进入的球员信息认证申请入口
/// 注意: 为防止底部溢出(overflow), buildBody 外层统一包 SingleChildScrollView,
///      联赛选择区域使用 Wrap 流式布局自动换行, 不使用固定高度 ListView, 绝对避免 overflow.
class BMApplyPlayerInfoPage extends BMBasePage {
  const BMApplyPlayerInfoPage({super.key});

  @override
  State<BMApplyPlayerInfoPage> createState() => _BMApplyPlayerInfoPageState();
}

class _BMApplyPlayerInfoPageState extends BMBasePageState<BMApplyPlayerInfoPage> {
  // ============ 表单状态 ============

  /// 姓名输入框控制器 (TextEditingController 类型)
  final TextEditingController _nameController = TextEditingController();

  /// 身高输入框控制器 (TextEditingController 类型, cm)
  final TextEditingController _heightController = TextEditingController();

  /// 体重输入框控制器 (TextEditingController 类型, kg)
  final TextEditingController _weightController = TextEditingController();

  /// 运动经历输入框控制器 (TextEditingController 类型, 多行)
  final TextEditingController _experienceController = TextEditingController();

  /// 性别选择索引 (int 类型, 0=男, 1=女, 2=保密)
  int _genderIndex = 0;

  /// 出生日期 (DateTime? 类型, 默认未选)
  DateTime? _birthday;

  /// 已选中的联赛索引集合 (Set<int> 类型, 支持多选, 自动去重)
  final Set<int> _selectedLeagueIndices = <int>{0};

  /// 联赛选择是否展开 (bool 类型, true=展示4行, false=折叠仅1行)
  bool _leagueExpanded = false;

  /// 单行联赛chip区域高度估算值 (double 类型, 包含行间距 runSpacing)
  final double _oneLeagueRowHeight = 54;

  /// 展开状态最大显示行数 (int 类型, 按需求=4)
  final int _maxLeagueRows = 4;

  /// 已选中的场上位置索引集合 (Set<int> 类型, 支持多选)
  final Set<int> _selectedPositionIndices = <int>{2};

  /// 性别选项 (List<(String, IconData)> 类型, 与 _genderIndex 对应)
  final List<(String, IconData)> _genderOptions = const [
    ('男', Icons.male),
    ('女', Icons.female),
    ('保密', Icons.no_accounts_outlined),
  ];

  /// 联赛选项 Mock 数据 (List<(String, String, IconData)> 类型, 中/英/图标三元组)
  /// 说明: 故意放 16 个让 Wrap 自动多行, 证明不会 overflow
  final List<(String, String, IconData)> _leagueOptions = const [
    ('英超', 'Premier League', Icons.sports_soccer),
    ('西甲', 'La Liga', Icons.sports_soccer),
    ('意甲', 'Serie A', Icons.sports_soccer),
    ('德甲', 'Bundesliga', Icons.sports_soccer),
    ('法甲', 'Ligue 1', Icons.sports_soccer),
    ('欧冠', 'Champions League', Icons.emoji_events),
    ('欧联', 'Europa League', Icons.emoji_events_outlined),
    ('亚冠', 'AFC Champions', Icons.public),
    ('中超', 'CSL', Icons.flag),
    ('日职联', 'J1 League', Icons.circle),
    ('K联赛', 'K League 1', Icons.sports_soccer),
    ('美职联', 'MLS', Icons.sports_soccer),
    ('NBA', 'NBA', Icons.sports_basketball),
    ('CBA', 'CBA', Icons.sports_basketball),
    ('EuroLeague', 'Euro Basketball', Icons.sports_basketball),
    ('WNBA', 'WNBA', Icons.sports_basketball),
  ];

  /// 场上位置 Mock 数据 (List<(String, String)> 类型, 中/英文)
  final List<(String, String)> _positionOptions = const [
    ('门将', 'GK'),
    ('左后卫', 'LB'),
    ('中后卫', 'CB'),
    ('右后卫', 'RB'),
    ('后腰', 'CDM'),
    ('中前卫', 'CM'),
    ('前腰', 'CAM'),
    ('左边锋', 'LW'),
    ('右边锋', 'RW'),
    ('中锋', 'ST'),
    ('控球后卫', 'PG'),
    ('得分后卫', 'SG'),
    ('小前锋', 'SF'),
    ('大前锋', 'PF'),
    ('中锋', 'C'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // ============ 构建入口 ============

  @override
  Widget buildBody(BuildContext context) {
    // 外层 SingleChildScrollView 兜底: 不论多少表单内容 + 任何屏幕尺寸,
    // 都不会出现 bottom overflow, 可一直滚动到底部提交按钮.
    // 额外叠加 MediaQuery.viewInsets.bottom (键盘弹出高度) 到 padding 底部,
    // 防止键盘弹起时误判为 bottom overflow.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 120 + bottomInset),
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavBar(context),
          const SizedBox(height: 16),
          _buildSectionTitle('基本信息', Icons.person_outline),
          const SizedBox(height: 8),
          _buildBasicInfoCard(),
          const SizedBox(height: 16),
          _buildLeagueSectionTitle(),
          const SizedBox(height: 8),
          _buildLeagueSelectionWrap(),
          const SizedBox(height: 16),
          _buildSectionTitle('擅长位置 (可多选)', Icons.filter_center_focus),
          const SizedBox(height: 8),
          _buildPositionSelectionWrap(),
          const SizedBox(height: 16),
          _buildSectionTitle('运动经历', Icons.menu_book_outlined),
          const SizedBox(height: 8),
          _buildExperienceCard(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ============ 顶部导航 ============

  /// 自定义导航栏 (返回 + 居中标题)
  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        border: Border(
          bottom: BorderSide(color: BMColors.pitch800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: BMColors.textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Expanded(
            child: Text(
              '球员信息申请',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BMColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// 构建段落标题 (左图标 + 文字)
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: BMColors.bright),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }

  /// 联赛段落专用标题 (右侧带「展开/收起」按钮, 点击切换可折叠状态)
  Widget _buildLeagueSectionTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.emoji_events_outlined, size: 14, color: BMColors.bright),
            SizedBox(width: 6),
            Text(
              '擅长联赛 (可多选)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => setState(() => _leagueExpanded = !_leagueExpanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: _leagueExpanded ? 0.5 : 0,
                  curve: Curves.easeOut,
                  child: const Icon(Icons.expand_more, size: 17, color: BMColors.bright),
                ),
                const SizedBox(width: 3),
                Text(
                  _leagueExpanded ? '收起' : '展开',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BMColors.bright,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============ 基本信息卡片 ============

  /// 基本信息表单卡片 (头像 + 姓名 + 性别 + 生日 + 身高体重)
  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildAvatarPicker(),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _nameController,
            label: '真实姓名',
            hintText: '请输入球员真实姓名',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _buildGenderSelector(),
          const SizedBox(height: 12),
          _buildBirthdayPicker(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _heightController,
                  label: '身高 (cm)',
                  hintText: '例如 185',
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: '体重 (kg)',
                  hintText: '例如 78',
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 头像选择组件 (圆形 + 点击换头像占位回调)
  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: () {
        debugPrint('BMApplyPlayerInfoPage 点击更换头像 (占位)');
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BMColors.bright, width: 1.5),
              color: BMColors.pitch800,
            ),
            child: const Icon(Icons.person, size: 36, color: BMColors.bright),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: BMColors.bright,
              shape: BoxShape.circle,
              border: Border.all(color: BMColors.pitch850, width: 2),
            ),
            child: const Icon(Icons.camera_alt, size: 13, color: BMColors.pitch950),
          ),
        ],
      ),
    );
  }

  /// 封装通用输入框 (label + TextField + 左图标 + 右下描边容器)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BMColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: BMColors.pitch950.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BMColors.pitch700),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BMColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 12, color: BMColors.textTertiary),
              icon: Icon(icon, size: 16, color: BMColors.bright),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  /// 性别选择器 (横向 3 个 chip 单选)
  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '性别',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BMColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: _genderOptions.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            final isSelected = _genderIndex == idx;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: idx != _genderOptions.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _genderIndex = idx),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? BMColors.bright.withValues(alpha: 0.15)
                          : BMColors.pitch950.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? BMColors.bright : BMColors.pitch700,
                        width: isSelected ? 1.2 : 0.6,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.$2,
                          size: 14,
                          color: isSelected ? BMColors.bright : BMColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? BMColors.bright : BMColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 出生日期选择 (左图标 + 右选中年月日 + 点击弹 DatePicker)
  Widget _buildBirthdayPicker() {
    final display = _birthday == null
        ? '请选择出生日期'
        : '${_birthday!.year.toString()}-'
            '${_birthday!.month.toString().padLeft(2, '0')}-'
            '${_birthday!.day.toString().padLeft(2, '0')}';
    final displayColor = _birthday == null ? BMColors.textTertiary : BMColors.textPrimary;
    return GestureDetector(
      onTap: _pickBirthday,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '出生日期',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: BMColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: BMColors.pitch950.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BMColors.pitch700),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 16, color: BMColors.bright),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: displayColor,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: BMColors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 弹出系统 DatePicker 选择生日
  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 60);
    final last = DateTime(now.year - 10);
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25, 6, 1),
      firstDate: first,
      lastDate: last,
      locale: const Locale('zh', 'CN'),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.dark(
              primary: BMColors.bright,
              surface: BMColors.pitch900,
              onSurface: BMColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: BMColors.pitch950),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: BMColors.pitch900,
              headerBackgroundColor: BMColors.pitch850,
              headerForegroundColor: BMColors.bright,
              dayForegroundColor: WidgetStateProperty.all(BMColors.textPrimary),
              todayForegroundColor: WidgetStateProperty.all(BMColors.bright),
              todayBackgroundColor: WidgetStateProperty.all(
                BMColors.bright.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _birthday = picked);
    }
  }

  // ============ 联赛选择 (核心: 使用Wrap, 绝对不会bottom overflow) ============

  /// 擅长联赛多选列表
  /// 说明: 这里刻意使用 Wrap (不是固定高度ListView, 不是Row, 不是Column)
  ///      Wrap 会根据屏幕宽度自动换行, 每一行的元素数量自适应,
  ///      整体高度由内容撑开, 外层 SingleChildScrollView 继续滚动到底.
  ///      与联赛选择相同模式的还有下方位置选择, 双保险杜绝 bottom overflow.
  /// 擅长联赛多选 (可折叠UI完全符合需求: 默认1行, 展开=4行, 超4行可竖直滑动)
  /// 1) 默认 _leagueExpanded=false: AnimatedContainer maxHeight=_oneLeagueRowHeight (1行),
  ///    physics=NeverScrollableScrollPhysics, 多余chip被Clip.antiAlias裁剪
  /// 2) 点击右上展开按钮 _leagueExpanded=true: maxHeight=4行高度, physics=AlwaysScrollable,
  ///    当联赛chip总数 > 4行时, 竖直滚动查看所有联赛
  Widget _buildLeagueSelectionWrap() {
    final maxH = _leagueExpanded
        ? _oneLeagueRowHeight * _maxLeagueRows
        : _oneLeagueRowHeight;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        constraints: BoxConstraints(maxHeight: maxH),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
        child: SingleChildScrollView(
          physics: _leagueExpanded
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: _leagueOptions.asMap().entries.map((entry) {
              final idx = entry.key;
              final lg = entry.value;
              final isSelected = _selectedLeagueIndices.contains(idx);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedLeagueIndices.remove(idx);
                    } else {
                      _selectedLeagueIndices.add(idx);
                    }
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BMColors.bright.withValues(alpha: 0.15)
                        : BMColors.pitch900.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? BMColors.bright
                          : BMColors.pitch700.withValues(alpha: 0.6),
                      width: isSelected ? 1.2 : 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        lg.$3,
                        size: 14,
                        color: isSelected ? BMColors.bright : BMColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lg.$1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? BMColors.bright : BMColors.textPrimary,
                            ),
                          ),
                          Text(
                            lg.$2,
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? BMColors.bright.withValues(alpha: 0.75)
                                  : BMColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      if (isSelected)
                        const Icon(Icons.check_circle, size: 13, color: BMColors.bright),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============ 位置选择 (同Wrap策略) ============

  /// 场上位置多选 (Wrap 自适应多行, 无固定高度, 不溢出)
  Widget _buildPositionSelectionWrap() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _positionOptions.asMap().entries.map((entry) {
          final idx = entry.key;
          final pos = entry.value;
          final isSelected = _selectedPositionIndices.contains(idx);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedPositionIndices.remove(idx);
                } else {
                  _selectedPositionIndices.add(idx);
                }
              });
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              constraints: const BoxConstraints(minWidth: 72),
              decoration: BoxDecoration(
                color: isSelected
                    ? BMColors.accent.withValues(alpha: 0.18)
                    : BMColors.pitch900.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? BMColors.accent : BMColors.pitch700.withValues(alpha: 0.6),
                  width: isSelected ? 1.2 : 0.6,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pos.$1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? BMColors.accent : BMColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pos.$2,
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                      color: isSelected
                          ? BMColors.accent.withValues(alpha: 0.8)
                          : BMColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============ 运动经历 & 提交 ============

  /// 运动经历文本框 (多行)
  Widget _buildExperienceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: _buildTextField(
        controller: _experienceController,
        label: '运动经历 / 获奖情况 / 所属俱乐部',
        hintText: '例如: 2018-2022 曼彻斯特城青年队; 2022 全国U23锦标赛冠军...',
        icon: Icons.edit_note,
        maxLines: 5,
      ),
    );
  }

  /// 底部提交按钮 (禁用态 / 加载中)
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submitForm,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [BMColors.accent, Color(0xFF2DD4BF)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: BMColors.accent.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_and_archive, size: 15, color: BMColors.pitch950),
            SizedBox(width: 6),
            Text(
              '提交球员信息申请',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: BMColors.pitch950,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 表单提交 (占位逻辑: debugPrint, 以后替换为真实POST接口)
  Future<void> _submitForm() async {
    final name = _nameController.text.trim();
    final height = _heightController.text.trim();
    final weight = _weightController.text.trim();
    final experience = _experienceController.text.trim();
    debugPrint('====================================');
    debugPrint('📝 BMApplyPlayerInfoPage 提交球员申请');
    debugPrint('  姓名=$name');
    debugPrint('  性别=${_genderOptions[_genderIndex].$1}');
    debugPrint('  生日=${_birthday?.toIso8601String() ?? "未选择"}');
    debugPrint('  身高=${height.isEmpty ? "未填" : "$height cm"}');
    debugPrint('  体重=${weight.isEmpty ? "未填" : "$weight kg"}');
    debugPrint('  擅长联赛=${_selectedLeagueIndices.map((i) => _leagueOptions[i].$1).join(",")}');
    debugPrint('  擅长位置=${_selectedPositionIndices.map((i) => _positionOptions[i].$1).join(",")}');
    debugPrint('  运动经历=${experience.isEmpty ? "未填" : experience.length}字');
    debugPrint('====================================');
  }
}
