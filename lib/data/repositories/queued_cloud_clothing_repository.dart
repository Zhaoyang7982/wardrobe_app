import '../../domain/models/clothing.dart';
import '../../domain/repositories/clothing_repository.dart';
import '../../domain/utils/wardrobe_list_filter.dart';
import '../sync/cloud_wardrobe_sync.dart';
import 'supabase_clothing_repository.dart';

/// 在 [SupabaseClothingRepository] 之上：失败时写本地缓存并入队，联网后由 [CloudWardrobeSync] 重放
class QueuedCloudClothingRepository implements ClothingRepository {
  QueuedCloudClothingRepository(this._inner, this._sync);

  final SupabaseClothingRepository _inner;
  final CloudWardrobeSync _sync;

  Future<Clothing?> _fromCache(String id) async {
    final list = await _sync.loadClothes();
    if (list == null) {
      return null;
    }
    for (final c in list) {
      if (c.id == id) {
        return c;
      }
    }
    return null;
  }

  @override
  Future<void> delete(String id) async {
    final online = await _sync.isOnline();
    if (online) {
      try {
        await _inner.delete(id);
        await _sync.removeClothingFromCache(id);
        return;
      } catch (e) {
        if (!isLikelyNetworkError(e)) {
          rethrow;
        }
      }
    }
    await _sync.removeClothingFromCache(id);
    await _sync.enqueueClothingDelete(id);
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
  Future<List<Clothing>> getAll() async {
    final online = await _sync.isOnline();
    if (online) {
      try {
        final list = await _inner.getAll();
        await _sync.saveClothes(list);
        return list;
      } catch (e) {
        if (!isLikelyNetworkError(e)) {
          rethrow;
        }
        return await _sync.loadClothes() ?? [];
      }
    }
    return await _sync.loadClothes() ?? [];
  }

  @override
  Future<Clothing?> getById(String id) async {
    final online = await _sync.isOnline();
    if (online) {
      try {
        final c = await _inner.getById(id);
        return c ?? await _fromCache(id);
      } catch (e) {
        if (!isLikelyNetworkError(e)) {
          rethrow;
        }
        return _fromCache(id);
      }
    }
    return _fromCache(id);
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
    final items = await getAll();
    return WardrobeListFilter.apply(
      items: items,
      quickCategory: quickCategory,
      keyword: keyword,
      panelCategories: panelCategories,
      panelColors: panelColors,
      panelSeasons: panelSeasons,
      panelOccasions: panelOccasions,
      panelStyles: panelStyles,
      sort: sort,
    );
  }

  @override
  Future<void> save(Clothing clothing) async {
    final online = await _sync.isOnline();
    if (online) {
      try {
        await _inner.save(clothing);
        await _sync.mergeClothing(clothing);
        return;
      } catch (e) {
        if (!isLikelyNetworkError(e)) {
          rethrow;
        }
      }
    }
    await _sync.mergeClothing(clothing);
    await _sync.enqueueClothingSave(clothing);
  }

  @override
  Future<List<Clothing>> search(String keyword) async {
    final k = keyword.trim();
    if (k.isEmpty) {
      return getAll();
    }
    final lower = k.toLowerCase();
    final all = await getAll();
    return all.where((c) {
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
