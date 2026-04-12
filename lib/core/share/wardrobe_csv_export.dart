import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../../domain/models/clothing.dart';

final _dateFmt = DateFormat('yyyy-MM-dd');

/// 导出衣橱为 CSV 文本（UTF-8，含 BOM 便于 Excel 识别中文）
String buildWardrobeCsvString(List<Clothing> clothes) {
  final sorted = List<Clothing>.from(clothes)
    ..sort((a, b) => a.name.compareTo(b.name));

  const headers = [
    'id',
    '名称',
    '类别',
    '颜色',
    '品牌',
    '尺码',
    '标签',
    '季节',
    '场合',
    '风格',
    '购买日期',
    '购买价格',
    '状态',
    '穿着次数',
    '上次穿着',
    '备注',
    '图片URL',
    '裁剪图URL',
  ];

  final rows = <List<String>>[headers];
  for (final c in sorted) {
    rows.add([
      c.id,
      c.name,
      c.category,
      c.colors.join('；'),
      c.brand ?? '',
      c.size ?? '',
      c.tags.join('；'),
      c.season ?? '',
      c.occasion ?? '',
      c.style ?? '',
      c.purchaseDate != null ? _dateFmt.format(c.purchaseDate!) : '',
      c.purchasePrice != null ? c.purchasePrice!.toString() : '',
      c.status,
      c.usageCount.toString(),
      c.lastWornDate != null ? _dateFmt.format(c.lastWornDate!) : '',
      c.notes ?? '',
      c.imageUrl ?? '',
      c.croppedImageUrl ?? '',
    ]);
  }

  final csvStr = Csv(
    fieldDelimiter: ',',
    quoteCharacter: '"',
    lineDelimiter: '\r\n',
  ).encode(rows);
  return '${String.fromCharCodes([0xFEFF])}$csvStr';
}

List<int> wardrobeCsvBytes(List<Clothing> clothes) {
  return utf8.encode(buildWardrobeCsvString(clothes));
}

/// UTF-16 LE + BOM，Windows 下 WPS/Excel 双击打开更不易乱码（仍可用系统分享）
List<int> wardrobeCsvBytesUtf16Le(List<Clothing> clothes) {
  final inner = buildWardrobeCsvString(clothes);
  final content =
      inner.startsWith(String.fromCharCode(0xFEFF)) ? inner.substring(1) : inner;
  final units = content.codeUnits;
  final out = Uint8List(2 + units.length * 2);
  out[0] = 0xFF;
  out[1] = 0xFE;
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    out[2 + i * 2] = u & 0xFF;
    out[2 + i * 2 + 1] = (u >> 8) & 0xFF;
  }
  return out;
}
