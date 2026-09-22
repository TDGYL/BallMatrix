import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// 战术板元素类型枚举
enum _BMTacticalType {
  player,   // 我方球员 (蓝色圆)
  opponent, // 对方球员 (红色圆)
  ball,     // 足球 (黄黑圆)
  arrow,    // 实心箭头
  line,     // 普通直线
  text,     // 文字标注
}

/// 战术板单个数据元素
class _BMTacticalElement {
  /// 唯一 id (String 类型, 时间戳生成)
  final String id;

  /// 元素类型 (_BMTacticalType 枚举)
  final _BMTacticalType type;

  /// 起点/圆心坐标 (Offset 类型, 逻辑画布坐标)
  final Offset start;

  /// 终点坐标 (Offset? 类型, 仅线/箭头使用; 点元素为 null)
  final Offset? end;

  /// 显示文字 (String? 类型, 仅 text 元素使用)
  final String? text;

  const _BMTacticalElement({
    required this.id,
    required this.type,
    required this.start,
    this.end,
    this.text,
  });

  /// copyWith 复制对象, 只更新非 null 参数
  _BMTacticalElement copyWith({
    String? id,
    _BMTacticalType? type,
    Offset? start,
    Offset? end,
    String? text,
  }) {
    return _BMTacticalElement(
      id: id ?? this.id,
      type: type ?? this.type,
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
    );
  }
}

/// BMTacticalBoardPage: 战术板页面
/// 差异化设计 (对比 hanklive 紫色主题 + 纵向场地):
/// 1. 深绿 BallMatrix 主题 (pitch900 / pitch850 / pitch700)
/// 2. 横向足球场比例 (540x360) vs hanklive 纵向 360x540
/// 3. 工具栏合并为一行 (撤销重做 + 工具切换) 不占用3行空间
/// 4. 半场/全场切换 + 阵型预设在底部
/// 架构: 单类单文件, MVVM View 层, 继承 BMBasePage
class BMTacticalBoardPage extends BMBasePage {
  const BMTacticalBoardPage({super.key});

  @override
  State<BMTacticalBoardPage> createState() => _BMTacticalBoardPageState();
}

class _BMTacticalBoardPageState extends BMBasePageState<BMTacticalBoardPage> {
  /// 横向场地逻辑画布尺寸 (Size 类型, 3:2 比例)
  static const Size _canvasSize = Size(540, 360);

  /// 元素列表 (List<_BMTacticalElement> 类型, 画布所有内容)
  final List<_BMTacticalElement> _elements = [];

  /// 当前选中工具 (_BMTacticalType 类型, 新增元素类型)
  _BMTacticalType _currentTool = _BMTacticalType.player;

  /// 是否半场模式 (bool 类型, true=只画右半场)
  bool _isHalfField = false;

  /// 撤销栈 (List<List<_BMTacticalElement>> 类型, 最多 20 步)
  final List<List<_BMTacticalElement>> _undoStack = [];

  /// 重做栈 (List<List<_BMTacticalElement>> 类型, undo 时保存)
  final List<List<_BMTacticalElement>> _redoStack = [];

  /// 正在拖拽中的点元素 (_BMTacticalElement? 类型, null=未拖拽)
  _BMTacticalElement? _draggingElement;

  /// 正在绘制的线/箭头起点 (_BMTacticalElement? 类型, 拖动时临时存在)
  _BMTacticalElement? _drawingElement;

  /// 生成唯一 id
  String _genId() => 'el_${DateTime.now().millisecondsSinceEpoch}_${_elements.length}';

