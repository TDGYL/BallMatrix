import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bm_player_ability_model.dart';

/// BMPlayerAbilityGenerator - playersixpowercountgeneratedevice (functiontoolclass)
/// rule (requirement 2026-09-23):
/// 1. ATT/TEC/STA/DEF/POW/SPD sixitemeachitemtake 1~100 count
/// 2. countptssortrule: playerAvolume27min > playerBvolume19min
/// => playerAsixitemdata of "mergevalue"(sixitemand) mustplayerB
/// 3. samepts of playernotdoconstraint (onlyconstraint"notsamepts" of closesystem)
/// implement (pts):
/// - ptsheight => sixitem"andpoint"large (gridptssingleadd, eachdiff1mintotallessdiff6)
/// - andlater, sixitem 1~100 innermin (eachitemstillyescount)
/// - andpoint: base = 100 + score*5 (score=19 -> 195, score=27 -> 235)
/// eachdiff 1 mintotaldiff 5, singleitemdegreenottheinterval => mergegrid
/// purposescope: toolpage「generate ability report」gettakesixitemdata (originalplayerdetailAPI)
class BMPlayerAbilityGenerator {
 /// privateconstructor (statictoolclass, forbiddeninstance)
 BMPlayerAbilityGenerator._();

 /// countkindsub (Random type, top levelreuseseries)
 static final Random _random = Random();

 /// singleitemcountlowerlimit (int type, requirement: 1-100 )
 static const int _minValue = 1;

 /// singleitemcountupperlimit (int type, requirement: 1-100 )
 static const int _maxValue = 100;

 /// sixitemdegreetotal (int type, ATT/TEC/STA/DEF/POW/SPD)
 static const int _dimensionCount = 6;

 /// totalpointoffset (int type, ptsplayerandalsomergezone)
 static const int _baseSum = 100;

 /// byptsgeneratesixitempowercount
 /// [playerId] - playeruniqueID (int type, onlyforbuild model)
 /// [playerName] - playername (String type, onlyforbuild model)
 /// [score] - playerpts (int type, e.g.: 27min/19min, valuelargesixitemmerge)
 /// returns: BMPlayerAbilityModel (sixitemas 1~100 count, mergedegreeandptsgridcenterrelated)
 static BMPlayerAbilityModel generate({
 required int playerId,
 required String playerName,
 required int score,
 }) {
 // 1. totalpoint: score eachdiff 1 min, sixitemandlessdiff 5 (2*_jitter=4 < 5, grid)
 final targetSum = (_baseSum + score * 5).clamp(
 _dimensionCount * _minValue,
 _dimensionCount * _maxValue,
);
 // 2. sixitem 1~100 innermintheand (firstequally divided, againmakemake)
 final values = _distributeRandom(targetSum);
 return BMPlayerAbilityModel(
 playerId: playerId,
 playerName: playerName,
 att: values[0],
 tec: values[1],
 sta: values[2],
 def: values[3],
 pow: values[4],
 spd: values[5],
);
 }

 /// willgoalandminto 6 item, eachitem 1~100
 /// [targetSum] - sixitemandgoalvalue (int type, 6~600)
 /// returns: List int sixitemvalue (andwait targetSum, eachitem 1~100)
 static List<int> _distributeRandom(int targetSum) {
 // 2a. equally divided: + remainingcountfirstitem +1
 final base = targetSum ~/ _dimensionCount;
 final rem = targetSum % _dimensionCount;
 final values = List<int>.generate(
 _dimensionCount,
 (i) => base + (i < rem ? 1: 0),
);
 // 2b. : convert (keepandnotchange, makemakesixitemdiff)
 for (int round = 0; round < 8; round++) {
 final i = _random.nextInt(_dimensionCount);
 final j = _random.nextInt(_dimensionCount);
 if (i == j) continue;
 // canconvertvolume: i notability 1, j notabilityheight 100
 final maxGive = values[i] - _minValue;
 final maxTake = _maxValue - values[j];
 final cap = maxGive < maxTake ? maxGive: maxTake;
 if (cap <= 0) continue;
 final move = _random.nextInt(cap + 1);
 values[i] -= move;
 values[j] += move;
 }
 return values;
 }
}

