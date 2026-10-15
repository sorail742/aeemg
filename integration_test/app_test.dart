// Démarrage de l'application sur émulateur (OPS-010) : job « android integration » de
// .github/workflows/compatibility.yml, sur API 24 (minSdk) et API 34.
import 'package:aeemg/main.dart' as app;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Attend en temps réel (pas d'horloge simulée sur appareil) qu'un widget apparaisse.
Future<void> attendre(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final fin = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(fin)) {
      fail('Introuvable après ${timeout.inSeconds} s : $finder');
    }
    await tester.pump(const Duration(milliseconds: 200));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("l'application démarre et affiche l'accueil", (tester) async {
    // config/example.json ne contient pas de vrai projet : l'app démarre sans Supabase.
    await app.main();

    // Le splash redirige vers /home après 2,2 s.
    await attendre(tester, find.text('Hadiths'));
    expect(find.text('AEEMG'), findsWidgets);
    expect(find.text('Accueil'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
