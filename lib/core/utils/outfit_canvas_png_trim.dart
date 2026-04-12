import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 将「创建搭配」画布导出的 PNG 按近似背景色裁边，减少列表/详情里大片留白。
/// 失败则返回原字节。
///
/// 移动端高 DPR 截图边缘常出现与 #F5F2EC 略有偏差的灰边，逐像素 bbox 会把整宽都当成「前景」
/// 从而裁不掉左右留白；因此增加「整列/整行多数像素为背景」的边界检测作为主逻辑。
Uint8List trimOutfitCanvasPng(Uint8List png) {
  final image = img.decodeImage(png);
  if (image == null) {
    return png;
  }

  bool isBg(int r, int g, int b, int a) {
    if (a < 45) {
      return true;
    }
    if ((r - 245).abs() <= 24 && (g - 242).abs() <= 24 && (b - 236).abs() <= 24) {
      return true;
    }
    if ((r - 232).abs() <= 22 && (g - 228).abs() <= 22 && (b - 221).abs() <= 22) {
      return true;
    }
    final hi = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final lo = r < g ? (r < b ? r : b) : (g < b ? g : b);
    if (hi >= 210 && lo >= 192 && (hi - lo) <= 30) {
      return true;
    }
    // 略暗的浅灰边（部分 GPU / Impeller 混色）
    if (hi >= 200 && lo >= 178 && (hi - lo) <= 38) {
      return true;
    }
    // 高亮度、低饱和度大块（背景泛化）
    final lum = (0.299 * r + 0.587 * g + 0.114 * b);
    if (lum >= 198 && (hi - lo) <= 42) {
      return true;
    }
    return false;
  }

  final w = image.width;
  final h = image.height;

  final yStep = h > 900 ? 2 : 1;
  final xStep = w > 900 ? 2 : 1;

  final colBg = List<double>.generate(w, (x) {
    var bg = 0;
    var n = 0;
    for (var y = 0; y < h; y += yStep) {
      n++;
      final p = image.getPixel(x, y);
      if (isBg(p.r.toInt(), p.g.toInt(), p.b.toInt(), p.a.toInt())) {
        bg++;
      }
    }
    return n == 0 ? 1.0 : bg / n;
  });

  final rowBg = List<double>.generate(h, (y) {
    var bg = 0;
    var n = 0;
    for (var x = 0; x < w; x += xStep) {
      n++;
      final p = image.getPixel(x, y);
      if (isBg(p.r.toInt(), p.g.toInt(), p.b.toInt(), p.a.toInt())) {
        bg++;
      }
    }
    return n == 0 ? 1.0 : bg / n;
  });

  const edgeBgThreshold = 0.86;

  var minX = 0;
  for (var x = 0; x < w; x++) {
    if (colBg[x] < edgeBgThreshold) {
      minX = x;
      break;
    }
  }
  var maxX = w - 1;
  for (var x = w - 1; x >= 0; x--) {
    if (colBg[x] < edgeBgThreshold) {
      maxX = x;
      break;
    }
  }

  var minY = 0;
  for (var y = 0; y < h; y++) {
    if (rowBg[y] < edgeBgThreshold) {
      minY = y;
      break;
    }
  }
  var maxY = h - 1;
  for (var y = h - 1; y >= 0; y--) {
    if (rowBg[y] < edgeBgThreshold) {
      maxY = y;
      break;
    }
  }

  if (maxX < minX || maxY < minY) {
    return png;
  }

  const pad = 16;
  minX = (minX - pad).clamp(0, w - 1);
  minY = (minY - pad).clamp(0, h - 1);
  maxX = (maxX + pad).clamp(0, w - 1);
  maxY = (maxY + pad).clamp(0, h - 1);

  var cw = maxX - minX + 1;
  var ch = maxY - minY + 1;

  // 裁得过小则回退到逐像素 bbox（防止浅色衣物被列检测误判成全背景）
  if (cw < 48 || ch < 48 || cw * ch < w * h * 0.04) {
    return _trimByPixelBbox(image, png, isBg);
  }

  final cropped = img.copyCrop(image, x: minX, y: minY, width: cw, height: ch);
  return Uint8List.fromList(img.encodePng(cropped));
}

Uint8List _trimByPixelBbox(img.Image image, Uint8List png, bool Function(int r, int g, int b, int a) isBg) {
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  var any = false;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final a = p.a.toInt();
      if (!isBg(r, g, b, a)) {
        any = true;
        if (x < minX) {
          minX = x;
        }
        if (y < minY) {
          minY = y;
        }
        if (x > maxX) {
          maxX = x;
        }
        if (y > maxY) {
          maxY = y;
        }
      }
    }
  }

  if (!any || maxX < minX || maxY < minY) {
    return png;
  }

  const pad = 16;
  minX = (minX - pad).clamp(0, image.width - 1);
  minY = (minY - pad).clamp(0, image.height - 1);
  maxX = (maxX + pad).clamp(0, image.width - 1);
  maxY = (maxY + pad).clamp(0, image.height - 1);

  final cw = maxX - minX + 1;
  final ch = maxY - minY + 1;
  if (cw < 24 || ch < 24) {
    return png;
  }

  final cropped = img.copyCrop(image, x: minX, y: minY, width: cw, height: ch);
  return Uint8List.fromList(img.encodePng(cropped));
}
