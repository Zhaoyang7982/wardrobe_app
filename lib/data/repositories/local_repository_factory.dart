import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/clothing_repository.dart';
import '../../domain/repositories/outfit_repository.dart';
import 'local_repository_factory_io.dart' if (dart.library.html) 'local_repository_factory_web.dart' as impl;

Future<ClothingRepository> createLocalClothingRepository(Ref ref) =>
    impl.createLocalClothingRepository(ref);

Future<OutfitRepository> createLocalOutfitRepository(Ref ref) =>
    impl.createLocalOutfitRepository(ref);
