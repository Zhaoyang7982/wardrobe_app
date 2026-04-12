import '../models/clothing.dart';
import '../repositories/clothing_repository.dart';

/// 衣橱列表：排序、关键词与筛选面板（与 Isar / Supabase 行为一致）
class WardrobeListFilter {
  WardrobeListFilter._();

  static List<Clothing> apply({
    required List<Clothing> items,
    String? quickCategory,
    String? keyword,
    Set<String> panelCategories = const {},
    Set<String> panelColors = const {},
    Set<String> panelSeasons = const {},
    Set<String> panelOccasions = const {},
    Set<String> panelStyles = const {},
    WardrobeSortMode sort = WardrobeSortMode.recentAdded,
  }) {
    var result = List<Clothing>.from(items);

    switch (sort) {
      case WardrobeSortMode.recentAdded:
        break;
      case WardrobeSortMode.mostWorn:
        result.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case WardrobeSortMode.purchaseDate:
        result.sort((a, b) {
          final ad = a.purchaseDate;
          final bd = b.purchaseDate;
          if (ad == null && bd == null) {
            return 0;
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
      result = result.where((c) {
        if (c.name.toLowerCase().contains(kw)) {
          return true;
        }
        if ((c.brand ?? '').toLowerCase().contains(kw)) {
          return true;
        }
        return c.tags.any((t) => t.toLowerCase().contains(kw));
      }).toList();
    }

    result = result.where((c) {
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
      if (panelSeasons.isNotEmpty && !multiFieldMatches(c.season, panelSeasons)) {
        return false;
      }
      if (panelOccasions.isNotEmpty && !multiFieldMatches(c.occasion, panelOccasions)) {
        return false;
      }
      if (panelStyles.isNotEmpty && !multiFieldMatches(c.style, panelStyles)) {
        return false;
      }
      return true;
    }).toList();

    return result;
  }

  static bool multiFieldMatches(String? field, Set<String> selected) {
    if (field == null || field.isEmpty) {
      return false;
    }
    final parts = field.split('、').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    return selected.any(parts.contains);
  }
}
