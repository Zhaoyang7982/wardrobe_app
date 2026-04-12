import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> savePngToDownloadsOrDocuments(Uint8List bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final sub = Directory(p.join(dir.path, 'outfit_snapshots'));
  if (!await sub.exists()) {
    await sub.create(recursive: true);
  }
  final file = File(p.join(sub.path, fileName));
  await file.writeAsBytes(bytes);
  return file.path;
}
