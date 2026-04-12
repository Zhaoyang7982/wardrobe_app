import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/stored_image_ref.dart';
import 'read_file_bytes.dart';

/// 将本地路径 / data URI 上传到 Storage，返回公开 URL；已是 http(s) 则原样返回
class WardrobeImageUploader {
  WardrobeImageUploader(this._client);

  final SupabaseClient _client;

  static const _bucket = 'wardrobe';

  Future<String?> uploadIfNeeded({
    required String? imageRef,
    required String clothingId,
    required String fileName,
  }) async {
    if (imageRef == null || imageRef.isEmpty) {
      return null;
    }
    if (imageRef.startsWith('http://') || imageRef.startsWith('https://')) {
      return imageRef;
    }

    Uint8List? bytes;
    var contentType = 'image/jpeg';
    if (isDataImageRef(imageRef)) {
      bytes = decodeDataImageRef(imageRef);
      if (imageRef.contains('image/png')) {
        contentType = 'image/png';
      }
    } else if (!kIsWeb) {
      final path = localFilePathFromImageRef(imageRef);
      if (path != null) {
        bytes = await readFileBytes(path);
        if (fileName.toLowerCase().endsWith('.png')) {
          contentType = 'image/png';
        }
      }
    }

    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final uid = _client.auth.currentUser!.id;
    final objectPath = '$uid/$clothingId/$fileName';

    await _client.storage.from(_bucket).uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );

    return _client.storage.from(_bucket).getPublicUrl(objectPath);
  }

  /// 搭配画布导出为 PNG 后上传，路径 `uid/outfits/{outfitId}/cover.png`
  Future<String> uploadOutfitCoverPng({
    required Uint8List bytes,
    required String outfitId,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final objectPath = '$uid/outfits/$outfitId/cover.png';
    await _client.storage.from(_bucket).uploadBinary(
      objectPath,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
    );
    return _client.storage.from(_bucket).getPublicUrl(objectPath);
  }
}
