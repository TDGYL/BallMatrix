import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bm_base_page.dart';
import '../../theme/bm_colors.dart';

/// notesplit classesenum (BM differentiation: compare hanklive singlenonesplit classes, addadd4split classes Tab)
enum _BMNoteCategory {
 all('all', Icons.article_outlined),
  match('match', Icons.sports_soccer),
  training('', Icons.fitness_center_outlined),
  life('', Icons.wb_sunny_outlined);

 /// displaytext (String type, Tabupperdisplay)
 final String label;

 /// icon (IconData type, Tabuppericon)
 final IconData icon;
 const _BMNoteCategory(this.label, this.icon);
}

/// notemodel (one class per fileinner, innermakeusage)
class _BMNoteModel {
 /// noteuniqueidentifier (String type, timestampgenerate)
 final String id;

 /// notetitle (String type)
 String title;

 /// notecontent (String type)
 String content;

 /// notesplit classes (_BMNoteCategory enum, default match)
 final _BMNoteCategory category;

 /// createtime (int type, millisecondtimestamp)
 final int createdAt;

 /// updatetime (int type, millisecondtimestamp)
 int updatedAt;

 _BMNoteModel({
 required this.id,
 required this.title,
 required this.content,
 required this.category,
 required this.createdAt,
 required this.updatedAt,
 });

 Map<String, dynamic> toJson() => {
 'id': id,
        'title': title,
        'content': content,
        'category': category.index,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  static _BMNoteModel? fromJson(Map<String, dynamic> m) {
    final idx = m['category'] is int ? m['category'] as int : 0;
    final cat = (idx >= 0 && idx < _BMNoteCategory.values.length)
        ? _BMNoteCategory.values[idx]
        : _BMNoteCategory.match;
    return _BMNoteModel(
      id: m['id']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      content: m['content']?.toString() ?? '',
      category: cat,
      createdAt: m['createdAt'] is int ? m['createdAt'] as int : DateTime.now().millisecondsSinceEpoch,
      updatedAt: m['updatedAt'] is int ? m['updatedAt'] as int: DateTime.now().millisecondsSinceEpoch,
);
 }
}

/// BMNotesPage: notepage
/// differentiated design (compare hanklive Notes):
/// 1. dark green BallMatrix theme (pitch900 / pitch850 / pitch700)
/// 2. 4 split classes Tab (all/match//) - hanklive nohassplit classes
/// 3. top-right cornerpillpost button (and topicList completefullone: bright green12%fill+1.2pxstroke) - hanklive yes FAB
/// 4. cardtop-left cornersplit classescolor Tag (match=blue, =, =)
/// architecture: one class per file, extends BMBasePage
class BMNotesPage extends BMBasePage {
 const BMNotesPage({super.key});

 @override
 State<BMNotesPage> createState() => _BMNotesPageState();
}

class _BMNotesPageState extends BMBasePageState<BMNotesPage> with SingleTickerProviderStateMixin {
 /// SharedPreferences localstorage Key
 static const String _kKey = 'bm_tool_notes_v1';

 /// notelist
 final List<_BMNoteModel> _notes = [];

 /// currentselected Tab (_BMNoteCategory type)
 _BMNoteCategory _category = _BMNoteCategory.all;

 /// Tab controller
 TabController? _tabCtrl;

 /// loadinginmarker
 bool _isLoading = true;

 @override
 void initState() {
 super.initState();
 _tabCtrl = TabController(length: _BMNoteCategory.values.length, vsync: this);
 _tabCtrl!.addListener(() {
 if (!_tabCtrl!.indexIsChanging) {
 setState(() => _category = _BMNoteCategory.values[_tabCtrl!.index]);
 }
 });
 _loadNotes();
 }

 @override
 void dispose() {
 _tabCtrl?.dispose();
 super.dispose();
 }

 /// fromlocal SharedPreferences loadingnote
 Future<void> _loadNotes() async {
 try {
 final pref = await SharedPreferences.getInstance();
 final raw = pref.getString(_kKey);
 _notes.clear();
 if (raw != null && raw.isNotEmpty) {
 final arr = jsonDecode(raw);
 if (arr is List) {
 for (final item in arr) {
 if (item is Map<String, dynamic>) {
 final n = _BMNoteModel.fromJson(item);
 if (n != null && n.id.isNotEmpty) _notes.add(n);
 }
 }
 }
 }
 _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
 } catch (_) {
 _notes.clear();
 }
 setState(() => _isLoading = false);
 }

