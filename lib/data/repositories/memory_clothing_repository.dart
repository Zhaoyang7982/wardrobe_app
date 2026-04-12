import '../../domain/models/clothing.dart';
import '../../domain/repositories/clothing_repository.dart';

/// Web 等无 Isar 环境下的内存实现（进程内、刷新即清空）
class MemoryClothingRepository implements ClothingRepository {
  final List<Clothing> _items = [];

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
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

  @override
  Future<List<Clothing>> getAll() async => List.unmodifiable(_items);

  @override
  Future<Clothing?> getById(String id) async {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
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
    var items = List<Clothing>.from(_items);

    int orderKey(Clothing c) {
      final i = _items.indexWhere((e) => e.id == c.id);
      return i < 0 ? 0 : i;
    }

    switch (sort) {
      case WardrobeSortMode.recentAdded:
        items.sort((a, b) => orderKey(b).compareTo(orderKey(a)));
        break;
      case WardrobeSortMode.mostWorn:
        items.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case WardrobeSortMode.purchaseDate:
        items.sort((a, b) {
          final ad = a.purchaseDate;
          final bd = b.purchaseDate;
          if (ad == null && bd == null) {
            return orderKey(b).compareTo(orderKey(a));
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
      if (panelColors.isNotEmpty && !c.colors.any(panelColors.contains)) {
        return false;
      }
      if (panelSeasons.isNotEmpty && !_multiFieldMatches(c.season, panelSeasons)) {
        return false;
      }
      if (panelOccasions.isNotEmpty && !_multiFieldMatches(c.occasion, panelOccasions)) {
        return false;
      }
      if (panelStyles.isNotEmpty && !_multiFieldMatches(c.style, panelStyles)) {
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
  Future<void> save(Clothing clothing) async {
    final i = _items.indexWhere((e) => e.id == clothing.id);
    if (i >= 0) {
      _items[i] = clothing;
    } else {
      _items.add(clothing);
    }
  }

  @override
  Future<List<Clothing>> search(String keyword) async {
    final k = keyword.trim();
    if (k.isEmpty) {
      return getAll();
    }
    final lower = k.toLowerCase();
    return _items.where((c) {
      if (c.name.toLowerCase().contains(lower)) {
        return true;
      }
      if ((c.brand ?? '').toLowerCase().contains(lower)) {
        return true;
      }
      return c.tags.any((t) => t.toLowerCase().contains(lower));
    }).toList();
  }
}
