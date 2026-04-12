import '../../domain/models/outfit.dart';
import '../../domain/repositories/outfit_repository.dart';

/// Web 等无 Isar 环境下的内存实现
class MemoryOutfitRepository implements OutfitRepository {
  final List<Outfit> _items = [];

  @override
  Future<void> delete(String id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) {
      return;
    }
    final o = _items[i];
    if (o.wornDates.isEmpty) {
      _items.removeAt(i);
      return;
    }
    _items[i] = o.copyWith(isArchived: true);
  }

  @override
  Future<void> permanentlyDelete(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Outfit>> getAll() async =>
      _items.where((e) => !e.isArchived).toList();

  @override
  Future<List<Outfit>> getAllIncludingArchived() async =>
      List.unmodifiable(_items);

  @override
  Future<Outfit?> getById(String id) async {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
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
    return _items.where((o) => o.clothingIds.contains(clothingId)).toList();
  }

  @override
  Future<void> save(Outfit outfit) async {
    final i = _items.indexWhere((e) => e.id == outfit.id);
    if (i >= 0) {
      _items[i] = outfit;
    } else {
      _items.add(outfit);
    }
  }
}
