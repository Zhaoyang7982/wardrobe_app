import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../domain/usecases/outfit_recommendation_usecase.dart';

/// 从 `assets/env/app.env`（或 example）读取 AI 配置；密钥勿写入代码库。
AiClientConfig loadAiClientConfig() {
  String? pick(String key) {
    final v = dotenv.env[key]?.trim();
    if (v == null || v.isEmpty) {
      return null;
    }
    return v;
  }

  return AiClientConfig(
    apiKey: pick('AI_API_KEY'),
    baseUrl: pick('AI_API_BASE_URL'),
    model: pick('AI_MODEL') ?? 'gpt-4o-mini',
  );
}
