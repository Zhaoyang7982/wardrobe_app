import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// 生成带品牌水印的搭配分享图（PNG）
Future<Uint8List?> renderOutfitSharePng({
  required String outfitName,
  Uint8List? coverBytes,
  int width = 1080,
  int height = 1350,
}) async {
  ui.Image? cover;
  if (coverBytes != null && coverBytes.isNotEmpty) {
    try {
      final codec = await ui.instantiateImageCodec(coverBytes);
      final frame = await codec.getNextFrame();
      cover = frame.image;
    } catch (_) {
      cover = null;
    }
  }

  const footerH = 200.0;
  final coverH = height - footerH;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(width.toDouble(), height.toDouble());

  canvas.drawRect(
    Offset.zero & size,
    Paint()..color = const Color(0xFFE8E4DD),
  );

  final dest = Rect.fromLTWH(0, 0, width.toDouble(), coverH);
  if (cover != null) {
    _drawImageCover(canvas, cover, dest);
  } else {
    final p = Paint()..color = const Color(0xFFD4CEC4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(dest.deflate(24), const Radius.circular(16)),
      p,
    );
    final hint = TextPainter(
      text: TextSpan(
        text: '搭配',
        style: TextStyle(
          color: Colors.brown.shade400,
          fontSize: 56,
          fontWeight: FontWeight.w300,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hint.paint(
      canvas,
      Offset(
        (width - hint.width) / 2,
        (coverH - hint.height) / 2,
      ),
    );
  }

  final footerRect = Rect.fromLTWH(0, coverH, width.toDouble(), footerH);
  final grad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.black.withValues(alpha: 0),
      Colors.black.withValues(alpha: 0.55),
      Colors.black.withValues(alpha: 0.82),
    ],
    stops: const [0, 0.35, 1],
  );
  canvas.drawRect(
    footerRect,
    Paint()..shader = grad.createShader(footerRect),
  );

  final titleTp = TextPainter(
    text: TextSpan(
      text: outfitName,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: width - 56);
  titleTp.paint(canvas, Offset(28, coverH - titleTp.height - 88));

  final brandTp = TextPainter(
    text: TextSpan(
      children: [
        TextSpan(
          text: AppConstants.appName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(
          text: ' · 搭配分享',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 24,
          ),
        ),
      ],
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width - 56);
  brandTp.paint(canvas, Offset(28, height - brandTp.height - 36));

  final picture = recorder.endRecording();
  final out = await picture.toImage(width, height);
  cover?.dispose();
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
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(sx, sy, sw, sh),
    dest,
    Paint()..filterQuality = FilterQuality.high,
  );
}
