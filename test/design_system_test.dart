import 'package:aeemg/shared/widgets/ds/aeemg_motion.dart';
import 'package:aeemg/shared/widgets/ds/aeemg_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: child),
  ),
);

const _items = [
  AeemgNavItem(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Accueil',
  ),
  AeemgNavItem(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: 'Profil',
  ),
];

void main() {
  testWidgets('AeemgNavBar : appui sur un onglet et état sélectionné annoncé', (
    tester,
  ) async {
    int? tapped;
    await tester.pumpWidget(
      _app(
        AeemgNavBar(items: _items, currentIndex: 0, onTap: (i) => tapped = i),
      ),
    );

    await tester.tap(find.text('Profil'));
    expect(tapped, 1);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Accueil')),
      isSemantics(isButton: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Profil')),
      isSemantics(isButton: true, isSelected: false),
    );
  });

  testWidgets("AeemgPressable ne bloque pas l'appui de l'enfant", (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        AeemgPressable(
          child: TextButton(onPressed: () => taps++, child: const Text('OK')),
        ),
      ),
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('reveal et squelette : aucune animation si elles sont réduites', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Column(
            children: [
              const Text('Contenu').reveal(context, index: 3),
              const AeemgSkeleton(width: 100),
            ],
          ),
        ),
        reduceMotion: true,
      ),
    );

    expect(find.byType(Animate), findsNothing);
    expect(find.text('Contenu'), findsOneWidget);
  });

  testWidgets('reveal anime le contenu sinon', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(builder: (context) => const Text('Contenu').reveal(context)),
      ),
    );

    expect(find.byType(Animate), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Contenu'), findsOneWidget);
  });
}
