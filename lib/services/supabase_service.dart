import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/event.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

enum RealtimeEventType { insert, update, delete }

class EventRealtimePayload {
  final RealtimeEventType type;
  final Event event;

  EventRealtimePayload({required this.type, required this.event});
}

class CategoryRealtimePayload {
  final RealtimeEventType type;
  final Category category;

  CategoryRealtimePayload({required this.type, required this.category});
}

class SimulatedNotification {
  final String title;
  final String body;

  SimulatedNotification({required this.title, required this.body});
}

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal() {
    _initMockState();
  }

  bool get isMockMode => _isMockMode;
  bool _isMockMode = true;

  sb.SupabaseClient? _client;

  // Local Mock Database State
  late final List<Category> _mockCategories;
  late final List<Event> _mockEvents;
  
  // Controllers
  final _realtimeEventController = StreamController<EventRealtimePayload>.broadcast();
  final _realtimeCategoryController = StreamController<CategoryRealtimePayload>.broadcast();
  final _simulatedNotificationController = StreamController<SimulatedNotification>.broadcast();

  Stream<SimulatedNotification> get simulatedNotificationStream => _simulatedNotificationController.stream;


  // Initialize service
  Future<void> initialize() async {
    final hasCredentials = Constants.supabaseUrl.isNotEmpty &&
        Constants.supabaseUrl != 'YOUR_SUPABASE_URL' &&
        Constants.supabaseAnonKey.isNotEmpty &&
        Constants.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

    if (!hasCredentials) {
      if (kDebugMode) {
        print('SupabaseService: Running in DEMO MOCK MODE.');
      }
      _isMockMode = true;
      return;
    }

    try {
      await sb.Supabase.initialize(
        url: Constants.supabaseUrl,
        anonKey: Constants.supabaseAnonKey,
      );
      _client = sb.Supabase.instance.client;
      _isMockMode = false;

      if (kDebugMode) {
        print('SupabaseService: Successfully initialized Supabase client.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SupabaseService initialization failed: $e. Falling back to Demo Mock Mode.');
      }
      _isMockMode = true;
    }
  }

  // ---------------- MOCK STATE INITIALIZATION ----------------
  void _initMockState() {
    _mockCategories = [
      Category(id: 'cat-1', name: 'Workshops', color: '#2196F3'),
      Category(id: 'cat-2', name: 'Conferences', color: '#9C27B0'),
      Category(id: 'cat-3', name: 'Seminars', color: '#4CAF50'),
      Category(id: 'cat-4', name: 'Networking', color: '#FF9800'),
      Category(id: 'cat-5', name: 'Competitions', color: '#F44336'),
      Category(id: 'cat-6', name: 'Other', color: '#607D8B'),
    ];

    final now = DateTime.now();
    _mockEvents = [
      Event(
        id: 'evt-1',
        title: 'IEEE Extreme 24.0 Hackathon',
        description: 'A 24-hour global competitive programming challenge.',
        venue: 'CS Seminar Hall & Online',
        organizerName: 'IEEE CS Student Chapter',
        startDatetime: DateTime(now.year, now.month, now.day + 1, 9, 0),
        endDatetime: DateTime(now.year, now.month, now.day + 1, 17, 0),
        categoryId: 'cat-5',
        category: _mockCategories[4],
        bannerUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800',
        registrationLink: 'https://ieeextreme.org',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  // ---------------- CATEGORIES ----------------

  Future<List<Category>> getCategories() async {
    if (_isMockMode) {
      return List.from(_mockCategories);
    }

    final response = await _client!
        .from('categories')
        .select()
        .order('name');
    
    return (response as List).map((c) => Category.fromJson(c)).toList();
  }

  // ---------------- EVENTS CRUD ----------------

  Future<List<Event>> getEvents() async {
    if (_isMockMode) {
      final events = List<Event>.from(_mockEvents);
      events.sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
      return events;
    }

    final response = await _client!
        .from('events')
        .select('*, categories(*)')
        .order('start_datetime', ascending: true);

    return (response as List).map((e) => Event.fromJson(e)).toList();
  }

  Future<void> _sendFCMNotification(Event event) async {
    if (Constants.firebaseServiceAccountJson.isEmpty ||
        Constants.firebaseServiceAccountJson == 'YOUR_FIREBASE_SERVICE_ACCOUNT_JSON') {
      if (kDebugMode) {
        print('FCM: Service Account not configured. Skipping push notification.');
      }
      return;
    }

    try {
      final credentials = auth.ServiceAccountCredentials.fromJson(
        Constants.firebaseServiceAccountJson,
      );

      final Map<String, dynamic> serviceAccountMap = json.decode(
        Constants.firebaseServiceAccountJson,
      );
      final projectId = serviceAccountMap['project_id'];

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(credentials, scopes);

      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': {
            'topic': 'events',
            'notification': {
              'title': 'New Event: ${event.title}',
              'body': 'Scheduled on ${DateFormat('EEEE, MMM d').format(event.startDatetime)}${event.venue.isNotEmpty ? ' at ${event.venue}' : ''}',
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'event_id': event.id,
            },
            'android': {
              'notification': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'category': 'NEW_EVENT',
                },
              },
            },
          },
        }),
      );

      if (kDebugMode) {
        print('FCM HTTP v1 notification sent response code: ${response.statusCode}');
      }
      client.close();
    } catch (e) {
      if (kDebugMode) {
        print('Error sending FCM notification: $e');
      }
    }
  }

  Future<Event> createEvent(Event event) async {
    if (_isMockMode) {
      final cat = _mockCategories.firstWhere(
        (c) => c.id == event.categoryId,
        orElse: () => _mockCategories.last,
      );

      final newEvent = event.copyWith(
        id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
        category: cat,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _mockEvents.add(newEvent);
      _realtimeEventController.add(EventRealtimePayload(type: RealtimeEventType.insert, event: newEvent));
      
      // If Firebase is not configured, simulate an FCM push notification
      if (Constants.firebaseApiKey.contains('DummyKey') ||
          Constants.firebaseServiceAccountJson.contains('YOUR_FIREBASE')) {
        final formattedDate = DateFormat('EEEE, MMM d').format(newEvent.startDatetime);
        _simulatedNotificationController.add(
          SimulatedNotification(
            title: 'New Event: ${newEvent.title}',
            body: 'Scheduled on $formattedDate${newEvent.venue.isNotEmpty ? ' at ${newEvent.venue}' : ''}',
          ),
        );
      }

      _sendFCMNotification(newEvent);
      return newEvent;
    }

    final data = event.toJson();
    final response = await _client!
        .from('events')
        .insert(data)
        .select('*, categories(*)')
        .single();

    final createdEvent = Event.fromJson(response);
    
    // If Firebase is not configured, simulate an FCM push notification locally
    if (Constants.firebaseApiKey.contains('DummyKey') ||
        Constants.firebaseServiceAccountJson.contains('YOUR_FIREBASE')) {
      final formattedDate = DateFormat('EEEE, MMM d').format(createdEvent.startDatetime);
      _simulatedNotificationController.add(
        SimulatedNotification(
          title: 'New Event: ${createdEvent.title}',
          body: 'Scheduled on $formattedDate${createdEvent.venue.isNotEmpty ? ' at ${createdEvent.venue}' : ''}',
        ),
      );
    }
    
    // Send Push Notification via FCM topic
    await _sendFCMNotification(createdEvent);

    return createdEvent;
  }

  Future<Event> updateEvent(Event event) async {
    if (_isMockMode) {
      final index = _mockEvents.indexWhere((e) => e.id == event.id);
      if (index == -1) throw Exception('Event not found');

      final cat = _mockCategories.firstWhere(
        (c) => c.id == event.categoryId,
        orElse: () => _mockCategories.last,
      );

      final updatedEvent = event.copyWith(
        category: cat,
        updatedAt: DateTime.now(),
      );

      _mockEvents[index] = updatedEvent;
      _realtimeEventController.add(EventRealtimePayload(type: RealtimeEventType.update, event: updatedEvent));
      return updatedEvent;
    }

    final data = event.toJson();
    final response = await _client!
        .from('events')
        .update(data)
        .eq('id', event.id)
        .select('*, categories(*)')
        .single();

    return Event.fromJson(response);
  }

  Future<void> deleteEvent(String id) async {
    if (_isMockMode) {
      final index = _mockEvents.indexWhere((e) => e.id == id);
      if (index == -1) return;

      final deletedEvent = _mockEvents.removeAt(index);
      _realtimeEventController.add(EventRealtimePayload(type: RealtimeEventType.delete, event: deletedEvent));
      return;
    }

    await _client!
        .from('events')
        .delete()
        .eq('id', id);
  }

  // ---------------- STORAGE ----------------

  Future<String?> uploadBannerImage(Uint8List bytes, String filename) async {
    if (_isMockMode) {
      return 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800';
    }

    try {
      final path = 'banners/${DateTime.now().millisecondsSinceEpoch}_$filename';
      await _client!.storage.from('event-banners').uploadBinary(path, bytes);
      return _client!.storage.from('event-banners').getPublicUrl(path);
    } catch (e) {
      if (kDebugMode) print('Upload failed: $e');
      return null;
    }
  }

  // ---------------- REALTIME ENGINE ----------------

  sb.RealtimeChannel? _eventRealtimeChannel;
  sb.RealtimeChannel? _categoryRealtimeChannel;

  Stream<EventRealtimePayload> get realtimeEventStream => _realtimeEventController.stream;
  Stream<CategoryRealtimePayload> get realtimeCategoryStream => _realtimeCategoryController.stream;

  void setupRealtimeSubscription() {
    if (_isMockMode) return;

    if (_eventRealtimeChannel == null) {
      _eventRealtimeChannel = _client!.channel('public:events');
      _eventRealtimeChannel!.onPostgresChanges(
        event: sb.PostgresChangeEvent.all,
        schema: 'public',
        table: 'events',
        callback: (payload) async {
          final eventType = payload.eventType;
          final newRecord = payload.newRecord;
          final oldRecord = payload.oldRecord;

          try {
            if (eventType == sb.PostgresChangeEvent.insert || eventType == sb.PostgresChangeEvent.update) {
              final fullEvent = await _fetchSingleEventWithJoins(newRecord['id'] as String);
              if (fullEvent != null) {
                _realtimeEventController.add(
                  EventRealtimePayload(
                    type: eventType == sb.PostgresChangeEvent.insert ? RealtimeEventType.insert : RealtimeEventType.update,
                    event: fullEvent,
                  ),
                );

                // If Firebase is not configured, simulate an FCM push notification
                if (eventType == sb.PostgresChangeEvent.insert) {
                  if (Constants.firebaseApiKey.contains('DummyKey') ||
                      Constants.firebaseServiceAccountJson.contains('YOUR_FIREBASE')) {
                    final formattedDate = DateFormat('EEEE, MMM d').format(fullEvent.startDatetime);
                    _simulatedNotificationController.add(
                      SimulatedNotification(
                        title: 'New Event: ${fullEvent.title}',
                        body: 'Scheduled on $formattedDate${fullEvent.venue.isNotEmpty ? ' at ${fullEvent.venue}' : ''}',
                      ),
                    );
                  }
                }
              }
            } else if (eventType == sb.PostgresChangeEvent.delete) {
              final deletedEvent = Event(
                id: oldRecord['id'] as String,
                title: '',
                venue: '',
                organizerName: '',
                startDatetime: DateTime.now(),
                endDatetime: DateTime.now(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              _realtimeEventController.add(
                EventRealtimePayload(type: RealtimeEventType.delete, event: deletedEvent),
              );
            }
          } catch (e) {
            if (kDebugMode) print('Error processing realtime payload: $e');
          }
        },
      ).subscribe();
    }

    if (_categoryRealtimeChannel == null) {
      _categoryRealtimeChannel = _client!.channel('public:categories');
      _categoryRealtimeChannel!.onPostgresChanges(
        event: sb.PostgresChangeEvent.all,
        schema: 'public',
        table: 'categories',
        callback: (payload) {
          final eventType = payload.eventType;
          final newRecord = payload.newRecord;
          final oldRecord = payload.oldRecord;

          try {
            if (eventType == sb.PostgresChangeEvent.insert || eventType == sb.PostgresChangeEvent.update) {
              final cat = Category.fromJson(newRecord);
              _realtimeCategoryController.add(
                CategoryRealtimePayload(
                  type: eventType == sb.PostgresChangeEvent.insert ? RealtimeEventType.insert : RealtimeEventType.update,
                  category: cat,
                ),
              );

              // If Firebase is not configured, simulate an FCM push notification
              if (eventType == sb.PostgresChangeEvent.insert) {
                if (Constants.firebaseApiKey.contains('DummyKey') ||
                    Constants.firebaseServiceAccountJson.contains('YOUR_FIREBASE')) {
                  _simulatedNotificationController.add(
                    SimulatedNotification(
                      title: 'New Filter Option Available!',
                      body: 'Category "${cat.name}" has been added.',
                    ),
                  );
                }
              }
            } else if (eventType == sb.PostgresChangeEvent.delete) {
              final deletedCat = Category(
                id: oldRecord['id'] as String,
                name: '',
                color: '#607D8B',
              );
              _realtimeCategoryController.add(
                CategoryRealtimePayload(
                  type: RealtimeEventType.delete,
                  category: deletedCat,
                ),
              );
            }
          } catch (e) {
            if (kDebugMode) print('Error processing category realtime payload: $e');
          }
        },
      ).subscribe();
    }
  }

  void cancelRealtimeSubscription() {
    if (_eventRealtimeChannel != null) {
      _client?.removeChannel(_eventRealtimeChannel!);
      _eventRealtimeChannel = null;
    }
    if (_categoryRealtimeChannel != null) {
      _client?.removeChannel(_categoryRealtimeChannel!);
      _categoryRealtimeChannel = null;
    }
  }

  Future<Event?> _fetchSingleEventWithJoins(String id) async {
    try {
      final response = await _client!
          .from('events')
          .select('*, categories(*)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Event.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
