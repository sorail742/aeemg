import 'package:aeemg/core/router/route_guard.dart';
import 'package:aeemg/shared/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

MemberProfile _profil(String role) => MemberProfile.fromJson({
  'id': '00000000-0000-0000-0000-000000000001',
  'full_name': 'Test',
  'role': role,
  'created_at': '2026-10-14T00:00:00Z',
});

String? _guard(
  String location, {
  bool connecte = false,
  String? role,
  bool profilCharge = true,
}) => guardRedirect(
  uri: Uri.parse(location),
  isAuthenticated: connecte,
  profile: role == null ? null : _profil(role),
  profileLoaded: profilCharge,
);

void main() {
  group('accessFor', () {
    test('routes publiques', () {
      for (final path in [
        '/',
        '/home',
        '/social',
        '/agenda',
        '/quran/surah/2',
        '/profile',
      ]) {
        expect(accessFor(path), RouteAccess.public, reason: path);
      }
    });

    test('routes authentifiées', () {
      for (final path in [
        '/members',
        '/profile/edit',
        '/profile/password',
        '/notifications/settings',
        '/messages/chat/abc',
        '/donations',
        '/finance',
        '/feedback',
        '/social/create',
      ]) {
        expect(accessFor(path), RouteAccess.authenticated, reason: path);
      }
    });

    test('routes staff', () {
      expect(accessFor('/admin'), RouteAccess.staff);
      expect(accessFor('/administration'), RouteAccess.public);
    });
  });

  group('guardRedirect (SEC-024)', () {
    test('visiteur sur une route publique : passe', () {
      expect(_guard('/home'), isNull);
    });

    test('visiteur sur une route authentifiée : connexion avec retour', () {
      expect(_guard('/finance'), '/login?from=%2Ffinance');
      expect(_guard('/profile/edit'), '/login?from=%2Fprofile%2Fedit');
    });

    test('visiteur sur /admin : connexion avec retour', () {
      expect(_guard('/admin'), '/login?from=%2Fadmin');
    });

    test('membre connecté sur une route authentifiée : passe', () {
      expect(_guard('/finance', connecte: true, role: 'member'), isNull);
    });

    test('membre non staff sur /admin : accueil', () {
      for (final role in ['member', 'volunteer', 'treasurer', 'visitor']) {
        expect(
          _guard('/admin', connecte: true, role: role),
          '/home',
          reason: role,
        );
      }
    });

    test('staff sur /admin : passe', () {
      for (final role in [
        'super_admin',
        'admin',
        'moderator',
        'section_lead',
      ]) {
        expect(
          _guard('/admin', connecte: true, role: role),
          isNull,
          reason: role,
        );
      }
    });

    test('profil en cours de chargement : pas de redirection prématurée', () {
      expect(_guard('/admin', connecte: true, profilCharge: false), isNull);
    });

    test('connecté sur /login : retour à la page demandée ou au profil', () {
      expect(_guard('/login?from=%2Ffinance', connecte: true), '/finance');
      expect(_guard('/login', connecte: true), '/profile');
      expect(_guard('/login'), isNull);
    });
  });

  group('safeReturnPath', () {
    test('refuse les URL externes et /login', () {
      expect(safeReturnPath('https://exemple.com'), isNull);
      expect(safeReturnPath('//exemple.com/admin'), isNull);
      expect(safeReturnPath('/login?from=/admin'), isNull);
      expect(safeReturnPath(null), isNull);
      expect(safeReturnPath('/messages/chat/1'), '/messages/chat/1');
    });
  });

  group('GoRouter avec la garde', () {
    Future<GoRouter> lancer(
      WidgetTester tester, {
      required bool connecte,
      String? role,
      required String location,
    }) async {
      Widget page(String nom) => Scaffold(body: Text(nom));
      final router = GoRouter(
        initialLocation: location,
        redirect: (context, state) => guardRedirect(
          uri: state.uri,
          isAuthenticated: connecte,
          profile: role == null ? null : _profil(role),
          profileLoaded: true,
        ),
        routes: [
          for (final path in [
            '/home',
            '/login',
            '/admin',
            '/finance',
            '/profile',
          ])
            GoRoute(path: path, builder: (_, _) => page(path)),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('visiteur sur /admin → écran de connexion', (tester) async {
      final router = await lancer(tester, connecte: false, location: '/admin');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
      expect(find.text('/login'), findsOneWidget);
    });

    testWidgets('membre sur /admin → accueil', (tester) async {
      final router = await lancer(
        tester,
        connecte: true,
        role: 'member',
        location: '/admin',
      );
      expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    });

    testWidgets('admin sur /admin → écran admin', (tester) async {
      final router = await lancer(
        tester,
        connecte: true,
        role: 'admin',
        location: '/admin',
      );
      expect(router.routerDelegate.currentConfiguration.uri.path, '/admin');
    });

    testWidgets(
      'visiteur sur /finance → connexion, puis retour après connexion',
      (tester) async {
        final visiteur = await lancer(
          tester,
          connecte: false,
          location: '/finance',
        );
        final login = visiteur.routerDelegate.currentConfiguration.uri;
        expect(login.path, '/login');
        final connecte = await lancer(
          tester,
          connecte: true,
          location: login.toString(),
        );
        expect(
          connecte.routerDelegate.currentConfiguration.uri.path,
          '/finance',
        );
      },
    );
  });
}
