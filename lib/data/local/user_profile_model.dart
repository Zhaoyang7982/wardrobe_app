import 'package:isar/isar.dart';

import '../../domain/models/user_profile.dart';

part 'user_profile_model.g.dart';

/// Isar 用户偏好（单例语义，用 [profileId] 唯一标识，默认 `default`）
@collection
class UserProfileModel {
  UserProfileModel();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String profileId;

  List<String> styles = [];

  String? bodyType;

  double? height;

  double? weight;

  List<String> favoriteColors = [];

  List<String> favoriteOccasions = [];

  factory UserProfileModel.fromDomain(UserProfile entity) {
    return UserProfileModel()
      ..profileId = entity.profileId
      ..styles = List<String>.from(entity.styles)
      ..bodyType = entity.bodyType
      ..height = entity.height
      ..weight = entity.weight
      ..favoriteColors = List<String>.from(entity.favoriteColors)
      ..favoriteOccasions = List<String>.from(entity.favoriteOccasions);
  }

  UserProfile toDomain() {
    return UserProfile(
      profileId: profileId,
      styles: List<String>.from(styles),
      bodyType: bodyType,
      height: height,
      weight: weight,
      favoriteColors: List<String>.from(favoriteColors),
      favoriteOccasions: List<String>.from(favoriteOccasions),
    );
  }
}
