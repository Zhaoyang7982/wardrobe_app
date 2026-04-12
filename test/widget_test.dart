import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wardrobe_app/data/repositories/repository_providers.dart';
import 'package:wardrobe_app/domain/models/clothing.dart';
import 'package:wardrobe_app/domain/models/outfit.dart';
import 'package:wardrobe_app/domain/models/recommendation_day_context.dart';
import 'package:wardrobe_app/domain/repositories/clothing_repository.dart';
import 'package:wardrobe_app/domain/repositories/outfit_repository.dart';
import 'package:wardrobe_app/domain/usecases/outfit_recommendation_usecase.dart';
import 'package:wardrobe_app/main.dart';
import 'package:wardrobe_app/presentation/providers/today_recommendation_provider.dart';

/// 测试用仓储，避免单测环境初始化 Isar
class _FakeClothingRepository implements ClothingRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Clothing>> filterBy({
    String? category,
    String? color,
    String? season,
    String? occasion,
  }) async =>
      [];

  @override
  Future<List<Clothing>> getAll() async => [];

  @override
  Future<Clothing?> getById(String id) async => null;

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
  }) async =>
      [];

  @override
  Future<void> save(Clothing clothing) async {}

  @override
  Future<List<Clothing>> search(String keyword) async => [];
}

class _FakeOutfitRepository implements OutfitRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Outfit>> getAll() async => [];

  @override
  Future<List<Outfit>> getAllIncludingArchived() async => [];

  @override
  Future<Outfit?> getById(String id) async => null;

  @override
  Future<List<Outfit>> getByDate(DateTime date) async => [];

  @override
  Future<List<Outfit>> listContainingClothing(String clothingId) async => [];

  @override
  Future<void> save(Outfit outfit) async {}

  @override
  Future<void> permanentlyDelete(String id) async {}
}

void main() {
  testWidgets('启动后进入衣橱 Tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clothingRepositoryProvider.overrideWith(
            (ref) async => _FakeClothingRepository(),
          ),
          outfitRepositoryProvider.overrideWith(
            (ref) async => _FakeOutfitRepository(),
          ),
          todayRecommendationProvider.overrideWith((ref) async {
            return TodayRecommendationResult(
              outfits: const [],
              seasonLabel: '春',
              primarySource: RecommendationPrimarySource.rule,
              dayContext: RecommendationDayContext.localFallback(
                DateTime(2026, 4, 12),
              ),
            );
          }),
        ],
        child: const WardrobeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('衣橱'), findsWidgets);
  });
}
