import 'package:aeemg/core/providers/supabase_provider.dart';
import 'package:aeemg/features/social/data/social_repository.dart';
import 'package:aeemg/features/social/presentation/feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Sans Supabase, le fil affiche un état vide au lieu de planter (écran gris)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseClientProvider.overrideWithValue(null)],
          child: const MaterialApp(home: FeedScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      // Indépendant du libellé exact de l'écran (refonte AMEL-027 en cours).
      expect(find.textContaining('Aucune publication'), findsOneWidget);
    },
  );

  test('Sans Supabase, les écritures lèvent une erreur lisible', () async {
    final repo = SocialRepository(null);
    expect(await repo.fetchFeed(), isEmpty);
    expect(await repo.fetchComments('x'), isEmpty);
    expect(
      () => repo.likePost('x'),
      throwsA(
        isA<SocialUnavailableException>().having(
          (e) => e.toString(),
          'message',
          contains('indisponible'),
        ),
      ),
    );
  });
}
