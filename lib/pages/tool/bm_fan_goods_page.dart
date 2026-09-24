import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_goods_model.dart';
import '../../services/bm_goods_api_service.dart';

/// BMFanGoodsPage - 球迷好物(周边)页面
/// 数据来源: assets/data/goodsList.xlsx (本地表格, 23件商品)
/// 功能: 一级分类横向菜单过滤 + 状态筛选 (全部/想入手/观望/已拥有)
///       + 两列瀑布卡片 (图片/名称/球队/品牌/价格/状态)
/// 架构: MVVM View层, 继承 BMBasePage, 单类单文件
class BMFanGoodsPage extends BMBasePage {
  const BMFanGoodsPage({super.key});

  @override
  State<BMFanGoodsPage> createState() => _BMFanGoodsPageState();
}

class _BMFanGoodsPageState extends BMBasePageState<BMFanGoodsPage> {
  /// 全量商品列表 (List<BMGoodsModel> 类型, 接口返回)
  List<BMGoodsModel> _allGoods = [];

  /// 一级分类列表 (List<String> 类型, 表格去重, 首位插入 '全部')
  List<String> _categories = ['全部'];

  /// 当前选中的一级分类 (String 类型, '全部'=不过滤)
  String _currentCategory = '全部';

  /// 当前选中的状态筛选 (String 类型, '全部'/'想入手'/'观望'/'已拥有')
  String _currentStatus = '全部';

  /// 加载状态 (bool 类型, true=骨架屏)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGoods();
  }

  /// 加载商品数据 (本地 xlsx 解析)
  Future<void> _fetchGoods() async {
    final goods = await BMGoodsApiService.instance.fetchAllGoods();
    final categories = await BMGoodsApiService.instance.fetchCategories();
    if (!mounted) return;
    setState(() {
      _allGoods = goods;
      _categories = ['全部', ...categories];
      _isLoading = false;
    });
  }

  /// 当前过滤后的列表 (getter, 分类 + 状态双重过滤)
  List<BMGoodsModel> get _filteredGoods {
    return _allGoods.where((g) {
      final catOk = _currentCategory == '全部' || g.category == _currentCategory;
      final statusOk = _currentStatus == '全部' || g.status == _currentStatus;
      return catOk && statusOk;
    }).toList();
  }

  /// 状态筛选项 (List<String> 类型, 固定4项)
  static const List<String> _statusFilters = ['全部', '想入手', '观望', '已拥有'];

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCategoryBar(),
          _buildStatusBar(),
          Expanded(
            child: _isLoading
                ? _buildSkeletonList()
                : _buildGoodsGrid(),
          ),
        ],
      ),
    );
  }

  /// 顶部导航 (返回 + 标题 + 商品总数)
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: BMColors.pitch950,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BMColors.pitch850,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
          ),
          child: const Icon(Icons.chevron_left,
              color: Colors.white, size: 18),
        ),
      ),
      title: Text(
        _isLoading ? '球迷好物' : '球迷好物 (${_allGoods.length})',
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }

  /// 一级分类横向菜单 (全部 + 表格3个分类)
  Widget _buildCategoryBar() {
    return Container(
      color: BMColors.pitch950,
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final active = _currentCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _currentCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? BMColors.bright : BMColors.pitch850,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      active ? BMColors.bright : BMColors.pitch700,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? BMColors.pitch950 : BMColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 状态筛选行 (全部/想入手/观望/已拥有 小胶囊)
  Widget _buildStatusBar() {
    return Container(
      color: BMColors.pitch950,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Row(
        children: _statusFilters.map((s) {
          final active = _currentStatus == s;
          final count = s == '全部'
              ? _allGoods.length
              : _allGoods.where((g) => g.status == s).length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _currentStatus = s),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active
                      ? BMColors.bright.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? BMColors.bright.withValues(alpha: 0.6)
                        : BMColors.pitch700.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '$s $count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: active ? BMColors.bright : BMColors.textTertiary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 加载骨架屏 (两列灰色占位卡)
  Widget _buildSkeletonList() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: BMColors.pitch850,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  /// 商品两列网格
  Widget _buildGoodsGrid() {
    final list = _filteredGoods;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 40, color: BMColors.textTertiary),
            const SizedBox(height: 10),
            const Text('暂无相关好物',
                style: TextStyle(
                    color: BMColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _buildGoodsCard(list[i]),
    );
  }

  /// 构建单个商品卡片
  /// [goods] - 商品模型 (BMGoodsModel 类型)
  Widget _buildGoodsCard(BMGoodsModel goods) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showGoodsDetail(goods),
      child: Container(
        decoration: BoxDecoration(
          color: BMColors.pitch850,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片区 (固定比例裁切, 失败占位)
            AspectRatio(
              aspectRatio: 1.35,
              child: Image.network(
                goods.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: BMColors.pitch800,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined,
                      size: 26, color: BMColors.textTertiary),
                ),
              ),
            ),
            // 文字区 (Expanded 自适应剩余高度, 长名称不溢出)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名称
                    Text(
                      goods.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: BMColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    // 球队/球星 + 状态 行
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goods.teamOrBrand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: BMColors.textTertiary, fontSize: 10),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(goods.statusColorValue)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(goods.statusColorValue)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            goods.status,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(goods.statusColorValue),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 弹性间隔 (吸收富余高度, 不足时压缩为 0)
                    const Spacer(),
                    // 价格 + 品牌 (固定贴底)
                    Row(
                      children: [
                        Text(
                          goods.priceText,
                          style: const TextStyle(
                              color: BMColors.bright,
                              fontSize: 13,
                              fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Text(
                          goods.brandDisplay,
                          style: const TextStyle(
                              color: BMColors.textTertiary, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 商品详情底部弹窗
  /// [goods] - 商品模型 (BMGoodsModel 类型)
  void _showGoodsDetail(BMGoodsModel goods) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: BMColors.pitch850,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 大图
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                goods.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: BMColors.pitch800,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined,
                      size: 40, color: BMColors.textTertiary),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // 名称 + 状态
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    goods.name,
                    style: const TextStyle(
                        color: BMColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        Color(goods.statusColorValue).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Color(goods.statusColorValue)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    goods.status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(goods.statusColorValue)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 价格
            Text(
              goods.priceText,
              style: const TextStyle(
                  color: BMColors.bright,
                  fontSize: 20,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            // 属性标签网格 (分类/运动/球队/品牌/材质/备注)
            _buildDetailRow('分类', '${goods.category} · ${goods.subCategory}'),
            _buildDetailRow('适用运动', goods.sport),
            _buildDetailRow('球队/球星', goods.team == '-' ? '通用' : goods.team),
            _buildDetailRow('品牌', goods.brandDisplay),
            _buildDetailRow('规格/材质', goods.spec),
            if (goods.remark != '-')
              _buildDetailRow('备注', goods.remark),
            const SizedBox(height: 18),
            // 关闭按钮
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BMColors.bright,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  '知道了',
                  style: TextStyle(
                      color: BMColors.pitch950,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// 详情属性行 (左标签右值)
  /// [label] - 标签 (String 类型)
  /// [value] - 值 (String 类型)
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: const TextStyle(
                    color: BMColors.textTertiary, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: BMColors.textPrimary,
                  fontSize: 11,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
