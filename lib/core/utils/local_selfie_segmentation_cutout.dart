import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'image_service.dart';

/// MediaPipe Image Segmenter 同款 selfie 模型（人物前景），免费会员端上抠图用。
///
/// 能力边界：针对「画面里能形成人物前景」的自拍 / 半身 / 镜前上身更稳；抠出的是**人物区域**而非服装语义，
/// 人穿着衣服时通常连同衣物外轮廓一起保留。纯衣物平铺、无人入镜时易失败，应引导用户换角度或升 VIP。
class LocalSelfieSegmentationCutout {
  LocalSelfieSegmentationCutout._();

  static const _assetPath = 'assets/models/selfie_segmenter.tflite';

  static Interpreter? _interpreter;

  /// 返回带透明底的 PNG 字节；失败抛出 [ImageServiceException]
  static Future<Uint8List> matteFromImageBytes(Uint8List imageBytes) async {
    if (kIsWeb) {
      throw ImageServiceException(
        '网页版不支持端上 TFLite 抠图',
        shouldRetry: false,
      );
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ImageServiceException('无法解码图片', shouldRetry: false);
    }

    final interpreter = _interpreter ??= await Interpreter.fromAsset(
      _assetPath,
      options: InterpreterOptions()..threads = 2,
    );
    interpreter.allocateTensors();

    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    final inShape = inputTensor.shape;
    if (inShape.length != 4 || inShape[3] != 3) {
      throw ImageServiceException('本地模型输入形状不符合预期', shouldRetry: false);
    }
    final inH = inShape[1];
    final inW = inShape[2];

    final resized = img.copyResize(
      decoded,
      width: inW,
      height: inH,
      interpolation: img.Interpolation.linear,
    );

    _fillInputNhwcRgb01(inputTensor, resized, inH, inW);

    interpreter.invoke();

    final mask256 = _parseForegroundMask(outputTensor, inH, inW);
    final meanProb = mask256.reduce((a, b) => a + b) / mask256.length;
    if (meanProb < 0.04) {
      throw ImageServiceException(
        '本地模型未识别到明显的人物前景（俯拍衣物或远景时常见）。请「跳过抠图」或升级 VIP 使用云端抠图。',
        shouldRetry: false,
      );
    }

    final maskFull = _resizeMaskBilinear(
      mask256,
      inW,
      inH,
      decoded.width,
      decoded.height,
    );

    final out = img.Image(width: decoded.width, height: decoded.height);
    for (var y = 0; y < decoded.height; y++) {
      for (var x = 0; x < decoded.width; x++) {
        final src = decoded.getPixel(x, y);
        final a = (maskFull[y * decoded.width + x] * 255).round().clamp(0, 255);
        out.setPixelRgba(x, y, src.r.toInt(), src.g.toInt(), src.b.toInt(), a);
      }
    }

    return Uint8List.fromList(img.encodePng(out));
  }

  static void _fillInputNhwcRgb01(
    Tensor inputTensor,
    img.Image resized,
    int inH,
    int inW,
  ) {
    final bytes = inputTensor.data;
    final floats = bytes.buffer.asFloat32List(
      bytes.offsetInBytes ~/ 4,
      bytes.lengthInBytes ~/ 4,
    );
    var i = 0;
    for (var y = 0; y < inH; y++) {
      for (var x = 0; x < inW; x++) {
        final p = resized.getPixel(x, y);
        floats[i++] = p.r / 255.0;
        floats[i++] = p.g / 255.0;
        floats[i++] = p.b / 255.0;
      }
    }
  }

  /// 与模型输入同尺寸的每像素前景概率 [0,1]
  static Float32List _parseForegroundMask(
    Tensor outputTensor,
    int inH,
    int inW,
  ) {
    final shape = outputTensor.shape;
    final type = outputTensor.type;
    final raw = outputTensor.data;
    final n = inH * inW;
    final out = Float32List(n);

    if (shape.length == 4 && shape[3] == 2) {
      final floats = _asFloat32List(raw, type);
      for (var i = 0; i < n; i++) {
        final a = floats[i * 2];
        final b = floats[i * 2 + 1];
        final m = a > b ? a : b;
        final ea = math.exp(a - m);
        final eb = math.exp(b - m);
        out[i] = eb / (ea + eb);
      }
      return out;
    }

    if (shape.length == 4 && shape[3] == 1) {
      final floats = _asFloat32List(raw, type);
      for (var i = 0; i < n; i++) {
        final v = floats[i];
        out[i] = 1 / (1 + math.exp(-v));
      }
      return out;
    }

    throw ImageServiceException(
      '本地模型输出形状不符合预期：$shape',
      shouldRetry: false,
    );
  }

  static Float32List _asFloat32List(Uint8List raw, TensorType type) {
    if (type == TensorType.float32) {
      return raw.buffer.asFloat32List(
        raw.offsetInBytes ~/ 4,
        raw.lengthInBytes ~/ 4,
      );
    }
    if (type == TensorType.float16) {
      final u16 = raw.buffer.asUint16List(
        raw.offsetInBytes ~/ 2,
        raw.lengthInBytes ~/ 2,
      );
      final f32 = Float32List(u16.length);
      for (var i = 0; i < u16.length; i++) {
        f32[i] = _float16ToDouble(u16[i]);
      }
      return f32;
    }
    throw ImageServiceException(
      '不支持的输出类型：$type',
      shouldRetry: false,
    );
  }

  static double _float16ToDouble(int bits) {
    final h = bits & 0xffff;
    final sign = (h >> 15) & 0x1;
    var exponent = (h >> 10) & 0x1f;
    var mantissa = h & 0x3ff;
    if (exponent == 0) {
      if (mantissa == 0) {
        return sign != 0 ? -0.0 : 0.0;
      }
      return math.pow(2.0, -14).toDouble() *
          (mantissa / 1024) *
          (sign != 0 ? -1 : 1);
    }
    if (exponent == 31) {
      if (mantissa != 0) {
        return double.nan;
      }
      return sign != 0 ? double.negativeInfinity : double.infinity;
    }
    return math.pow(2.0, exponent - 15).toDouble() *
        (1 + mantissa / 1024) *
        (sign != 0 ? -1 : 1);
  }

  static Float32List _resizeMaskBilinear(
    Float32List src,
    int sw,
    int sh,
    int dw,
    int dh,
  ) {
    final dst = Float32List(dw * dh);
    for (var y = 0; y < dh; y++) {
      final sy = (y + 0.5) * sh / dh - 0.5;
      final y0 = sy.floor().clamp(0, sh - 1);
      final y1 = (y0 + 1).clamp(0, sh - 1);
      final wy = sy - y0;
      for (var x = 0; x < dw; x++) {
        final sx = (x + 0.5) * sw / dw - 0.5;
        final x0 = sx.floor().clamp(0, sw - 1);
        final x1 = (x0 + 1).clamp(0, sw - 1);
        final wx = sx - x0;
        final v00 = src[y0 * sw + x0];
        final v10 = src[y0 * sw + x1];
        final v01 = src[y1 * sw + x0];
        final v11 = src[y1 * sw + x1];
        final top = v00 * (1 - wx) + v10 * wx;
        final bot = v01 * (1 - wx) + v11 * wx;
        dst[y * dw + x] = (top * (1 - wy) + bot * wy)
            .clamp(0.0, 1.0)
            .toDouble();
      }
    }
    return dst;
  }
}
