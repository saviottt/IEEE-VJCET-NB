import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';

class CategoryNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  StreamSubscription<CategoryRealtimePayload>? _realtimeSubscription;

  CategoryNotifier() : super(const AsyncValue.loading()) {
    loadCategories();
    _setupRealtime();
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _supabaseService.getCategories();
      state = AsyncValue.data(categories);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _setupRealtime() {
    _supabaseService.setupRealtimeSubscription();
    _realtimeSubscription = _supabaseService.realtimeCategoryStream.listen((payload) {
      final category = payload.category;
      
      state.whenData((currentCategories) {
        final updatedList = List<Category>.from(currentCategories);

        switch (payload.type) {
          case RealtimeEventType.insert:
            if (!updatedList.any((c) => c.id == category.id)) {
              updatedList.add(category);
              updatedList.sort((a, b) => a.name.compareTo(b.name));
              state = AsyncValue.data(updatedList);
            }
            break;
          case RealtimeEventType.update:
            final index = updatedList.indexWhere((c) => c.id == category.id);
            if (index != -1) {
              updatedList[index] = category;
            } else {
              updatedList.add(category);
            }
            updatedList.sort((a, b) => a.name.compareTo(b.name));
            state = AsyncValue.data(updatedList);
            break;
          case RealtimeEventType.delete:
            updatedList.removeWhere((c) => c.id == category.id);
            state = AsyncValue.data(updatedList);
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<List<Category>>>((ref) {
  return CategoryNotifier();
});
