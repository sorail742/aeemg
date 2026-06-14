import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/islamic_repository.dart';

final islamicRepositoryProvider = Provider<IslamicRepository>((ref) {
  return IslamicRepository(ref.watch(supabaseClientProvider));
});

final islamicLibraryProvider = FutureProvider((ref) async {
  return ref.read(islamicRepositoryProvider).fetchLibrary();
});

final islamicFavoritesProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  return ref.read(islamicRepositoryProvider).fetchFavoriteIds(user.id);
});
