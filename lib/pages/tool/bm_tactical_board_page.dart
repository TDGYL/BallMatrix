import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// tacticalelementtypeenum
enum _BMTacticalType {
 player, // our sideplayer (bluecolor)
 opponent, // correctdirectionplayer (color)
 ball, // football ()
 arrow, // actualarrow
 dashedArrow, // dashed linearrow
 line, // generalcommonline
 polyline, // polyline (morepointline)
 freehand, // bybrush (curve)
 rect, // rectangleframe (zoneannotation)
 zone, // semi-transparentcolor blockzone
 text, // textannotation
 erase, // removesingleitemselement (taphit inelementremove)
}

/// tacticalsingleitemsdataelement
class _BMTacticalElement {
 /// unique id (String type, timestampgenerate)
 final String id;

 /// elementtype (_BMTacticalType enum)
 final _BMTacticalType type;

 /// point/tag (Offset type, logiccanvastag)
 final Offset start;

 /// finalpointtag (Offset? type, line/arrow/rectanglemakeuse; pointelementas null)
 final Offset? end;

 /// polyline/brushpathpoint (List<Offset> type, only polyline/freehand makeusage)
 final List<Offset> points;

 /// displaytext (String? type, only text elementmakeusage)
 final String? text;

 /// elementcolor (Color type, line/arrow/rectangle/zone/textmakeusage)
 final Color color;

 /// whetherdashed linestyle (bool type, line/arrowmakeusage)
 final bool isDashed;

 /// stroke width (double type, line/arrow/brushmakeusage)
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

 /// copyWith copyobject, onlyupdatenon null argument
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

/// BMTacticalBoardPage: tacticalpage
/// feature (v2 add):
/// - : our side/correctdirectionplayer/footballdrag, solid line/dashed linearrow, line, textannotation
/// - add: polyline(polyline), bybrush(freehand), rectanglezoneframe, semi-transparentcolor block(zone)
/// - add: lineitemscolorpicker (8color), dashed line/solid lineswitch, stroke widthselect (/in/)
/// - add: removesingleitemselement (Delete tooltapelementremove)
/// - add: formation preset 433/442/352
/// - add: boardexport PNG savetosystem gallery (RepaintBoundary screenshot)
/// - keep: undo/redo/clear, halfcourt/fullcourtswitch, elementdrag
/// architecture: one class per file, MVVM View layer, extends BMBasePage
class BMTacticalBoardPage extends BMBasePage {
 const BMTacticalBoardPage({super.key});

 @override
 State<BMTacticalBoardPage> createState() => _BMTacticalBoardPageState();
}

class _BMTacticalBoardPageState extends BMBasePageState<BMTacticalBoardPage> {
 /// directioncourtlogiccanvassize (Size type, 2:3 ratioexample, footballcourttagviewdirection)
 static const Size _canvasSize = Size(360, 540);

 /// canvasscreenshot Key (GlobalKey type, RepaintBoundary locateexportusage)
 final GlobalKey _canvasKey = GlobalKey();

 /// elementlist (List<_BMTacticalElement> type, canvasallhascontent)
 final List<_BMTacticalElement> _elements = [];

 /// currentselectedtool (_BMTacticalType type, addelementtype)
 _BMTacticalType _currentTool = _BMTacticalType.player;

 /// currentbrushcolor (Color type, Newline/arrow/rectangle/zone/textmakeusage)
 Color _currentColor = const Color(0xFFFBBF24);

 /// currentwhetherdashed line (bool type, Newline/arrowmakeusage)
 bool _isDashed = false;

 /// currentstroke width (double type, 3 tier: 1.8 / 2.6 in / 4.0 )
 double _strokeWidth = 2.6;

 /// whetherhalfcourtmodulestyle (bool type, true=onlyrighthalfcourt)
 bool _isHalfField = false;

 /// undo (List<List<_BMTacticalElement>> type, more 20 )
 final List<List<_BMTacticalElement>> _undoStack = [];

 /// redo (List<List<_BMTacticalElement>> type, undo whensave)
 final List<List<_BMTacticalElement>> _redoStack = [];

 /// centerdragin of pointelement (_BMTacticalElement? type, null=not yetdrag)
 _BMTacticalElement? _draggingElement;

 /// centerpaint of line/arrow/polyline/brushelement (_BMTacticalElement? type)
 _BMTacticalElement? _drawingElement;

 /// polyline/brush of laterpoint (Offset? type, distanceleavevaluecheckwhetheraddpoint)
 Offset? _lastPoint;

