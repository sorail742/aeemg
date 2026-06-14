import 'package:aeemg/app.dart';
import 'package:aeemg/core/providers/offline_cache_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr');
    dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://placeholder.supabase.co
SUPABASE_ANON_KEY=placeholder-anon-key
''');
  });

  testWidgets('AEEMG affiche l\'écran d\'accueil', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const AeemgApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AEEMG'), findsOneWidget);
    expect(find.text('Verset du jour'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
  });
}
