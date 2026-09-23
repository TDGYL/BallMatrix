/// BMPlayerInfo - 足球球员信息
/// API：GET /api/livespeed/football/match/player-info?player_id=&match_id=
/// 用户指定返回结构：
///   position: "F" (G 守门员 / D 后卫 / M 中场 / F 前锋)
///   player_id: 101246223
///   player_name: "内马尔"
///   player_logo: ""
///   shirt_number: 0
///   country_name: ""
///   country_logo: ""
///   market_value: 0
///   market_value_currency: "EUR"
///   weight: 0 (kg)
///   height: 0 (cm)
class BMPlayerInfo {
  /// 球员ID (int 类型, 请求必传参数)
  final int playerId;

  /// 球员名 (String? 类型)
  final String? playerName;

  /// 球员头像 URL (String? 类型)
  final String? playerLogo;

  /// 球衣号码 (int? 类型)
  final int? shirtNumber;

  /// 场上位置缩写 (String? 类型: G/D/M/F)
  final String? position;

  /// 国家名 (String? 类型)
  final String? countryName;

  /// 国家队 Logo URL (String? 类型)
  final String? countryLogo;

  /// 市场价值 (int? 类型, 单位: market_value_currency)
  final int? marketValue;

  /// 价值货币单位 (String? 类型, 例 EUR / USD / CNY)
  final String? marketValueCurrency;

  /// 身高 cm (int? 类型)
  final int? height;

  /// 体重 kg (int? 类型)
  final int? weight;

  const BMPlayerInfo({
    this.playerId = 0,
    this.playerName,
    this.playerLogo,
    this.shirtNumber,
    this.position,
    this.countryName,
    this.countryLogo,
    this.marketValue,
    this.marketValueCurrency,
    this.height,
    this.weight,
  });

  factory BMPlayerInfo.fromJson(Map<String, dynamic> json) {
    final pid = json['player_id'] ?? json['playerId'];
    final mv = json['market_value'] ?? json['marketValue'];
    return BMPlayerInfo(
      playerId: (pid is num) ? pid.toInt() : (int.tryParse(pid?.toString() ?? '') ?? 0),
      playerName: (json['player_name'] ?? json['playerName'] ?? json['name'])?.toString(),
      playerLogo: (json['player_logo'] ?? json['playerLogo'] ?? json['avatar'] ?? json['photo'])?.toString(),
      shirtNumber: (json['shirt_number'] is num)
          ? (json['shirt_number'] as num).toInt()
          : (json['number'] is num ? (json['number'] as num).toInt() : null),
      position: (json['position'] ?? json['pos'])?.toString(),
      countryName: (json['country_name'] ?? json['countryName'] ?? json['nationality'])?.toString(),
      countryLogo: (json['country_logo'] ?? json['countryLogo'] ?? json['flag'])?.toString(),
      marketValue: (mv is num)
          ? mv.toInt()
          : (double.tryParse(mv?.toString() ?? '')?.toInt() ?? null),
      marketValueCurrency:
          (json['market_value_currency'] ?? json['marketValueCurrency'] ?? json['currency'])?.toString(),
      height: (json['height'] is num)
          ? (json['height'] as num).toInt()
          : (int.tryParse(json['height']?.toString() ?? '') ?? null),
      weight: (json['weight'] is num)
          ? (json['weight'] as num).toInt()
          : (int.tryParse(json['weight']?.toString() ?? '') ?? null),
    );
  }

  /// 位置缩写 → 中文全名 (用户 Bottom Sheet 展示用)
  String get positionFullLabel {
    switch ((position ?? '').toUpperCase()) {
      case 'G':
      case 'GK':
        return '守门员';
      case 'D':
      case 'DF':
        return '后卫';
      case 'M':
      case 'MF':
        return '中场';
      case 'F':
      case 'FW':
        return '前锋';
      default:
        return position ?? '-';
    }
  }

  /// 身高格式化: 180 → 180cm
  String get heightLabel {
    if (height == null || height == 0) return '-';
    return '${height}cm';
  }

  /// 体重格式化: 70 → 70kg
  String get weightLabel {
    if (weight == null || weight == 0) return '-';
    return '${weight}kg';
  }

  /// 身价格式化（简短显示）：1000000 → "€100万" (万/亿自动换算)
  String get marketValueLabel {
    if (marketValue == null || marketValue == 0) return '-';
    final unit = marketValueCurrency?.isNotEmpty == true ? _currencySymbol(marketValueCurrency!) : '';
    final v = marketValue!;
    String numStr;
    if (v >= 100000000) {
      numStr = '${(v / 100000000).toStringAsFixed(1)}亿';
    } else if (v >= 10000) {
      numStr = '${(v / 10000).toStringAsFixed(0)}万';
    } else {
      numStr = '$v';
    }
    return '$unit$numStr';
  }

  /// 货币代号 → 符号映射
  static String _currencySymbol(String code) {
    final up = code.toUpperCase();
    if (up == 'EUR') return '€';
    if (up == r'€') return '€';
    if (up == 'USD') return r'$';
    if (up == r'$') return r'$';
    if (up == 'CNY' || up == 'RMB') return '¥';
    if (up == '¥') return '¥';
    if (up == 'GBP') return '£';
    if (up == '£') return '£';
    if (up == 'JPY') return '¥';
    if (up == '円') return '¥';
    return '$code ';
  }
}
