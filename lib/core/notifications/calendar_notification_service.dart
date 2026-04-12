import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// 在 Android/iOS 上为某日预约一条本地通知（Web/桌面跳过）
class CalendarNotificationService {
  CalendarNotificationService._();

  static final CalendarNotificationService instance = CalendarNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static int notificationIdForDay(DateTime day) =>
      day.year * 10000 + day.month * 100 + day.day;

  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!supported) {
      return;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings);
    _ready = true;

    if (Platform.isAndroid) {
      // 与 Geolocator 等「同时」请求会触发系统
      // 「Can request only one set of permissions at a time」，
      // 导致 grantResults 为空、定位权限回调异常。推迟到首帧后再请求。
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 2500));
        if (!_ready) {
          return;
        }
        try {
          await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission();
        } catch (e, st) {
          debugPrint('requestNotificationsPermission 推迟请求失败: $e\n$st');
        }
      });
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> cancelDay(DateTime day) async {
    if (!_ready) {
      return;
    }
    await _plugin.cancel(notificationIdForDay(day));
  }

  /// 在 [day] 的 [hour]:[minute] 本地时间触发（若已过期则不发）
  Future<void> scheduleDayReminder({
    required DateTime day,
    required int hour,
    required int minute,
    required String body,
  }) async {
    if (!_ready || !supported) {
      return;
    }
    final id = notificationIdForDay(day);
    await _plugin.cancel(id);

    final scheduled = tz.TZDateTime(tz.local, day.year, day.month, day.day, hour, minute);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const android = AndroidNotificationDetails(
      'wardrobe_calendar',
      '衣橱日历提醒',
      channelDescription: '日历活动与搭配计划提醒',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: android, iOS: DarwinNotificationDetails());

    await _plugin.zonedSchedule(
      id,
      '衣橱日历',
      body.isEmpty ? '今日有搭配或活动安排' : body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
