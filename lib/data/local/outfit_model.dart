import 'package:isar/isar.dart';

import '../../domain/models/outfit.dart';

part 'outfit_model.g.dart';

/// Isar 搭配表
@collection
class OutfitModel {
  OutfitModel();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String outfitId;

  late String name;

  List<String> clothingIds = [];

  String? scene;

  String? occasion;

  String? season;

  String? imageUrl;

  List<DateTime> wornDates = [];

  List<DateTime> plannedDates = [];

  String? notes;

  bool isShared = false;

  bool isArchived = false;

  factory OutfitModel.fromDomain(Outfit entity) {
    return OutfitModel()
      ..outfitId = entity.id
      ..name = entity.name
      ..clothingIds = List<String>.from(entity.clothingIds)
      ..scene = entity.scene
      ..occasion = entity.occasion
      ..season = entity.season
      ..imageUrl = entity.imageUrl
      ..wornDates = List<DateTime>.from(entity.wornDates)
      ..plannedDates = List<DateTime>.from(entity.plannedDates)
      ..notes = entity.notes
      ..isShared = entity.isShared
      ..isArchived = entity.isArchived;
  }

  Outfit toDomain() {
    return Outfit(
      id: outfitId,
      name: name,
      clothingIds: List<String>.from(clothingIds),
      scene: scene,
      occasion: occasion,
      season: season,
      imageUrl: imageUrl,
      wornDates: List<DateTime>.from(wornDates),
      plannedDates: List<DateTime>.from(plannedDates),
      notes: notes,
      isShared: isShared,
      isArchived: isArchived,
    );
  }
}
