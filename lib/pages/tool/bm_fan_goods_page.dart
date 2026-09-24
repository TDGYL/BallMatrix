import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';
import '../../models/bm_goods_model.dart';
import '../../services/bm_goods_api_service.dart';

/// BMFanGoodsPage - Fan Goods(merchandise)page
/// datasource: assets/data/goodsList.xlsx (localsheet, 23file)
/// feature: primary categorydirectionmenufilter + statefilter (all/Want/Watching/Owned)
/// + columncard (image/name/team/brand/grid/state)
/// architecture: MVVM Viewlayer, extends BMBasePage, one class per file
class BMFanGoodsPage extends BMBasePage {
 const BMFanGoodsPage({super.key});

 @override
 State<BMFanGoodsPage> createState() => _BMFanGoodsPageState();
}

class _BMFanGoodsPageState extends BMBasePageState<BMFanGoodsPage> {
 /// fullvolumelist (List<BMGoodsModel> type, API response)
 List<BMGoodsModel> _allGoods = [];

 /// primary categorylist (List<String> type, sheetdeduplicate, positioninsert 'all')
  List<String> _categories = ['all'];

 /// currentselected of primary category (String type, 'all'=no filter)
 String _currentCategory = 'all';

 /// currentselected of statefilter (String type, 'all'/'Want'/'Watching'/'Owned')
  String _currentStatus = 'all';

 /// loadingstate (bool type, true=skeleton)
 bool _isLoading = true;

 @override
 void initState() {
 super.initState();
 _fetchGoods();
 }

 /// loadingdata (local xlsx parse)
 Future<void> _fetchGoods() async {
 final goods = await BMGoodsApiService.instance.fetchAllGoods();
 final categories = await BMGoodsApiService.instance.fetchCategories();
 if (!mounted) return;
 setState(() {
 _allGoods = goods;
 _categories = ['all',...categories];
 _isLoading = false;
 });
 }

 /// currentfilterlater of list (getter, split classes + statedoubleheavyfilter)
 List<BMGoodsModel> get _filteredGoods {
 return _allGoods.where((g) {
 final catOk = _currentCategory == 'all' || g.category == _currentCategory;
      final statusOk = _currentStatus == 'all' || g.status == _currentStatus;
 return catOk && statusOk;
 }).toList();
 }

 /// stateoption (List<String> type, fixed4item)
 static const List<String> _statusFilters = ['all', 'Want', 'Watching', 'Owned'];

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

 /// topnavigation (returns + title + total)
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
 _isLoading ? 'Fan Goods' : 'Fan Goods (${_allGoods.length})',
 style: const TextStyle(
 color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
),
);
 }

 /// primary categorydirectionmenu (all + sheet3itemssplit classes)
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
 color: active ? BMColors.bright: BMColors.pitch850,
 borderRadius: BorderRadius.circular(20),
 border: Border.all(
 color:
 active ? BMColors.bright: BMColors.pitch700,
),
),
 alignment: Alignment.center,
 child: Text(
 cat,
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w700,
 color: active ? BMColors.pitch950: BMColors.textPrimary,
),
),
),
);
 },
),
);
 }

 /// statefilterline (all/Want/Watching/Owned smallpill)
 Widget _buildStatusBar() {
 return Container(
 color: BMColors.pitch950,
 padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
 child: Row(
 children: _statusFilters.map((s) {
 final active = _currentStatus == s;
 final count = s == 'all'
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
 color: active ? BMColors.bright: BMColors.textTertiary,
),
),
),
),
);
 }).toList(),
),
);
 }

 /// loadingskeleton (columncolorplaceholdercard)
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

 /// columngrid
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
 const Text('No Related Goods',
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

 /// buildsingleitemsgoods card
 /// [goods] - model (BMGoodsModel type)
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
 // imagezone (fixedratioexample, failureplaceholder)
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
 // textzone (Expanded adaptiveremaining height, lengthnamenotoverflow)
 Expanded(
 child: Padding(
 padding: const EdgeInsets.all(10),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // name
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
 // team/star player + state line
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
 // flexibleinterval (receiveremainingheight, insufficientwhencompressas 0)
 const Spacer(),
 // grid + brand (fixedpinned to bottom)
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

 /// detailbottom sheet
 /// [goods] - model (BMGoodsModel type)
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
 // large
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
 // name + state
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
 // grid
 Text(
 goods.priceText,
 style: const TextStyle(
 color: BMColors.bright,
 fontSize: 20,
 fontWeight: FontWeight.w900),
),
 const SizedBox(height: 12),
 // propertytaggrid (split classes/sport/team/brand/material/remark)
 _buildDetailRow('split classes', '${goods.category} · ${goods.subCategory}'),
            _buildDetailRow('applicable sport', goods.sport),
            _buildDetailRow('team/star player', goods.team == '-' ? 'common' : goods.team),
            _buildDetailRow('brand', goods.brandDisplay),
            _buildDetailRow('spec/material', goods.spec),
            if (goods.remark != '-')
              _buildDetailRow('remark', goods.remark),
            const SizedBox(height: 18),
            // closebutton
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
                  'know',
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

 /// detailpropertyline (lefttagrightvalue)
 /// [label] - tag (String type)
 /// [value] - value (String type)
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
