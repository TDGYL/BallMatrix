import 'package:flutter/material.dart';

/// BMBasketballFlowChartPainter - 篮球比赛走势折线图绘制器
/// 对齐 basketball_match_detail.html 的 Chart.js gameFlowChart (type: 'line'):
///   1. 主队分差曲线 (亮绿, 15% 透明度填充, 圆点数据点 pointRadius:3)
///   2. 客队分差曲线 (蓝, 10% 透明度填充, pointRadius:0 无点)
///   3. y 轴水平网格线 (白色 6% 透明度) + 左侧 8px 刻度小字
///   4. x 轴不显示 (底部 Q 标签由外部 Row 提供)
/// 数据源: 详情接口 home_scores/away_scores ("23,21,16,18,0") → 各节累计分差序列
/// 架构: CustomPainter, 单类单文件
class BMBasketballFlowChartPainter extends CustomPainter {
  /// 主队各节累计分差序列 (List<int> 类型, 例: [0,2,-1,3] 每节结束时 主队总分-客队总分)
  final List<int> homeDiffs;

  /// 客队各节累计分差序列 (List<int> 类型, 即主队分差取反)
  final List<int> awayDiffs;

  /// 主队曲线颜色 (Color 类型, 默认主题亮绿)
  final Color homeColor;

  /// 客队曲线颜色 (Color 类型, 默认蓝)
  final Color awayColor;

  BMBasketballFlowChartPainter({
    required this.homeDiffs,
    required this.awayDiffs,
    this.homeColor = const Color(0xFF10B981),
    this.awayColor = const Color(0xFF3B82F6),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (homeDiffs.isEmpty && awayDiffs.isEmpty) return;
    _size = size;
    final all = [...homeDiffs, ...awayDiffs, 0];
    int maxV = all.reduce((a, b) => a > b ? a : b);
    int minV = all.reduce((a, b) => a < b ? a : b);
    if (maxV == minV) maxV = minV + 1;
    // 上下留 18% 内边距
    final range = (maxV - minV).toDouble();
    final padding = range * 0.18 + 1;
    final yMax = maxV + padding;
    final yMin = minV - padding;

    // y -> 像素 (值大在上)
    double yOf(double v) => size.height - (v - yMin) / (yMax - yMin) * size.height;

    // x -> 像素 (点均匀分布, 左右各留 8px)
    double xOf(int i, int count) {
      if (count <= 1) return size.width / 2;
      final usable = size.width - 16;
      return 8 + (i / (count - 1)) * usable;
    }

    // ===== 1. 水平网格线 + 左侧刻度 (html: grid rgba(255,255,255,0.05)) =====
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.8;
    final tickPainter = TextPainter(textDirection: TextDirection.ltr);
    const gridCount = 4;
    for (int g = 0; g <= gridCount; g++) {
      final v = yMin + (yMax - yMin) * g / gridCount;
      final y = yOf(v);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      tickPainter.text = TextSpan(
        text: v.round().toString(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.28),
          fontSize: 8,
          fontFamily: 'monospace',
        ),
      );
      tickPainter.layout();
      tickPainter.paint(canvas, Offset(2, y - tickPainter.height / 2));
    }

    // ===== 2. 客队曲线 (先画被主队覆盖, 无数据点) =====
    _drawLine(
      canvas,
      awayDiffs,
      yOf,
      xOf,
      awayColor,
      awayColor.withValues(alpha: 0.10),
      showPoints: false,
    );

    // ===== 3. 主队曲线 (后画, 带数据点) =====
    _drawLine(
      canvas,
      homeDiffs,
      yOf,
      xOf,
      homeColor,
      homeColor.withValues(alpha: 0.15),
      showPoints: true,
    );
  }

  /// 画布尺寸缓存 (Size? 类型, 供填充路径底边闭合使用)
  Size? _size;

  /// 绘制单条分差曲线 (二次贝塞尔平滑 + 底部渐变填充 + 可选数据点)
  /// [canvas] - 画布 (Canvas 类型)
  /// [diffs] - 分差序列 (List<int> 类型)
  /// [yOf] - 分差值→y像素 映射 (double Function(double))
  /// [xOf] - 序号→x像素 映射 (double Function(int,int))
  /// [lineColor] - 曲线颜色 (Color 类型)
  /// [fillColor] - 填充颜色 (Color 类型)
  /// [showPoints] - 是否绘制圆点数据点 (bool 类型, html pointRadius:3/0)
  void _drawLine(
    Canvas canvas,
    List<int> diffs,
    double Function(double) yOf,
    double Function(int, int) xOf,
    Color lineColor,
    Color fillColor, {
    required bool showPoints,
  }) {
    if (diffs.isEmpty || _size == null) return;
    final count = diffs.length;
    final bottom = _size!.height;
    final points = <Offset>[
      for (int i = 0; i < count; i++)
        Offset(xOf(i, count), yOf(diffs[i].toDouble())),
    ];

    // 平滑曲线路径 (tension 0.4 ≈ 二次贝塞尔中点法)
    final linePath = Path()..moveTo(points[0].dx, points[0].dy);
    if (count == 1) {
      linePath.lineTo(points[0].dx + 1, points[0].dy);
    } else {
      for (int i = 1; i < count; i++) {
        final prev = points[i - 1];
        final cur = points[i];
        final midX = (prev.dx + cur.dx) / 2;
        linePath.quadraticBezierTo(midX, prev.dy, cur.dx, cur.dy);
      }
    }

    // 填充路径 (曲线 → 底部闭合)
    final fillPath = Path.from(linePath);
    fillPath.lineTo(points.last.dx, bottom);
    fillPath.lineTo(points.first.dx, bottom);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // 曲线描边 (borderWidth: 2)
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 数据点 (外圈主题色 + 内芯白, html pointRadius:3)
    if (showPoints) {
      for (final p in points) {
        canvas.drawCircle(p, 3, Paint()..color = lineColor);
        canvas.drawCircle(p, 1.5, Paint()..color = Colors.white.withValues(alpha: 0.85));
      }
    }
  }

  @override
  bool shouldRepaint(covariant BMBasketballFlowChartPainter old) {
    return old.homeDiffs != homeDiffs ||
        old.awayDiffs != awayDiffs ||
        old.homeColor != homeColor ||
        old.awayColor != awayColor;
  }
}
