import 'package:aeemg/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sans --dart-define, la configuration est vide et non utilisable', () {
    // Les tests ne passent pas de --dart-define-from-file : aucune valeur
    // ne doit provenir d'un fichier embarqué (SEC-019).
    expect(Env.supabaseUrl, isEmpty);
    expect(Env.supabaseAnonKey, isEmpty);
    expect(Env.appEnv, 'dev');
    expect(Env.isConfigured, isFalse);
  });
}
