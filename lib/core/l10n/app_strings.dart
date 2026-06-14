/// Chaînes FR / Peul (FF) — Phase 4.
abstract final class AppStrings {
  static String t(String key, String locale) {
    final map = locale == 'ff' ? _ff : _fr;
    return map[key] ?? _fr[key] ?? key;
  }

  static const _fr = {
    'nav_home': 'Accueil',
    'nav_social': 'Social',
    'nav_agenda': 'Agenda',
    'nav_messages': 'Messages',
    'nav_mosque': 'Mosquée',
    'nav_profile': 'Profil',
    'settings': 'Paramètres',
    'language': 'Langue',
    'offline_mode': 'Mode hors ligne',
    'offline_hint': 'Verset, événement et annonces en cache',
    'admin': 'Administration',
    'beta_feedback': 'Retours beta',
    'orange_money': 'Orange Money',
    'add_calendar': 'Ajouter au calendrier',
  };

  static const _ff = {
    'nav_home': 'Fuɗɗorde',
    'nav_social': 'Social',
    'nav_agenda': 'Kalander',
    'nav_messages': 'Ɓeydu',
    'nav_mosque': 'Misiji',
    'nav_profile': 'Profil',
    'settings': 'Teelte',
    'language': 'Ɗemngal',
    'offline_mode': 'Offline',
    'offline_hint': 'Aya, event e sanne cache',
    'admin': 'Admin',
    'beta_feedback': 'Beta feedback',
    'orange_money': 'Orange Money',
    'add_calendar': 'Ɓeydu e kalander',
  };
}
