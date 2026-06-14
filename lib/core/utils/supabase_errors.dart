import 'package:supabase_flutter/supabase_flutter.dart';

/// Messages d'erreur conviviaux en français pour l'utilisateur AEEMG.
String friendlySupabaseError(Object error) {
  if (error is PostgrestException) {
    if (error.code == 'PGRST205') {
      return 'Base de données non initialisée.\n'
          'Exécutez les migrations SQL dans Supabase '
          '(voir docs/SUPABASE_SETUP.md).';
    }
    if (error.code == '42501') {
      return 'Accès refusé. Connectez-vous ou contactez un administrateur.';
    }
    return error.message;
  }

  if (error is AuthException) {
    return friendlyAuthError(error.message);
  }

  return error.toString();
}

String friendlyAuthError(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('unsupported phone provider')) {
    return 'Utilisez la connexion par email (gratuite).';
  }
  if (lower.contains('email not confirmed') ||
      lower.contains('invalid email')) {
    return 'Email non confirmé. Vérifiez votre boîte mail ou désactivez '
        '« Confirm email » dans Supabase → Authentication → Email.';
  }
  if (lower.contains('invalid login credentials')) {
    return 'Email ou mot de passe incorrect.\n\n'
        '• Compte créé par code email ? Connectez-vous via « Code email », '
        'puis Profil → Définir un mot de passe.\n'
        '• Pas de compte ? Cliquez sur « S\'inscrire ».\n'
        '• Inscription récente ? Confirmez votre email si Supabase l\'exige.';
  }
  if (lower.contains('already registered') ||
      lower.contains('user already registered')) {
    return 'Cet email existe déjà. Connectez-vous, ou via « Code email » '
        'puis Profil → Définir un mot de passe.';
  }
  if (lower.contains('signup is disabled')) {
    return 'Inscription désactivée. Activez Email dans Supabase → Authentication.';
  }
  if (lower.contains('invalid otp') || lower.contains('token')) {
    return 'Code OTP invalide. Vérifiez le code reçu par SMS.';
  }
  if (lower.contains('rate limit')) {
    return 'Trop de tentatives. Patientez quelques minutes.';
  }
  return message;
}

bool isMissingTableError(Object error) {
  return error is PostgrestException && error.code == 'PGRST205';
}
