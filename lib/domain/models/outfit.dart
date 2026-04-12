/// 搭配领域实体
class Outfit {
  const Outfit({
    required this.id,
    required this.name,
    required this.clothingIds,
    this.scene,
    this.occasion,
    this.season,
    this.imageUrl,
    required this.wornDates,
    required this.plannedDates,
    this.notes,
    required this.isShared,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final List<String> clothingIds;
  final String? scene;
  final String? occasion;
  final String? season;
  final String? imageUrl;
  final List<DateTime> wornDates;
  final List<DateTime> plannedDates;
  final String? notes;
  final bool isShared;

  /// 为 true 时不在「搭配」列表展示，但仍保留数据（日历已穿/计划、详情仍可打开）。
  final bool isArchived;

  Outfit copyWith({
    String? id,
    String? name,
    List<String>? clothingIds,
    String? scene,
    String? occasion,
    String? season,
    String? imageUrl,
    List<DateTime>? wornDates,
    List<DateTime>? plannedDates,
    String? notes,
    bool? isShared,
    bool? isArchived,
  }) {
    return Outfit(
      id: id ?? this.id,
      name: name ?? this.name,
      clothingIds: clothingIds ?? List<String>.from(this.clothingIds),
      scene: scene ?? this.scene,
      occasion: occasion ?? this.occasion,
      season: season ?? this.season,
      imageUrl: imageUrl ?? this.imageUrl,
      wornDates: wornDates ?? List<DateTime>.from(this.wornDates),
      plannedDates: plannedDates ?? List<DateTime>.from(this.plannedDates),
      notes: notes ?? this.notes,
      isShared: isShared ?? this.isShared,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
