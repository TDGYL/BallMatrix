import 'package:flutter/material.dart';

import '../../models/bm_search_match_model.dart';
import '../../services/bm_community_api_service.dart';
import '../../theme/bm_colors.dart';
import '../bm_base_page.dart';

/// BMPostTopicMatchSearchPage - 发布话题的关联比赛搜索页
/// 功能与接口对齐 hanklive HankPostMatchSearchPage:
///   - 关键词搜索: GET /api/livespeed/index/search (text=关键词, 取 matches 分组)
///   - 热门比赛:   GET /api/livespeed/index/search/match/hot
///   - 点击任意比赛卡片 pop 回发布页并携带 BMSearchMatch
/// 界面差异化: 深色球场绿主题 (pitch950 底 + 亮绿描边卡片 + 左右队名内侧布局),
///   参照页为浅紫白底卡片 + 居中 VS 渐变胶囊, 视觉完全区分
class BMPostTopicMatchSearchPage extends BMBasePage {
  const BMPostTopicMatchSearchPage({super.key});

  @override
  State<BMPostTopicMatchSearchPage> createState() =>
      _BMPostTopicMatchSearchPageState();
}

class _BMPostTopicMatchSearchPageState
    extends BMBasePageState<BMPostTopicMatchSearchPage> {
  /// 社区 API 服务 (BMCommunityApiService 类型, 搜索/热门接口)
  final BMCommunityApiService _apiService = BMCommunityApiService();

  /// 搜索框控制器 (TextEditingController 类型)
  final TextEditingController _searchController = TextEditingController();

  /// 当前搜索关键词 (String 类型, 非空时展示搜索结果区)
  String _keyword = '';

  /// 搜索结果 - 足球列表 (List<BMSearchMatch> 类型, category=1)
  List<BMSearchMatch> _footballSearch = [];

  /// 搜索结果 - 篮球列表 (List<BMSearchMatch> 类型, category=2)
  List<BMSearchMatch> _basketballSearch = [];

  /// 热门比赛 - 足球列表 (List<BMSearchMatch> 类型, category=1)
  List<BMSearchMatch> _footballHot = [];

  /// 热门比赛 - 篮球列表 (List<BMSearchMatch> 类型, category=2)
  List<BMSearchMatch> _basketballHot = [];

  /// 当前选中的运动 Tab (int 类型, 1=足球 2=篮球)
  int _currentCategory = 1;

  /// 搜索加载中 (bool 类型)
  bool _searchLoading = false;

  /// 热门加载中 (bool 类型)
  bool _hotLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHotMatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 请求热门比赛 (GET /api/livespeed/index/search/match/hot)
  /// 按 category 分流: 足球(1)添加数组一, 篮球(2)添加数组二
  Future<void> _fetchHotMatches() async {
    final result = await _apiService.fetchHotMatches();
    if (!mounted) return;
    setState(() {
      final football = <BMSearchMatch>[];
      final basketball = <BMSearchMatch>[];
      for (final m in result) {
        if (m.categoryId == 2) {
          basketball.add(m);
        } else {
          football.add(m);
        }
      }
      _footballHot = football;
      _basketballHot = basketball;
      _hotLoading = false;
    });
  }

  /// 关键词搜索比赛 (GET /api/livespeed/index/search)
  /// 过滤 data.matches 数组球类型分流: 足球(1)添加数组一, 篮球(2)添加数组二
  /// [text] - 搜索关键词 (String 类型, 球队名)
  Future<void> _doSearch(String text) async {
    final kw = text.trim();
    if (kw.isEmpty) {
      setState(() {
        _footballSearch = [];
        _basketballSearch = [];
        _keyword = '';
      });
      return;
    }
    setState(() {
      _keyword = kw;
      _searchLoading = true;
    });
    final result = await _apiService.fetchSearchResults(text: kw);
    if (!mounted) return;
    setState(() {
      final football = <BMSearchMatch>[];
      final basketball = <BMSearchMatch>[];
      for (final m in (result?.matches ?? [])) {
        if (m.categoryId == 2) {
          basketball.add(m);
        } else {
          football.add(m);
        }
      }
      _footballSearch = football;
      _basketballSearch = basketball;
      _searchLoading = false;
    });
  }

  /// 切换运动 Tab
  /// [category] - 目标类型 (int 类型, 1=足球 2=篮球)
  void _switchCategory(int category) {
    if (_currentCategory == category) return;
    setState(() {
      _currentCategory = category;
    });
  }

  /// 当前 Tab 对应的数据列表 (有关键词取搜索结果, 否则取热门)
  List<BMSearchMatch> get _currentList {
    final searching = _keyword.isNotEmpty;
    if (_currentCategory == 2) {
      return searching ? _basketballSearch : _basketballHot;
    }
    return searching ? _footballSearch : _footballHot;
  }

  @override
  Widget buildBody(BuildContext context) {
    return Container(
      color: BMColors.pitch950,
      child: Column(
        children: [
          _buildNavBar(),
          _buildSearchField(),
          _buildCategoryTabs(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// 顶部导航 (返回 + 标题)
  Widget _buildNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      decoration: BoxDecoration(
        color: BMColors.pitch950,
        border: Border(
          bottom: BorderSide(color: BMColors.pitch800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
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
              '选择比赛',
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

  /// 搜索输入框 (深色圆角 + 亮绿搜索图标)
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BMColors.pitch900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BMColors.pitch800),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: BMColors.bright),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 13,
                color: BMColors.textPrimary,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _doSearch,
              onChanged: (v) {
                if (v.isEmpty) _doSearch('');
              },
              decoration: const InputDecoration(
                isCollapsed: true,
                hintText: '搜索球队名称',
                hintStyle: TextStyle(
                  color: BMColors.textTertiary,
                  fontSize: 13,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 运动 Tab 菜单 (足球/篮球, Row+Expanded 均分宽度)
  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          Expanded(child: _buildCategoryTab('足球', 1)),
          const SizedBox(width: 10),
          Expanded(child: _buildCategoryTab('篮球', 2)),
        ],
      ),
    );
  }

  /// 单个运动 Tab (选中亮绿描边, 未选中灰描边)
  /// [label] - Tab 文案 (String 类型)
  /// [category] - Tab 类型 (int 类型, 1=足球 2=篮球)
  Widget _buildCategoryTab(String label, int category) {
    final bool selected = _currentCategory == category;
    return GestureDetector(
      onTap: () => _switchCategory(category),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? BMColors.bright.withValues(alpha: 0.12)
              : BMColors.pitch900,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? BMColors.bright : BMColors.pitch800,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? BMColors.bright : BMColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 主体内容 (按当前 Tab 展示对应分流列表, 有关键词=搜索结果 / 无关键词=热门比赛)
  Widget _buildBody() {
    final list = _currentList;
    final searching = _keyword.isNotEmpty;
    return ListView(
      key: ValueKey('body-$_currentCategory-$searching-$_keyword'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      children: [
        _buildSectionTitle(searching ? '搜索结果' : '热门比赛'),
        if (searching && _searchLoading)
          _buildLoading()
        else if (!searching && _hotLoading)
          _buildLoading()
        else if (list.isEmpty)
          _buildEmpty(searching ? '未找到相关比赛' : '暂无热门比赛')
        else
          ...list.map(_buildMatchItem),
      ],
    );
  }

  /// 分区标题 (左侧亮绿竖条 + 文案)
  /// [title] - 分区标题文案 (String 类型)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: BMColors.bright,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: BMColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 加载中占位
  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: BMColors.bright,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  /// 空态占位
  /// [text] - 空态文案 (String 类型)
  Widget _buildEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: BMColors.textTertiary),
        ),
      ),
    );
  }

  /// 单场比赛条目 (深色卡片: 联赛名顶部 + 左右队名/队标 + 中间比分)
  /// 差异化: 参照页为白底居中布局, 本页为深色 + 比分居中替代 VS 胶囊
  /// [m] - 搜索结果比赛 (BMSearchMatch 类型)
  Widget _buildMatchItem(BMSearchMatch m) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, m),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: BMColors.pitch900.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: BMColors.pitch800.withValues(alpha: 0.8),
          ),
        ),
        child: Column(
          children: [
            // 联赛名 (顶部小字)
            if ((m.competitionName ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  m.competitionName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: BMColors.textTertiary,
                  ),
                ),
              ),
            // 主队 + 比分 + 客队
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTeamLogo(m.homeTeamLogo, 26),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          m.homeTeamName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BMColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${m.homeTeamScore ?? 0} - ${m.awayTeamScore ?? 0}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: BMColors.bright,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          m.awayTeamName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BMColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      _buildTeamLogo(m.awayTeamLogo, 26),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 队标 (圆形深色底 + 网络 Logo + 失败兜底盾牌图标)
  /// [url] - Logo URL (String? 类型)
  /// [size] - 尺寸 (double 类型)
  Widget _buildTeamLogo(String? url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: BMColors.pitch800,
      ),
      child: ClipOval(
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(size),
              )
            : _fallbackIcon(size),
      ),
    );
  }

  /// 队标兜底图标 (盾牌)
  /// [size] - 尺寸 (double 类型)
  Widget _fallbackIcon(double size) {
    return Icon(
      Icons.shield,
      size: size * 0.55,
      color: BMColors.textTertiary,
    );
  }
}
