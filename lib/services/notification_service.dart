import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Create high importance Android notification channel for heads-up notifications
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'ieee_events_channel',
        'IEEE Event Notifications',
        description: 'Notifications for new community and chapter events',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
      }

      _isInitialized = true;
      debugPrint('NotificationService successfully initialized.');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  Future<bool?> requestPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        debugPrint('Notification permission granted: $granted');
        return granted;
      }
    } catch (e) {
      debugPrint('Failed to request notification permission: $e');
    }
    return false;
  }

  Future<void> showSystemNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final notificationId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'ieee_events_channel',
        'IEEE Event Notifications',
        channelDescription: 'Notifications for new community and chapter events',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _localNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing system notification: $e');
    }
  }
}
