import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 衣物图存储约定：`file://`、非 Web 下的本地绝对路径、或 Web 下的 `data:image/...;base64,...`
bool isDataImageRef(String ref) => ref.startsWith('data:image');

Uint8List? decodeDataImageRef(String ref) {
  if (!isDataImageRef(ref)) {
    return null;
  }
  final i = ref.indexOf(',');
  if (i < 0 || i >= ref.length - 1) {
    return null;
  }
  try {
    return Uint8List.fromList(base64Decode(ref.substring(i + 1)));
  } catch (_) {
    return null;
  }
}

bool isNetworkImageUrl(String u) => u.startsWith('http://') || u.startsWith('https://');

/// 非 data、非 http(s)、非 file 的字符串在非 Web 下视为本地绝对路径
String? localFilePathFromImageRef(String? u) {
  if (u == null || u.isEmpty) {
    return null;
  }
  if (isDataImageRef(u) || isNetworkImageUrl(u)) {
    return null;
  }
  if (u.startsWith('file://')) {
    return Uri.parse(u).toFilePath();
  }
  if (kIsWeb) {
    return null;
  }
  return u;
}

/// 从衣物保存的 URL 字段构建图片组件（Web 为内存图，原生为文件）
///
/// [imageAlignment]：搭配封面等「内容在画布左上」的图建议用 [Alignment.topLeft]，避免 [BoxFit.cover] 裁到中间大片留白。
Widget imageFromClothingRef(
  String? url, {
  required BoxFit fit,
  required Widget placeholder,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  Color? backgroundColor,
  Alignment imageAlignment = Alignment.center,
}) {
  if (url == null || url.isEmpty) {
    return placeholder;
  }
  final bytes = decodeDataImageRef(url);
  if (bytes != null) {
    Widget img = Image.memory(
      bytes,
      fit: fit,
      alignment: imageAlignment,
      errorBuilder: errorBuilder,
    );
    if (backgroundColor != null) {
      img = ColoredBox(color: backgroundColor, child: img);
    }
    return img;
  }
  if (isNetworkImageUrl(url)) {
    Widget img = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      alignment: imageAlignment,
      placeholder: (context, _) => placeholder,
      errorWidget: (context, urlStr, error) {
        final eb = errorBuilder;
        if (eb != null) {
          return eb(context, error, null);
        }
        return placeholder;
      },
    );
    if (backgroundColor != null) {
      img = ColoredBox(color: backgroundColor, child: img);
    }
    return img;
  }
  final path = localFilePathFromImageRef(url);
  if (path != null) {
    return Image.file(
      File(path),
      fit: fit,
      alignment: imageAlignment,
      errorBuilder: errorBuilder,
    );
  }
  return placeholder;
}
