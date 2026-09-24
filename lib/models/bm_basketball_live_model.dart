// BMBasketballLiveModels - basketballlivedatamodel
// data source: GET /api/livespeed/basketball/match/process -> data.tlive array
// structure: [{ period_name: 'Q1', tlives: [{ time, score, event, position }] }]
// fielddescription: position 0=ininstantly / 1=home team / 2=away team

/// BMBasketballLiveEvent - singleliveevent (tlives array element)
class BMBasketballLiveEvent {
 /// match time (String type, e.g.: '02:14')
 final String time;

 /// live score (String type, e.g.: '112-108')
 final String score;

 /// eventdescription (String type, e.g.: 'storage hit infarthreemin！')
 final String event;

 /// home/away team logo (int type, 0=ininstantly 1=home team 2=away team)
 final int position;

 const BMBasketballLiveEvent({
 required this.time,
 required this.score,
 required this.event,
 required this.position,
 });

 /// from tlives array element Map build
 /// [json] - tlives element (Map<String, dynamic> type)
 factory BMBasketballLiveEvent.fromJson(Map<String, dynamic> json) {
 return BMBasketballLiveEvent(
 time: (json['time'] ?? '').toString(),
      score: (json['score'] ?? '').toString(),
      event: (json['event'] ?? '').toString(),
      position: json['position'] is num ? (json['position'] as num).toInt(): 0,
);
 }

 /// is home teamevent (bool type)
 bool get isHome => position == 1;

 /// whetheraway teamevent (bool type)
 bool get isAway => position == 2;

 /// whetherininstantlyevent (bool type)
 bool get isNeutral => position == 0;

 /// whethergetminevent (bool type, descriptionincludesgetminkey: getmin/hit in/threemin/basket/ball/upperbasket/goal/2+1)
 bool get isScoreEvent {
 final e = event;
 return e.contains('getmin') ||
        e.contains('hit in') ||
        e.contains('threemin') ||
        e.contains('basket') ||
        e.contains('ball') ||
        e.contains('upperbasket') ||
        e.contains('goal') ||
        e.contains('2+1') ||
        e.contains('jump');
 }
}

/// BMBasketballLivePeriod - singlesectionlivegroup (tlive array element)
class BMBasketballLivePeriod {
 /// sectionname (String type, e.g.: 'Q1' / 'No. 1section')
 final String periodName;

 /// thesectioneventlist (List<BMBasketballLiveEvent> type, APIoriginalindex)
 final List<BMBasketballLiveEvent> events;

 const BMBasketballLivePeriod({
 required this.periodName,
 required this.events,
 });

 /// from tlive array element Map build
 /// [json] - tlive element (Map<String, dynamic> type, {period_name, tlives})
 factory BMBasketballLivePeriod.fromJson(Map<String, dynamic> json) {
 final rawTlives = json['tlives'];
    final events = <BMBasketballLiveEvent>[];
    if (rawTlives is List) {
      for (final e in rawTlives) {
        if (e is Map<String, dynamic>) {
          events.add(BMBasketballLiveEvent.fromJson(e));
        }
      }
    }
    return BMBasketballLivePeriod(
      periodName: (json['period_name'] ?? json['periodName'] ?? '').toString(),
      events: events,
    );
  }
}
