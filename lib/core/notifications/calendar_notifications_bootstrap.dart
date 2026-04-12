import 'calendar_notifications_bootstrap_stub.dart'
    if (dart.library.io) 'calendar_notifications_bootstrap_io.dart' as impl;

Future<void> bootstrapCalendarNotifications() => impl.bootstrapCalendarNotifications();
