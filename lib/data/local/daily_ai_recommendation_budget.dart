import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 「今日推荐」混元 / OpenAI 兼容接口：每自然日（本地时区）仅允许成功走通 AI 一次。
class DailyAiRecommendationBudget {
  DailyAiRecommendationBudget._();

  static const _prefsKey = 'wardrobe_daily_ai_recommend_date_v1';

  static String _todayLocal() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());

  /// 今日是否已占用免费额度（成功用过 AI 后会被标记）。
  static Future<bool> isConsumedForToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) == _todayLocal();
  }

  /// 在确认本次结果为 AI 推荐成功后调用。
  static Future<void> markConsumedForToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _todayLocal());
  }
}
