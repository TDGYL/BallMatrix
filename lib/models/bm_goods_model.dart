/// BMGoodsModel - fansmerchandisedatamodel
/// datasource: assets/data/goodsList.xlsx (localsheetparse)
/// architecture: MVVM Modellayer
class BMGoodsModel {
 /// index (int type, sheetNo. onecolumn)
 final int index;

 /// primary category (String type, e.g.: jerseybackupstorage/star playerbootsstorage/fanscreative merchandisemerchandise)
 final String category;

 /// secondary category (String type, e.g.: home and away jerseys/retro jerseys/football boots)
 final String subCategory;

 /// product name (String type, e.g.: 2024-25 homecourtjersey)
 final String name;

 /// applicable sport (String type, e.g.: football/basketball/footballbasketball)
 final String sport;

 /// team/star player (String type, e.g.: , '-' means none)
 final String team;

 /// brand (String type, e.g.: Adidas/Nike/Puma, '-' means none)
 final String brand;

 /// spec/material (String type, e.g.: fan edition/)
 final String spec;

 /// reference price, singlepositionelement (double type, 0 meansnot yetknow)
 final double price;

 /// collection status (String type, e.g.: Want/Watching/Owned)
 final String status;

 /// remark (String type, '-' means none)
 final String remark;

 /// URL (String type, imagenetwork)
 final String imageUrl;

 /// constructor
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

 /// team/brandshowtext (getter, '-' swapasemptystring, forcardtoppill)
 String get teamOrBrand => team == '-' ? brand: team;

 /// brandshowtext (getter, '-' swapas 'no brand')
  String get brandDisplay => brand == '-' ? 'common': brand;

 /// statecorrespondingcolor (getter, Want=bright green / Watching= / Owned=color)
 int get statusColorValue {
 switch (status) {
 case 'Want':
        return 0xFF10B981;
      case 'Watching':
        return 0xFFFBBF24;
      case 'Owned':
 return 0xFF22D3EE;
 default:
 return 0xFF94A3B8;
 }
 }

 /// gridshowtext (getter, e.g.: '¥599' / 'Price TBD')
  String get priceText => price > 0 ? '¥${price.toStringAsFixed(0)}' : 'Price TBD';

 /// fromsheetlinedatabuild model
 /// [row] - singlelinecellarray (List<String> type, 12column, No. 0lineastableheader)
 /// returns: BMGoodsModel instance, exceptionlinereturnsdefaultemptymodel
 factory BMGoodsModel.fromRow(List<String> row) {
 String cell(int i) => i < row.length ? row[i].trim(): '';
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
