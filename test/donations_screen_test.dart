import 'package:aeemg/features/auth/presentation/providers/auth_provider.dart';
import 'package:aeemg/features/donations/data/donations_repository.dart';
import 'package:aeemg/features/donations/presentation/donations_screen.dart';
import 'package:aeemg/features/donations/presentation/providers/donations_providers.dart';
import 'package:aeemg/features/donations/presentation/widgets/donation_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeDonationsRepository extends DonationsRepository {
  _FakeDonationsRepository() : super(null);

  @override
  Future<List<DonationCampaign>> fetchCampaigns() async => const [
    DonationCampaign(
      id: 'c1',
      title: 'Collecte Ramadan',
      description: 'Paniers alimentaires pour les étudiants.',
      category: 'ramadan',
      goalAmount: 1000000,
      raisedAmount: 250000,
      isActive: true,
    ),
  ];

  @override
  Future<List<DonationRecord>> fetchMyDonations(String userId) async => [];

  @override
  Future<String> createDonation({
    required String userId,
    required double amount,
    required String category,
    String? campaignId,
    bool isAnonymous = false,
  }) async => throw const PostgrestException(
    message: 'permission denied for table donations',
    code: '42501',
  );
}

final _member = User(
  id: 'u1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

Future<void> _pump(WidgetTester tester, {User? user}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        donationsRepositoryProvider.overrideWithValue(
          _FakeDonationsRepository(),
        ),
        currentUserProvider.overrideWithValue(user),
      ],
      child: const MaterialApp(home: DonationsScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

/// Démonte l'écran : aucune apparition décalée ne reste en attente.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets(
    'Hors connexion : campagnes visibles, dons proposés après connexion',
    (tester) async {
      await _pump(tester);

      expect(find.text('Faire un don'), findsOneWidget);
      expect(find.text('Collecte Ramadan'), findsOneWidget);
      expect(find.text('25 %'), findsOneWidget);
      expect(find.text('Connectez-vous pour donner.'), findsOneWidget);
      expect(find.text('Connectez-vous pour contribuer.'), findsOneWidget);

      await tester.tap(find.text('Mes dons'));
      await tester.pumpAndSettle();
      expect(
        find.text('Connectez-vous pour voir votre historique de dons.'),
        findsOneWidget,
      );

      await _dispose(tester);
    },
  );

  testWidgets(
    "Échec du paiement : message compréhensible, jamais l'erreur brute (REL-008)",
    (tester) async {
      await _pump(tester, user: _member);

      final firstAmount = find.descendant(
        of: find.byType(QuickDonateCard),
        matching: find.byType(InkWell),
      );
      await tester.tap(firstAmount.first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '+224620000000');
      await tester.tap(find.text('Payer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('Paiement impossible : Accès refusé.'),
        findsOneWidget,
      );
      expect(find.textContaining('permission denied'), findsNothing);

      await _dispose(tester);
    },
  );
}
