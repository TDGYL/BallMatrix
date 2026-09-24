import 'package:flutter/foundation.dart';

/// BMPlayerRankModel - leagueplayerrankingboarddatamodel
/// sourceAPI: GET /api/livespeed/football/competition/player-rank -> data array item
/// purposescope: toolpageleaguelowerdirectionplayerboardsingleshow (board/centerboard/assistboardetc)
class BMPlayerRankModel {
 /// playeruniqueID (int type, backend primary key, fornavigatetoplayerdetailpage)
 final int playerId;

 /// rankingitemtypename (String type, e.g.: goal/center/assist/yellow card, by key argumentdisplay)
 final String rankName;

 /// rankposition (int type, starting from 1, No. 1name/No. 2name..., UI first3namecanshow//color)
 final int position;

 /// playerdisplayname (String type, intextfullname, e.g.: ·special·)
 final String playerName;

 /// playeravatarURL (String type, farsideresource, may be empty, UI needdefaultplaceholderavatar)
 final String playerLogo;

 /// allteam namename (String type, intextgoodname, e.g.: special)
 final String teamName;

 /// datastatisticsvalue (int type, corresponding key of accumulatetotal, e.g.: k_shots_on=centercount36)
 final int total;

 const BMPlayerRankModel({
 required this.playerId,
 required this.rankName,
 required this.position,
 required this.playerName,
 required this.playerLogo,
 required this.teamName,
 required this.total,
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
 static BMPlayerRankModel? fromMap(Map<String, dynamic> map) {
 try {
 final playerId = _safeInt(map['player_id']);
      final rankName = _safeString(map['rank_name']);
      final position = _safeInt(map['position']);
      final playerName = _safeString(map['player_name']);
      final playerLogo = _safeString(map['player_logo']);
      final teamName = _safeString(map['team_name']);
      final total = _safeInt(map['total']);
      if (playerId == null ||
          playerName == null ||
          position == null ||
          total == null) {
        return null;
      }
      return BMPlayerRankModel(
        playerId: playerId,
        rankName: rankName ?? 'data',
        position: position,
        playerName: playerName,
        playerLogo: playerLogo ?? '',
        teamName: teamName ?? '',
        total: total,
      );
    } catch (e) {
      debugPrint('BMPlayerRankModel.fromMap parseexception: $e, map=$map');
      return null;
    }
  }
}
