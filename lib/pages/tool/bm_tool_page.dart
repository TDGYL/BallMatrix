import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_competition_model.dart';
import '../../services/bm_match_api_service.dart';

/// BMToolPage - 智算工具页
/// 功能: 展示高阶计算矩阵、雷达图、分析工具卡片
/// 架构: MVVM View层
/// 作用范围: 底部导航第三个Tab
class BMToolPage extends BMBasePage {
  const BMToolPage({super.key});

  @override
  State<BMToolPage> createState() => _BMToolPageState();
}

class _BMToolPageState extends BMBasePageState<BMToolPage> {
  /// 主队选择索引 (int 类型, 从0开始)
  int _teamAIndex = 0;

  /// 客队选择索引 (int 类型, 从0开始)
  int _teamBIndex = 0;

  /// 联赛筛选索引 (int 类型, 从0开始, 选中的真实联赛的数组下标)
  int _selectedLeagueIndex = 0;

  /// 联赛选择是否展开 (bool 类型, true=展开显示4行, false=折叠仅显示1行)
  bool _leagueExpanded = false;

  /// 联赛真实数据加载中标记 (bool 类型, 防止重复请求)
  bool _leaguesLoading = false;

  /// 联赛真实数据加载失败标记 (bool 类型, 区分『接口失败』和『接口成功但空数组』两种空态)
  bool _leagueLoadFailed = false;

  /// 联赛真实数据列表 (List<BMCompetitionModel> 类型, 从接口拉取, 初始化空)
  List<BMCompetitionModel> _leagues = [];

  /// 单行联赛chip区域高度 (double 类型, 估算用于折叠状态1行裁剪, 含 spacing)
  final double _oneLeagueRowHeight = 52;

  /// 展开状态最大显示行数 (int 类型, 按需求固定=4)
  final int _maxLeagueRows = 4;

  /// 比赛API服务实例 (BMMatchApiService 类型, 单例复用)
  final BMMatchApiService _apiService = BMMatchApiService();

  /// 是否计算中 (bool 类型)
  bool _isCalculating = false;

  /// 计算结果文本 (String 类型)
  String? _resultText;

  /// 主队列表 (Mock数据)
  final List<String> _teamAOptions = const ['皇家马德里', '阿森纳', '拜仁慕尼黑'];

  /// 客队列表 (Mock数据)
  final List<String> _teamBOptions = const ['曼彻斯特城', '切尔西', '巴黎圣日耳曼'];

  @override
  void initState() {
    super.initState();
    // 页面初始化时主动拉取真实联赛列表, 只请求一次不重复拉
    _loadCompetitionList();
  }

  /// 初始化加载联赛列表 (真实接口: GET /api/livespeed/football/competition/list)
  /// 异常时自动回退: 接口空/失败 = 保持_leagues=[] 让_buildLeagueFilter展示fallback占位
  Future<void> _loadCompetitionList() async {
    if (_leaguesLoading) return;
    setState(() {
      _leaguesLoading = true;
      _leagueLoadFailed = false;
    });
    try {
      debugPrint('🌐 BMToolPage initState 请求足球联赛列表');
      final list = await _apiService.fetchCompetitionList();
      if (!mounted) return;
      setState(() {
        _leagues = list;
        // 保证选中索引不越界
        if (_selectedLeagueIndex >= list.length) {
          _selectedLeagueIndex = list.isEmpty ? 0 : list.length - 1;
        }
        _leagueLoadFailed = list.isEmpty;
      });
      debugPrint('✅ BMToolPage initState 联赛列表应用成功: ${_leagues.length}条');
    } catch (e) {
      debugPrint('❌ BMToolPage initState 联赛列表请求异常: $e');
      if (mounted) setState(() => _leagueLoadFailed = true);
    } finally {
      if (mounted) setState(() => _leaguesLoading = false);
    }
  }


