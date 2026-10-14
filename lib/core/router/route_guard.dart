import '../../shared/models/profile.dart';

/// Niveau d'accès d'une route (SEC-024). Défense en profondeur : la RLS reste la vraie
/// barrière, la garde évite d'afficher des écrans inutilisables (accès par URL sur le web).
enum RouteAccess { public, authenticated, staff }

const _authenticatedPrefixes = [
  '/members',
  '/profile/edit',
  '/profile/password',
  '/notifications',
  '/messages',
  '/donations',
  '/finance',
  '/feedback',
  '/social/create',
];

const _staffPrefixes = ['/admin'];

bool _matches(String path, String prefix) =>
    path == prefix || path.startsWith('$prefix/');

RouteAccess accessFor(String path) {
  if (_staffPrefixes.any((p) => _matches(path, p))) return RouteAccess.staff;
  if (_authenticatedPrefixes.any((p) => _matches(path, p))) {
    return RouteAccess.authenticated;
  }
  return RouteAccess.public;
}

/// Chemin de retour après connexion : uniquement un chemin interne (pas d'URL externe,
/// pas de `//hôte`), jamais `/login` lui-même.
String? safeReturnPath(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  if (_matches(Uri.parse(from).path, '/login')) return null;
  return from;
}

/// Redirection à appliquer, ou null pour laisser passer.
///
/// [profileLoaded] est faux tant que le profil se charge : les routes staff ne sont pas
/// redirigées pendant ce temps (l'écran affiche son chargement), puis la garde est
/// réévaluée dès que le profil arrive.
String? guardRedirect({
  required Uri uri,
  required bool isAuthenticated,
  required MemberProfile? profile,
  required bool profileLoaded,
}) {
  final path = uri.path;

  if (_matches(path, '/login')) {
    if (!isAuthenticated) return null;
    return safeReturnPath(uri.queryParameters['from']) ?? '/profile';
  }

  final access = accessFor(path);
  if (access == RouteAccess.public) return null;

  if (!isAuthenticated) {
    return Uri(
      path: '/login',
      queryParameters: {'from': uri.toString()},
    ).toString();
  }

  if (access == RouteAccess.staff &&
      profileLoaded &&
      !(profile?.isStaff ?? false)) {
    return '/home';
  }
  return null;
}
