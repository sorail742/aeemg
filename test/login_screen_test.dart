import 'package:aeemg/features/auth/presentation/login_screen.dart';
import 'package:aeemg/shared/widgets/ds/aeemg_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Écran de téléphone (390 × 844) plutôt que la surface de test par défaut.
Future<void> _pump(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: LoginScreen())),
  );
  await tester.pump(const Duration(seconds: 2));
}

/// Démonte l'écran : aucune apparition décalée ne reste en attente.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

TextField _passwordField(WidgetTester tester) => tester.widget<TextField>(
  find.descendant(
    of: find.byType(AeemgPasswordField),
    matching: find.byType(TextField),
  ),
);

void main() {
  testWidgets('Connexion : onglet mot de passe, inscription, code email', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);

    await tester.ensureVisible(find.text("Pas de compte ? S'inscrire"));
    await tester.pump();
    await tester.tap(find.text("Pas de compte ? S'inscrire"));
    await tester.pumpAndSettle();
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Nom complet'), findsOneWidget);

    await tester.ensureVisible(find.text('Code email'));
    await tester.pump();
    await tester.tap(find.text('Code email'));
    await tester.pumpAndSettle();
    expect(find.text('Recevoir le code'), findsOneWidget);
    expect(find.byType(AeemgPasswordField), findsNothing);

    await _dispose(tester);
  });

  testWidgets('Le mot de passe peut être affiché puis masqué', (tester) async {
    await _pump(tester);

    expect(_passwordField(tester).obscureText, isTrue);
    await tester.tap(find.byTooltip('Afficher le mot de passe'));
    await tester.pump();
    expect(_passwordField(tester).obscureText, isFalse);
    await tester.tap(find.byTooltip('Masquer le mot de passe'));
    await tester.pump();
    expect(_passwordField(tester).obscureText, isTrue);

    await _dispose(tester);
  });

  testWidgets('Sans Supabase, la validation explique pourquoi', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(find.text('Se connecter'));
    await tester.pump();
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Supabase non configuré.'), findsOneWidget);

    await _dispose(tester);
  });
}
