import '../../domain/models/outfit.dart';
import '../../domain/repositories/outfit_repository.dart';
import '../sync/cloud_wardrobe_sync.dart';
import 'supabase_outfit_repository.dart';

/// 在 [SupabaseOutfitRepository] 之上：离线缓存与写队列
class QueuedCloudOutfitRepository implements OutfitRepository {
  QueuedCloudOutfitRepository(this._inner, this._sync);

  final SupabaseOutfitRepository _inner;
  final CloudWardrobeSync _sync;

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing == null) {
      await _sync.removeOutfitFromCache(id);
      return;
    }
    if (existing.wornDates.isEmpty) {
      await _sync.removeOutfitFromCache(id);
      final online = await _sync.isOnline();
      if (online) {
        try {
          await _inner.permanentlyDelete(id);
          return;
        } catch (e) {
          if (!isLikelyNetworkError(e)) {
            rethrow;
          }
        }
      }
      await _sync.enqueueOutfitDelete(id);
      return;
    }
    final archived = existing.copyWith(isArchived: true);
    await _sync.mergeOutfit(archived);
    final online = await _sync.isOnline();
    if (online) {
      try {
        await _inner.save(archived);
        return;
      } catch (e) {
        if (!isLikelyNetworkError(e)) {
          rethrow;
        }
      }
    }
    await _sync.enqueueOutfitSave(archived);
  }

  @override
  Future<void> permanentlyDelete(String id) async {
    await _sync.removeOutfitFromCache(id);
    final online = await _sync.isOnline();
    if (online) {
      try {
        await _inner.permanentlyDelete(id);
        return;
      } catch (e) {
        if (!isLikelyNetworkError(e)) {
          rethrow;
        }
      }
    }
    await _sync.enqueueOutfitDelete(id);
  }

  @override
  Future<List<Outfit>> getAll() async {
    final online = await _sync.isOnline();
    if (online) {
      try {
        final active = await _inner.getAll();
        final full = await _inner.getAllIncludingArchived();
        await _sync.saveOutfits(full);
        return active;
      } catch (e) {
        if (!isLikelyNetworkError(e)) {
          rethrow;
        }
        final cached = await _sync.loadOutfits() ?? [];
        return cached.where((o) => !o.isArchived).toList();
      }
    }
    final cached = await _sync.loadOutfits() ?? [];
    return cached.where((o) => !o.isArchived).toList();
  }

  @override
  Future<List<Outfit>> getAllIncludingArchived() async {
    final online = await _sync.isOnline();
    if (online) {
      try {
        final list = await _inner.getAllIncludingArchived();
        await _sync.saveOutfits(list);
        return list;
      } catch (e) {
        if (!isLikelyNetworkError(e)) {
          rethrow;
        }
        return await _sync.loadOutfits() ?? [];
      }
    }
    return await _sync.loadOutfits() ?? [];
  }

  @override
  Future<Outfit?> getById(String id) async {
    final online = await _sync.isOnline();
    if (online) {
      try {
        final o = await _inner.getById(id);
        if (o != null) {
          return o;
        }
        return _fromCache(id);
      } catch (e) {
        if (!isLikelyNetworkError(e)) {
          rethrow;
        }
        return _fromCache(id);
      }
    }
    return _fromCache(id);
  }

  Future<Outfit?> _fromCache(String id) async {
    final list = await _sync.loadOutfits();
    if (list == null) {
      return null;
    }
    for (final o in list) {
      if (o.id == id) {
        return o;
      }
    }
    return null;
  }

  @override
  Future<List<Outfit>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final all = await getAllIncludingArchived();
    return all.where((o) {
      final inWorn = o.wornDates.any((d) => !d.isBefore(start) && d.isBefore(end));
      final inPlanned = o.plannedDates.any((d) => !d.isBefore(start) && d.isBefore(end));
      return inWorn || inPlanned;
    }).toList();
  }

  @override
  Future<List<Outfit>> listContainingClothing(String clothingId) async {
    final all = await getAllIncludingArchived();
    return all.where((o) => o.clothingIds.contains(clothingId)).toList();
  }

  @override
  Future<void> save(Outfit outfit) async {
    final online = await _sync.isOnline();
    if (online) {
      try {
        await _inner.save(outfit);
        await _sync.mergeOutfit(outfit);
        return;
      } catch (e) {
        if (!isLikelyNetworkError(e)) {
          rethrow;
        }
      }
    }
    await _sync.mergeOutfit(outfit);
    await _sync.enqueueOutfitSave(outfit);
  }
}
