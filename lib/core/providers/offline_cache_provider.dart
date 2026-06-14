import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cache/offline_cache.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences doit être initialisé dans main()');
});

final offlineCacheProvider = Provider<OfflineCache>((ref) {
  return OfflineCache(ref.watch(sharedPreferencesProvider));
});