  /// 保存当前状态到撤销栈
  void _saveUndo() {
    _undoStack.add(List.from(_elements));
    if (_undoStack.length > 20) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  /// 撤销
  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.from(_elements));
    _elements
      ..clear()
      ..addAll(_undoStack.removeLast());
    setState(() {});
  }

  /// 重做
  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.from(_elements));
    _elements
      ..clear()
      ..addAll(_redoStack.removeLast());
    setState(() {});
  }

  /// 清空画布
  void _clearAll() {
    if (_elements.isEmpty) return;
    _saveUndo();
    _elements.clear();
    setState(() {});
  }

  /// 应用阵型预设 (只支持默认 433 全场地)
  void _apply433() {
    _saveUndo();
    _elements.clear();
    final w = _canvasSize.width;
    final h = _canvasSize.height;
    final positions = <Offset>[
      Offset(w * 0.08, h * 0.50),
      Offset(w * 0.22, h * 0.18),
      Offset(w * 0.22, h * 0.38),
      Offset(w * 0.22, h * 0.62),
      Offset(w * 0.22, h * 0.82),
      Offset(w * 0.45, h * 0.25),
      Offset(w * 0.45, h * 0.50),
      Offset(w * 0.45, h * 0.75),
      Offset(w * 0.68, h * 0.30),
      Offset(w * 0.68, h * 0.50),
      Offset(w * 0.68, h * 0.70),
    ];
    for (int i = 0; i < positions.length; i++) {
      _elements.add(_BMTacticalElement(
        id: _genId(),
        type: _BMTacticalType.player,
        start: positions[i],
      ));
    }
    setState(() {});
  }

  /// 显示文字输入弹窗, 返回输入文字 (取消返回 null)
  Future<String?> _showTextDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BMColors.pitch900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Text', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Tactical note...',
            hintStyle: TextStyle(color: BMColors.textSecondary),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BMColors.pitch700),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BMColors.pitch700),
            ),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: BMColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Add', style: TextStyle(color: BMColors.bright, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // === 手势处理 ===
  void _onPanStart(DragStartDetails d) {
    final pos = d.localPosition;
    // 工具=player/opponent/ball: 先检查点中了某个元素 -> 拖拽移动, 没点中 -> 新增
    final isPoint = _currentTool == _BMTacticalType.player ||
        _currentTool == _BMTacticalType.opponent ||
        _currentTool == _BMTacticalType.ball;
    if (isPoint) {
      for (int i = _elements.length - 1; i >= 0; i--) {
        final e = _elements[i];
        final eIsPoint = e.type == _BMTacticalType.player ||
            e.type == _BMTacticalType.opponent ||
            e.type == _BMTacticalType.ball;
        if (eIsPoint && (e.start - pos).distance <= 18) {
          _draggingElement = e;
          _saveUndo();
          return;
        }
      }
      // 没点中现有点 -> 新增点元素
      _saveUndo();
      _elements.add(_BMTacticalElement(id: _genId(), type: _currentTool, start: pos));
      setState(() {});
      return;
    }
    // 工具=line/arrow: 开始画
    if (_currentTool == _BMTacticalType.line || _currentTool == _BMTacticalType.arrow) {
      _saveUndo();
      _drawingElement = _BMTacticalElement(id: _genId(), type: _currentTool, start: pos, end: pos);
      _elements.add(_drawingElement!);
      setState(() {});
      return;
    }
    // 工具=text: 弹窗询问后在点的位置放置
    if (_currentTool == _BMTacticalType.text) {
      _showTextDialog().then((t) {
        if (t != null && t.isNotEmpty) {
          _saveUndo();
          _elements.add(_BMTacticalElement(id: _genId(), type: _BMTacticalType.text, start: pos, text: t));
          setState(() {});
        }
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_draggingElement != null) {
      final idx = _elements.indexWhere((e) => e.id == _draggingElement!.id);
      if (idx >= 0) {
        _elements[idx] = _draggingElement!.copyWith(start: d.localPosition);
        setState(() {});
      }
      return;
    }
    if (_drawingElement != null) {
      final idx = _elements.indexWhere((e) => e.id == _drawingElement!.id);
      if (idx >= 0) {
        _elements[idx] = _drawingElement!.copyWith(end: d.localPosition);
        setState(() {});
      }
    }
  }

  void _onPanEnd(DragEndDetails _) {
    if (_drawingElement != null) {
      // 线太短就删掉
      final e = _drawingElement!;
      if (e.end != null && (e.end! - e.start).distance < 12) {
        _elements.removeWhere((x) => x.id == e.id);
      }
      _drawingElement = null;
      setState(() {});
    }
    _draggingElement = null;
  }

  // === 构建 ===
  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildCanvasArea()),
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: BMColors.pitch950,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BMColors.pitch850,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
          ),
          child: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
        ),
      ),
      title: const Text(
        'Tactical Board',
        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: _apply433,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BMColors.bright.withValues(alpha: 0.12),
                border: Border.all(color: BMColors.bright.withValues(alpha: 0.5), width: 1.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list_alt, size: 12, color: BMColors.bright),
                  SizedBox(width: 4),
                  Text('433', style: TextStyle(color: BMColors.bright, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: BMColors.pitch950,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _miniButton(Icons.undo, 'Undo', _undo, _undoStack.isEmpty),
          const SizedBox(width: 6),
          _miniButton(Icons.redo, 'Redo', _redo, _redoStack.isEmpty),
          const SizedBox(width: 6),
          _miniButton(Icons.delete_outline, 'Clear', _clearAll, _elements.isEmpty),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _isHalfField = !_isHalfField),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isHalfField ? BMColors.bright : BMColors.pitch800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
              ),
              child: Text(
                _isHalfField ? 'Half' : 'Full',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _isHalfField ? BMColors.pitch950 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniButton(IconData icon, String label, VoidCallback onTap, bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: disabled ? 0.3 : 1.0,
        child: Container(
          width: 54,
          height: 30,
          decoration: BoxDecoration(
            color: BMColors.pitch850,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: BMColors.textPrimary),
              Text(label, style: const TextStyle(fontSize: 8, color: BMColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasArea() {
    return Container(
      color: BMColors.pitch900,
      alignment: Alignment.center,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 2.5,
        boundaryMargin: const EdgeInsets.all(50),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  size: _canvasSize,
                  painter: _BMFieldPainter(isHalf: _isHalfField, elements: _elements),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    final items = <(_BMTacticalType, IconData, String)>[
      (_BMTacticalType.player, Icons.circle, 'Our'),
      (_BMTacticalType.opponent, Icons.horizontal_rule, 'Opp'),
      (_BMTacticalType.ball, Icons.sports_soccer_outlined, 'Ball'),
      (_BMTacticalType.arrow, Icons.arrow_forward, 'Arrow'),
      (_BMTacticalType.line, Icons.show_chart, 'Line'),
      (_BMTacticalType.text, Icons.text_fields, 'Text'),
    ];
    return Container(
      color: BMColors.pitch950,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final (t, ic, lb) = items[i];
              final active = _currentTool == t;
              return GestureDetector(
                onTap: () => setState(() => _currentTool = t),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 56,
                  decoration: BoxDecoration(
                    color: active ? BMColors.bright : BMColors.pitch850,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: active ? BMColors.bright : BMColors.pitch700.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(ic, size: 16, color: active ? BMColors.pitch950 : Colors.white),
                      const SizedBox(height: 2),
                      Text(lb, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: active ? BMColors.pitch950 : Colors.white)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// 场地 + 元素 painter
// =====================================================================
class _BMFieldPainter extends CustomPainter {
  final bool isHalf;
  final List<_BMTacticalElement> elements;
  _BMFieldPainter({required this.isHalf, required this.elements});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 1. 草地底色 (渐变深浅交替条纹)
    final stripeCount = 10;
    for (int i = 0; i < stripeCount; i++) {
      final left = w * i / stripeCount;
      final right = w * (i + 1) / stripeCount;
      canvas.drawRect(
        Rect.fromLTRB(left, 0, right, h),
        Paint()..color = i.isEven ? const Color(0xFF14532D) : const Color(0xFF166534),
      );
    }
    // 2. 外框 / 中圈 / 中线
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRect(Rect.fromLTRB(6, 6, w - 6, h - 6), line);

    final midX = w / 2;
    // 半场模式: 中线画在左 1/3 位置, 只画右半场地线
    final halfStartX = isHalf ? w * 0.33 : midX;
    if (!isHalf) {
      canvas.drawLine(Offset(midX, 6), Offset(midX, h - 6), thin);
      canvas.drawCircle(Offset(midX, h / 2), h * 0.16, thin);
      canvas.drawCircle(Offset(midX, h / 2), 3, Paint()..color = Colors.white.withValues(alpha: 0.9));
    } else {
      canvas.drawLine(Offset(halfStartX, 6), Offset(halfStartX, h - 6), thin);
      canvas.drawCircle(Offset(halfStartX, h / 2), h * 0.16, thin);
    }
    // 左右禁区 / 小禁区 (半场模式只画右边)
    void drawBox(double cx, double factor) {
      final bigW = h * 0.50 * factor;
      final bigH = h * 0.75 * factor;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, h / 2), width: bigW, height: bigH),
        thin,
      );
      final smW = h * 0.17 * factor;
      final smH = h * 0.40 * factor;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, h / 2), width: smW, height: smH),
        thin,
      );
    }

    final leftCx = 6 + h * 0.16;
    final rightCx = w - 6 - h * 0.16;
    if (!isHalf) drawBox(leftCx, 1.0);
    drawBox(rightCx, 1.0);

    // 3. 绘制所有战术元素
    for (final e in elements) {
      switch (e.type) {
        case _BMTacticalType.player:
          _drawCircle(canvas, e.start, 16, const Color(0xFF3B82F6), Colors.white, text: '');
          break;
        case _BMTacticalType.opponent:
          _drawCircle(canvas, e.start, 16, const Color(0xFFEF4444), Colors.white, text: '');
          break;
        case _BMTacticalType.ball:
          _drawBall(canvas, e.start, 11);
          break;
        case _BMTacticalType.line:
          if (e.end != null) {
            canvas.drawLine(e.start, e.end!, Paint()..color = const Color(0xFFFBBF24)..strokeWidth = 2.6..style = PaintingStyle.stroke);
          }
          break;
        case _BMTacticalType.arrow:
          if (e.end != null) _drawArrow(canvas, e.start, e.end!, const Color(0xFF22D3EE));
          break;
        case _BMTacticalType.text:
          if (e.text != null) {
            final tp = TextPainter(
              text: TextSpan(
                text: e.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  backgroundColor: Color(0xAA000000),
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas, e.start);
          }
          break;
      }
    }
  }

  void _drawCircle(Canvas c, Offset p, double r, Color fill, Color stroke, {required String text}) {
    c.drawCircle(p, r, Paint()..color = fill);
    c.drawCircle(p, r, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 1.6);
    if (text.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: stroke, fontSize: 10, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }
  }

  void _drawBall(Canvas c, Offset p, double r) {
    c.drawCircle(p, r, Paint()..color = Colors.white);
    // 5 边形块
    final ang = -math.pi / 2;
    for (int i = 0; i < 5; i++) {
      final a = ang + 2 * math.pi * i / 5;
      final p1 = Offset(p.dx + r * 0.58 * math.cos(a), p.dy + r * 0.58 * math.sin(a));
      final p2 = Offset(p.dx + r * 0.58 * math.cos(a + 2 * math.pi / 5), p.dy + r * 0.58 * math.sin(a + 2 * math.pi / 5));
      c.drawLine(p1, p2, Paint()..color = Colors.black..strokeWidth = 1.2);
      c.drawLine(p, p1, Paint()..color = Colors.black..strokeWidth = 1.2);
      if (i == 4) c.drawLine(p, p2, Paint()..color = Colors.black..strokeWidth = 1.2);
    }
  }

  void _drawArrow(Canvas c, Offset a, Offset b, Color color) {
    final paint = Paint()..color = color..strokeWidth = 2.6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    c.drawLine(a, b, paint);
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final theta = math.atan2(dy, dx);
    const head = 14.0;
    final aw = 0.45;
    final p1 = Offset(b.dx - head * math.cos(theta - aw), b.dy - head * math.sin(theta - aw));
    final p2 = Offset(b.dx - head * math.cos(theta + aw), b.dy - head * math.sin(theta + aw));
    final path = Path()
      ..moveTo(b.dx, b.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    c.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BMFieldPainter old) => true;
}
