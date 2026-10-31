import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/providers/offline_cache_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;
  // Fix rapide pour la CI: autoriser le téléchargement des polices Google au runtime.
  // Le correctif durable est d'empaqueter les fontes localement dans assets/fonts.
  GoogleFonts.config.allowRuntimeFetching = true;

  await initializeDateFormatting('fr');
  await SupabaseConfig.initialize();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AeemgApp(),
    ),
  );
}
