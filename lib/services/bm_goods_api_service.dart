import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/bm_goods_model.dart';

/// BMGoodsApiService - fansmerchandisedataservice
/// feature: from assets/data/goodsList.xlsx readsheetandparseasmodellist
/// original: xlsx thisyes zip , decompresslaterparse xl/worksheets/sheet1.xml
/// (linecolumncell) + xl/sharedStrings.xml (shared string)
/// architecture: MVVM Servicelayer, singleton
class BMGoodsApiService {
 /// singletoninstance (BMGoodsApiService type)
 static final BMGoodsApiService instance = BMGoodsApiService._();

 /// privateconstructor
 BMGoodsApiService._();

 /// listcache (List<BMGoodsModel> type, first timeloadinglaterreuse)
 List<BMGoodsModel>? _cachedGoods;

 /// primary categoryhasindexlistcache (List<String> type, bysheetoutputorderdeduplicate)
 List<String>? _cachedCategories;

 /// xlsx path (String type, constant)
 static const String _assetPath = 'assets/data/goodsList.xlsx';

 /// loadingalllist (lazy load, first timeparselatercache)
 /// returns: List<BMGoodsModel> all, parsefailurereturnsemptyarray
 Future<List<BMGoodsModel>> fetchAllGoods() async {
 if (_cachedGoods != null) return _cachedGoods!;
 try {
 final ByteData data = await rootBundle.load(_assetPath);
 final List<BMGoodsModel> goods = _parseXlsx(data.buffer.asUint8List());
 _cachedGoods = goods;
 return goods;
 } catch (_) {
 return [];
 }
 }

 /// loadingprimary categorylist (lazy load, depends onfullvolumedatadeduplicate)
 /// returns: List<String> split classesnamehasindexdeduplicatelist, emptydatareturns ['all']
 Future<List<String>> fetchCategories() async {
 if (_cachedCategories != null) return _cachedCategories!;
 final goods = await fetchAllGoods();
 final seen = <String>{};
 for (final g in goods) {
 if (g.category.isNotEmpty) seen.add(g.category);
 }
 _cachedCategories = seen.toList();
 return _cachedCategories ?? [];
 }

 /// parse xlsx textthrottleaslist
 /// [bytes] - xlsx textfiletextsection (List<int> type)
 /// returns: List<BMGoodsModel>, No. 0linetableheaderskip
 List<BMGoodsModel> _parseXlsx(List<int> bytes) {
 // 1. decompress zip
 final Archive archive = ZipDecoder().decodeBytes(bytes);

 // 2. readshared string (t="s" cell of valueyesinnerindex)
 final List<String> sharedStrings = [];
 final sharedFile = archive.findFile('xl/sharedStrings.xml');
    if (sharedFile != null) {
      final xml = utf8.decode(sharedFile.content as List<int>);
      for (final m
          in RegExp(r'<si>(.*?)</si>', dotAll: true).allMatches(xml)) {
 // concat <si> innerallhas <t> text (textcellcanabilitymoresection)
 final inner = m.group(1) ?? '';
        final buf = StringBuffer();
        for (final t in RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true)
            .allMatches(inner)) {
          buf.write(t.group(1) ?? '');
        }
        sharedStrings.add(_decodeXmlEntities(buf.toString()));
      }
    }

    // 3. readworksheet
    final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
 if (sheetFile == null) return [];
 final sheetXml = utf8.decode(sheetFile.content as List<int>);

 // 4. linetakecell (column indexA=0,B=1..., skiptableheaderNo. 1line)
 final rows = <List<String>>[];
 for (final rowMatch
 in RegExp(r'<row[^>]*>(.*?)</row>', dotAll: true)
            .allMatches(sheetXml)) {
      final rowXml = rowMatch.group(1) ?? '';
      final cells = <String>[];
      for (final cellMatch
          in RegExp(r'<c([^>]*)>(.*?)</c>', dotAll: true)
              .allMatches(rowXml)) {
        final attrs = cellMatch.group(1) ?? '';
        final inner = cellMatch.group(2) ?? '';
        // column index -> index (r="B3" in of textpartial)
 final colRef =
 RegExp(r'r="([A-Z]+)\d*"').firstMatch(attrs)?.group(1) ?? '';
 int colIndex = 0;
 for (final ch in colRef.codeUnits) {
 colIndex = colIndex * 26 + (ch - 64); // A=1, B=2...
 }
 colIndex = colIndex > 0 ? colIndex - 1: cells.length;
 // value: t="s" take, otherstake <v> originaltext
 String value = '';
        final vMatch = RegExp(r'<v[^>]*>(.*?)</v>', dotAll: true)
            .firstMatch(inner)?.group(1);
        if (attrs.contains('t="s"') && vMatch != null) {
          final idx = int.tryParse(vMatch) ?? -1;
          value = (idx >= 0 && idx < sharedStrings.length)
              ? sharedStrings[idx]
              : '';
        } else {
          value = _decodeXmlEntities(vMatch ?? '');
 }
 // patchmiddleemptycell
 while (cells.length < colIndex) {
 cells.add('');
 }
 if (cells.length == colIndex) {
 cells.add(value);
 }
 }
 rows.add(cells);
 }

 // 5. linetableheaderskip, remaininglineconvertmodel
 return rows
.skip(1)
.where((r) => r.length >= 4 && r[3].isNotEmpty)
.map(BMGoodsModel.fromRow)
.toList();
 }

 /// decode XML escapeactualbody (&amp; &lt; &gt; &quot; &apos; numberactualbody)
 /// [raw] - rawtext (String type)
 /// returns: decodelater of text
 String _decodeXmlEntities(String raw) {
 return raw
.replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAllMapped(RegExp(r'&#(\d+);'),
            (m) => String.fromCharCode(int.parse(m.group(1) ?? '0')))
        .replaceAll('&amp;', '&');
  }
}
