import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/stored_image_ref.dart';

/// 将衣物/搭配图引用解析为 PNG/JPEG 等原始字节（用于离屏绘制）
Future<Uint8List?> loadImageRefAsBytes(String? ref) async {
  if (ref == null || ref.isEmpty) {
    return null;
  }
  final embedded = decodeDataImageRef(ref);
  if (embedded != null) {
    return embedded;
  }
  if (isNetworkImageUrl(ref)) {
    try {
      final res = await Dio().get<List<int>>(
        ref,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = res.data;
      if (data == null || data.isEmpty) {
        return null;
      }
      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }
  final path = localFilePathFromImageRef(ref);
  if (path != null && !kIsWeb) {
    try {
      return await File(path).readAsBytes();
    } catch (_) {
      return null;
    }
  }
  return null;
}
