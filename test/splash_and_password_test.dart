import 'package:aeemg/features/auth/presentation/set_password_screen.dart';
import 'package:aeemg/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _splashApp({bool reduceMotion = false}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/home', builder: (_, _) => const Text('Accueil')),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
  );
}

void main() {
  testWidgets("Splash : logo et nom, puis l'accueil après 2,2 s", (
    tester,
  ) async {
    await tester.pumpWidget(_splashApp());
    await tester.pump();

    expect(find.text('A E E M G'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.bySemanticsLabel('Chargement'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Accueil'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets('Splash avec animations réduites : accueil après 0,6 s', (
    tester,
  ) async {
    await tester.pumpWidget(_splashApp(reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets('Mot de passe : la confirmation doit correspondre', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SetPasswordScreen())),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(
      find.text('Au moins 10 caractères, avec des lettres et des chiffres.'),
      findsOneWidget,
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'motdepasse123');
    await tester.enterText(fields.at(1), 'motdepasse124');
    await tester.ensureVisible(find.text('Enregistrer le mot de passe'));
    await tester.pump();
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pump();

    expect(
      find.text('Les mots de passe ne correspondent pas.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
