/// 衣物领域实体（与数据源无关）
class Clothing {
  const Clothing({
    required this.id,
    required this.name,
    required this.category,
    required this.colors,
    this.brand,
    this.size,
    this.imageUrl,
    this.croppedImageUrl,
    required this.tags,
    this.season,
    this.occasion,
    this.style,
    this.purchaseDate,
    this.purchasePrice,
    required this.status,
    required this.usageCount,
    this.lastWornDate,
    this.notes,
  });

  final String id;
  final String name;
  final String category;
  final List<String> colors;
  final String? brand;
  final String? size;
  final String? imageUrl;
  final String? croppedImageUrl;
  final List<String> tags;
  final String? season;
  final String? occasion;
  final String? style;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String status;
  final int usageCount;
  final DateTime? lastWornDate;
  final String? notes;
}