/// BMPlayerAbilityStore - playersixpowerlocalstorageservice (SharedPreferences persist)
/// rule (requirement 2026-09-23):
/// 1. generatecountbeforefirstlocalcache, hit inreturns (sameoneplayersixitemdatanotchange)
/// 2. localnonecachegeneratecount, generatelaterimmediatelywritebacklocal
/// 3. storagedegree: by playerId onepeopleoneitems, key = bm_player_ability_{playerId}
/// purposescope: toolpage「generate ability report」countcachereadwrite
class BMPlayerAbilityStore {
 /// privateconstructor (statictoolclass, forbiddeninstance)
 BMPlayerAbilityStore._();

 /// storagekeyfirst (String type, concat playerId makeusage)
 static const String _keyPrefix = 'bm_player_ability_';

 /// fromlocalreadplayersixpower
 /// [playerId] - playeruniqueID (int type)
 /// [playerName] - playername (String type, localcachenonenametextwhenfallback)
 /// returns: BMPlayerAbilityModel? (localnonecache/parsefailurereturns null)
 static Future<BMPlayerAbilityModel?> load({
 required int playerId,
 String? playerName,
 }) async {
 try {
 final prefs = await SharedPreferences.getInstance();
 final raw = prefs.getString('$_keyPrefix$playerId');
 if (raw == null || raw.isEmpty) return null;
 // JSON deserialize -> Map (and save of jsonEncode formatgridcorrect)
 final decoded = jsonDecode(raw);
 if (decoded is! Map<String, dynamic>) return null;
 final model = BMPlayerAbilityModel.fromPlayerDataMap(
 decoded,
 playerId: playerId,
 playerName: playerName,
);
 if (model != null && _isValid(model)) {
 debugPrint('📦 BMPlayerAbilityStore localhit in: playerId=$playerId, sixitem=[${model.att},${model.tec},${model.sta},${model.def},${model.pow},${model.spd}]');
        return model;
      }
      return null;
    } catch (e) {
      debugPrint('❌ BMPlayerAbilityStore.load exception: $e, playerId=$playerId');
 return null;
 }
 }

 /// willplayersixpowerwritelocal
 /// [model] - playerabilitypowermodel (BMPlayerAbilityModel type, includessixitem 1~100 value)
 /// returns: bool (writesuccess true, failure false)
 static Future<bool> save(BMPlayerAbilityModel model) async {
 try {
 final prefs = await SharedPreferences.getInstance();
 // JSON serializestorage (and load of jsonDecode formatgridcorrect, canalsooriginal)
 final jsonStr = jsonEncode(<String, dynamic>{
 'ability': {
          'att': model.att,
          'tec': model.tec,
          'sta': model.sta,
          'def': model.def,
          'pow': model.pow,
          'spd': model.spd,
        },
        'name': model.playerName,
      });
      final ok = await prefs.setString(
        '$_keyPrefix${model.playerId}',
        jsonStr,
      );
      debugPrint('💾 BMPlayerAbilityStore.save playerId=${model.playerId} result=$ok, data=$jsonStr');
      return ok;
    } catch (e) {
      debugPrint('❌ BMPlayerAbilityStore.save exception: $e, playerId=${model.playerId}');
 return false;
 }
 }

 /// modellegalvalidate (sixitem 1~100)
 /// [model] - validatemodel (BMPlayerAbilityModel type)
 /// returns: bool (sixitemall 1~100 returns true)
 static bool _isValid(BMPlayerAbilityModel model) {
 final values = [model.att, model.tec, model.sta, model.def, model.pow, model.spd];
 return values.every((v) => v >= 1 && v <= 100);
 }
}
