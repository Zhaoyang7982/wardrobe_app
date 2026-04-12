import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/outfit.dart';
import '../../domain/repositories/outfit_repository.dart';

/// 云端搭配仓储（`outfits` 表；封面图 URL 存表内）
class SupabaseOutfitRepository implements OutfitRepository {
  SupabaseOutfitRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'outfits';

  String get _userId => _client.auth.currentUser!.id;

  /// 日历「某日」在领域层用本地日期的 0 点表示；云端存 UTC ISO，读回须按本地日历日还原，
  /// 否则东八区等时区下会出现保存后落在前一天、看起来像未生效。
  static DateTime _localCalendarDay(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  static List<DateTime> _dateList(dynamic v) {
    if (v == null) {
      return [];
    }
    if (v is! List) {
      return [];
    }
    final out = <DateTime>[];
    for (final e in v) {
      if (e == null) {
        continue;
      }
      final d = DateTime.tryParse(e.toString());
      if (d != null) {
        out.add(_localCalendarDay(d));
      }
    }
    return out;
  }

  static List<String> _stringList(dynamic v) {
    if (v == null) {
      return [];
    }
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return [];
  }

  static Outfit fromRow(Map<String, dynamic> j) {
    return Outfit(
      id: j['id'].toString(),
      name: j['name'] as String,
      clothingIds: _stringList(j['clothing_ids']),
      scene: j['scene'] as String?,
      occasion: j['occasion'] as String?,
      season: j['season'] as String?,
      imageUrl: j['cover_image_url'] as String?,
      wornDates: _dateList(j['worn_dates']),
      plannedDates: _dateList(j['planned_dates']),
      notes: j['notes'] as String?,
      isShared: j['is_shared'] as bool? ?? false,
      isArchived: j['is_archived'] as bool? ?? false,
    );
  }

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing == null) {
      return;
    }
    if (existing.wornDates.isEmpty) {
      await permanentlyDelete(id);
      return;
    }
    await save(existing.copyWith(isArchived: true));
  }

  @override
  Future<void> permanentlyDelete(String id) async {
    await _client.from(_table).delete().eq('id', id).eq('user_id', _userId);
  }

  @override
  Future<List<Outfit>> getAll() async {
    // 不在 PostgREST 条件里使用 is_archived：远端若尚未执行 002 迁移会缺列并报错。
    final res = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    final list = res as List<dynamic>;
    return list
        .map((e) => fromRow(Map<String, dynamic>.from(e as Map)))
        .where((o) => !o.isArchived)
        .toList();
  }

  @override
  Future<List<Outfit>> getAllIncludingArchived() async {
    final res = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    final list = res as List<dynamic>;
    return list.map((e) => fromRow(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<Outfit?> getById(String id) async {
    final res = await _client.from(_table).select().eq('id', id).eq('user_id', _userId).maybeSingle();
    if (res == null) {
      return null;
    }
    return fromRow(Map<String, dynamic>.from(res));
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

  Map<String, dynamic> _upsertRow(Outfit outfit) {
    return <String, dynamic>{
      'id': outfit.id,
      'user_id': _userId,
      'name': outfit.name,
      'clothing_ids': outfit.clothingIds,
      'scene': outfit.scene,
      'occasion': outfit.occasion,
      'season': outfit.season,
      'cover_image_url': outfit.imageUrl,
      'worn_dates': outfit.wornDates.map((e) => e.toUtc().toIso8601String()).toList(),
      'planned_dates': outfit.plannedDates.map((e) => e.toUtc().toIso8601String()).toList(),
      'notes': outfit.notes,
      'is_shared': outfit.isShared,
      'is_archived': outfit.isArchived,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  @override
  Future<void> save(Outfit outfit) async {
    await _client.from(_table).upsert(_upsertRow(outfit), onConflict: 'id');
  }
}
