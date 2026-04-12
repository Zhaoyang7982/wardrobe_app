import '../models/clothing.dart';
import '../models/outfit.dart';

/// 衣橱统计聚合结果（供统计页展示）
class WardrobeStatsSnapshot {
  const WardrobeStatsSnapshot({
    required this.totalPieces,
    required this.totalValue,
    required this.pricedPieces,
    required this.monthlyWearSessions,
    required this.categoryCounts,
    required this.top10ByWear,
    required this.neverWorn,
    required this.spendByCategory,
    required this.clothesForCostPerWear,
    required this.wearSessionsByClothingId,
  });

  /// 衣物总件数
  final int totalPieces;

  /// 有标价衣物的总价（null 价格不计入）
  final double totalValue;

  /// 有购买价格的件数
  final int pricedPieces;

  /// 本月搭配穿着记录次数（每条 outfit×日期 算一次）
  final int monthlyWearSessions;

  /// 类别 -> 件数
  final Map<String, int> categoryCounts;

  /// 按「搭配日历已穿」聚合次数降序，最多 10（仅含穿着次数 > 0）
  final List<Clothing> top10ByWear;

  /// 在任意已记录「已穿」搭配日中从未出现的衣物
  final List<Clothing> neverWorn;

  /// 有价格的衣物按类别汇总花费
  final Map<String, double> spendByCategory;

  /// 有价格且「日历已穿」聚合次数>0（用于每次穿着成本）
  final List<Clothing> clothesForCostPerWear;

  /// 每件衣物在搭配 [Outfit.wornDates] 中出现的次数（每个搭配×每个已穿日计 1 次）
  final Map<String, int> wearSessionsByClothingId;

  int outfitWearSessions(Clothing c) => wearSessionsByClothingId[c.id] ?? 0;

  static DateTime _localDateOnly(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  factory WardrobeStatsSnapshot.compute(
    List<Clothing> clothes,
    List<Outfit> outfits,
    DateTime now,
  ) {
    final categoryCounts = <String, int>{};
    for (final c in clothes) {
      categoryCounts.update(c.category, (v) => v + 1, ifAbsent: () => 1);
    }

    var totalValue = 0.0;
    var pricedPieces = 0;
    final spendByCategory = <String, double>{};
    for (final c in clothes) {
      final p = c.purchasePrice;
      if (p != null && p > 0) {
        totalValue += p;
        pricedPieces++;
        spendByCategory.update(c.category, (v) => v + p, ifAbsent: () => p);
      }
    }

    final wearById = <String, int>{};
    for (final o in outfits) {
      for (final _ in o.wornDates) {
        for (final id in o.clothingIds) {
          wearById.update(id, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    var monthlyWearSessions = 0;
    for (final o in outfits) {
      for (final wd in o.wornDates) {
        final d = _localDateOnly(wd);
        if (d.year == now.year && d.month == now.month) {
          monthlyWearSessions++;
        }
      }
    }

    final withWear = clothes.where((c) => (wearById[c.id] ?? 0) > 0).toList()
      ..sort((a, b) {
        final wa = wearById[a.id] ?? 0;
        final wb = wearById[b.id] ?? 0;
        final cmp = wb.compareTo(wa);
        if (cmp != 0) {
          return cmp;
        }
        return a.name.compareTo(b.name);
      });
    final top10 = withWear.take(10).toList();

    final neverWorn = clothes.where((c) => (wearById[c.id] ?? 0) == 0).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final costList = clothes
        .where(
          (c) =>
              c.purchasePrice != null &&
              c.purchasePrice! > 0 &&
              (wearById[c.id] ?? 0) > 0,
        )
        .toList()
      ..sort((a, b) {
        final wa = wearById[a.id] ?? 0;
        final wb = wearById[b.id] ?? 0;
        final ca = a.purchasePrice! / wa;
        final cb = b.purchasePrice! / wb;
        return cb.compareTo(ca);
      });

    return WardrobeStatsSnapshot(
      totalPieces: clothes.length,
      totalValue: totalValue,
      pricedPieces: pricedPieces,
      monthlyWearSessions: monthlyWearSessions,
      categoryCounts: categoryCounts,
      top10ByWear: top10,
      neverWorn: neverWorn,
      spendByCategory: spendByCategory,
      clothesForCostPerWear: costList,
      wearSessionsByClothingId: wearById,
    );
  }
}
