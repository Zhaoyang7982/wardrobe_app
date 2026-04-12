import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 某日活动备注与提醒时间（仅存本地，与云端搭配计划独立）
class CalendarDayExtras {
  const CalendarDayExtras({this.note = '', this.reminderHour, this.reminderMinute});

  final String note;
  final int? reminderHour;
  final int? reminderMinute;

  bool get hasReminder => reminderHour != null && reminderMinute != null;

  Map<String, dynamic> toJson() => {
        'note': note,
        'rh': reminderHour,
        'rm': reminderMinute,
      };

  static CalendarDayExtras fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return const CalendarDayExtras();
    }
    return CalendarDayExtras(
      note: j['note'] as String? ?? '',
      reminderHour: (j['rh'] as num?)?.toInt(),
      reminderMinute: (j['rm'] as num?)?.toInt(),
    );
  }
}

/// SharedPreferences 持久化日历备注/提醒
class CalendarDayStore {
  static const _prefix = 'calendar_day_extras_v1_';

  static String dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<CalendarDayExtras> load(DateTime day) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('$_prefix${dayKey(day)}');
    if (raw == null || raw.isEmpty) {
      return const CalendarDayExtras();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>?;
      return CalendarDayExtras.fromJson(map);
    } catch (_) {
      return const CalendarDayExtras();
    }
  }

  Future<void> save(DateTime day, CalendarDayExtras extras) async {
    final p = await SharedPreferences.getInstance();
    final key = '$_prefix${dayKey(day)}';
    if (extras.note.isEmpty && !extras.hasReminder) {
      await p.remove(key);
      return;
    }
    await p.setString(key, jsonEncode(extras.toJson()));
  }

  /// 一次性读出所有已存日期（用于日历小圆点）
  Future<Map<DateTime, CalendarDayExtras>> loadAll() async {
    final p = await SharedPreferences.getInstance();
    final out = <DateTime, CalendarDayExtras>{};
    for (final key in p.getKeys()) {
      if (!key.startsWith(_prefix)) {
        continue;
      }
      final suffix = key.substring(_prefix.length);
      final parts = suffix.split('-');
      if (parts.length != 3) {
        continue;
      }
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) {
        continue;
      }
      final day = DateTime(y, m, d);
      final raw = p.getString(key);
      if (raw == null || raw.isEmpty) {
        continue;
      }
      try {
        out[day] = CalendarDayExtras.fromJson(jsonDecode(raw) as Map<String, dynamic>?);
      } catch (_) {}
    }
    return out;
  }
}