  @override
  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildRadarSection(),
          const SizedBox(height: 16),
          _buildToolGrid(),
        ],
      ),
    );
  }

  /// 构建页面头部
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory, size: 12, color: BMColors.bright),
                const SizedBox(width: 4),
                const Text(
                  '独家高阶计算矩阵',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BMColors.bright,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              '智算数据分析实验室',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: BMColors.pitch800,
            border: Border.all(color: BMColors.pitch700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '模型版本 v4.2',
            style: TextStyle(fontSize: 10, color: BMColors.textSecondary),
          ),
        ),
      ],
    );
  }

  /// 构建雷达图区域
  Widget _buildRadarSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRadarHeader(),
          const SizedBox(height: 12),
          _buildLeagueLabel(),
          const SizedBox(height: 8),
          _buildLeagueFilter(),
          const SizedBox(height: 14),
          _buildTeamSelectors(),
          const SizedBox(height: 14),
          _buildRadarPlaceholder(),
          const SizedBox(height: 14),
          _buildCalculateButton(),
        ],
      ),
    );
  }

  /// 构建联赛筛选标题标签 (右侧带「展开/收起」按钮, chevron随状态0.5圈旋转动画)
  Widget _buildLeagueLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(
              Icons.emoji_events_outlined,
              size: 12,
              color: BMColors.textSecondary,
            ),
            SizedBox(width: 4),
            Text(
              '选择联赛',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: BMColors.textSecondary,
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
                  child: const Icon(Icons.expand_more, size: 15, color: BMColors.bright),
                ),
                const SizedBox(width: 2),
                Text(
                  _leagueExpanded ? '收起' : '展开',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

  /// 构建联赛筛选列表 (可折叠三态完全符合需求)
  /// 折叠态: AnimatedContainer maxHeight = 1行(_oneLeagueRowHeight) + NeverScrollableScrollPhysics
  ///         -> 仅显示第一行, 多余chip被Clip.antiAlias裁剪不可见, 不可拖拽滚动
  /// 展开态: maxHeight = 4行(_oneLeagueRowHeight * _maxLeagueRows) + AlwaysScrollableScrollPhysics
  ///         -> 若联赛数 > 4行, 超出部分可上下拖动竖直滚动; 若<=4行则显示全部
  Widget _buildLeagueFilter() {
    final maxH = _leagueExpanded
        ? _oneLeagueRowHeight * _maxLeagueRows
        : _oneLeagueRowHeight;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      constraints: BoxConstraints(maxHeight: maxH),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
      child: SingleChildScrollView(
        physics: _leagueExpanded
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: _buildLeagueChipList(),
      ),
    );
  }

  /// 生成联赛chip的 children 列表 (统一入口 便于loading/fallback/真实三态切换)
  /// 1) _leaguesLoading=true: 显示灰色加载占位
  /// 2) _leagues.isEmpty: 显示「暂无联赛数据」fallback (避免空白或越界)
  /// 3) 有真实数据: 使用 BMCompetitionModel.name/cap/main 渲染, main=1 额外加「主流」星标
  Widget _buildLeagueChipList() {
    if (_leaguesLoading) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: List.generate(5, (_) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: BMColors.pitch900.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: BMColors.pitch700.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 58,
                  height: 10,
                  decoration: BoxDecoration(
                    color: BMColors.pitch700.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 38,
                  height: 8,
                  decoration: BoxDecoration(
                    color: BMColors.pitch800.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          );
        }),
      );
    }
    if (_leagues.isEmpty) {
      final icon = _leagueLoadFailed ? Icons.refresh : Icons.info_outline;
      final text = _leagueLoadFailed ? '联赛加载失败，点击重试' : '暂无联赛数据';
      return GestureDetector(
        onTap: () => _loadCompetitionList(),
        behavior: HitTestBehavior.opaque,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: BMColors.pitch900.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: BMColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 12, color: BMColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: _leagues.asMap().entries.map((entry) {
        final idx = entry.key;
        final lg = entry.value;
        final isSelected = _selectedLeagueIndex == idx;
        final isMain = lg.main == 1;
        return GestureDetector(
          onTap: () => setState(() => _selectedLeagueIndex = idx),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? BMColors.bright.withValues(alpha: 0.25)
                        : BMColors.pitch800,
                  ),
                  child: Text(
                    lg.cap.isEmpty ? '·' : lg.cap.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? BMColors.bright : BMColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lg.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? BMColors.bright : BMColors.textPrimary,
                      ),
                    ),
                    if (isMain) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 10, color: Color(0xFFFBBF24)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建雷达区域标题
  Widget _buildRadarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.pie_chart_outline,
              size: 14,
              color: BMColors.bright,
            ),
            const SizedBox(width: 6),
            const Text(
              '两球员多维雷达实力模型引擎',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
        const Text(
          '实时计算中',
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: BMColors.bright,
          ),
        ),
      ],
    );
  }

  /// 构建队伍选择器
  Widget _buildTeamSelectors() {
    return Row(
      children: [
        Expanded(
          child: _buildTeamSelector(
            'Player A',
            _teamAOptions,
            _teamAIndex,
            (v) => setState(() => _teamAIndex = v),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTeamSelector(
            'Player B',
            _teamBOptions,
            _teamBIndex,
            (v) => setState(() => _teamBIndex = v),
          ),
        ),
      ],
    );
  }

  /// 构建单个队伍选择器
  /// 参数: [label] 标签, [options] 选项列表, [selectedIndex] 选中索引, [onChanged] 回调
  Widget _buildTeamSelector(
    String label,
    List<String> options,
    int selectedIndex,
    ValueChanged<int> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: BMColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButton<int>(
            value: selectedIndex,
            underline: const SizedBox(),
            isExpanded: true,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: BMColors.textPrimary,
            ),
            dropdownColor: BMColors.pitch900,
            items: options
                .asMap()
                .entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => onChanged(v ?? 0),
          ),
        ],
      ),
    );
  }

  /// 构建雷达图占位
  Widget _buildRadarPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: BMColors.pitch950.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radar, size: 48, color: BMColors.bright),
            SizedBox(height: 8),
            Text(
              '多维雷达实力模型',
              style: TextStyle(fontSize: 12, color: BMColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建计算按钮
  Widget _buildCalculateButton() {
    return GestureDetector(
      onTap: _isCalculating ? null : _startCalculation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [BMColors.accent, Color(0xFF2DD4BF)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: BMColors.accent.withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isCalculating)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BMColors.pitch950,
                ),
              )
            else
              const Icon(Icons.play_arrow, size: 14, color: BMColors.pitch950),
            const SizedBox(width: 6),
            Text(
              _resultText ?? '生成战力报告',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: BMColors.pitch950,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 启动计算模拟
  void _startCalculation() {
    setState(() {
      _isCalculating = true;
      _resultText = '算力运算中...';
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _resultText = '生成战力报告';
        });
      }
    });
  }

  /// 构建工具卡片网格
  Widget _buildToolGrid() {
    final tools = [
      ('凯利与必发冷热指数', '捕获各大机构赔率异常偏离度与资金博弈方向', Icons.calculate, BMColors.cyan),
      ('历史交锋盘路克制', '结合裁判尺度、主客战术相克属性深挖克星指数', Icons.timeline, BMColors.purple),
      ('实时比赛 Momentum 走势', '分钟级进攻压制力曲线，捕捉临场进球信号', Icons.waves, BMColors.amber),
      (
        '异动指标实时预警',
        '自定义 xG 突破、红黄牌及剧烈水位变轨推送',
        Icons.notifications_off_outlined,
        BMColors.bright,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildToolCard(tool.$1, tool.$2, tool.$3, tool.$4);
      },
    );
  }

  /// 构建单个工具卡片
  /// 参数: [title] 标题, [desc] 描述, [icon] 图标, [color] 颜色
  Widget _buildToolCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: BMColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 10,
              height: 1.3,
              color: BMColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
