/// 用户偏好 / 档案领域实体（通常单例一条）
class UserProfile {
  const UserProfile({
    this.profileId = 'default',
    required this.styles,
    this.bodyType,
    this.height,
    this.weight,
    required this.favoriteColors,
    required this.favoriteOccasions,
  });

  final String profileId;
  final List<String> styles;
  final String? bodyType;
  final double? height;
  final double? weight;
  final List<String> favoriteColors;
  final List<String> favoriteOccasions;
}
