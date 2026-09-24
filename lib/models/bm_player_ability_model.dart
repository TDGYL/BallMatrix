import 'package:flutter/foundation.dart';

/// BMPlayerAbilityModel - playermorepowerabilitypowerdatamodel
/// sourceAPI: GET /api/livespeed/football/info?id={playerId} -> data["ability"] Map
/// reference: MEPlayerVM.m:296-304 (ability Maptake 6itemsdegree att/tec/sta/def/pow/spd)
/// purposescope: toolpagetap「generate ability report」later, nameplayer of 6abilitypowercomparepaint
class BMPlayerAbilityModel {
 /// playeruniqueID (int type, home, correspondingrequestinput id)
 final int playerId;

 /// playerdisplayname (String type, example/compareshowusage)
 final String playerName;

 /// ATT=abilitypower (int type, 0-100 percent, 6edgeshapetoppoint1)
 final int att;

 /// TEC=abilitypower (int type, 0-100 percent, 6edgeshapetoppoint2)
 final int tec;

 /// STA=/stateabilitypower (int type, 0-100 percent, 6edgeshapetoppoint3)
 final int sta;

 /// DEF=abilitypower (int type, 0-100 percent, 6edgeshapetoppoint4)
 final int def;

 /// POW=powervolume/heightbodyelement (int type, 0-100 percent, 6edgeshapetoppoint5)
 final int pow;

 /// SPD=speed/sendabilitypower (int type, 0-100 percent, 6edgeshapetoppoint6)
 final int spd;

 const BMPlayerAbilityModel({
 required this.playerId,
 required this.playerName,
 required this.att,
 required this.tec,
 required this.sta,
 required this.def,
 required this.pow,
 required this.spd,
 });

 /// from Map securityconvertas int?
 /// compatible int / num / String("123") multiple types, exceptionor null returns null
 static int? _safeInt(dynamic v) {
 if (v == null) return null;
 if (v is int) return v;
 if (v is num) return v.toInt();
 if (v is String) {
 final s = v.trim();
 if (s.isEmpty) return null;
 return int.tryParse(s);
 }
 return null;
 }

 /// from Map securityconvertas String?
 /// non-nullobjects are always toString(), null returns null; auto trim firstlateremptywhite
 static String? _safeString(dynamic v) {
 if (v == null) return null;
 if (v is String) {
 final s = v.trim();
 return s.isEmpty ? null: s;
 }
 return v.toString();
 }

 /// from /football/info API response of data Map createabilitypowermodel
 /// rule: firsttake data["ability"] sub Map -> take att/tec/sta/def/pow/spd 6item
 /// ⚠️ per item int value 0-100(reference MEPlayerVM attributeValueMap = MAX(0,MIN(100,num)));
 /// likeresult ability sub itemmissingorillegal -> correspondingvalue 0 fallback, notwholeitems
 /// [playerId] - alreadyknow of playerID (asouter data yesplayerdetail, ability sub Map notincludes playerId)
 /// [playerName] - alreadyknow of playername (outer data orcalldirectionpassinput)
 static BMPlayerAbilityModel? fromPlayerDataMap(
 Map<String, dynamic> data, {
 required int playerId,
 String? playerName,
 }) {
 try {
 // 1. from data outertakeplayername(compatible hanklive fieldname name_zh / name / player_name)
 final fallbackName = playerName ??
 _safeString(data['name_zh']) ??
          _safeString(data['name']) ??
          _safeString(data['player_name']) ??
          'player$playerId';

 // 2. ability sub Map (reference MEPlayerVM.m:296 NSDictionary *ability = dic[@"ability"])
      final ability = data['ability'];
 Map<String, dynamic> abilityMap = <String, dynamic>{};
 if (ability is Map<String, dynamic>) {
 abilityMap = ability;
 }

 // 3. 6abilitypower, eachitemmissing/illegal -> 0 fallback, and clamp 0~100
 int clamp0100(int? v) {
 if (v == null) return 0;
 if (v < 0) return 0;
 if (v > 100) return 100;
 return v;
 }

 return BMPlayerAbilityModel(
 playerId: playerId,
 playerName: fallbackName,
 att: clamp0100(_safeInt(abilityMap['att'])),
        tec: clamp0100(_safeInt(abilityMap['tec'])),
        sta: clamp0100(_safeInt(abilityMap['sta'])),
        def: clamp0100(_safeInt(abilityMap['def'])),
        pow: clamp0100(_safeInt(abilityMap['pow'])),
        spd: clamp0100(_safeInt(abilityMap['spd'])),
      );
    } catch (e) {
      debugPrint('BMPlayerAbilityModel.fromPlayerDataMap parseexception: $e, playerId=$playerId');
 return null;
 }
 }

 /// gettake6itemsdegreevalue of orderlist (corresponding MERadarChartView: ATT→TEC→STA→DEF→POW→SPD)
 /// return valuealreadyreturnone 0.0~1.0 (value/100), halfratioexamplemakeuse
 List<double> get normalizedValues {
 return [
 att / 100.0,
 tec / 100.0,
 sta / 100.0,
 def / 100.0,
 pow / 100.0,
 spd / 100.0,
 ];
 }

 /// 6itemsdegreedisplaytagorder (corresponding iOS axisTitles order, 1:1 alignment)
 static const List<String> dimensionLabels = [
 'ATT',
    'TEC',
    'STA',
    'DEF',
    'POW',
    'SPD',
  ];
}
