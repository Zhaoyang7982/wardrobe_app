import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/clothing.dart';
import '../../domain/repositories/clothing_repository.dart';
import '../../domain/utils/wardrobe_list_filter.dart';
import '../supabase/wardrobe_image_upload.dart';

/// 云端衣物仓储（Storage + `clothes` 表）
class SupabaseClothingRepository implements ClothingRepository {
  SupabaseClothingRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'clothes';

  String get _userId => _client.auth.currentUser!.id;

  static List<String> _stringList(dynamic v) {
    if (v == null) {
      return [];
    }
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return [];
  }

  static DateTime? _parseDt(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is String) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  static Clothing fromRow(Map<String, dynamic> j) {
    return Clothing(
      id: j['id'].toString(),
      name: j['name'] as String,
      category: j['category'] as String,
      colors: _stringList(j['colors']),
      brand: j['brand'] as String?,
      size: j['size'] as String?,
      imageUrl: j['image_public_url'] as String?,
      croppedImageUrl: j['cropped_image_public_url'] as String?,
      tags: _stringList(j['tags']),
      season: j['season'] as String?,
      occasion: j['occasion'] as String?,
      style: j['style'] as String?,
      purchaseDate: _parseDt(j['purchase_date']),
      purchasePrice: (j['purchase_price'] as num?)?.toDouble(),
      status: j['status'] as String? ?? '在穿',
      usageCount: (j['usage_count'] as num?)?.toInt() ?? 0,
      lastWornDate: _parseDt(j['last_worn_date']),
      notes: j['notes'] as String?,
    );
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id).eq('user_id', _userId);
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
    final res = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    final list = res as List<dynamic>;
    return list.map((e) => fromRow(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<Clothing?> getById(String id) async {
    final res = await _client.from(_table).select().eq('id', id).eq('user_id', _userId).maybeSingle();
    if (res == null) {
      return null;
    }
    return fromRow(Map<String, dynamic>.from(res));
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
    final uploader = WardrobeImageUploader(_client);
    final imageUrl = await uploader.uploadIfNeeded(
      imageRef: clothing.imageUrl,
      clothingId: clothing.id,
      fileName: 'original.jpg',
    );
    final croppedUrl = await uploader.uploadIfNeeded(
      imageRef: clothing.croppedImageUrl,
      clothingId: clothing.id,
      fileName: 'cropped.png',
    );

    final row = <String, dynamic>{
      'id': clothing.id,
      'user_id': _userId,
      'name': clothing.name,
      'category': clothing.category,
      'colors': clothing.colors,
      'brand': clothing.brand,
      'size': clothing.size,
      'image_public_url': imageUrl,
      'cropped_image_public_url': croppedUrl,
      'tags': clothing.tags,
      'season': clothing.season,
      'occasion': clothing.occasion,
      'style': clothing.style,
      'purchase_date': clothing.purchaseDate?.toUtc().toIso8601String(),
      'purchase_price': clothing.purchasePrice,
      'status': clothing.status,
      'usage_count': clothing.usageCount,
      'last_worn_date': clothing.lastWornDate?.toUtc().toIso8601String(),
      'notes': clothing.notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _client.from(_table).upsert(row, onConflict: 'id');
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