 /// savenotetolocal SharedPreferences
 Future<void> _save() async {
 try {
 final pref = await SharedPreferences.getInstance();
 await pref.setString(_kKey, jsonEncode(_notes.map((e) => e.toJson()).toList()));
 } catch (_) {}
 }

 /// gettakefilterlaternote (by _category filter)
 List<_BMNoteModel> get _filtered {
 if (_category == _BMNoteCategory.all) return _notes;
 return _notes.where((e) => e.category == _category).toList();
 }

 /// openeditpage (Neworedit)
 /// [existing] - _BMNoteModel? type, alreadystorethenedit
 Future<void> _editNote({_BMNoteModel? existing, _BMNoteCategory? initialCategory}) async {
 late _BMNoteCategory cat;
 if (initialCategory != null) {
 cat = initialCategory;
 } else if (existing?.category != null) {
 cat = existing!.category;
 } else {
 cat = (_category == _BMNoteCategory.all) ? _BMNoteCategory.match: _category;
 }
 final res = await Navigator.push<_BMNoteModel>(
 context,
 MaterialPageRoute(
 builder: (_) => _BMNoteEditPage(existing: existing, initialCategory: cat),
),
);
 if (res == null) return;
 final i = _notes.indexWhere((e) => e.id == res.id);
 if (i >= 0) {
 _notes[i] = res;
 } else {
 _notes.insert(0, res);
 }
 _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
 await _save();
 setState(() {});
 }

