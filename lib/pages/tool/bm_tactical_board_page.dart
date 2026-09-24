import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// 战术板元素类型枚举
enum _BMTacticalType {
  player,    // 我方球员 (蓝色圆)
  opponent,  // 对方球员 (红色圆)
  ball,      // 足球 (黄黑圆)
  arrow,     // 实心箭头
  dashedArrow, // 虚线箭头
  line,      // 普通直线
  polyline,  // 折线 (多点连线)
  freehand,  // 自由画笔 (手绘曲线)
  rect,      // 矩形框 (区域标注)
  zone,      // 半透明色块区域
  text,      // 文字标注
  erase,     // 删除单个元素 (点击命中元素删除)
}

/// 战术板单个数据元素
class _BMTacticalElement {
  /// 唯一 id (String 类型, 时间戳生成)
  final String id;

  /// 元素类型 (_BMTacticalType 枚举)
  final _BMTacticalType type;

  /// 起点/圆心坐标 (Offset 类型, 逻辑画布坐标)
  final Offset start;

  /// 终点坐标 (Offset? 类型, 线/箭头/矩形使用; 点元素为 null)
  final Offset? end;

  /// 折线/画笔路径点 (List<Offset> 类型, 仅 polyline/freehand 使用)
  final List<Offset> points;

  /// 显示文字 (String? 类型, 仅 text 元素使用)
  final String? text;

  /// 元素颜色 (Color 类型, 线/箭头/矩形/区域/文字使用)
  final Color color;

  /// 是否虚线样式 (bool 类型, 线/箭头使用)
  final bool isDashed;

  /// 线宽 (double 类型, 线/箭头/画笔使用)
  final double strokeWidth;

  const _BMTacticalElement({
    required this.id,
    required this.type,
    required this.start,
    this.end,
    this.points = const [],
    this.text,
    this.color = const Color(0xFFFBBF24),
    this.isDashed = false,
    this.strokeWidth = 2.6,
  });

