import 'package:flutter/foundation.dart';

/// BMCompetitionSeasonModel - footballleagueseasondatamodel
/// sourceAPI: GET /api/livespeed/football/competition/season-list -> data array item
/// reference: hanklive/lib/models/hank_season_info_model.dart field 1:1 corresponding
/// purposescope: toolpageleaguelowergettakeseason -> use season_id requestplayer/ptsboard/match
class BMCompetitionSeasonModel {
 /// seasonuniqueID (int type, backend primary key, requestptsboard/match/playerboardwhen season_id inputrequired)
 final int seasonId;

 /// seasonyearname (String type, e.g.: "2024-2025" / "2026-2027", forUIdisplaycurrentseason)
 final String year;

 /// whethercurrentseasonmarker (int type, 1=centerin progress of currentseason / 0=historyseason, reference hanklive priority isCurrent=1)
 final int isCurrent;

 const BMCompetitionSeasonModel({
 required this.seasonId,
 required this.year,
 required this.isCurrent,
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

 /// fromlaterside Map<String, dynamic> create model instance
 /// single parse failure returns null, callers advised to use for + try-catch avoid dropping whole batch
 static BMCompetitionSeasonModel? fromMap(Map<String, dynamic> map) {
 try {
 final seasonId = _safeInt(map['season_id']);
      final year = _safeString(map['year']);
      final isCurrent = _safeInt(map['is_current']);
      if (seasonId == null) return null;
      return BMCompetitionSeasonModel(
        seasonId: seasonId,
        year: year ?? '',
        isCurrent: isCurrent ?? 0,
      );
    } catch (e) {
      debugPrint('BMCompetitionSeasonModel.fromMap parseexception: $e, map=$map');
      return null;
    }
  }
}
