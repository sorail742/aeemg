/// Configuration publique de l'application, injectée à la compilation
/// (ADR-0009, SEC-019) :
///
/// ```bash
/// flutter run --dart-define-from-file=config/dev.json
/// ```
///
/// Aucune valeur n'est lue d'un fichier embarqué dans l'application. Seules
/// des valeurs publiques peuvent figurer ici (URL et clé anon/publishable
/// Supabase) : les secrets restent dans les Edge Functions.
class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// `dev`, `staging` ou `prod`.
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('placeholder') &&
      !supabaseUrl.contains('votre-projet');
}
