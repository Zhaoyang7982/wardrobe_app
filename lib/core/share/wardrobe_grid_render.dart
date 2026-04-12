import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/models/clothing.dart';
import '../constants/app_constants.dart';
import 'load_image_bytes.dart';

/// 衣橱总览图：4 列网格 + 底部品牌条（PNG）。仅绘制前 [maxItems] 件，避免超大图。
Future<Uint8List?> renderWardrobeOverviewPng(
  List<Clothing> clothes, {
  int columns = 4,
  int maxItems = 120,
  double cell = 200,
  double gap = 10,
  double padding = 20,
}) async {
  final sorted = List<Clothing>.from(clothes)
    ..sort((a, b) => a.name.compareTo(b.name));
  final slice = sorted.take(maxItems).toList();
  final rows = (slice.length / columns).ceil();
  if (rows == 0) {
    return null;
  }

  final gridW = columns * cell + (columns - 1) * gap;
  final gridH = rows * cell + (rows - 1) * gap;
  const footerH = 100.0;
  final width = (padding * 2 + gridW).ceil();
  final height = (padding * 2 + gridH + footerH).ceil();

  final cells = <ui.Image?>[];
  for (final c in slice) {
    final ref = c.croppedImageUrl ?? c.imageUrl;
    final bytes = await loadImageRefAsBytes(ref);
    ui.Image? img;
    if (bytes != null && bytes.isNotEmpty) {
      try {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        img = frame.image;
      } catch (_) {
        img = null;
      }
    }
    cells.add(img);
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFF5F1EB),
  );

  for (var i = 0; i < slice.length; i++) {
    final col = i % columns;
    final row = i ~/ columns;
    final x = padding + col * (cell + gap);
    final y = padding + row * (cell + gap);
    final cellRect = Rect.fromLTWH(x, y, cell, cell);
    final img = cells[i];
    if (img != null) {
      _drawImageCover(canvas, img, cellRect);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
        Paint()..color = const Color(0xFFE0D9CF),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: slice[i].name.length <= 6
              ? slice[i].name
              : '${slice[i].name.substring(0, 6)}…',
          style: const TextStyle(color: Color(0xFF6D5D4C), fontSize: 18),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: cell - 12);
      tp.paint(canvas, Offset(x + 6, y + (cell - tp.height) / 2));
    }
  }

  final footY = padding + gridH + 8;
  final brandTp = TextPainter(
    text: TextSpan(
      text: '${AppConstants.appName} · 衣橱总览（${slice.length}/${sorted.length} 件）',
      style: const TextStyle(
        color: Color(0xFF4A3F35),
        fontSize: 26,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width - padding * 2);
  brandTp.paint(canvas, Offset(padding, footY + 8));

  if (sorted.length > maxItems) {
    final more = TextPainter(
      text: TextSpan(
        text: '另有 ${sorted.length - maxItems} 件未入图，请导出 CSV 查看完整清单',
        style: TextStyle(
          color: Colors.brown.shade600,
          fontSize: 20,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - padding * 2);
    more.paint(canvas, Offset(padding, footY + 44));
  }

  final picture = recorder.endRecording();
  final out = await picture.toImage(width, height);
  for (final img in cells) {
    img?.dispose();
  }
  final bd = await out.toByteData(format: ui.ImageByteFormat.png);
  out.dispose();
  return bd?.buffer.asUint8List();
}

void _drawImageCover(Canvas canvas, ui.Image image, Rect dest) {
  final iw = image.width.toDouble();
  final ih = image.height.toDouble();
  final dw = dest.width;
  final dh = dest.height;
  final scale = math.max(dw / iw, dh / ih);
  final sw = dw / scale;
  final sh = dh / scale;
  final sx = (iw - sw) / 2;
  final sy = (ih - sh) / 2;
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(dest, const Radius.circular(8)));
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(sx, sy, sw, sh),
    dest,
    Paint()..filterQuality = FilterQuality.medium,
  );
  canvas.restore();
}
