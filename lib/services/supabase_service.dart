import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/event.dart';
import '../models/category.dart';
import '../utils/constants.dart';

enum RealtimeEventType { insert, update, delete }

class EventRealtimePayload {
  final RealtimeEventType type;
  final Event event;

  EventRealtimePayload({required this.type, required this.event});
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
      return newEvent;
    }

    final data = event.toJson();
    final response = await _client!
        .from('events')
        .insert(data)
        .select('*, categories(*)')
        .single();

    final createdEvent = Event.fromJson(response);
    
    // Send Push Notification via FCM topic
    try {
      // In a real production app, this would be handled by a Supabase Edge Function
      // or a backend service. For this collaborative demo, we'll simulate the 
      // notification trigger logic or use a client-side FCM push if possible.
      // Since client-side FCM sending is restricted, we'll subscribe users to 
      // an 'events' topic in main.dart and assume a backend function sends the message.
      if (kDebugMode) {
        print('FCM: Event created. Backend would notify "events" topic.');
      }
    } catch (e) {
      if (kDebugMode) print('FCM Notification error: $e');
    }

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

  sb.RealtimeChannel? _realtimeChannel;
  Stream<EventRealtimePayload> get realtimeEventStream => _realtimeEventController.stream;

  void setupRealtimeSubscription() {
    if (_isMockMode || _realtimeChannel != null) return;

    _realtimeChannel = _client!.channel('public:events');
    _realtimeChannel!.onPostgresChanges(
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

  void cancelRealtimeSubscription() {
    if (_realtimeChannel != null) {
      _client?.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
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
