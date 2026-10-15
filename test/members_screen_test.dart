import 'package:aeemg/features/auth/presentation/providers/auth_provider.dart';
import 'package:aeemg/features/members/data/members_repository.dart';
import 'package:aeemg/features/members/presentation/members_screen.dart';
import 'package:aeemg/features/members/presentation/providers/members_provider.dart';
import 'package:aeemg/features/notifications/presentation/notifications_screen.dart';
import 'package:aeemg/shared/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMembersRepository extends MembersRepository {
  _FakeMembersRepository(this.members) : super(null);

  final List<MemberProfile> members;
  final queries = <String?>[];

  @override
  Future<List<MemberProfile>> fetchMembers({String? sectionQuery}) async {
    queries.add(sectionQuery);
    if (sectionQuery == null) return members;
    return members
        .where((m) => (m.section ?? '').contains(sectionQuery))
        .toList();
  }
}

MemberProfile _member(String name, {String? section, String role = 'member'}) =>
    MemberProfile(
      id: name,
      fullName: name,
      section: section,
      role: role,
      isProfilePublic: true,
      createdAt: DateTime(2026),
    );

Future<void> _pump(WidgetTester tester, Widget screen, List overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
}

/// Démonte l'écran : aucune apparition décalée ne reste en attente.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('Annuaire : nombre de membres, rôles et filtre par section', (
    tester,
  ) async {
    final repo = _FakeMembersRepository([
      _member('Aïssatou Bah', section: 'Conakry', role: 'treasurer'),
      _member('Mamadou Diallo', section: 'Labé'),
    ]);
    await _pump(tester, const MembersScreen(), [
      membersRepositoryProvider.overrideWithValue(repo),
    ]);

    expect(find.text('2 membres'), findsOneWidget);
    expect(find.text('Aïssatou Bah'), findsOneWidget);
    expect(find.text('Trésorier'), findsOneWidget);
    expect(find.text('Membre'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Labé');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(repo.queries.last, 'Labé');
    expect(find.text('1 membre'), findsOneWidget);
    expect(find.text('Aïssatou Bah'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Kindia');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Aucun résultat pour « Kindia ».'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('Notifications hors connexion : invitation à se connecter', (
    tester,
  ) async {
    await _pump(tester, const NotificationsScreen(), [
      currentUserProvider.overrideWithValue(null),
    ]);

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byTooltip('Préférences'), findsOneWidget);

    await _dispose(tester);
  });
}