 /// Delete Note (double confirmation)
 Future<void> _deleteNote(_BMNoteModel n) async {
 final ok = await showDialog<bool>(
 context: context,
 builder: (ctx) => AlertDialog(
 backgroundColor: BMColors.pitch900,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
 title: const Text('Delete Note', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        content: Text(
          'confirmremove "${n.title.isEmpty ? 'Untitled' : n.title}" ?',
          style: TextStyle(color: BMColors.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Take effect', style: TextStyle(color: BMColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('remove', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _notes.removeWhere((e) => e.id == n.id);
    await _save();
    setState(() {});
  }

  String _fmtTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color _catColor(_BMNoteCategory c) => switch (c) {
        _BMNoteCategory.match => const Color(0xFF3B82F6),
        _BMNoteCategory.training => const Color(0xFF22C55E),
        _BMNoteCategory.life => const Color(0xFFF59E0B),
        _ => BMColors.bright,
      };

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: BMColors.bright, strokeWidth: 2))
          : Column(
              children: [
                _buildTabs(),
                Expanded(child: _buildList()),
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
      title: const Text('Notes', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
 // ⭐️ differentiation: and topicList completefullone of top-right cornerpillpost button
 actions: [
 Padding(
 padding: const EdgeInsets.only(right: 12),
 child: GestureDetector(
 onTap: () => _editNote(),
 behavior: HitTestBehavior.opaque,
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 decoration: BoxDecoration(
 color: BMColors.bright.withValues(alpha: 0.12),
 border: Border.all(color: BMColors.bright.withValues(alpha: 0.5), width: 1.2),
 borderRadius: BorderRadius.circular(20),
),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: const [
 Icon(Icons.add, size: 12, color: BMColors.bright),
 SizedBox(width: 4),
 Text('New', style: TextStyle(color: BMColors.bright, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          color: BMColors.pitch700.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: BMColors.pitch950,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: false,
        labelColor: Colors.white,
        unselectedLabelColor: BMColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        indicator: BoxDecoration(
          color: BMColors.pitch800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.6)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 3),
        dividerColor: Colors.transparent,
        tabs: _BMNoteCategory.values.map((c) {
          return Tab(
            height: 38,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 12),
                const SizedBox(width: 4),
                Text(c.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.note_alt_outlined, size: 48, color: Color(0xFF4B5563)),
            const SizedBox(height: 10),
            Text('No ${_category.label}note', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildCard(list[i]),
    );
  }

  Widget _buildCard(_BMNoteModel n) {
    final cc = _catColor(n.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: BMColors.pitch850,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BMColors.pitch700.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _editNote(existing: n),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: cc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(n.category.icon, size: 10, color: cc),
                        const SizedBox(width: 3),
                        Text(n.category.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: cc)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Stack(
                      children: [
                        Container(decoration: BoxDecoration(color: cc.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6))),
                        Positioned.fill(child: Icon(Icons.sticky_note_2_outlined, size: 12, color: cc)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title.isEmpty ? 'Untitled' : n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.content.isEmpty ? '（emptynote）': n.content,
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(color: BMColors.textSecondary, fontSize: 12, height: 1.4),
),
 const SizedBox(height: 8),
 Text(_fmtTime(n.updatedAt), style: TextStyle(color: BMColors.textTertiary, fontSize: 10)),
 ],
),
),
 const SizedBox(width: 8),
 GestureDetector(
 onTap: () => _deleteNote(n),
 behavior: HitTestBehavior.opaque,
 child: Container(
 width: 28,
 height: 28,
 decoration: BoxDecoration(
 color: const Color(0xFF7F1D1D).withValues(alpha: 0.6),
 borderRadius: BorderRadius.circular(8),
),
 child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFF87171)),
),
),
 ],
),
),
),
);
 }
}

// =====================================================================
// noteeditpage (push enter, push returns _BMNoteModel modifylaterobject)
// =====================================================================
class _BMNoteEditPage extends StatefulWidget {
 final _BMNoteModel? existing;
 final _BMNoteCategory initialCategory;
 const _BMNoteEditPage({this.existing, required this.initialCategory});

 @override
 State<_BMNoteEditPage> createState() => _BMNoteEditPageState();
}

class _BMNoteEditPageState extends State<_BMNoteEditPage> {
 late TextEditingController _titleCtrl;
 late TextEditingController _contentCtrl;
 late _BMNoteCategory _cat;

 @override
 void initState() {
 super.initState();
 final e = widget.existing;
 _titleCtrl = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _cat = e?.category ?? widget.initialCategory;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final res = (widget.existing == null)
        ? _BMNoteModel(
            id: 'note_$now',
            title: title,
            content: content,
            category: _cat,
            createdAt: now,
            updatedAt: now,
          )
        : _BMNoteModel(
            id: widget.existing!.id,
            title: title,
            content: content,
            category: _cat,
            createdAt: widget.existing!.createdAt,
            updatedAt: now,
          );
    Navigator.pop(context, res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BMColors.pitch900,
      appBar: AppBar(
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
        title: Text(widget.existing == null ? 'Newnote' : 'editnote', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: BMColors.bright, borderRadius: BorderRadius.circular(10)),
                child: const Text('save', style: TextStyle(color: BMColors.pitch950, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('split classes', style: TextStyle(color: BMColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [_BMNoteCategory.all, _BMNoteCategory.match, _BMNoteCategory.training, _BMNoteCategory.life]
                  .where((c) => c != _BMNoteCategory.all)
                  .map((c) {
                final active = _cat == c;
                Color color;
                switch (c) {
                  case _BMNoteCategory.match:
                    color = const Color(0xFF3B82F6);
                    break;
                  case _BMNoteCategory.training:
                    color = const Color(0xFF22C55E);
                    break;
                  case _BMNoteCategory.life:
                    color = const Color(0xFFF59E0B);
                    break;
                  default:
                    color = BMColors.bright;
                }
                return GestureDetector(
                  onTap: () => setState(() => _cat = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? color : BMColors.pitch850,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: active ? Colors.transparent : BMColors.pitch700.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 12, color: active ? Colors.white : BMColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(c.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? Colors.white : BMColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('title', style: TextStyle(color: BMColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'inputnotetitle...',
                hintStyle: TextStyle(color: BMColors.textTertiary),
                isDense: true,
                filled: true,
                fillColor: BMColors.pitch850,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: BMColors.pitch700)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: BMColors.pitch700)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            const Text('content', style: TextStyle(color: BMColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _contentCtrl,
              maxLines: 14,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
              decoration: InputDecoration(
                hintText: 'recordmatch、、in of pointpoint...',
                hintStyle: TextStyle(color: BMColors.textTertiary),
                filled: true,
                fillColor: BMColors.pitch850,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: BMColors.pitch700)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: BMColors.pitch700)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
