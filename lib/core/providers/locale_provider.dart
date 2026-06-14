import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_cache_provider.dart';

final localeCodeProvider = StateProvider<String>((ref) {
  return ref.read(sharedPreferencesProvider).getString('app_locale') ?? 'fr';
});

Future<void> setAppLocale(WidgetRef ref, String code) async {
  await ref.read(sharedPreferencesProvider).setString('app_locale', code);
  ref.read(localeCodeProvider.notifier).state = code;
}
