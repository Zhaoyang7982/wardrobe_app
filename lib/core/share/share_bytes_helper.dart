import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 将字节通过系统分享面板分享（移动端/桌面写临时文件；Web 使用内存文件）
Future<void> shareFileBytes({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {
  final safeName = fileName.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
  if (kIsWeb) {
    final xf = XFile.fromData(
      Uint8List.fromList(bytes),
      name: safeName,
      mimeType: mimeType,
    );
    await SharePlus.instance.share(ShareParams(files: [xf]));
    return;
  }

  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$safeName';
  await File(path).writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: mimeType, name: safeName)],
    ),
  );
}
