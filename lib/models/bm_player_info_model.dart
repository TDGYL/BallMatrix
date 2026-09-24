/// BMPlayerInfo - footballplayerinfo
/// API：GET /api/livespeed/football/match/player-info?player_id=&match_id=
/// userspecifiedreturnsstructure：
/// position: "F" (G member / D laterguard / M incourt / F first forward)
/// player_id: 101246223
/// player_name: "inner"
///   player_logo: ""
///   shirt_number: 0
///   country_name: ""
///   country_logo: ""
///   market_value: 0
///   market_value_currency: "EUR"
/// weight: 0 (kg)
/// height: 0 (cm)
class BMPlayerInfo {
 /// playerID (int type, requestrequiredargument)
 final int playerId;

 /// playername (String? type)
 final String? playerName;

 /// playeravatar URL (String? type)
 final String? playerLogo;

 /// jerseynumber (int? type)
 final int? shirtNumber;

 /// courtupperpositionabbreviation (String? type: G/D/M/F)
 final String? position;

 /// countryname (String? type)
 final String? countryName;

 /// countryteam Logo URL (String? type)
 final String? countryLogo;

 /// courtvalue (int? type, singleposition: market_value_currency)
 final int? marketValue;

 /// valuesingleposition (String? type, example EUR / USD / CNY)
 final String? marketValueCurrency;

 /// height cm (int? type)
 final int? height;

 /// weight kg (int? type)
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

 /// positionabbreviation → intextfullname (user Bottom Sheet showusage)
 String get positionFullLabel {
 switch ((position ?? '').toUpperCase()) {
      case 'G':
      case 'GK':
        return 'member';
      case 'D':
      case 'DF':
        return 'laterguard';
      case 'M':
      case 'MF':
        return 'incourt';
      case 'F':
      case 'FW':
        return 'first forward';
      default:
        return position ?? '-';
 }
 }

 /// heightformat: 180 → 180cm
 String get heightLabel {
 if (height == null || height == 0) return '-';
    return '${height}cm';
 }

 /// weightformat: 70 → 70kg
 String get weightLabel {
 if (weight == null || weight == 0) return '-';
    return '${weight}kg';
 }

 /// market valueformat（display）：1000000 → "€10010k" (auto convert 10k/100M)
 String get marketValueLabel {
 if (marketValue == null || marketValue == 0) return '-';
    final unit = marketValueCurrency?.isNotEmpty == true ? _currencySymbol(marketValueCurrency!) : '';
    final v = marketValue!;
    String numStr;
    if (v >= 100000000) {
      numStr = '${(v / 100000000).toStringAsFixed(1)}100M';
    } else if (v >= 10000) {
      numStr = '${(v / 10000).toStringAsFixed(0)}10k';
    } else {
      numStr = '$v';
    }
    return '$unit$numStr';
 }

 /// No. → No.mapping
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
    if (up == '') return '¥';
    return '$code ';
  }
}
