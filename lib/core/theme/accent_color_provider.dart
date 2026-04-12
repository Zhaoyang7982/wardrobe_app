import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 与 [AppTheme] 默认浅色种子一致（清新马卡龙 · 薄荷糖）
const int kDefaultAccentArgb = 0xFF8FE5D0;

const String _prefsKey = 'app_theme_accent_argb_v1';

/// 用户选择的强调色（ARGB 整型），持久化到 SharedPreferences
final accentColorArgbProvider =
    AsyncNotifierProvider<AccentColorArgbNotifier, int>(AccentColorArgbNotifier.new);

class AccentColorArgbNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_prefsKey) ?? kDefaultAccentArgb;
  }

  Future<void> setAccentArgb(int argb) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_prefsKey, argb);
    state = AsyncData(argb);
  }

  Future<void> resetToDefault() => setAccentArgb(kDefaultAccentArgb);
}

/// 预设：清新活泼马卡龙（高明度、中饱和，作 seed 时 primary 仍清晰）
const List<({String label, int argb})> kAccentColorPresets = [
  (label: '薄荷糖', argb: 0xFF8FE5D0),
  (label: '蜜桃粉', argb: 0xFFFFB8C8),
  (label: '柠檬冰', argb: 0xFFFFF2A8),
  (label: '婴儿蓝', argb: 0xFFB8E4FF),
  (label: '香芋紫', argb: 0xFFE4C4FF),
  (label: '蜜瓜绿', argb: 0xFFC8F5C0),
  (label: '橘子汽', argb: 0xFFFFD4A8),
  (label: '樱花苏打', argb: 0xFFFFD6EC),
];
