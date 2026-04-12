import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'clothing_model.dart';
import 'outfit_model.dart';
import 'user_profile_model.dart';

/// 封装 Isar 实例，便于注入与测试
class DatabaseService {
  DatabaseService._(this._isar);

  final Isar _isar;

  /// 当前打开的 Isar 单例
  Isar get isar => _isar;

  /// 打开（或复用）本地数据库
  static Future<DatabaseService> open() async {
    if (kIsWeb) {
      throw UnsupportedError('当前 Isar 配置仅支持非 Web 平台；Web 请使用其它存储方案。');
    }
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        ClothingModelSchema,
        OutfitModelSchema,
        UserProfileModelSchema,
      ],
      directory: dir.path,
      inspector: kDebugMode,
    );
    return DatabaseService._(isar);
  }

  Future<void> close() => _isar.close();
}

/// 应用级数据库服务（长生命周期，避免重复 open）
final databaseServiceProvider = FutureProvider<DatabaseService>((ref) async {
  ref.keepAlive();
  final service = await DatabaseService.open();
  ref.onDispose(service.close);
  return service;
});
