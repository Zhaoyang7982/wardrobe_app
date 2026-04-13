import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/clothing.dart';
import '../../domain/models/outfit.dart';
import '../repositories/supabase_clothing_repository.dart';
import '../repositories/supabase_outfit_repository.dart';

bool isLikelyNetworkError(Object e) {
  if (e is TimeoutException) {
    return true;
  }
  if (e is AuthException) {
    return false;
  }
  final s = e.toString().toLowerCase();
  return s.contains('socket') ||
      s.contains('failed host lookup') ||
      s.contains('connection refused') ||
      s.contains('connection reset') ||
      s.contains('network') ||
      s.contains('clientexception') ||
      s.contains('timed out') ||
      s.contains('handshake');
}

/// 云端离线缓存 + 持久化写队列，恢复网络后重放
class CloudWardrobeSync {
  CloudWardrobeSync({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static const _keyQueue = 'wardrobe_sync_queue_v1';
  static const _keyClothes = 'wardrobe_cache_clothes_v1';
  static const _keyOutfits = 'wardrobe_cache_outfits_v1';

  Future<bool> isOnline() async {
    final r = await _connectivity.checkConnectivity();
    return r.any((e) => e != ConnectivityResult.none);
  }

  Future<List<Map<String, dynamic>>> _loadQueue() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_keyQueue);
      if (s == null || s.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(s);
      if (decoded is! List) {
        return [];
      }
      final out = <Map<String, dynamic>>[];
      for (final e in decoded) {
        if (e is Map) {
          out.add(Map<String, dynamic>.from(e));
        }
      }
      return out;
    } catch (e, st) {
      debugPrint('读取同步队列失败，已清空异常数据: $e\n$st');
      final p = await SharedPreferences.getInstance();
      await p.remove(_keyQueue);
      return [];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> ops) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyQueue, jsonEncode(ops));
  }

  Future<int> pendingCount() async {
    final q = await _loadQueue();
    return q.length;
  }

  Future<void> clearCacheAndQueue() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyQueue);
    await p.remove(_keyClothes);
    await p.remove(_keyOutfits);
  }

  static Map<String, dynamic> _clothingRow(Clothing c) => {
        'id': c.id,
        'name': c.name,
        'category': c.category,
        'colors': c.colors,
        'brand': c.brand,
        'size': c.size,
        'image_public_url': c.imageUrl,
        'cropped_image_public_url': c.croppedImageUrl,
        'tags': c.tags,
        'season': c.season,
        'occasion': c.occasion,
        'style': c.style,
        'purchase_date': c.purchaseDate?.toUtc().toIso8601String(),
        'purchase_price': c.purchasePrice,
        'status': c.status,
        'usage_count': c.usageCount,
        'last_worn_date': c.lastWornDate?.toUtc().toIso8601String(),
        'notes': c.notes,
      };

  static Map<String, dynamic> _outfitRow(Outfit o) => {
        'id': o.id,
        'name': o.name,
        'clothing_ids': o.clothingIds,
        'scene': o.scene,
        'occasion': o.occasion,
        'season': o.season,
        'cover_image_url': o.imageUrl,
        'worn_dates': o.wornDates.map((e) => e.toUtc().toIso8601String()).toList(),
        'planned_dates': o.plannedDates.map((e) => e.toUtc().toIso8601String()).toList(),
        'notes': o.notes,
        'is_shared': o.isShared,
        'is_archived': o.isArchived,
      };

  Future<List<Clothing>?> loadClothes() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_keyClothes);
      if (s == null || s.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(s);
      if (decoded is! List) {
        return null;
      }
      final out = <Clothing>[];
      for (final e in decoded) {
        if (e is Map) {
          out.add(
            SupabaseClothingRepository.fromRow(
              Map<String, dynamic>.from(e),
            ),
          );
        }
      }
      return out;
    } catch (e, st) {
      debugPrint('读取衣物离线缓存失败，已丢弃: $e\n$st');
      final p = await SharedPreferences.getInstance();
      await p.remove(_keyClothes);
      return null;
    }
  }

  Future<void> saveClothes(List<Clothing> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyClothes, jsonEncode(list.map(_clothingRow).toList()));
  }

  Future<void> mergeClothing(Clothing c) async {
    final existing = await loadClothes() ?? [];
    final i = existing.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      existing[i] = c;
    } else {
      existing.insert(0, c);
    }
    await saveClothes(existing);
  }

  Future<void> removeClothingFromCache(String id) async {
    final existing = await loadClothes() ?? [];
    existing.removeWhere((x) => x.id == id);
    await saveClothes(existing);
  }

  Future<List<Outfit>?> loadOutfits() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_keyOutfits);
      if (s == null || s.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(s);
      if (decoded is! List) {
        return null;
      }
      final out = <Outfit>[];
      for (final e in decoded) {
        if (e is Map) {
          out.add(
            SupabaseOutfitRepository.fromRow(
              Map<String, dynamic>.from(e),
            ),
          );
        }
      }
      return out;
    } catch (e, st) {
      debugPrint('读取搭配离线缓存失败，已丢弃: $e\n$st');
      final p = await SharedPreferences.getInstance();
      await p.remove(_keyOutfits);
      return null;
    }
  }

  Future<void> saveOutfits(List<Outfit> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyOutfits, jsonEncode(list.map(_outfitRow).toList()));
  }

  Future<void> mergeOutfit(Outfit o) async {
    final existing = await loadOutfits() ?? [];
    final i = existing.indexWhere((x) => x.id == o.id);
    if (i >= 0) {
      existing[i] = o;
    } else {
      existing.insert(0, o);
    }
    await saveOutfits(existing);
  }

  Future<void> removeOutfitFromCache(String id) async {
    final existing = await loadOutfits() ?? [];
    existing.removeWhere((x) => x.id == id);
    await saveOutfits(existing);
  }

  Future<void> enqueueClothingSave(Clothing c) async {
    final q = await _loadQueue();
    q.removeWhere((op) => op['op'] == 'clothing_delete' && op['id'] == c.id);
    q.add({'op': 'clothing_save', 'payload': _clothingRow(c)});
    await _saveQueue(q);
  }

  Future<void> enqueueClothingDelete(String id) async {
    final q = await _loadQueue();
    q.removeWhere((op) {
      if (op['op'] != 'clothing_save') {
        return false;
      }
      final p = op['payload'];
      return p is Map && p['id'] == id;
    });
    q.add({'op': 'clothing_delete', 'id': id});
    await _saveQueue(q);
  }

  Future<void> enqueueOutfitSave(Outfit o) async {
    final q = await _loadQueue();
    q.removeWhere((op) => op['op'] == 'outfit_delete' && op['id'] == o.id);
    q.add({'op': 'outfit_save', 'payload': _outfitRow(o)});
    await _saveQueue(q);
  }

  Future<void> enqueueOutfitDelete(String id) async {
    final q = await _loadQueue();
    q.removeWhere((op) {
      if (op['op'] != 'outfit_save') {
        return false;
      }
      final p = op['payload'];
      return p is Map && p['id'] == id;
    });
    q.add({'op': 'outfit_delete', 'id': id});
    await _saveQueue(q);
  }

  Future<void> flushIfOnline() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      return;
    }
    if (!await isOnline()) {
      return;
    }

    final q = await _loadQueue();
    if (q.isEmpty) {
      return;
    }

    final clothesRepo = SupabaseClothingRepository(client);
    final outfitsRepo = SupabaseOutfitRepository(client);
    final remaining = <Map<String, dynamic>>[];

    for (final op in q) {
      try {
        switch (op['op']) {
          case 'clothing_save':
            final payload = Map<String, dynamic>.from(op['payload'] as Map);
            await clothesRepo.save(SupabaseClothingRepository.fromRow(payload));
            break;
          case 'clothing_delete':
            await clothesRepo.delete(op['id'] as String);
            break;
          case 'outfit_save':
            final payload = Map<String, dynamic>.from(op['payload'] as Map);
            await outfitsRepo.save(SupabaseOutfitRepository.fromRow(payload));
            break;
          case 'outfit_delete':
            await outfitsRepo.permanentlyDelete(op['id'] as String);
            break;
          default:
            break;
        }
      } catch (e, st) {
        debugPrint('同步队列项失败，稍后重试: $op $e\n$st');
        remaining.add(op);
      }
    }

    await _saveQueue(remaining);

    try {
      await saveClothes(await clothesRepo.getAll());
    } catch (_) {}
    try {
      await saveOutfits(await outfitsRepo.getAllIncludingArchived());
    } catch (_) {}
  }
}