 /// optionalcolorodds (List<Color> type, 8 color)
 static const List<Color> _colorPalette = [
 Color(0xFFFBBF24), // 
 Color(0xFF22D3EE), // color
 Color(0xFFEF4444), // color
 Color(0xFF3B82F6), // bluecolor
 Color(0xFF10B981), // color
 Color(0xFFF97316), // orange
 Color(0xFFA855F7), // purple
 Color(0xFFFFFFFF), // white
 ];

 /// generateunique id
 String _genId() =>
 'el_${DateTime.now().millisecondsSinceEpoch}_${_elements.length}';

 /// savecurrentstatetoundo
 void _saveUndo() {
 _undoStack.add(List.from(_elements));
 if (_undoStack.length > 20) _undoStack.removeAt(0);
 _redoStack.clear();
 }

 /// undo
 void _undo() {
 if (_undoStack.isEmpty) return;
 _redoStack.add(List.from(_elements));
 _elements
..clear()
..addAll(_undoStack.removeLast());
 setState(() {});
 }

 /// redo
 void _redo() {
 if (_redoStack.isEmpty) return;
 _undoStack.add(List.from(_elements));
 _elements
..clear()
..addAll(_redoStack.removeLast());
 setState(() {});
 }

 /// clearcanvas
 void _clearAll() {
 if (_elements.isEmpty) return;
 _saveUndo();
 _elements.clear();
 setState(() {});
 }

 /// shoulduseformation preset (directionfullcourt)
 /// [formation] - formationname (String type, '433' / '442' / '352')
 void _applyFormation(String formation) {
 _saveUndo();
 _elements.clear();
 final w = _canvasSize.width;
 final h = _canvasSize.height;
 // eachformationtag: y from 0.08(will) to 0.68(first forward)
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

 /// displaytextinputdialog, returnsinputtext (Take effectreturns null)
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

 /// hit in of canelement (pointelement + lineitemsinpoint, distanceleavevaluecheck)
 /// [pos] - pointtag (Offset type)
 /// returns: _BMTacticalElement? hit in of element
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
 // linesectionhit in: pointtolinesectiondistanceleave <= 14
 if (e.end != null) {
 final d = _pointToSegmentDistance(pos, e.start, e.end!);
 if (d <= 14) return e;
 }
 } else if (e.type == _BMTacticalType.polyline ||
 e.type == _BMTacticalType.freehand) {
 // pathhit in: anyonelinesectiondistanceleave <= 14
 if (e.points.length >= 2) {
 for (int j = 0; j < e.points.length - 1; j++) {
 final d = _pointToSegmentDistance(pos, e.points[j], e.points[j + 1]);
 if (d <= 14) return e;
 }
 }
 } else if (e.type == _BMTacticalType.rect || e.type == _BMTacticalType.zone) {
 // rectanglehit in: pointrectangleinner
 if (e.end != null) {
 final r = Rect.fromPoints(e.start, e.end!);
 if (r.contains(pos)) return e;
 }
 }
 }
 return null;
 }

 /// pointtolinesectiondistanceleave (double type)
 /// [p] - point, [a] - linesectionpoint, [b] - linesectionfinalpoint
 double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
 final ab = b - a;
 final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
 if (len2 == 0) return (p - a).distance;
 double t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2;
 t = t.clamp(0.0, 1.0);
 final proj = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
 return (p - proj).distance;
 }

 // === gesturehandle ===
 void _onPanStart(DragStartDetails d) {
 final pos = d.localPosition;
 // tool=player/opponent/ball: pointinhaspoint -> drag, nopointin -> add
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
 // tool=erase: pointinelement -> removesingleitems (supportallhastype)
 if (_currentTool == _BMTacticalType.erase) {
 final hit = _hitTest(pos);
 if (hit != null) {
 _saveUndo();
 _elements.removeWhere((x) => x.id == hit.id);
 setState(() {});
 }
 return;
 }
 // polyline/brush: bylowerstartreceivepathpoint
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
 // line/arrow/dashed linearrow/rectangle/zone: start
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
 // tool=text: dialoglaterpoint of positionplace
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
 // polyline/brush: distanceupperonerecordpoint >= 8 append (D + sublesspointcount)
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
 // line/arrow/rectangle: updatefinalpoint
 final updated = _drawingElement!.copyWith(end: d.localPosition);
 _elements[idx] = updated;
 _drawingElement = updated;
 setState(() {});
 }
 }

 void _onPanEnd(DragEndDetails _) {
 if (_drawingElement != null) {
 final e = _drawingElement!;
 // line/arrowremove; polyline/brushpointcountlessremove; rectanglesmallremove
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

 // === exportsave to gallery ===
 /// exportboardas PNG andsavetosystem gallery (iOS nativephoto library)
 Future<void> _saveToGallery() async {
 try {
 final boundary = _canvasKey.currentContext?.findRenderObject()
 as RenderRepaintBoundary?;
 if (boundary == null) {
 _showToast('Export Failed');
        return;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showToast('Export Failed');
 return;
 }
 // Gal file: autorequestphoto libraryaddpermission (iOS addOnly), save PNG tosystem gallery
 await Gal.putImageBytes(
 byteData.buffer.asUint8List(),
 name: 'tactical_board_${DateTime.now().millisecondsSinceEpoch}',
      );
      _showToast('alreadysavetophoto library');
 } on GalException catch (e) {
 // permission / systemsystemlimitmakewaitnameexception
 _showToast(e.type.message);
 } catch (_) {
 _showToast('savefailure');
 }
 }

 /// Toast toast
 /// [msg] - toasttext (String type)
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

 // === build ===
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
 // formation preset 3 items
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
 // savetophoto librarybutton
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

 /// topbar: undo/redo/clear + removetool + halfcourt/fullcourt
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
 color: _isHalfField ? BMColors.pitch950: Colors.white,
),
),
),
),
 ],
),
);
 }

 /// stylebar: colorodds + dashed lineswitch + stroke width 3 tier
 Widget _buildStyleBar() {
 return Container(
 color: BMColors.pitch950,
 padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
 child: Row(
 children: [
 // colorodds (directionscroll)
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
 color: selected ? Colors.white: BMColors.pitch700,
 width: selected ? 2.5: 1,
),
),
),
);
 },
),
),
),
 const SizedBox(width: 8),
 // dashed line/solid lineswitch
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
 color: _isDashed ? BMColors.bright: BMColors.pitch700,
 width: 1,
),
),
 child: Text(
 _isDashed ? 'dashed line' : 'solid line',
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.w700,
 color: _isDashed ? BMColors.bright: Colors.white,
),
),
),
),
 const SizedBox(width: 6),
 // stroke width 3 tier
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
 color: selected ? BMColors.bright: BMColors.pitch700,
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
 onTap: disabled ? null: onTap,
 behavior: HitTestBehavior.opaque,
 child: Opacity(
 opacity: disabled ? 0.3: 1.0,
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
 color: active ? BMColors.bright: BMColors.pitch850,
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
 color: active ? BMColors.pitch950: Colors.white),
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
// court + element painter
// =====================================================================
class _BMFieldPainter extends CustomPainter {
 /// whetherhalfcourtmodulestyle (bool type)
 final bool isHalf;

