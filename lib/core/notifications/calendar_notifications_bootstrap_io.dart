import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'calendar_notification_service.dart';

Future<void> bootstrapCalendarNotifications() async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return;
  }
  try {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    await CalendarNotificationService.instance.init();
  } catch (e, st) {
    debugPrint('日历通知初始化跳过: $e\n$st');
  }
}
