import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai/ai_env.dart';
import '../../data/remote/recommendation_day_context_loader.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/models/recommendation_day_context.dart';
import '../../domain/usecases/outfit_recommendation_usecase.dart';

/// 衣橱首页「今日推荐」数据（规则优先保底；配置完整时尝试 AI）
final todayRecommendationProvider =
    FutureProvider.autoDispose<TodayRecommendationResult>((ref) async {
  final dayFut = RecommendationDayContextLoader.load();
  final clothingRepo = await ref.watch(clothingRepositoryProvider.future);
  final outfitRepo = await ref.watch(outfitRepositoryProvider.future);
  final clothes = await clothingRepo.getAll();
  final outfits = await outfitRepo.getAll();
  RecommendationDayContext dayCtx;
  try {
    dayCtx = await dayFut;
  } catch (_) {
    dayCtx = RecommendationDayContext.localFallback(DateTime.now());
  }
  final useCase = OutfitRecommendationUseCase(
    loadAiConfig: loadAiClientConfig,
  );
  final core = await useCase.execute(
    clothes: clothes,
    outfits: outfits,
    dayContext: dayCtx,
  );
  return core.copyWith(dayContext: dayCtx);
});
