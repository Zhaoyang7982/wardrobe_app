import 'dart:typed_data';

import 'read_file_bytes_io.dart' if (dart.library.html) 'read_file_bytes_stub.dart' as impl;

Future<Uint8List?> readFileBytes(String path) => impl.readFileBytes(path);
