import 'package:flutter/material.dart';

/// BMBasketballFlowChartPainter - basketballmatchtrendpolylinepaintdevice
/// alignment basketball_match_detail.html of Chart.js gameFlowChart (type: 'line'):
/// 1. home teammindiffcurve (bright green, 15% opacityfill, pointdatapoint pointRadius:3)
/// 2. away teammindiffcurve (blue, 10% opacityfill, pointRadius:0 nonepoint)
/// 3. y horizontalgridline (white 6% opacity) + left side 8px momentdegreesmalltext
/// 4. x notdisplay (bottom Q tagbyouterpart Row )
/// data source: detailAPI home_scores/away_scores ("23,21,16,18,0") → per-quarter cumulative diff series
/// architecture: CustomPainter, one class per file
class BMBasketballFlowChartPainter extends CustomPainter {
 /// home teamper-quarter cumulative diff series (List<int> type, e.g.: [0,2,-1,3] eachsectionendwhen home teamtotal-away teamtotal)
 final List<int> homeDiffs;

 /// away teamper-quarter cumulative diff series (List<int> type, i.e.home teammindifftake)
 final List<int> awayDiffs;

 /// home teamcurve color (Color type, defaultthemebright green)
 final Color homeColor;

 /// away teamcurve color (Color type, defaultblue)
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
 final all = [...homeDiffs,...awayDiffs, 0];
 int maxV = all.reduce((a, b) => a > b ? a: b);
 int minV = all.reduce((a, b) => a < b ? a: b);
 if (maxV == minV) maxV = minV + 1;
 // upperlower 18% padding
 final range = (maxV - minV).toDouble();
 final padding = range * 0.18 + 1;
 final yMax = maxV + padding;
 final yMin = minV - padding;

 // y -> px (valuelargeupper)
 double yOf(double v) => size.height - (v - yMin) / (yMax - yMin) * size.height;

 // x -> px (pointevenmin, leftrighteach 8px)
 double xOf(int i, int count) {
 if (count <= 1) return size.width / 2;
 final usable = size.width - 16;
 return 8 + (i / (count - 1)) * usable;
 }

 // ===== 1. horizontalgridline + left sidemomentdegree (html: grid rgba(255,255,255,0.05)) =====
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

 // ===== 2. away teamcurve (firstbyhome teamoverride, nonedatapoint) =====
 _drawLine(
 canvas,
 awayDiffs,
 yOf,
 xOf,
 awayColor,
 awayColor.withValues(alpha: 0.10),
 showPoints: false,
);

 // ===== 3. home teamcurve (later, datapoint) =====
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

 /// canvassizecache (Size? type, fillpathbottomedgeclosedmergemakeusage)
 Size? _size;

 /// paintsinglemindiffcurve (twotimeD + bottomchangefill + optionaldatapoint)
 /// [canvas] - canvas (Canvas type)
 /// [diffs] - mindiffseries (List<int> type)
 /// [yOf] - mindiffvalue→ypx mapping (double Function(double))
 /// [xOf] - index→xpx mapping (double Function(int,int))
 /// [lineColor] - curve color (Color type)
 /// [fillColor] - fillcolor (Color type)
 /// [showPoints] - whetherpaintpointdatapoint (bool type, html pointRadius:3/0)
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

 // Dcurvepath (tension 0.4 ≈ twotimeinpoint)
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

 // fillpath (curve → bottomclosedmerge)
 final fillPath = Path.from(linePath);
 fillPath.lineTo(points.last.dx, bottom);
 fillPath.lineTo(points.first.dx, bottom);
 fillPath.close();
 canvas.drawPath(fillPath, Paint()..color = fillColor);

 // curvestroke (borderWidth: 2)
 canvas.drawPath(
 linePath,
 Paint()
..color = lineColor
..style = PaintingStyle.stroke
..strokeWidth = 2
..strokeCap = StrokeCap.round
..strokeJoin = StrokeJoin.round,
);

 // datapoint (outeraccent color + innerwhite, html pointRadius:3)
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
