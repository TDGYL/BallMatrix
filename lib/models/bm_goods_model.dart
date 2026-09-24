/// BMGoodsModel - 球迷周边商品数据模型
/// 数据来源: assets/data/goodsList.xlsx (本地表格解析)
/// 架构: MVVM Model层
class BMGoodsModel {
  /// 序号 (int 类型, 表格第一列)
  final int index;

  /// 一级分类 (String 类型, 如: 球衣装备库/球星球鞋库/球迷文创周边)
  final String category;

  /// 二级分类 (String 类型, 如: 球队主客场球衣/复古球衣/足球战靴)
  final String subCategory;

  /// 商品名称 (String 类型, 如: 皇马 2024-25 主场球衣)
  final String name;

  /// 适用运动 (String 类型, 如: 足球/篮球/足球篮球)
  final String sport;

  /// 球队/球星 (String 类型, 如: 皇家马德里, '-' 表示无)
  final String team;

  /// 品牌 (String 类型, 如: Adidas/Nike/Puma, '-' 表示无)
  final String brand;

  /// 规格/材质 (String 类型, 如: 球迷版/棉涤混纺)
  final String spec;

  /// 参考价格, 单位元 (double 类型, 0 表示未知)
  final double price;

  /// 收藏状态 (String 类型, 如: 想入手/观望/已拥有)
  final String status;

  /// 备注 (String 类型, '-' 表示无)
  final String remark;

  /// 配图URL (String 类型, 商品图片网络地址)
  final String imageUrl;

  /// 构造函数
  const BMGoodsModel({
    required this.index,
    required this.category,
    required this.subCategory,
    required this.name,
    required this.sport,
    required this.team,
    required this.brand,
    required this.spec,
    required this.price,
    required this.status,
    required this.remark,
    required this.imageUrl,
  });

  /// 队伍/品牌展示文案 (getter, '-' 替换为空串, 用于卡片顶部胶囊)
  String get teamOrBrand => team == '-' ? brand : team;

  /// 品牌展示文案 (getter, '-' 替换为 '无品牌')
  String get brandDisplay => brand == '-' ? '通用' : brand;

  /// 状态对应颜色 (getter, 想入手=亮绿 / 观望=琥珀 / 已拥有=青色)
  int get statusColorValue {
    switch (status) {
      case '想入手':
        return 0xFF10B981;
      case '观望':
        return 0xFFFBBF24;
      case '已拥有':
        return 0xFF22D3EE;
      default:
        return 0xFF94A3B8;
    }
  }

  /// 价格展示文案 (getter, 如: '¥599' / '价格待定')
  String get priceText => price > 0 ? '¥${price.toStringAsFixed(0)}' : '价格待定';

  /// 从表格行数据构建模型
  /// [row] - 单行单元格数组 (List<String> 类型, 12列, 第0行为表头)
  /// 返回: BMGoodsModel 实例, 异常行返回默认空模型
  factory BMGoodsModel.fromRow(List<String> row) {
    String cell(int i) => i < row.length ? row[i].trim() : '';
    return BMGoodsModel(
      index: int.tryParse(cell(0)) ?? 0,
      category: cell(1),
      subCategory: cell(2),
      name: cell(3),
      sport: cell(4),
      team: cell(5),
      brand: cell(6),
      spec: cell(7),
      price: double.tryParse(cell(8)) ?? 0,
      status: cell(9),
      remark: cell(10),
      imageUrl: cell(11),
    );
  }
}
