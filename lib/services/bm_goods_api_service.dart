import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/bm_goods_model.dart';

/// BMGoodsApiService - 球迷周边商品数据服务
/// 功能: 从 assets/data/goodsList.xlsx 读取表格并解析为商品模型列表
/// 原理: xlsx 本质是 zip 包, 解压后解析 xl/worksheets/sheet1.xml
///       (行列单元格) + xl/sharedStrings.xml (共享字符串池)
/// 架构: MVVM Service层, 单例
class BMGoodsApiService {
  /// 单例实例 (BMGoodsApiService 类型)
  static final BMGoodsApiService instance = BMGoodsApiService._();

  /// 私有构造函数
  BMGoodsApiService._();

  /// 商品列表缓存 (List<BMGoodsModel> 类型, 首次加载后复用)
  List<BMGoodsModel>? _cachedGoods;

  /// 一级分类有序列表缓存 (List<String> 类型, 按表格出现顺序去重)
  List<String>? _cachedCategories;

  /// xlsx 资产路径 (String 类型, 常量)
  static const String _assetPath = 'assets/data/goodsList.xlsx';

  /// 加载全部商品列表 (懒加载, 首次解析后走缓存)
  /// 返回: List<BMGoodsModel> 全部商品, 解析失败返回空数组
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

  /// 加载一级分类列表 (懒加载, 依赖全量数据去重)
  /// 返回: List<String> 分类名有序去重列表, 空数据返回 ['全部']
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

  /// 解析 xlsx 字节流为商品列表
  /// [bytes] - xlsx 文件字节 (List<int> 类型)
  /// 返回: List<BMGoodsModel>, 第0行表头跳过
  List<BMGoodsModel> _parseXlsx(List<int> bytes) {
    // 1. 解压 zip
    final Archive archive = ZipDecoder().decodeBytes(bytes);

    // 2. 读取共享字符串池 (t="s" 单元格的值是池内索引)
    final List<String> sharedStrings = [];
    final sharedFile = archive.findFile('xl/sharedStrings.xml');
    if (sharedFile != null) {
      final xml = utf8.decode(sharedFile.content as List<int>);
      for (final m
          in RegExp(r'<si>(.*?)</si>', dotAll: true).allMatches(xml)) {
        // 拼接 <si> 内所有 <t> 文本 (富文本单元格可能多段)
        final inner = m.group(1) ?? '';
        final buf = StringBuffer();
        for (final t in RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true)
            .allMatches(inner)) {
          buf.write(t.group(1) ?? '');
        }
        sharedStrings.add(_decodeXmlEntities(buf.toString()));
      }
    }

    // 3. 读取工作表
    final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
    if (sheetFile == null) return [];
    final sheetXml = utf8.decode(sheetFile.content as List<int>);

    // 4. 逐行提取单元格 (列号A=0,B=1..., 跳过表头第1行)
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
        // 列号 -> 下标 (r="B3" 中的字母部分)
        final colRef =
            RegExp(r'r="([A-Z]+)\d*"').firstMatch(attrs)?.group(1) ?? '';
        int colIndex = 0;
        for (final ch in colRef.codeUnits) {
          colIndex = colIndex * 26 + (ch - 64); // A=1, B=2...
        }
        colIndex = colIndex > 0 ? colIndex - 1 : cells.length;
        // 值: t="s" 取共享池, 其他取 <v> 原文
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
        // 补齐中间空单元格
        while (cells.length < colIndex) {
          cells.add('');
        }
        if (cells.length == colIndex) {
          cells.add(value);
        }
      }
      rows.add(cells);
    }

    // 5. 首行表头跳过, 剩余行转模型
    return rows
        .skip(1)
        .where((r) => r.length >= 4 && r[3].isNotEmpty)
        .map(BMGoodsModel.fromRow)
        .toList();
  }

  /// 解码 XML 转义实体 (&amp; &lt; &gt; &quot; &apos; 数字实体)
  /// [raw] - 原始文本 (String 类型)
  /// 返回: 解码后的文本
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
