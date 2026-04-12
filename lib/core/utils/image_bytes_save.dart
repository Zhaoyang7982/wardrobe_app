import 'dart:typed_data';

import 'image_bytes_save_io.dart' if (dart.library.html) 'image_bytes_save_web.dart' as impl;

/// 将 PNG 字节保存到本地目录（原生）或触发浏览器下载（Web）
Future<String?> savePngToDownloadsOrDocuments(Uint8List bytes, String fileName) =>
    impl.savePngToDownloadsOrDocuments(bytes, fileName);
