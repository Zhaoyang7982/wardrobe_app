import 'package:isar/isar.dart';

import '../../domain/models/clothing.dart';
import '../../domain/repositories/clothing_repository.dart';
import '../local/clothing_model.dart';

/// [ClothingRepository] 的 Isar 本地实现
class IsarClothingRepository implements ClothingRepository {
  IsarClothingRepository(this._isar);

  final Isar _isar;

  @override
  Future<List<Clothing>> getAll() async {
    final list = await _isar.clothingModels.where().findAll();
    return list.map((e) => e.toDomain()).toList();
  }

  @override
  Future<Clothing?> getById(String id) async {
    final m = await _isar.clothingModels.getByClothingId(id);
    return m?.toDomain();
  }

  @override
  Future<void> save(Clothing clothing) async {
    await _isar.writeTxn(() async {
      final col = _isar.clothingModels;
      final existing = await col.getByClothingId(clothing.id);
      final model = ClothingModel.fromDomain(clothing);
      if (existing != null) {
        model.id = existing.id;
      }
      await col.put(model);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _isar.writeTxn(() async {
      await _isar.clothingModels.deleteByClothingId(id);
    });
  }

  @override
  Future<List<Clothing>> search(String keyword) async {
    final k = keyword.trim();
    if (k.isEmpty) {
      return getAll();
    }
    final lower = k.toLowerCase();
    final list = await _isar.clothingModels
        .filter()
        .group(
          (q) => q
              .nameContains(lower, caseSensitive: false)
              .or()
              .brandContains(lower, caseSensitive: false)
              .or()
              .tagsElementContains(lower, caseSensitive: false),
        )
        .findAll();
    return list.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Clothing>> listForWardrobe({
    String? quickCategory,
    String? keyword,
    Set<String> panelCategories = const {},
    Set<String> panelColors = const {},
    Set<String> panelSeasons = const {},
    Set<String> panelOccasions = const {},
    Set<String> panelStyles = const {},
    WardrobeSortMode sort = WardrobeSortMode.recentAdded,
  }) async {
    var models = await _isar.clothingModels.where().findAll();

    switch (sort) {
      case WardrobeSortMode.recentAdded:
        models.sort((a, b) => b.id.compareTo(a.id));
        break;
      case WardrobeSortMode.mostWorn:
        models.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case WardrobeSortMode.purchaseDate:
        models.sort((a, b) {
          final ad = a.purchaseDate;
          final bd = b.purchaseDate;
          if (ad == null && bd == null) {
            return b.id.compareTo(a.id);
          }
          if (ad == null) {
            return 1;
          }
          if (bd == null) {
            return -1;
          }
          return bd.compareTo(ad);
        });
        break;
    }

    var items = models.map((e) => e.toDomain()).toList();

    final kw = keyword?.trim().toLowerCase();
    if (kw != null && kw.isNotEmpty) {
      items = items.where((c) {
        if (c.name.toLowerCase().contains(kw)) {
          return true;
        }
        if ((c.brand ?? '').toLowerCase().contains(kw)) {
          return true;
        }
        return c.tags.any((t) => t.toLowerCase().contains(kw));
      }).toList();
    }

    items = items.where((c) {
      if (quickCategory != null &&
          quickCategory.isNotEmpty &&
          quickCategory != '全部' &&
          c.category != quickCategory) {
        return false;
      }
      if (panelCategories.isNotEmpty && !panelCategories.contains(c.category)) {
        return false;
      }
      if (panelColors.isNotEmpty &&
          !c.colors.any(panelColors.contains)) {
        return false;
      }
      if (panelSeasons.isNotEmpty &&
          !_multiFieldMatches(c.season, panelSeasons)) {
        return false;
      }
      if (panelOccasions.isNotEmpty &&
          !_multiFieldMatches(c.occasion, panelOccasions)) {
        return false;
      }
      if (panelStyles.isNotEmpty &&
          !_multiFieldMatches(c.style, panelStyles)) {
        return false;
      }
      return true;
    }).toList();

    return items;
  }

  static bool _multiFieldMatches(String? field, Set<String> selected) {
    if (field == null || field.isEmpty) {
      return false;
    }
    final parts = field.split('、').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    return selected.any(parts.contains);
  }

  @override
  Future<List<Clothing>> filterBy({
    String? category,
    String? color,
    String? season,
    String? occasion,
  }) async {
    final all = await getAll();
    return all.where((c) {
      if (category != null && c.category != category) {
        return false;
      }
      if (color != null && !c.colors.contains(color)) {
        return false;
      }
      if (season != null && c.season != season) {
        return false;
      }
      if (occasion != null && c.occasion != occasion) {
        return false;
      }
      return true;
    }).toList();
  }
}