 /// tacticalelementlist (List<_BMTacticalElement> type)
 final List<_BMTacticalElement> elements;

 _BMFieldPainter({required this.isHalf, required this.elements});

 @override
 void paint(Canvas canvas, Size size) {
 final w = size.width;
 final h = size.height;
 // 1. bottomcolor (changedepthitems 10 items)
 final stripeCount = 10;
 for (int i = 0; i < stripeCount; i++) {
 final top = h * i / stripeCount;
 final bottom = h * (i + 1) / stripeCount;
 canvas.drawRect(
 Rect.fromLTRB(0, top, w, bottom),
 Paint()..color = i.isEven ? const Color(0xFF14532D): const Color(0xFF166534),
);
 }
 // 2. outerframe / center circle / halfway line
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
 final halfStartY = isHalf ? h * 0.33: midY;
 if (!isHalf) {
 canvas.drawLine(Offset(6, midY), Offset(w - 6, midY), thin);
 canvas.drawCircle(Offset(w / 2, midY), w * 0.16, thin);
 canvas.drawCircle(Offset(w / 2, midY), 3,
 Paint()..color = Colors.white.withValues(alpha: 0.9));
 } else {
 canvas.drawLine(Offset(6, halfStartY), Offset(w - 6, halfStartY), thin);
 canvas.drawCircle(Offset(w / 2, halfStartY), w * 0.16, thin);
 }
 // upperlowerforbiddenzone / smallforbiddenzone
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

 // 3. paintallhastacticalelement
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
 // polyline: pointline, endsectionarrow
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
 // bybrush: Dcurve
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
 // semi-transparentcolor block + border
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
 color: e.color == const Color(0xFFFBBF24) ? Colors.white: e.color,
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
 // erase onlyforgestureremove, notrenderelement
 break;
 }
 }
 }

 /// line (supportdashed line)
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

 /// dashed line Path paint (manualminsection)
 void _drawDashedPath(Canvas c, Path path, Paint paint) {
 const dashLen = 9.0;
 const gapLen = 6.0;
 for (final metric in path.computeMetrics()) {
 double start = 0;
 while (start < metric.length) {
 final end = (start + dashLen) < metric.length ? start + dashLen: metric.length;
 c.drawPath(metric.extractPath(start, end), paint);
 start = end + gapLen;
 }
 }
 }

 /// rectangleframe (supportdashed line)
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

 /// arrowheader (threecornershape)
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
