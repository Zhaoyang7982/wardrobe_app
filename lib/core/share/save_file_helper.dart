import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// 系统「另存为」对话框写入文件（Windows/macOS/Linux/Android/iOS/Web 由 file_picker 实现）
///
/// 桌面端传入 [bytes] 后由插件写入选定路径；用户取消返回 false。
Future<bool> saveBytesWithFilePicker({
  required List<int> bytes,
  required String dialogTitle,
  required String fileName,
  required List<String> allowedExtensions,
}) async {
  final u8 = Uint8List.fromList(bytes);
  final path = await FilePicker.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    bytes: u8,
    lockParentWindow: !kIsWeb,
  );
  // Web：插件通过下载触发保存，返回值恒为 null
  if (kIsWeb) {
    return true;
  }
  return path != null;
}
