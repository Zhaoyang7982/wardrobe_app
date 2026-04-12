import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/clothing_repository.dart';
import '../../domain/repositories/outfit_repository.dart';
import 'memory_clothing_repository.dart';
import 'memory_outfit_repository.dart';

Future<ClothingRepository> createLocalClothingRepository(Ref ref) async {
  return MemoryClothingRepository();
}

Future<OutfitRepository> createLocalOutfitRepository(Ref ref) async {
  return MemoryOutfitRepository();
}
