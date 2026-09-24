/// BMBasketballQuarterScore - 篮球比赛节数比分矩阵模型
/// 作用范围: 篮球详情页顶部记分卡 Q1~Q4(+加时) 分节比分表格
/// 数据来源:
///   1. GET /api/livespeed/basketball/match/detail 返回的 home_scores/away_scores (逗号分隔字符串, 例: "28,32,24,28")
///   2. BMBasketballMatchItem 的 homeQ1~homeQ4 / awayQ1~awayQ4 字段
///   3. BMMatchModel 传入的 homeTeam/homeScore 兜底
class BMBasketballQuarterScore {
  /// 主队各节比分 (List<int> 类型, index 0=Q1, 1=Q2, 2=Q3, 3=Q4, 4+=加时)
  final List<int> homeQuarters;

  /// 客队各节比分 (List<int> 类型, 与 homeQuarters 等长)
  final List<int> awayQuarters;

  /// 主队总分 (int 类型, 各节累加, 无数据为 0)
  final int homeTotal;

  /// 客队总分 (int 类型, 各节累加, 无数据为 0)
  final int awayTotal;

  const BMBasketballQuarterScore({
    this.homeQuarters = const [],
    this.awayQuarters = const [],
    this.homeTotal = 0,
    this.awayTotal = 0,
  });

  /// 是否有有效节数数据 (bool 类型, 至少有一节数据为 true)
  bool get hasData => homeQuarters.isNotEmpty || awayQuarters.isNotEmpty;

  /// 节数 (int 类型, 取主客队较长列表长度, 例: 4=常规 5+=含加时)
  int get quarterCount =>
      homeQuarters.length > awayQuarters.length
          ? homeQuarters.length
          : awayQuarters.length;

  /// 节标签列表 (List<String> 类型, 例: ['Q1','Q2','Q3','Q4','OT1'])
  List<String> get quarterLabels {
    return List<String>.generate(quarterCount, (i) => i < 4 ? 'Q${i + 1}' : 'OT${i - 3}');
  }

  /// 从逗号分隔字符串解析各节比分 (例: "28,32,24,28" → [28,32,24,28])
  /// [raw] - 原始比分字符串 (String? 类型, 支持空值)
  /// 返回: List<int> 各节比分 (解析失败返回空数组)
  static List<int> _parseQuarters(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final parts = raw.split(',');
    final result = <int>[];
    for (final p in parts) {
      final v = int.tryParse(p.trim());
      if (v != null) result.add(v);
    }
    return result;
  }

  /// 从详情接口 data Map 构建 (优先逗号分隔字符串)
  /// [data] - 详情接口返回的 data Map (Map<String,dynamic> 类型)
  /// 返回: BMBasketballQuarterScore (无数据时 hasData=false)
  factory BMBasketballQuarterScore.fromDetailMap(Map<String, dynamic>? data) {
    if (data == null) return const BMBasketballQuarterScore();
    // 兼容 key: home_scores/homeScores/home_score/homeScore (String 逗号分隔或 List)
    dynamic rawHome = data['home_scores'] ?? data['homeScores'] ?? data['home_score'] ?? data['homeScore'];
    dynamic rawAway = data['away_scores'] ?? data['awayScores'] ?? data['away_score'] ?? data['awayScore'];
    // home_score 可能是 Map {total, q1...} 或 String "28,32,24,28" 或 List
    List<int> homeQ = _coerceQuarters(rawHome);
    List<int> awayQ = _coerceQuarters(rawAway);
    if (homeQ.isEmpty && awayQ.isEmpty) return const BMBasketballQuarterScore();
    final homeTotal = data['home_total'] is num
        ? (data['home_total'] as num).toInt()
        : homeQ.fold(0, (a, b) => a + b);
    final awayTotal = data['away_total'] is num
        ? (data['away_total'] as num).toInt()
        : awayQ.fold(0, (a, b) => a + b);
    return BMBasketballQuarterScore(
      homeQuarters: homeQ,
      awayQuarters: awayQ,
      homeTotal: homeTotal,
      awayTotal: awayTotal,
    );
  }

  /// 多类型值转节数列表 (String 逗号分隔 / List / Map{q1..q4} 三态兼容)
  /// [v] - 原始值 (dynamic 类型)
  /// 返回: List<int> 各节比分
  static List<int> _coerceQuarters(dynamic v) {
    if (v == null) return const [];
    if (v is String) return _parseQuarters(v);
    if (v is List) {
      return v.map((e) => int.tryParse(e.toString()) ?? 0).toList();
    }
    if (v is Map) {
      // Map 形式: {q1: 28, q2: 32, ...} 或 {Q1: 28, ...}
      final result = <int>[];
      for (int i = 1; i <= 12; i++) {
        final qv = v['q$i'] ?? v['Q$i'] ?? v['quarter$i'];
        if (qv == null) break;
        result.add(int.tryParse(qv.toString()) ?? 0);
      }
      return result;
    }
    if (v is num) return [v.toInt()];
    return const [];
  }
}
