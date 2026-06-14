import 'package:aeemg/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthRepository.normalizeEmail', () {
    test('accepte un email valide', () {
      expect(
        AuthRepository.normalizeEmail('  Membre@AEEMG.org  '),
        'membre@aeemg.org',
      );
    });

    test('rejette un email invalide', () {
      expect(
        () => AuthRepository.normalizeEmail('pas-un-email'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthRepository.validatePassword', () {
    test('accepte un mot de passe valide', () {
      expect(() => AuthRepository.validatePassword('secret1'), returnsNormally);
    });

    test('rejette un mot de passe trop court', () {
      expect(
        () => AuthRepository.validatePassword('123'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
