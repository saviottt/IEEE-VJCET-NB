import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../services/supabase_service.dart';

class EventState {
  final bool isLoading;
  final List<Event> events;
  final String searchQuery;
  final String? selectedCategoryId;
  final String? errorMessage;
  final Event? lastAddedEvent;

  EventState({
    this.isLoading = true,
    this.events = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.errorMessage,
    this.lastAddedEvent,
  });

  EventState copyWith({
    bool? isLoading,
    List<Event>? events,
    String? searchQuery,
    String? selectedCategoryId,
    String? errorMessage,
    Event? lastAddedEvent,
  }) {
    return EventState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId,
      errorMessage: errorMessage ?? this.errorMessage,
      lastAddedEvent: lastAddedEvent ?? this.lastAddedEvent,
    );
  }

  // Derived filtered events
  List<Event> get filteredEvents {
    return events.where((event) {
      // 1. Filter by category
      if (selectedCategoryId != null && event.categoryId != selectedCategoryId) {
        return false;
      }

      // 2. Filter by search query (title, venue, organizerName, category name)
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = event.title.toLowerCase().contains(query);
        final matchesVenue = event.venue.toLowerCase().contains(query);
        final matchesOrganizer = event.organizerName.toLowerCase().contains(query);
        final matchesCategory = event.category?.name.toLowerCase().contains(query) ?? false;
        
        return matchesTitle || matchesVenue || matchesOrganizer || matchesCategory;
      }

      return true;
    }).toList();
  }
}

class EventNotifier extends StateNotifier<EventState> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  StreamSubscription<EventRealtimePayload>? _realtimeSubscription;

  EventNotifier() : super(EventState()) {
    loadEvents();
    _setupRealtime();
  }

  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final events = await _supabaseService.getEvents();
      state = state.copyWith(isLoading: false, events: events);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryId(String? categoryId) {
    if (categoryId == 'ALL') {
      state = EventState(
        isLoading: state.isLoading,
        events: state.events,
        searchQuery: state.searchQuery,
        selectedCategoryId: null,
        errorMessage: state.errorMessage,
      );
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  Future<void> createEvent(Event event) async {
    try {
      final newEvent = await _supabaseService.createEvent(event);
      if (!_supabaseService.isMockMode) {
        if (!state.events.any((e) => e.id == newEvent.id)) {
          final updated = [newEvent, ...state.events];
          _sortAndSet(updated, lastAddedEvent: newEvent);
        }
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      final updatedEvent = await _supabaseService.updateEvent(event);
      if (!_supabaseService.isMockMode) {
        final updated = state.events.map((e) => e.id == updatedEvent.id ? updatedEvent : e).toList();
        _sortAndSet(updated);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _supabaseService.deleteEvent(id);
      if (!_supabaseService.isMockMode) {
        final updated = state.events.where((e) => e.id != id).toList();
        _sortAndSet(updated);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  void _sortAndSet(List<Event> list, {Event? lastAddedEvent}) {
    list.sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
    state = state.copyWith(
      events: list,
      lastAddedEvent: lastAddedEvent,
    );
  }

  void _setupRealtime() {
    _supabaseService.setupRealtimeSubscription();
    _realtimeSubscription = _supabaseService.realtimeEventStream.listen((payload) {
      final event = payload.event;
      final updatedEvents = List<Event>.from(state.events);

      switch (payload.type) {
        case RealtimeEventType.insert:
          if (!updatedEvents.any((e) => e.id == event.id)) {
            updatedEvents.insert(0, event);
            _sortAndSet(updatedEvents, lastAddedEvent: event);
            return;
          }
          break;
        case RealtimeEventType.update:
          final index = updatedEvents.indexWhere((e) => e.id == event.id);
          if (index != -1) {
            updatedEvents[index] = event;
          } else {
            updatedEvents.insert(0, event);
          }
          break;
        case RealtimeEventType.delete:
          updatedEvents.removeWhere((e) => e.id == event.id);
          break;
      }

      _sortAndSet(updatedEvents);
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _supabaseService.cancelRealtimeSubscription();
    super.dispose();
  }
}

final eventProvider = StateNotifierProvider<EventNotifier, EventState>((ref) {
  return EventNotifier();
});
