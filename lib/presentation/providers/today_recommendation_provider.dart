import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai/ai_env.dart';
import '../../data/local/daily_ai_recommendation_budget.dart';
import '../../data/remote/recommendation_day_context_loader.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/models/recommendation_day_context.dart';
import '../../domain/usecases/outfit_recommendation_usecase.dart';

/// 衣橱「今日推荐」数据：移动端在配置完整时可走 AI；Web 端固定本地规则，不请求大模型。
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
  final dailyAiUsed = await DailyAiRecommendationBudget.isConsumedForToday();
  final useCase = OutfitRecommendationUseCase(
    loadAiConfig: loadAiClientConfig,
  );
  final core = await useCase.execute(
    clothes: clothes,
    outfits: outfits,
    dayContext: dayCtx,
    skipAiDueToDailyLimit: dailyAiUsed,
    skipAi: kIsWeb,
  );
  if (core.primarySource == RecommendationPrimarySource.ai) {
    await DailyAiRecommendationBudget.markConsumedForToday();
  }
  return core.copyWith(dayContext: dayCtx);
});