  /// copyWith 复制对象, 只更新非 null 参数
  _BMTacticalElement copyWith({
    String? id,
    _BMTacticalType? type,
    Offset? start,
    Offset? end,
    List<Offset>? points,
    String? text,
    Color? color,
    bool? isDashed,
    double? strokeWidth,
  }) {
    return _BMTacticalElement(
      id: id ?? this.id,
      type: type ?? this.type,
      start: start ?? this.start,
      end: end ?? this.end,
      points: points ?? this.points,
      text: text ?? this.text,
      color: color ?? this.color,
      isDashed: isDashed ?? this.isDashed,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

/// BMTacticalBoardPage: 战术板页面
/// 功能 (v2 增强):
///   - 基础: 我方/对方球员/足球拖拽摆放, 实线/虚线箭头, 直线, 文字标注
///   - 新增: 折线(polyline), 自由画笔(freehand), 矩形区域框, 半透明色块(zone)
///   - 新增: 线条颜色选择器 (8色), 虚线/实线切换, 线宽选择 (细/中/粗)
///   - 新增: 删除单个元素 (Delete 工具点击元素删除)
///   - 新增: 阵型预设 433/442/352
///   - 新增: 画板导出 PNG 保存到系统相册 (RepaintBoundary 截图)
///   - 保留: 撤销/重做/清空, 半场/全场切换, 元素拖拽移动
/// 架构: 单类单文件, MVVM View 层, 继承 BMBasePage
class BMTacticalBoardPage extends BMBasePage {
  const BMTacticalBoardPage({super.key});

  @override
  State<BMTacticalBoardPage> createState() => _BMTacticalBoardPageState();
}

class _BMTacticalBoardPageState extends BMBasePageState<BMTacticalBoardPage> {
  /// 纵向场地逻辑画布尺寸 (Size 类型, 2:3 比例, 足球场标准俯视纵向)
  static const Size _canvasSize = Size(360, 540);

  /// 画布截图 Key (GlobalKey 类型, RepaintBoundary 定位导出用)
  final GlobalKey _canvasKey = GlobalKey();

  /// 元素列表 (List<_BMTacticalElement> 类型, 画布所有内容)
  final List<_BMTacticalElement> _elements = [];

  /// 当前选中工具 (_BMTacticalType 类型, 新增元素类型)
  _BMTacticalType _currentTool = _BMTacticalType.player;

  /// 当前画笔颜色 (Color 类型, 新建线/箭头/矩形/区域/文字使用)
  Color _currentColor = const Color(0xFFFBBF24);

  /// 当前是否虚线 (bool 类型, 新建线/箭头使用)
  bool _isDashed = false;

  /// 当前线宽 (double 类型, 3 档: 1.8 细 / 2.6 中 / 4.0 粗)
  double _strokeWidth = 2.6;

  /// 是否半场模式 (bool 类型, true=只画右半场)
  bool _isHalfField = false;

  /// 撤销栈 (List<List<_BMTacticalElement>> 类型, 最多 20 步)
  final List<List<_BMTacticalElement>> _undoStack = [];

  /// 重做栈 (List<List<_BMTacticalElement>> 类型, undo 时保存)
  final List<List<_BMTacticalElement>> _redoStack = [];

  /// 正在拖拽中的点元素 (_BMTacticalElement? 类型, null=未拖拽)
  _BMTacticalElement? _draggingElement;

  /// 正在绘制的线/箭头/折线/画笔元素 (_BMTacticalElement? 类型)
  _BMTacticalElement? _drawingElement;

  /// 折线/画笔的手指最后落点 (Offset? 类型, 距离阈值判断是否加点)
  Offset? _lastPoint;

  /// 可选颜色盘 (List<Color> 类型, 8 色)
  static const List<Color> _colorPalette = [
    Color(0xFFFBBF24), // 琥珀黄
    Color(0xFF22D3EE), // 青色
    Color(0xFFEF4444), // 红色
    Color(0xFF3B82F6), // 蓝色
    Color(0xFF10B981), // 绿色
    Color(0xFFF97316), // 橙色
    Color(0xFFA855F7), // 紫色
    Color(0xFFFFFFFF), // 白色
  ];

  /// 生成唯一 id
  String _genId() =>
      'el_${DateTime.now().millisecondsSinceEpoch}_${_elements.length}';

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

  /// 应用阵型预设 (纵向全场)
  /// [formation] - 阵型名 (String 类型, '433' / '442' / '352')
  void _applyFormation(String formation) {
    _saveUndo();
    _elements.clear();
    final w = _canvasSize.width;
    final h = _canvasSize.height;
    // 各阵型坐标: y 从 0.08(门将) 到 0.68(前锋)
    final Map<String, List<Offset>> presets = {
      '433': [
        Offset(w * 0.50, h * 0.08),
        Offset(w * 0.18, h * 0.22), Offset(w * 0.38, h * 0.22),
        Offset(w * 0.62, h * 0.22), Offset(w * 0.82, h * 0.22),
        Offset(w * 0.25, h * 0.45), Offset(w * 0.50, h * 0.45),
        Offset(w * 0.75, h * 0.45),
        Offset(w * 0.30, h * 0.68), Offset(w * 0.50, h * 0.68),
        Offset(w * 0.70, h * 0.68),
      ],
      '442': [
        Offset(w * 0.50, h * 0.08),
        Offset(w * 0.18, h * 0.22), Offset(w * 0.38, h * 0.22),
        Offset(w * 0.62, h * 0.22), Offset(w * 0.82, h * 0.22),
        Offset(w * 0.20, h * 0.45), Offset(w * 0.40, h * 0.45),
        Offset(w * 0.60, h * 0.45), Offset(w * 0.80, h * 0.45),
        Offset(w * 0.38, h * 0.68), Offset(w * 0.62, h * 0.68),
      ],
      '352': [
        Offset(w * 0.50, h * 0.08),
        Offset(w * 0.18, h * 0.20), Offset(w * 0.50, h * 0.16),
        Offset(w * 0.82, h * 0.20),
        Offset(w * 0.15, h * 0.45), Offset(w * 0.38, h * 0.42),
        Offset(w * 0.62, h * 0.42), Offset(w * 0.85, h * 0.45),
        Offset(w * 0.30, h * 0.50), Offset(w * 0.70, h * 0.50),
        Offset(w * 0.40, h * 0.68), Offset(w * 0.60, h * 0.68),
      ],
    };
    final positions = presets[formation] ?? presets['433']!;
    for (final p in positions) {
      _elements.add(_BMTacticalElement(
        id: _genId(),
        type: _BMTacticalType.player,
        start: p,
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
        title: const Text('Add Text',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
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
            child: const Text('Cancel',
                style: TextStyle(color: BMColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Add',
                style: TextStyle(
                    color: BMColors.bright, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// 查找命中的可交互元素 (点元素 + 线条中点, 距离阈值判断)
  /// [pos] - 触点坐标 (Offset 类型)
  /// 返回: _BMTacticalElement? 命中的元素
  _BMTacticalElement? _hitTest(Offset pos) {
    for (int i = _elements.length - 1; i >= 0; i--) {
      final e = _elements[i];
      if (e.type == _BMTacticalType.player ||
          e.type == _BMTacticalType.opponent ||
          e.type == _BMTacticalType.ball ||
          e.type == _BMTacticalType.text) {
        if ((e.start - pos).distance <= 20) return e;
      } else if (e.type == _BMTacticalType.line ||
          e.type == _BMTacticalType.arrow ||
          e.type == _BMTacticalType.dashedArrow) {
        // 线段命中: 点到线段距离 <= 14
        if (e.end != null) {
          final d = _pointToSegmentDistance(pos, e.start, e.end!);
          if (d <= 14) return e;
        }
      } else if (e.type == _BMTacticalType.polyline ||
          e.type == _BMTacticalType.freehand) {
        // 路径命中: 任一线段距离 <= 14
        if (e.points.length >= 2) {
          for (int j = 0; j < e.points.length - 1; j++) {
            final d = _pointToSegmentDistance(pos, e.points[j], e.points[j + 1]);
            if (d <= 14) return e;
          }
        }
      } else if (e.type == _BMTacticalType.rect || e.type == _BMTacticalType.zone) {
        // 矩形命中: 点在矩形内
        if (e.end != null) {
          final r = Rect.fromPoints(e.start, e.end!);
          if (r.contains(pos)) return e;
        }
      }
    }
    return null;
  }

  /// 点到线段距离 (double 类型)
  /// [p] - 触点, [a] - 线段起点, [b] - 线段终点
  double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    double t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - proj).distance;
  }

  // === 手势处理 ===
  void _onPanStart(DragStartDetails d) {
    final pos = d.localPosition;
    // 工具=player/opponent/ball: 点中现有点 -> 拖拽移动, 没点中 -> 新增
    final isPoint = _currentTool == _BMTacticalType.player ||
        _currentTool == _BMTacticalType.opponent ||
        _currentTool == _BMTacticalType.ball;
    if (isPoint) {
      final hit = _hitTest(pos);
      if (hit != null &&
          (hit.type == _BMTacticalType.player ||
              hit.type == _BMTacticalType.opponent ||
              hit.type == _BMTacticalType.ball ||
              hit.type == _BMTacticalType.text)) {
        _draggingElement = hit;
        _saveUndo();
        return;
      }
      _saveUndo();
      _elements.add(_BMTacticalElement(
          id: _genId(), type: _currentTool, start: pos));
      setState(() {});
      return;
    }
    // 工具=erase: 点中元素 -> 删除单个 (支持所有类型)
    if (_currentTool == _BMTacticalType.erase) {
      final hit = _hitTest(pos);
      if (hit != null) {
        _saveUndo();
        _elements.removeWhere((x) => x.id == hit.id);
        setState(() {});
      }
      return;
    }
    // 折线/画笔: 按下开始收集路径点
    if (_currentTool == _BMTacticalType.polyline ||
        _currentTool == _BMTacticalType.freehand) {
      _saveUndo();
      _drawingElement = _BMTacticalElement(
        id: _genId(),
        type: _currentTool,
        start: pos,
        points: [pos],
        color: _currentColor,
        isDashed: _isDashed,
        strokeWidth: _strokeWidth,
      );
      _lastPoint = pos;
      _elements.add(_drawingElement!);
      setState(() {});
      return;
    }
    // 直线/箭头/虚线箭头/矩形/区域: 开始拖画
    if (_currentTool == _BMTacticalType.line ||
        _currentTool == _BMTacticalType.arrow ||
        _currentTool == _BMTacticalType.dashedArrow ||
        _currentTool == _BMTacticalType.rect ||
        _currentTool == _BMTacticalType.zone) {
      _saveUndo();
      _drawingElement = _BMTacticalElement(
        id: _genId(),
        type: _currentTool,
        start: pos,
        end: pos,
        color: _currentColor,
        isDashed: _isDashed,
        strokeWidth: _strokeWidth,
      );
      _elements.add(_drawingElement!);
      setState(() {});
      return;
    }
    // 工具=text: 弹窗询问后在点的位置放置
    if (_currentTool == _BMTacticalType.text) {
      _showTextDialog().then((t) {
        if (t != null && t.isNotEmpty) {
          _saveUndo();
          _elements.add(_BMTacticalElement(
            id: _genId(),
            type: _BMTacticalType.text,
            start: pos,
            text: t,
            color: _currentColor,
          ));
          setState(() {});
        }
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_draggingElement != null) {
      final idx = _elements.indexWhere((e) => e.id == _draggingElement!.id);
      if (idx >= 0) {
        final updated = _draggingElement!.copyWith(start: d.localPosition);
        _elements[idx] = updated;
        _draggingElement = updated;
        setState(() {});
      }
      return;
    }
    if (_drawingElement != null) {
      final idx = _elements.indexWhere((e) => e.id == _drawingElement!.id);
      if (idx < 0) return;
      // 折线/画笔: 距上一记录点 >= 8 才追加 (平滑 + 减少点数)
      if (_currentTool == _BMTacticalType.polyline ||
          _currentTool == _BMTacticalType.freehand) {
        final last = _lastPoint ?? _drawingElement!.start;
        if ((d.localPosition - last).distance >= 8) {
          final updated =
              _drawingElement!.copyWith(points: [..._drawingElement!.points, d.localPosition]);
          _elements[idx] = updated;
          _drawingElement = updated;
          _lastPoint = d.localPosition;
          setState(() {});
        }
        return;
      }
      // 直线/箭头/矩形: 更新终点
      final updated = _drawingElement!.copyWith(end: d.localPosition);
      _elements[idx] = updated;
      _drawingElement = updated;
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails _) {
    if (_drawingElement != null) {
      final e = _drawingElement!;
      // 直线/箭头太短删除; 折线/画笔点数太少删除; 矩形太小删除
      if ((e.type == _BMTacticalType.line ||
              e.type == _BMTacticalType.arrow ||
              e.type == _BMTacticalType.dashedArrow) &&
          e.end != null &&
          (e.end! - e.start).distance < 12) {
        _elements.removeWhere((x) => x.id == e.id);
      } else if ((e.type == _BMTacticalType.polyline ||
              e.type == _BMTacticalType.freehand) &&
          e.points.length < 3) {
        _elements.removeWhere((x) => x.id == e.id);
      } else if ((e.type == _BMTacticalType.rect ||
              e.type == _BMTacticalType.zone) &&
          e.end != null &&
          (e.end! - e.start).distance < 14) {
        _elements.removeWhere((x) => x.id == e.id);
      }
      _drawingElement = null;
      _lastPoint = null;
      setState(() {});
    }
    _draggingElement = null;
  }

  // === 导出保存相册 ===
  /// 导出画板为 PNG 并保存到系统相册 (iOS 原生相册)
  Future<void> _saveToGallery() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _showToast('导出失败');
        return;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showToast('导出失败');
        return;
      }
      // Gal 插件: 自动请求相册添加权限 (iOS addOnly), 保存 PNG 到系统相册
      await Gal.putImageBytes(
        byteData.buffer.asUint8List(),
        name: 'tactical_board_${DateTime.now().millisecondsSinceEpoch}',
      );
      _showToast('已保存到相册');
    } on GalException catch (e) {
      // 权限拒绝 / 系统限制等具名异常
      _showToast(e.type.message);
    } catch (_) {
      _showToast('保存失败');
    }
  }

  /// Toast 提示
  /// [msg] - 提示文案 (String 类型)
  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: BMColors.pitch800,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          _buildStyleBar(),
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
        style: TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
      ),
      actions: [
        // 阵型预设 3 个
        ...['433', '442', '352'].map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _applyFormation(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: BMColors.bright.withValues(alpha: 0.12),
                    border: Border.all(
                        color: BMColors.bright.withValues(alpha: 0.5),
                        width: 1.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f,
                      style: const TextStyle(
                          color: BMColors.bright,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            )),
        // 保存到相册按钮
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: _saveToGallery,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: BMColors.bright.withValues(alpha: 0.12),
                border: Border.all(
                    color: BMColors.bright.withValues(alpha: 0.5),
                    width: 1.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save_alt, size: 12, color: BMColors.bright),
                  SizedBox(width: 4),
                  Text('Save',
                      style: TextStyle(
                          color: BMColors.bright,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 顶栏: 撤销/重做/清空 + 删除工具 + 半场/全场
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
          _miniButton(
              Icons.delete_outline, 'Clear', _clearAll, _elements.isEmpty),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _isHalfField = !_isHalfField),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isHalfField ? BMColors.bright : BMColors.pitch800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: BMColors.pitch700.withValues(alpha: 0.5)),
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

  /// 样式栏: 颜色盘 + 虚线切换 + 线宽 3 档
  Widget _buildStyleBar() {
    return Container(
      color: BMColors.pitch950,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: Row(
        children: [
          // 颜色盘 (横向滚动)
          Expanded(
            child: SizedBox(
              height: 26,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colorPalette.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final c = _colorPalette[i];
                  final selected = _currentColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _currentColor = c),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : BMColors.pitch700,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 虚线/实线切换
          GestureDetector(
            onTap: () => setState(() => _isDashed = !_isDashed),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isDashed
                    ? BMColors.bright.withValues(alpha: 0.15)
                    : BMColors.pitch800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isDashed ? BMColors.bright : BMColors.pitch700,
                  width: 1,
                ),
              ),
              child: Text(
                _isDashed ? '虚线' : '实线',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _isDashed ? BMColors.bright : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // 线宽 3 档
          ...[1.8, 2.6, 4.0].map((w) {
            final selected = _strokeWidth == w;
            return GestureDetector(
              onTap: () => setState(() => _strokeWidth = w),
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? BMColors.bright.withValues(alpha: 0.15)
                      : BMColors.pitch800,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? BMColors.bright : BMColors.pitch700,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: w + 2,
                  height: w + 2,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniButton(
      IconData icon, String label, VoidCallback onTap, bool disabled) {
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
            border:
                Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: BMColors.textPrimary),
              Text(label,
                  style: const TextStyle(
                      fontSize: 8, color: BMColors.textPrimary)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: RepaintBoundary(
              key: _canvasKey,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  size: _canvasSize,
                  painter: _BMFieldPainter(
                      isHalf: _isHalfField, elements: _elements),
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
      (_BMTacticalType.dashedArrow, Icons.south_east, 'Dash'),
      (_BMTacticalType.line, Icons.show_chart, 'Line'),
      (_BMTacticalType.polyline, Icons.polyline, 'Poly'),
      (_BMTacticalType.freehand, Icons.draw, 'Draw'),
      (_BMTacticalType.rect, Icons.crop_square, 'Rect'),
      (_BMTacticalType.zone, Icons.layers, 'Zone'),
      (_BMTacticalType.text, Icons.text_fields, 'Text'),
      (_BMTacticalType.erase, Icons.delete_sweep_outlined, 'Erase'),
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
                    border: Border.all(
                        color: active
                            ? BMColors.bright
                            : BMColors.pitch700.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(ic,
                          size: 16,
                          color: active ? BMColors.pitch950 : Colors.white),
                      const SizedBox(height: 2),
                      Text(lb,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? BMColors.pitch950
                                  : Colors.white)),
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
  /// 是否半场模式 (bool 类型)
  final bool isHalf;

  /// 战术元素列表 (List<_BMTacticalElement> 类型)
  final List<_BMTacticalElement> elements;

  _BMFieldPainter({required this.isHalf, required this.elements});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 1. 草地底色 (渐变深浅交替横条纹 10 条)
    final stripeCount = 10;
    for (int i = 0; i < stripeCount; i++) {
      final top = h * i / stripeCount;
      final bottom = h * (i + 1) / stripeCount;
      canvas.drawRect(
        Rect.fromLTRB(0, top, w, bottom),
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

    final midY = h / 2;
    final halfStartY = isHalf ? h * 0.33 : midY;
    if (!isHalf) {
      canvas.drawLine(Offset(6, midY), Offset(w - 6, midY), thin);
      canvas.drawCircle(Offset(w / 2, midY), w * 0.16, thin);
      canvas.drawCircle(Offset(w / 2, midY), 3,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
    } else {
      canvas.drawLine(Offset(6, halfStartY), Offset(w - 6, halfStartY), thin);
      canvas.drawCircle(Offset(w / 2, halfStartY), w * 0.16, thin);
    }
    // 上下禁区 / 小禁区
    void drawBox(double cy, double factor) {
      final bigW = w * 0.75 * factor;
      final bigH = w * 0.50 * factor;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(w / 2, cy), width: bigW, height: bigH),
        thin,
      );
      final smW = w * 0.40 * factor;
      final smH = w * 0.17 * factor;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(w / 2, cy), width: smW, height: smH),
        thin,
      );
    }

    final topCy = 6 + w * 0.16;
    final bottomCy = h - 6 - w * 0.16;
    if (!isHalf) drawBox(topCy, 1.0);
    drawBox(bottomCy, 1.0);

    // 3. 绘制所有战术元素
    for (final e in elements) {
      switch (e.type) {
        case _BMTacticalType.player:
          _drawCircle(canvas, e.start, 16, const Color(0xFF3B82F6), Colors.white);
          break;
        case _BMTacticalType.opponent:
          _drawCircle(canvas, e.start, 16, const Color(0xFFEF4444), Colors.white);
          break;
        case _BMTacticalType.ball:
          _drawBall(canvas, e.start, 11);
          break;
        case _BMTacticalType.line:
          if (e.end != null) {
            _drawLine(canvas, e.start, e.end!, e.color, e.strokeWidth, e.isDashed);
          }
          break;
        case _BMTacticalType.arrow:
          if (e.end != null) {
            _drawLine(canvas, e.start, e.end!, e.color, e.strokeWidth, false);
            _drawArrowHead(canvas, e.start, e.end!, e.color);
          }
          break;
        case _BMTacticalType.dashedArrow:
          if (e.end != null) {
            _drawLine(canvas, e.start, e.end!, e.color, e.strokeWidth, true);
            _drawArrowHead(canvas, e.start, e.end!, e.color);
          }
          break;
        case _BMTacticalType.polyline:
          if (e.points.isNotEmpty) {
            // 折线: 相邻点连线, 末段带箭头
            for (int i = 0; i < e.points.length - 1; i++) {
              _drawLine(canvas, e.points[i], e.points[i + 1], e.color,
                  e.strokeWidth, e.isDashed);
            }
            if (e.points.length >= 2) {
              _drawArrowHead(
                  canvas, e.points[e.points.length - 2], e.points.last, e.color);
            }
          }
          break;
        case _BMTacticalType.freehand:
          if (e.points.length >= 2) {
            // 自由画笔: 平滑曲线
            final path = Path()..moveTo(e.points.first.dx, e.points.first.dy);
            for (int i = 1; i < e.points.length - 1; i++) {
              final mid = Offset(
                (e.points[i].dx + e.points[i + 1].dx) / 2,
                (e.points[i].dy + e.points[i + 1].dy) / 2,
              );
              path.quadraticBezierTo(
                  e.points[i].dx, e.points[i].dy, mid.dx, mid.dy);
            }
            path.lineTo(e.points.last.dx, e.points.last.dy);
            final paint = Paint()
              ..color = e.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = e.strokeWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round;
            if (e.isDashed) {
              _drawDashedPath(canvas, path, paint);
            } else {
              canvas.drawPath(path, paint);
            }
          }
          break;
        case _BMTacticalType.rect:
          if (e.end != null) {
            final r = Rect.fromPoints(e.start, e.end!);
            _drawRect(canvas, r, e.color, e.strokeWidth, e.isDashed);
          }
          break;
        case _BMTacticalType.zone:
          if (e.end != null) {
            final r = Rect.fromPoints(e.start, e.end!);
            // 半透明色块 + 边框
            canvas.drawRect(r, Paint()..color = e.color.withValues(alpha: 0.28));
            _drawRect(canvas, r, e.color, e.strokeWidth, false);
          }
          break;
        case _BMTacticalType.text:
          if (e.text != null) {
            final tp = TextPainter(
              text: TextSpan(
                text: e.text,
                style: TextStyle(
                  color: e.color == const Color(0xFFFBBF24) ? Colors.white : e.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  backgroundColor: const Color(0xAA000000),
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas, e.start);
          }
          break;
        case _BMTacticalType.erase:
          // erase 只用于手势删除, 不渲染元素
          break;
      }
    }
  }

  /// 画直线 (支持虚线)
  void _drawLine(Canvas c, Offset a, Offset b, Color color, double width, bool dashed) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (dashed) {
      _drawDashedPath(
          c,
          Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy),
          paint);
    } else {
      c.drawLine(a, b, paint);
    }
  }

  /// 虚线 Path 绘制 (手动分段)
  void _drawDashedPath(Canvas c, Path path, Paint paint) {
    const dashLen = 9.0;
    const gapLen = 6.0;
    for (final metric in path.computeMetrics()) {
      double start = 0;
      while (start < metric.length) {
        final end = (start + dashLen) < metric.length ? start + dashLen : metric.length;
        c.drawPath(metric.extractPath(start, end), paint);
        start = end + gapLen;
      }
    }
  }

  /// 画矩形框 (支持虚线)
  void _drawRect(Canvas c, Rect r, Color color, double width, bool dashed) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    if (dashed) {
      _drawDashedPath(
          c,
          Path()
            ..addRect(r),
          paint);
    } else {
      c.drawRect(r, paint);
    }
  }

  /// 画箭头头部 (三角形)
  void _drawArrowHead(Canvas c, Offset a, Offset b, Color color) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final theta = math.atan2(dy, dx);
    final head = 14.0;
    const aw = 0.45;
    final p1 = Offset(b.dx - head * math.cos(theta - aw), b.dy - head * math.sin(theta - aw));
    final p2 = Offset(b.dx - head * math.cos(theta + aw), b.dy - head * math.sin(theta + aw));
    final path = Path()
      ..moveTo(b.dx, b.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    c.drawPath(path, Paint()..color = color);
  }

  void _drawCircle(Canvas c, Offset p, double r, Color fill, Color stroke) {
    c.drawCircle(p, r, Paint()..color = fill);
    c.drawCircle(p, r, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 1.6);
  }

  void _drawBall(Canvas c, Offset p, double r) {
    c.drawCircle(p, r, Paint()..color = Colors.white);
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

  @override
  bool shouldRepaint(covariant _BMFieldPainter old) => true;
}
