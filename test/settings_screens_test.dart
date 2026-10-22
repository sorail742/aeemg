import 'package:aeemg/core/providers/offline_cache_provider.dart';
import 'package:aeemg/features/auth/presentation/providers/auth_provider.dart';
import 'package:aeemg/features/notifications/presentation/notification_settings_screen.dart';
import 'package:aeemg/features/settings/presentation/settings_screen.dart';
import 'package:aeemg/shared/widgets/ds/aeemg_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Laisse finir les apparitions décalées, puis démonte l'écran (aucun minuteur en attente).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('AeemgSwitchTile : un appui sur le titre bascule la valeur', (
    tester,
  ) async {
    bool? changed;
    await tester.pumpWidget(
      _app(
        AeemgSwitchTile(
          icon: Icons.sms_outlined,
          title: 'SMS de secours',
          value: false,
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.text('SMS de secours'));
    expect(changed, isTrue);
    expect(
      tester.getSemantics(find.byType(AeemgSwitchTile)),
      isSemantics(label: 'SMS de secours', hasToggledState: true),
    );
  });

  testWidgets('AeemgSwitchTile désactivé : aucun changement', (tester) async {
    await tester.pumpWidget(
      _app(
        const AeemgSwitchTile(
          icon: Icons.sms_outlined,
          title: 'SMS de secours',
          value: true,
          onChanged: null,
        ),
      ),
    );

    await tester.tap(find.text('SMS de secours'));
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  testWidgets('AeemgSegmented : choix annoncé et appui sur un autre segment', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      _app(
        AeemgSegmented<String>(
          options: const [('fr', 'Français'), ('ff', 'Peul')],
          selected: 'fr',
          onChanged: (v) => picked = v,
        ),
      ),
    );

    await tester.tap(find.text('Français'));
    expect(picked, isNull, reason: 'le segment actif ne renvoie rien');
    await tester.tap(find.text('Peul'));
    expect(picked, 'ff');
    expect(
      tester.getSemantics(find.text('Français')),
      isSemantics(label: 'Français', isButton: true, isSelected: true),
    );
  });

  testWidgets(
    'Paramètres hors connexion : langue et hors ligne, sans alertes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUserProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await _settle(tester);

      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('Actif'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(find.text('SMS de secours'), findsNothing);

      await tester.tap(find.text('Peul'));
      await _settle(tester);
      expect(prefs.getString('app_locale'), 'ff');
      expect(find.text('Teelte'), findsOneWidget);

      await _dispose(tester);
    },
  );

  testWidgets(
    'Préférences d\'alertes hors connexion : invitation à se connecter',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserProvider.overrideWithValue(null)],
          child: const MaterialApp(home: NotificationSettingsScreen()),
        ),
      );
      await _settle(tester);

      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.byType(AeemgSwitchTile), findsNothing);

      await _dispose(tester);
    },
  );
}
