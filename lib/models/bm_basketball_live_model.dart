// BMBasketballLiveModels - 篮球实况数据模型
// 数据源: GET /api/livespeed/basketball/match/process -> data.tlive 数组
// 结构: [{ period_name: 'Q1', tlives: [{ time, score, event, position }] }]
// 字段说明: position 0=中立 / 1=主队 / 2=客队

/// BMBasketballLiveEvent - 单条实况事件 (tlives 数组元素)
class BMBasketballLiveEvent {
  /// 比赛时间 (String 类型, 例: '02:14')
  final String time;

  /// 实时比分 (String 类型, 例: '112-108')
  final String score;

  /// 事件描述 (String 类型, 例: '库里 命中超远三分！')
  final String event;

  /// 主客队标识 (int 类型, 0=中立 1=主队 2=客队)
  final int position;

  const BMBasketballLiveEvent({
    required this.time,
    required this.score,
    required this.event,
    required this.position,
  });

  /// 从 tlives 数组元素 Map 构建
  /// [json] - tlives 元素 (Map<String, dynamic> 类型)
  factory BMBasketballLiveEvent.fromJson(Map<String, dynamic> json) {
    return BMBasketballLiveEvent(
      time: (json['time'] ?? '').toString(),
      score: (json['score'] ?? '').toString(),
      event: (json['event'] ?? '').toString(),
      position: json['position'] is num ? (json['position'] as num).toInt() : 0,
    );
  }

  /// 是否主队事件 (bool 类型)
  bool get isHome => position == 1;

  /// 是否客队事件 (bool 类型)
  bool get isAway => position == 2;

  /// 是否中立事件 (bool 类型)
  bool get isNeutral => position == 0;

  /// 是否得分事件 (bool 类型, 描述含得分关键词: 得分/命中/三分/扣篮/罚球/上篮/进球/2+1)
  bool get isScoreEvent {
    final e = event;
    return e.contains('得分') ||
        e.contains('命中') ||
        e.contains('三分') ||
        e.contains('扣篮') ||
        e.contains('罚球') ||
        e.contains('上篮') ||
        e.contains('进球') ||
        e.contains('2+1') ||
        e.contains('跳投');
  }
}

/// BMBasketballLivePeriod - 单节实况分组 (tlive 数组元素)
class BMBasketballLivePeriod {
  /// 节名 (String 类型, 例: 'Q1' / '第1节')
  final String periodName;

  /// 该节事件列表 (List<BMBasketballLiveEvent> 类型, 接口原序)
  final List<BMBasketballLiveEvent> events;

  const BMBasketballLivePeriod({
    required this.periodName,
    required this.events,
  });

  /// 从 tlive 数组元素 Map 构建
  /// [json] - tlive 元素 (Map<String, dynamic> 类型, {period_name, tlives})
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
