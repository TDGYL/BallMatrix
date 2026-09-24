import 'package:flutter/foundation.dart';

/// BMCompetitionModel - footballleague(competition)datamodel
/// sourceAPI: GET /api/livespeed/football/competition/list -> data array item
/// purposescope: homefilterdevice / toolpageleaguefilter / playerbest league waitfullitemitemallhasleagueselectUI
class BMCompetitionModel {
 /// leagueuniqueID (int type, backend primary key, forrequest matches when competition_ids filter)
 final int id;

 /// leaguedisplayname (String type, intextgoodname, e.g.: Premier League//)
 final String name;

 /// leagueabbreviationtext (String type, e.g.: Premier League=EPL / =O, left sidesmallicontextusage)
 final String cap;

 /// whetherhomeleaguemarker (int type, 1=homepinned/firstdisplay, 0=timelevelleague, sortwhencanindex)
 final int main;

 const BMCompetitionModel({
 required this.id,
 required this.name,
 required this.cap,
 required this.main,
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
 /// non-nullobjects are always toString(), null returns null
 static String? _safeString(dynamic v) {
 if (v == null) return null;
 if (v is String) {
 final s = v.trim();
 return s.isEmpty ? null: s;
 }
 return v.toString();
 }

 /// fromlaterside Map<String, dynamic> create model instance
 /// single parse failure returns null, callers advised to use for + try-catch avoid dropping whole batch
 static BMCompetitionModel? fromMap(Map<String, dynamic> map) {
 try {
 final id = _safeInt(map['id']);
      final name = _safeString(map['name']);
      final cap = _safeString(map['cap']);
      final main = _safeInt(map['main']);
 if (id == null || name == null) return null;
 // cap fallback: takenameNo. 1itemstextlargewrite (intexttaketext, texttaketext)
 final capFallback = name.isEmpty ? '·' : name.substring(0, 1).toUpperCase();
      return BMCompetitionModel(
        id: id,
        name: name,
        cap: cap ?? capFallback,
        main: main ?? 0,
      );
    } catch (e) {
      debugPrint('BMCompetitionModel.fromMap parseexception: $e, map=$map');
      return null;
    }
  }
}
