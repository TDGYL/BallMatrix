import 'dart:math';
import 'package:flutter/material.dart';

import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_competition_model.dart';
import '../../models/bm_competition_season_model.dart';
import '../../models/bm_player_ability_model.dart';
import '../../models/bm_player_rank_model.dart';
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
  /// 主队(球员A)选择索引 (int 类型, 从0开始, 对应球员排行榜数组下标)
  int _teamAIndex = 0;

  /// 客队(球员B)选择索引 (int 类型, 从0开始, 对应球员排行榜数组下标)
  int _teamBIndex = 1;

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

  /// 赛季列表加载中标记 (bool 类型, 防止重复请求)
  bool _seasonsLoading = false;

  /// 赛季列表加载失败标记 (bool 类型)
  bool _seasonsLoadFailed = false;

  /// 当前联赛下的赛季列表 (List<BMCompetitionSeasonModel> 类型, 从接口拉取, 初始化空)
  List<BMCompetitionSeasonModel> _seasons = [];

  /// 当前选中的赛季ID (int 类型, 默认取赛季列表首个 seasonId, 用于请求球员榜)
  int _currentSeasonId = 0;

  /// 球员排行榜加载中标记 (bool 类型, 防止重复请求)
  bool _playerRanksLoading = false;

  /// 球员排行榜加载失败标记 (bool 类型, 区分『接口失败』和『接口成功但空数组』)
  bool _playerRankLoadFailed = false;

  /// 当前联赛+赛季下的球员排行数据 (List<BMPlayerRankModel> 类型, 从接口拉取, 初始化空)
  List<BMPlayerRankModel> _playerRanks = [];

  /// 左列表球员选择索引 (int 类型, 从0开始, 对应球员排行榜中的数组下标, 默认选中第1名)
  int _selectedPlayerLeftIndex = 0;

  /// 右列表球员选择索引 (int 类型, 从0开始, 对应球员排行榜中的数组下标, 默认选中第2名)
  int _selectedPlayerRightIndex = 1;

  /// 比赛API服务实例 (BMMatchApiService 类型, 单例复用)
  final BMMatchApiService _apiService = BMMatchApiService();

  /// 是否计算中 (bool 类型)
  bool _isCalculating = false;

  /// 计算结果文本 (String 类型)
  String? _resultText;

  /// 主队选项 (List<BMPlayerRankModel> 类型, 需求: 球员列表数据替代原来的球队展示)
  List<BMPlayerRankModel> get _teamAOptions => _playerRanks;

  /// 客队选项 (List<BMPlayerRankModel> 类型, 需求: 球员列表数据替代原来的球队展示)
  List<BMPlayerRankModel> get _teamBOptions => _playerRanks;

  /// 左侧(Player A=蓝色)球员能力雷达数据 (BMPlayerAbilityModel? 类型, 点击生成战力报告串行请求先A再B, 第一步赋值)
  BMPlayerAbilityModel? _playerLeftAbility;

  /// 右侧(Player B=粉色)球员能力雷达数据 (BMPlayerAbilityModel? 类型, A成功后再请求B, 第二步赋值)
  BMPlayerAbilityModel? _playerRightAbility;

  /// 球员能力请求中标记 (bool 类型, 防止重复点击生成战力报告)
  bool _abilitiesLoading = false;

  /// 球员能力请求失败标记 (bool 类型, 展示失败提示)
  bool _abilitiesLoadFailed = false;

  @override
  void initState() {
    super.initState();
    // 页面初始化时主动拉取真实联赛列表, 只请求一次不重复拉
    _loadCompetitionList();
  }

  /// 初始化加载联赛列表 (真实接口: GET /api/livespeed/football/competition/list)
  /// 链路: 联赛成功 → 默认选中 idx=0 → 请求赛季列表(_loadSeasonList) → 赛季首id → 请求球员列表(_loadPlayerRanks, key=k_shots_on)
  Future<void> _loadCompetitionList() async {
    if (_leaguesLoading) return;
    setState(() {
      _leaguesLoading = true;
      _leagueLoadFailed = false;
    });
    try {
      debugPrint('🌐 BMToolPage step1/3: 请求足球联赛列表');
      final list = await _apiService.fetchCompetitionList();
      if (!mounted) return;
      setState(() {
        _leagues = list;
        // ⭐️ 默认选中第一个联赛 (idx=0)
        _selectedLeagueIndex = list.isEmpty ? 0 : 0;
        _leagueLoadFailed = list.isEmpty;
      });
      debugPrint('✅ BMToolPage step1/3: 联赛列表应用成功: ${_leagues.length}条, 默认选中idx=$_selectedLeagueIndex');
      // ⭐️ step2: 联赛加载完成后, 请求该联赛的赛季列表
      if (_leagues.isNotEmpty) {
        await _loadSeasonList(_leagues[_selectedLeagueIndex].id);
      }
    } catch (e) {
      debugPrint('❌ BMToolPage step1/3: 联赛列表请求异常: $e');
      if (mounted) setState(() => _leagueLoadFailed = true);
    } finally {
      if (mounted) setState(() => _leaguesLoading = false);
    }
  }

  /// 加载指定联赛的赛季列表 (step2/3: 真实接口 GET /api/livespeed/football/competition/season-list)
  /// [competitionId] - 联赛唯一ID
  /// 成功后: 取首个赛季 seasonId (服务端已按 isCurrent=1 优先排第一) → step3 请求球员榜 key=k_shots_on
  Future<void> _loadSeasonList(int competitionId) async {
    if (_seasonsLoading) return;
    setState(() {
      _seasonsLoading = true;
      _seasonsLoadFailed = false;
      _seasons = [];
      _currentSeasonId = 0;
    });
    try {
      debugPrint('🌐 BMToolPage step2/3: 请求联赛[$competitionId]赛季列表');
      final list = await _apiService.fetchSeasonList(competitionId: competitionId);
      if (!mounted) return;
      setState(() {
        _seasons = list;
        // ⭐️ 需求: 选择赛季的第一个id (服务层已按 isCurrent=1 排序, 所以第一个就是当前赛季)
        _currentSeasonId = list.isEmpty ? 0 : list.first.seasonId;
        _seasonsLoadFailed = list.isEmpty;
      });
      debugPrint('✅ BMToolPage step2/3: 赛季列表成功: ${_seasons.length}条, 首赛季id=$_currentSeasonId');
      // ⭐️ step3: 赛季首id确定后, 请求球员榜 key=k_shots_on (射正数排行)
      if (_currentSeasonId > 0) {
        await _loadPlayerRanks(
          competitionId: competitionId,
          seasonId: _currentSeasonId,
          rankKey: 'k_shots_on',
        );
      }
    } catch (e) {
      debugPrint('❌ BMToolPage step2/3: 赛季列表请求异常: $e');
      if (mounted) setState(() => _seasonsLoadFailed = true);
    } finally {
      if (mounted) setState(() => _seasonsLoading = false);
    }
  }

  /// 加载指定联赛+赛季的球员排行榜 (step3/3: 真实接口 GET /api/livespeed/football/competition/player-rank)
  /// [competitionId] - 联赛唯一ID
  /// [seasonId] - 赛季ID (从赛季列表首项获取)
  /// [rankKey] - 数据维度: k_shots_on=射正(本页默认), k_goals=进球, 等等
  /// 成功后: 左=球员A默认 idx=0 第1名, 右=球员B默认 idx=1 第2名, 球队选择器_teamAIndex/_teamBIndex 同步; 越界兜底
  Future<void> _loadPlayerRanks({
    required int competitionId,
    required int seasonId,
    String rankKey = 'k_shots_on',
  }) async {
    if (_playerRanksLoading) return;
    setState(() {
      _playerRanksLoading = true;
      _playerRankLoadFailed = false;
    });
    try {
      debugPrint('🌐 BMToolPage step3/3: 请求联赛[$competitionId]赛季[$seasonId]球员排行 key=$rankKey');
      final list = await _apiService.fetchPlayerRank(
        competitionId: competitionId,
        seasonId: seasonId,
        key: rankKey,
      );
      if (!mounted) return;
      setState(() {
        _playerRanks = list;
        // 双球员对比 + 球队选择器 同步默认选中
        _selectedPlayerLeftIndex = list.isEmpty ? 0 : 0;
        _selectedPlayerRightIndex = list.length < 2 ? (list.isEmpty ? 0 : list.length - 1) : 1;
        // ⭐️ 需求第3点: _teamAOptions/_teamBOptions 用球员列表替代球队展示
        _teamAIndex = list.isEmpty ? 0 : 0;
        _teamBIndex = list.length < 2 ? (list.isEmpty ? 0 : list.length - 1) : 1;
        _playerRankLoadFailed = list.isEmpty;
      });
      debugPrint('✅ BMToolPage step3/3: 球员排行成功: ${_playerRanks.length}条, '
          '左idx=$_selectedPlayerLeftIndex, 右idx=$_selectedPlayerRightIndex, '
          '球员Aidx=$_teamAIndex, 球员Bidx=$_teamBIndex');
    } catch (e) {
      debugPrint('❌ BMToolPage step3/3: 球员排行请求异常: $e');
      if (mounted) setState(() => _playerRankLoadFailed = true);
    } finally {
      if (mounted) setState(() => _playerRanksLoading = false);
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
          onTap: () async {
            setState(() => _selectedLeagueIndex = idx);
            // ⭐️ 切换联赛时: 重走 step2→step3 链路 (赛季→球员)
            if (_leagues.isNotEmpty && idx < _leagues.length) {
              await _loadSeasonList(_leagues[idx].id);
            }
          },
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

  /// 构建队伍(球员)选择器
  /// ⭐️ 需求第3点: 原来的球队 Mock 展示改为球员列表展示 (_teamAOptions/_teamBOptions = _playerRanks)
  Widget _buildTeamSelectors() {
    return Row(
      children: [
        Expanded(
          child: _buildTeamSelector(
            'Player A',
            const Color(0xFF60A5FA),
            _teamAOptions,
            _teamAIndex,
            (v) => setState(() => _teamAIndex = v),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTeamSelector(
            'Player B',
            const Color(0xFFF472B6),
            _teamBOptions,
            _teamBIndex,
            (v) => setState(() => _teamBIndex = v),
          ),
        ),
      ],
    );
  }

  /// 构建单个队伍(球员)选择器
  /// ⭐️ 参数类型从 List<String> 改为 List<BMPlayerRankModel>, 显示 排名+头像+姓名+球队+数据值
  /// [label] - 标签 Player A / Player B
  /// [sideColor] - 侧色 (A=蓝 / B=粉)
  /// [options] - 球员列表 = _playerRanks (getter: _teamAOptions/_teamBOptions)
  /// [selectedIndex] - 选中索引
  /// [onChanged] - 选中回调 idx
  Widget _buildTeamSelector(
    String label,
    Color sideColor,
    List<BMPlayerRankModel> options,
    int selectedIndex,
    ValueChanged<int> onChanged,
  ) {
    final hasData = options.isNotEmpty && selectedIndex < options.length;
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
            style: TextStyle(fontSize: 10, color: sideColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          if (_playerRanksLoading)
            _buildTeamSelectorLoading(sideColor)
          else if (!hasData)
            _buildTeamSelectorEmpty(sideColor)
          else
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedIndex,
                isExpanded: true,
                itemHeight: 60,
                dropdownColor: BMColors.pitch900,
                icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: sideColor),
                borderRadius: BorderRadius.circular(12),
                items: options.asMap().entries.map((e) {
                  final idx = e.key;
                  final p = e.value;
                  return DropdownMenuItem<int>(
                    value: idx,
                    child: _buildTeamSelectorItem(
                      p: p,
                      sideColor: sideColor,
                      isSelected: idx == selectedIndex,
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (ctx) {
                  return options.asMap().entries.map((e) {
                    final idx = e.key;
                    final p = e.value;
                    return _buildTeamSelectorItem(
                      p: p,
                      sideColor: sideColor,
                      isSelected: idx == selectedIndex,
                      compact: true,
                    );
                  }).toList();
                },
                onChanged: (v) => onChanged(v ?? 0),
              ),
            ),
        ],
      ),
    );
  }

  /// 球队(球员)选择器加载中占位
  Widget _buildTeamSelectorLoading(Color sideColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: BMColors.pitch800)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, decoration: BoxDecoration(color: BMColors.pitch800, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 5),
                Container(width: 90, height: 9, decoration: BoxDecoration(color: BMColors.pitch800.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(3))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.hourglass_top_rounded, size: 14, color: sideColor.withValues(alpha: 0.7)),
        ],
      ),
    );
  }

  /// 球队(球员)选择器空态/失败占位
  Widget _buildTeamSelectorEmpty(Color sideColor) {
    // 优先级: 赛季加载中 > 赛季失败 > 球员加载中(上层已处理) > 球员失败 > 空数据
    IconData icon;
    String text;
    VoidCallback? onTap;
    if (_seasonsLoading) {
      icon = Icons.hourglass_top_rounded;
      text = '赛季加载中...';
      onTap = null;
    } else if (_seasonsLoadFailed) {
      // ⭐️ 接入 _seasonsLoadFailed, 消除 unused warning
      icon = Icons.refresh_rounded;
      text = '赛季加载失败点击重试';
      onTap = _leagues.isNotEmpty
          ? () => _loadSeasonList(_leagues[_selectedLeagueIndex].id)
          : null;
    } else if (_playerRankLoadFailed && _leagues.isNotEmpty && _currentSeasonId > 0) {
      icon = Icons.refresh_rounded;
      text = '加载失败点击重试';
      onTap = () => _loadPlayerRanks(
            competitionId: _leagues[_selectedLeagueIndex].id,
            seasonId: _currentSeasonId,
            rankKey: 'k_shots_on',
          );
    } else {
      icon = Icons.info_outline_rounded;
      text = '暂无球员数据';
      onTap = null;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 14, color: sideColor.withValues(alpha: 0.75)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  color: (_seasonsLoadFailed || _playerRankLoadFailed)
                      ? sideColor.withValues(alpha: 0.85)
                      : BMColors.textTertiary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单条球员项 (DropdownMenuItem / 收起选中态 复用)
  Widget _buildTeamSelectorItem({
    required BMPlayerRankModel p,
    required Color sideColor,
    required bool isSelected,
    bool compact = false,
  }) {
    final rankColor = p.position == 1
        ? const Color(0xFFFBBF24)
        : p.position == 2
            ? const Color(0xFF94A3B8)
            : p.position == 3
                ? const Color(0xFFD97706)
                : BMColors.textTertiary;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${p.position}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: rankColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? sideColor : BMColors.pitch700.withValues(alpha: 0.8),
                width: isSelected ? 1.4 : 0.6,
              ),
              color: BMColors.pitch800,
            ),
            clipBehavior: Clip.antiAlias,
            child: p.playerLogo.isNotEmpty
                ? Image.network(
                    p.playerLogo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        p.playerName.isEmpty ? '·' : p.playerName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? sideColor : BMColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      p.playerName.isEmpty ? '·' : p.playerName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? sideColor : BMColors.textSecondary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? sideColor : BMColors.textPrimary,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: BMColors.textTertiary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${p.total}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: sideColor,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                p.rankName,
                style: TextStyle(
                  fontSize: 9,
                  color: BMColors.textTertiary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建 6 边形多维雷达实力模型图
  /// 参考: MERadarChartView.m (6顶点=ATT/TEC/STA/DEF/POW/SPD, 4环刻度)
  /// 绘制 2 组数据（Player A 蓝色 + Player B 粉色）
  Widget _buildRadarPlaceholder() {
    const labels = BMPlayerAbilityModel.dimensionLabels;
    const leftColor = Color(0xFF60A5FA);
    const rightColor = Color(0xFFF472B6);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        color: BMColors.pitch950.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (_abilitiesLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: BMColors.bright)),
                  SizedBox(width: 6),
                  Text('战力数据拉取中...', style: TextStyle(fontSize: 10, color: BMColors.textSecondary)),
                ],
              ),
            )
          else if (_abilitiesLoadFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: _startCalculation,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.refresh_rounded, size: 12, color: BMColors.bright),
                    SizedBox(width: 6),
                    Text('战力数据拉取失败，点击重试', style: TextStyle(fontSize: 10, color: BMColors.bright)),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.radar_rounded, size: 12, color: BMColors.bright),
                  SizedBox(width: 4),
                  Text('多维雷达实力模型', style: TextStyle(fontSize: 10, color: BMColors.textSecondary)),
                ],
              ),
            ),
          // 主雷达区域：严格 220x220 正方形 ➔ Stack 叠 6 个 Label + CustomPaint
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景 CustomPaint = 刻度环 + 6轴线 + 2组（Player B底 / Player A顶）多边形
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BMRadarPainter(
                      labelsCount: labels.length,
                      rings: 4,
                      leftValues: _playerLeftAbility?.normalizedValues,
                      rightValues: _playerRightAbility?.normalizedValues,
                      leftColor: leftColor,
                      rightColor: rightColor,
                    ),
                  ),
                ),
                // 6 个角 Label: ATT(i=0) 保持下移100px, 其他5角(TEC/STA/DEF/POW/SPD) 再额外统一向下位移100像素
                ...List.generate(labels.length, (i) {
                  // ATT(i=0): 沿角度方向 -100 (正好向下100)
                  // TEC/STA/DEF/POW/SPD(i!=0): 在贴雷达顶点的基础上, 屏幕坐标系 y+=100 向下100像素
                  final ePx = i == 0 ? -100.0 : 0.0;
                  final eDy = i == 0 ?   0.0 : 100.0;
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: CustomSingleChildLayout(
                        delegate: _BMOffsetLayoutDelegate(
                          index: i,
                          count: labels.length,
                          extraPx: ePx,
                          extraDy: eDy,
                        ),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: BMColors.bright.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // 图例: 左蓝 / 右粉
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRadarLegend(leftColor, _playerLeftAbility?.playerName ?? 'Player A'),
                _buildRadarLegend(rightColor, _playerRightAbility?.playerName ?? 'Player B'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 单个雷达图例 (色块 + 球员名)
  Widget _buildRadarLegend(Color color, String name) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withValues(alpha: 0.9), width: 1),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 110,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
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

  /// 启动战力报告生成 = 串行请求（先 Player A，成功后再 Player B）→ 绘制双球员雷达图
  /// 链路: 校验选中 -> fetchPlayerAbility(playerA) 成功 -> fetchPlayerAbility(playerB) -> setState 双能力模型
  Future<void> _startCalculation() async {
    // 1. 校验: 球员列表完整 + 双选择下标合法
    if (_playerRanks.isEmpty ||
        _teamAIndex >= _playerRanks.length ||
        _teamBIndex >= _playerRanks.length) {
      setState(() {
        _abilitiesLoadFailed = true;
        _resultText = '请先选择对比球员';
      });
      return;
    }
    if (_abilitiesLoading || _isCalculating) return;
    final playerA = _playerRanks[_teamAIndex];
    final playerB = _playerRanks[_teamBIndex];
    setState(() {
      _isCalculating = true;
      _abilitiesLoading = true;
      _abilitiesLoadFailed = false;
      _playerLeftAbility = null;
      _playerRightAbility = null;
      _resultText = '拉取球员A战力数据中(1/2)...';
    });
    try {
      debugPrint(
        '🚀 BMToolPage 串行请求双球员: 先A=${playerA.playerId}(${playerA.playerName}) -> 后B=${playerB.playerId}(${playerB.playerName})',
      );
      // === 2. 第1步: 请求 Player A (左侧蓝色) ===
      final abA = await _apiService.fetchPlayerAbility(
        playerId: playerA.playerId,
        playerNameHint: playerA.playerName,
      );
      if (!mounted) return;
      if (abA == null) {
        setState(() {
          _abilitiesLoadFailed = true;
          _playerLeftAbility = null;
          _playerRightAbility = null;
          _resultText = '球员A战力数据拉取失败';
        });
        return;
      }
      setState(() {
        _playerLeftAbility = abA;
        _resultText = '拉取球员B战力数据中(2/2)...';
      });
      // === 3. 第2步: 请求 Player B (右侧粉色，A成功后才执行) ===
      final abB = await _apiService.fetchPlayerAbility(
        playerId: playerB.playerId,
        playerNameHint: playerB.playerName,
      );
      if (!mounted) return;
      if (abB == null) {
        setState(() {
          _abilitiesLoadFailed = true;
          // A 成功但 B 失败，保留 A 但提示失败
          _playerRightAbility = null;
          _resultText = '球员B战力数据拉取失败';
        });
        return;
      }
      // === 4. 双球员都成功，赋值触发雷达双绘制
      setState(() {
        _playerLeftAbility = abA;
        _playerRightAbility = abB;
        _abilitiesLoadFailed = false;
        final avgA =
            ((abA.att + abA.tec + abA.sta + abA.def + abA.pow + abA.spd) / 6)
                .toStringAsFixed(1);
        final avgB =
            ((abB.att + abB.tec + abB.sta + abB.def + abB.pow + abB.spd) / 6)
                .toStringAsFixed(1);
        _resultText = '战力对比: ${abA.playerName} $avgA vs ${abB.playerName} $avgB';
      });
      debugPrint(
        '✅ BMToolPage 串行双球员能力请求完成: A=${abA.playerName} avgA}, B=${abB.playerName}',
      );
    } catch (e) {
      debugPrint('❌ BMToolPage 球员能力串行请求异常: $e');
      if (mounted) {
        setState(() {
          _abilitiesLoadFailed = true;
          _resultText = '战力数据异常，重试';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _abilitiesLoading = false;
        });
      }
    }
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

// ============================================================================
// 雷达图坐标共享静态工具 (0 误差保证: _BMRadarPainter 和 _BMOffsetLayoutDelegate 都调用)
// - 1:1 对应 MERadarChartView.m line 124-127 顶点公式
// ============================================================================

/// 雷达图真实半径常量 (double 类型, 顶点到中心距离 = 雷达正方形最短边 * 0.36)
const double _kRadarRadiusRatio = 0.36;

/// 【唯一真值函数】计算雷达多边形顶点坐标 (雷达图和 Label 都用这一个, 0 误差)
/// [size] 雷达正方形尺寸 (220x220)
/// [index] 0..count-1 顶点索引 (0=ATT顶部, 3=DEF底部)
/// [count] 顶点总数 (固定 6)
/// [extraPx] 额外同方向外推像素 (0 = 标签中心点刚好在雷达顶点)
Offset _radarVertexPoint(Size size, int index, int count, double extraPx) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final maxR = min(size.width, size.height) * _kRadarRadiusRatio;
  final r = maxR + extraPx;
  // 顶点角度公式: -pi/2(正上方) + 2pi*i/count (顺时针)
  final angle = (-pi / 2) + (2 * pi * index / count);
  return Offset(cx + r * cos(angle), cy + r * sin(angle));
}

// ============================================================================
// 6 角 Label 定位器
// ============================================================================

/// Label 极坐标定位器 (调用共享函数 _radarVertexPoint, 0 误差)
/// ⚠️ Dart 不支持 class in class, 所以放在文件顶层
class _BMOffsetLayoutDelegate extends SingleChildLayoutDelegate {
  /// 顶点索引 (int 类型, 0..count-1, 0=ATT正上方, 3=DEF正下方)
  final int index;

  /// 顶点总数 (int 类型, 固定 6)
  final int count;

  /// 额外外推像素 (double 类型, 沿顶点角度方向, >0向外, <0向内; ATT i=0 时 -100 正好向下100)
  final double extraPx;

  /// 额外屏幕坐标系 dy 偏移 (double 类型, 屏幕 y 方向向下为正, 用于 TEC~SPD 5 个统一向下 100)
  final double extraDy;

  _BMOffsetLayoutDelegate({
    required this.index,
    required this.count,
    required this.extraPx,
    required this.extraDy,
  });

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // ⭐️ 唯一真值函数 _radarVertexPoint
    final vertex = _radarVertexPoint(size, index, count, extraPx);
    return Offset(
      vertex.dx - childSize.width / 2,
      vertex.dy - childSize.height / 2 + extraDy, // ⭐️ 叠加 extraDy (屏幕向下 +)
    );
  }

  @override
  bool shouldRelayout(_BMOffsetLayoutDelegate oldDelegate) {
    return index != oldDelegate.index ||
        count != oldDelegate.count ||
        extraPx != oldDelegate.extraPx ||
        extraDy != oldDelegate.extraDy;
  }
}

// ============================================================================
// 雷达图 CustomPainter (调用共享函数 _radarVertexPoint, 0 误差)
// 绘制顺序: 4 环刻度 -> 6 条轴线 -> Player B 粉色(底) -> Player A 蓝色(顶)
// ============================================================================

/// 雷达图绘制器 (刻度=4 环, MERadarChartView.m line 49)
/// ⚠️ Dart 不支持 class in class, 所以放在文件顶层
class _BMRadarPainter extends CustomPainter {
  final int labelsCount;
  final int rings;
  final List<double>? leftValues;
  final List<double>? rightValues;
  final Color leftColor;
  final Color rightColor;

  _BMRadarPainter({
    required this.labelsCount,
    required this.rings,
    required this.leftValues,
    required this.rightValues,
    required this.leftColor,
    required this.rightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(size.width, size.height) * _kRadarRadiusRatio;

    // === 1. Grid 4 环 6 边形刻度 (MERadarChartView line 49) ===
    final gridPaint = Paint()
      ..color = BMColors.bright.withValues(alpha: 0.22)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int r = 1; r <= rings; r++) {
      final rr = maxR * r / rings;
      final path = Path();
      for (int i = 0; i < labelsCount; i++) {
        // ⭐️ 唯一真值函数 _radarVertexPoint (extraPx = rr - maxR, 因为 maxR 是 r=rings 的半径)
        final p = _radarVertexPoint(size, i, labelsCount, rr - maxR);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // === 2. 6 条轴线 (中心 -> 雷达顶点) ===
    final axisPaint = Paint()
      ..color = BMColors.bright.withValues(alpha: 0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < labelsCount; i++) {
      final vertex = _radarVertexPoint(size, i, labelsCount, 0);
      canvas.drawLine(Offset(cx, cy), vertex, axisPaint);
    }

    // === 3. 双组能力多边形 (Player B 底, Player A 顶) ===
    void drawData(List<double> vals, Color color, double fillAlpha, double strokeAlpha) {
      if (vals.length != labelsCount) return;
      final path = Path();
      for (int i = 0; i < labelsCount; i++) {
        final v = vals[i].clamp(0.0, 1.0);
        // v=0 -> 中心, v=1 -> 雷达顶点 (maxR), 反推出 extraPx = v*maxR - maxR
        final extraAtRatio = maxR * (v - 1.0);
        final p = _radarVertexPoint(size, i, labelsCount, extraAtRatio);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      final fillPaint = Paint()
        ..color = color.withValues(alpha: fillAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
      final strokePaint = Paint()
        ..color = color.withValues(alpha: strokeAlpha)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, strokePaint);
      final dotPaint = Paint()
        ..color = color.withValues(alpha: strokeAlpha)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < labelsCount; i++) {
        final v = vals[i].clamp(0.0, 1.0);
        final extraAtRatio = maxR * (v - 1.0);
        final p = _radarVertexPoint(size, i, labelsCount, extraAtRatio);
        canvas.drawCircle(p, 2.2, dotPaint);
      }
    }

    if (rightValues != null) {
      drawData(rightValues!, rightColor, 0.18, 0.82);
    }
    if (leftValues != null) {
      drawData(leftValues!, leftColor, 0.24, 0.94);
    }
  }

  @override
  bool shouldRepaint(_BMRadarPainter oldDelegate) {
    return oldDelegate.leftValues != leftValues ||
        oldDelegate.rightValues != rightValues ||
        oldDelegate.labelsCount != labelsCount ||
        oldDelegate.rings != rings ||
        oldDelegate.leftColor != leftColor ||
        oldDelegate.rightColor != rightColor;
  }
}
