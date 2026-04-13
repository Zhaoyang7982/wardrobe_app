import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'local_selfie_segmentation_cutout.dart';

/// remove.bg 成功后的引用：原生为 `file://`，Web 为 `data:image/...;base64,...`
class RemoveBgUrls {
  RemoveBgUrls({
    required this.originalImageUrl,
    required this.cutoutImageUrl,
  });

  final String originalImageUrl;
  final String cutoutImageUrl;
}

class ImageServiceException implements Exception {
  ImageServiceException(
    this.message, {
    this.shouldRetry = false,
    this.isQuotaExceeded = false,
  });

  final String message;
  final bool shouldRetry;
  final bool isQuotaExceeded;

  @override
  String toString() => message;
}

/// 选图、压缩、remove.bg 抠图（Web 无本地文件系统，使用字节与 data URI）
class ImageService {
  ImageService({
    ImagePicker? picker,
    Dio? dio,
  })  : _picker = picker ?? ImagePicker(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 90),
                sendTimeout: const Duration(seconds: 90),
              ),
            );

  static const int _maxUploadBytes = 1024 * 1024;
  static const String _removeBgUrl = 'https://api.remove.bg/v1.0/removebg';

  final ImagePicker _picker;
  final Dio _dio;

  Future<XFile?> pickFromCamera() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
  }

  Future<XFile?> pickFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
  }

  /// 将图片压缩到不超过 [maxBytes]，返回 JPEG 字节（Web / 原生通用）
  Future<Uint8List> compressToUnder1MbBytes(
    Uint8List sourceBytes, {
    int maxBytes = _maxUploadBytes,
  }) async {
    var bytes = sourceBytes;
    if (bytes.length <= maxBytes) {
      return bytes;
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw ImageServiceException('无法识别图片格式，请换一张图片');
    }
    img.Image image = decoded;

    const maxDim = 2048;
    if (image.width > maxDim || image.height > maxDim) {
      if (image.width >= image.height) {
        image = img.copyResize(image, width: maxDim);
      } else {
        image = img.copyResize(image, height: maxDim);
      }
    }

    for (var round = 0; round < 12; round++) {
      final quality = (92 - round * 7).clamp(15, 92);
      final jpg = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      if (jpg.length <= maxBytes) {
        return jpg;
      }
      if (image.width > 480 && image.height > 480) {
        final nw = (image.width * 0.88).round();
        final nh = (image.height * 0.88).round();
        image = img.copyResize(image, width: nw, height: nh);
      }
    }

    throw ImageServiceException('无法在合理画质内将图片压缩到 1MB 以内，请换一张较小的图片');
  }

  /// 原生：压缩后写入临时文件并返回 [File]（Web 不可用）
  Future<File> compressToUnder1Mb(
    File source, {
    int maxBytes = _maxUploadBytes,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('compressToUnder1Mb(File) 不支持 Web');
    }
    final sourceBytes = await source.readAsBytes();
    if (sourceBytes.length <= maxBytes) {
      return source;
    }
    final out = await compressToUnder1MbBytes(sourceBytes, maxBytes: maxBytes);
    return _writeTempFile(out, '.jpg');
  }

  /// 压缩图持久化：Web 返回 `data:image/jpeg;base64,...`，原生返回绝对路径（无 scheme）
  Future<String> persistCompressedOriginal(Uint8List jpegBytes) async {
    if (kIsWeb) {
      return 'data:image/jpeg;base64,${base64Encode(jpegBytes)}';
    }
    final f = await _writeTempFile(jpegBytes, '.jpg');
    return f.path;
  }

  /// 调用 remove.bg：[imageBytes] 为待上传 JPEG/PNG 等；[originalStorageRef] 写入返回结果的原图字段
  /// [useVipCloudRemoveBg] 为 true 时走 remove.bg；为 false 时走端上 TFLite（仅 iOS/Android）
  Future<RemoveBgUrls> removeBackgroundAdaptive(
    Uint8List imageBytes, {
    required String originalStorageRef,
    required bool useVipCloudRemoveBg,
    String filename = 'upload.jpg',
  }) async {
    if (useVipCloudRemoveBg) {
      return removeBackgroundBytes(
        imageBytes,
        originalStorageRef: originalStorageRef,
        filename: filename,
      );
    }
    if (kIsWeb) {
      throw ImageServiceException(
        '免费会员在网页版无法使用本地抠图。请「跳过抠图」，或升级 VIP 使用云端抠图。',
        shouldRetry: false,
      );
    }
    try {
      final png =
          await LocalSelfieSegmentationCutout.matteFromImageBytes(imageBytes);
      final cutoutRef = Uri.file(
        (await _writeTempFile(png, '.png')).absolute.path,
      ).toString();
      return RemoveBgUrls(
        originalImageUrl: originalStorageRef,
        cutoutImageUrl: cutoutRef,
      );
    } on ImageServiceException {
      rethrow;
    } catch (e) {
      throw ImageServiceException('本地抠图失败：$e', shouldRetry: true);
    }
  }

  Future<RemoveBgUrls> removeBackgroundBytes(
    Uint8List imageBytes, {
    required String originalStorageRef,
    String filename = 'upload.jpg',
  }) async {
    final apiKey = _readRemoveBgApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw ImageServiceException(
        '未配置 REMOVE_BG_API_KEY：请复制 assets/env/app.env.example 为 assets/env/app.env 并填写密钥，'
        '或运行 flutter run --dart-define=REMOVE_BG_API_KEY=你的密钥（密钥见 remove.bg 控制台）',
      );
    }

    try {
      final resp = await _dio.post<List<int>>(
        _removeBgUrl,
        data: FormData.fromMap({
          'size': 'auto',
          'image_file': MultipartFile.fromBytes(
            imageBytes,
            filename: filename,
          ),
        }),
        options: Options(
          headers: {'X-Api-Key': apiKey},
          responseType: ResponseType.bytes,
          validateStatus: (s) => s != null && s < 600,
        ),
      );

      final code = resp.statusCode ?? 0;
      final body = resp.data ?? <int>[];

      if (code == 200 && body.isNotEmpty) {
        final png = Uint8List.fromList(body);
        final cutoutRef = kIsWeb
            ? 'data:image/png;base64,${base64Encode(png)}'
            : Uri.file((await _writeTempFile(png, '.png')).absolute.path).toString();
        return RemoveBgUrls(
          originalImageUrl: originalStorageRef,
          cutoutImageUrl: cutoutRef,
        );
      }

      if (code == 402 || code == 403) {
        throw ImageServiceException(
          '今日次数已用完，可手动跳过抠图',
          isQuotaExceeded: true,
        );
      }

      if (code == 429) {
        throw ImageServiceException(
          '请求过于频繁或额度不足，请稍后再试，也可手动跳过抠图',
          isQuotaExceeded: true,
          shouldRetry: true,
        );
      }

      final msg = _parseRemoveBgErrorMessage(body);
      throw ImageServiceException(
        msg ?? '抠图服务返回错误（HTTP $code）',
        shouldRetry: code >= 500,
      );
    } on ImageServiceException {
      rethrow;
    } on DioException catch (e) {
      final retry = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;
      throw ImageServiceException(
        '网络异常，请检查网络后重试',
        shouldRetry: retry,
      );
    } catch (e) {
      throw ImageServiceException('抠图失败：$e', shouldRetry: true);
    }
  }

  Future<RemoveBgUrls> removeBackground(File imageFile) async {
    final originalUri = Uri.file(imageFile.absolute.path).toString();
    return removeBackgroundBytes(
      await imageFile.readAsBytes(),
      originalStorageRef: originalUri,
      filename: p.basename(imageFile.path),
    );
  }

  String? _readRemoveBgApiKey() {
    const fromDefine = String.fromEnvironment(
      'REMOVE_BG_API_KEY',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) {
      return fromDefine.trim();
    }
    final v = dotenv.env['REMOVE_BG_API_KEY']?.trim();
    if (v != null && v.isNotEmpty) {
      return v;
    }
    return null;
  }

  String? _parseRemoveBgErrorMessage(List<int> raw) {
    if (raw.isEmpty) {
      return null;
    }
    try {
      final text = utf8.decode(raw);
      final map = jsonDecode(text);
      if (map is Map && map['errors'] is List) {
        final errs = map['errors'] as List;
        if (errs.isNotEmpty && errs.first is Map) {
          final title = (errs.first as Map)['title'] as String?;
          if (title != null && title.isNotEmpty) {
            return title;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<File> _writeTempFile(Uint8List bytes, String ext) async {
    if (kIsWeb) {
      throw UnsupportedError('_writeTempFile 不应在 Web 调用');
    }
    final dir = await getTemporaryDirectory();
    final name = 'wardrobe_${DateTime.now().millisecondsSinceEpoch}$ext';
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
