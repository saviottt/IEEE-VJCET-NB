import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/home_screen.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Supabase
  await SupabaseService.instance.initialize();

  // Initialize local notifications service
  await NotificationService.instance.initialize();

  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );

  // Initialize Firebase and FCM notifications in the background so it doesn't block app launch
  _initFirebaseAndNotifications(container);
}

Future<void> _initFirebaseAndNotifications(ProviderContainer container) async {
  // Unconditionally listen for simulated notifications (independent of Firebase status)
  SupabaseService.instance.simulatedNotificationStream.listen((sim) {
    _handleIncomingNotification(
      container: container,
      title: sim.title,
      body: sim.body,
    );
  });

  try {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully from native resources.');
    } catch (e) {
      debugPrint('Firebase native initialization failed ($e). Falling back to programmatic config...');
      // Fallback programmatically so it doesn't fail/crash when google-services.json is missing
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: Constants.firebaseApiKey,
          appId: Constants.firebaseAppId,
          messagingSenderId: Constants.firebaseMessagingSenderId,
          projectId: Constants.firebaseProjectId,
        ),
      );
      debugPrint('Firebase initialized successfully via programmatic fallback.');
    }

    // Subscribe to events topic for collaborative updates (non-blocking)
    FirebaseMessaging.instance.subscribeToTopic('events').then((_) {
      debugPrint('FCM: Successfully subscribed to events topic.');
    }).catchError((err) {
      debugPrint('FCM: Error subscribing to events topic: $err');
    });
    
    // Request permission for notifications (non-blocking)
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    ).then((settings) {
      debugPrint('FCM: Permission request status: ${settings.authorizationStatus}');
    }).catchError((err) {
      debugPrint('FCM: Error requesting notification permission: $err');
    });

    // Listen for foreground FCM notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM notification received: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        _handleIncomingNotification(
          container: container,
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
        );
      }
    });
  } catch (e) {
    debugPrint('Firebase initialization / setup failed: $e');
  }
}

void _handleIncomingNotification({
  required ProviderContainer container,
  required String title,
  required String body,
}) {
  final settings = container.read(notificationSettingsProvider);

  // Trigger system notification if enabled
  if (settings.showSystem) {
    NotificationService.instance.showSystemNotification(
      title: title,
      body: body,
    );
  }

  // Trigger in-app banner if enabled
  if (settings.showInApp) {
    _showNotificationBanner(title, body);
  }
}

void _showNotificationBanner(String title, String? body) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate background
      duration: const Duration(seconds: 5),
      content: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'IEEE Calender',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

