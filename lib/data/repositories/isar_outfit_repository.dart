import 'package:isar/isar.dart';

import '../../domain/models/outfit.dart';
import '../../domain/repositories/outfit_repository.dart';
import '../local/outfit_model.dart';

/// [OutfitRepository] 的 Isar 本地实现
class IsarOutfitRepository implements OutfitRepository {
  IsarOutfitRepository(this._isar);

  final Isar _isar;

  @override
  Future<List<Outfit>> getAll() async {
    final list =
        await _isar.outfitModels.filter().isArchivedEqualTo(false).findAll();
    return list.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Outfit>> getAllIncludingArchived() async {
    final list = await _isar.outfitModels.where().findAll();
    return list.map((e) => e.toDomain()).toList();
  }

  @override
  Future<Outfit?> getById(String id) async {
    final m = await _isar.outfitModels.getByOutfitId(id);
    return m?.toDomain();
  }

  @override
  Future<void> save(Outfit outfit) async {
    await _isar.writeTxn(() async {
      final col = _isar.outfitModels;
      final existing = await col.getByOutfitId(outfit.id);
      final model = OutfitModel.fromDomain(outfit);
      if (existing != null) {
        model.id = existing.id;
      }
      await col.put(model);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _isar.writeTxn(() async {
      final m = await _isar.outfitModels.getByOutfitId(id);
      if (m == null) {
        return;
      }
      final d = m.toDomain();
      if (d.wornDates.isEmpty) {
        await _isar.outfitModels.deleteByOutfitId(id);
        return;
      }
      m.isArchived = true;
      await _isar.outfitModels.put(m);
    });
  }

  @override
  Future<void> permanentlyDelete(String id) async {
    await _isar.writeTxn(() async {
      await _isar.outfitModels.deleteByOutfitId(id);
    });
  }

  @override
  Future<List<Outfit>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final list = await _isar.outfitModels
        .filter()
        .group(
          (q) => q
              .wornDatesElementBetween(
                start,
                end,
                includeLower: true,
                includeUpper: false,
              )
              .or()
              .plannedDatesElementBetween(
                start,
                end,
                includeLower: true,
                includeUpper: false,
              ),
        )
        .findAll();

    return list.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Outfit>> listContainingClothing(String clothingId) async {
    final list = await _isar.outfitModels
        .filter()
        .clothingIdsElementEqualTo(clothingId)
        .findAll();
    return list.map((e) => e.toDomain()).toList();
  }
}
