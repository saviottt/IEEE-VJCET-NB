import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';

final categoryProvider = FutureProvider<List<Category>>((ref) async {
  return await SupabaseService.instance.getCategories();
});
