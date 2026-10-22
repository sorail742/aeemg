import 'package:aeemg/core/providers/supabase_provider.dart';
import 'package:aeemg/features/messages/presentation/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets(
    'Messages sans session : invitation à se connecter, sans erreur',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseClientProvider.overrideWithValue(null)],
          child: const MaterialApp(home: MessagesScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Groupes réservés aux membres'), findsOneWidget);

      await tester.tap(find.text('Annonces'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      // Démonte l'écran et laisse expirer les délais des apparitions décalées.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
