import 'package:aeemg/app.dart';
import 'package:aeemg/core/providers/offline_cache_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr');
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://placeholder.supabase.co
SUPABASE_ANON_KEY=placeholder-anon-key
''',
    );
  });

  testWidgets('AEEMG affiche l\'écran d\'accueil', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const AeemgApp(),
      ),
    );
    // Le splash anime en boucle puis redirige vers /home après 4 s, et l'accueil
    // rafraîchit les heures de prière chaque seconde : pumpAndSettle ne se
    // stabiliserait jamais, on avance donc le temps explicitement.
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('AEEMG'), findsOneWidget);
    expect(find.text('Hadiths'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);

    // Démonte l'app puis laisse expirer les délais ponctuels restants : la
    // rotation du hadith (home_provider) attend jusqu'à 30 min entre deux valeurs.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 31));
  });
}
