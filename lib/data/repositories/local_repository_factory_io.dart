import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/clothing_repository.dart';
import '../../domain/repositories/outfit_repository.dart';
import '../local/database_service.dart';
import 'isar_clothing_repository.dart';
import 'isar_outfit_repository.dart';

Future<ClothingRepository> createLocalClothingRepository(Ref ref) async {
  final db = await ref.watch(databaseServiceProvider.future);
  return IsarClothingRepository(db.isar);
}

Future<OutfitRepository> createLocalOutfitRepository(Ref ref) async {
  final db = await ref.watch(databaseServiceProvider.future);
  return IsarOutfitRepository(db.isar);
}
