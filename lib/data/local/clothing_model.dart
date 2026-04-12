import 'package:isar/isar.dart';

import '../../domain/models/clothing.dart';

part 'clothing_model.g.dart';

/// Isar 衣物表（领域 id 存于 [clothingId]，与 Isar 自增 [id] 区分）
@collection
class ClothingModel {
  ClothingModel();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String clothingId;

  late String name;

  late String category;

  List<String> colors = [];

  String? brand;

  String? size;

  String? imageUrl;

  String? croppedImageUrl;

  List<String> tags = [];

  String? season;

  String? occasion;

  String? style;

  DateTime? purchaseDate;

  /// 购买价格（与领域层一致，可为空）
  double? purchasePrice;

  late String status;

  int usageCount = 0;

  DateTime? lastWornDate;

  String? notes;

  /// 从领域实体构建（新建或覆盖写入前赋值）
  factory ClothingModel.fromDomain(Clothing entity) {
    return ClothingModel()
      ..clothingId = entity.id
      ..name = entity.name
      ..category = entity.category
      ..colors = List<String>.from(entity.colors)
      ..brand = entity.brand
      ..size = entity.size
      ..imageUrl = entity.imageUrl
      ..croppedImageUrl = entity.croppedImageUrl
      ..tags = List<String>.from(entity.tags)
      ..season = entity.season
      ..occasion = entity.occasion
      ..style = entity.style
      ..purchaseDate = entity.purchaseDate
      ..purchasePrice = entity.purchasePrice
      ..status = entity.status
      ..usageCount = entity.usageCount
      ..lastWornDate = entity.lastWornDate
      ..notes = entity.notes;
  }

  Clothing toDomain() {
    return Clothing(
      id: clothingId,
      name: name,
      category: category,
      colors: List<String>.from(colors),
      brand: brand,
      size: size,
      imageUrl: imageUrl,
      croppedImageUrl: croppedImageUrl,
      tags: List<String>.from(tags),
      season: season,
      occasion: occasion,
      style: style,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      status: status,
      usageCount: usageCount,
      lastWornDate: lastWornDate,
      notes: notes,
    );
  }
}
