import 'package:aeemg/core/utils/supabase_errors.dart';
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

  group('AuthRepository.validatePassword (SEC-022)', () {
    test('accepte 10 caractères avec lettres et chiffres', () {
      expect(
        () => AuthRepository.validatePassword('aeemg2026x'),
        returnsNormally,
      );
    });

    test('rejette moins de 10 caractères', () {
      expect(
        () => AuthRepository.validatePassword('secret12'),
        throwsA(isA<AuthException>()),
      );
    });

    test('rejette un mot de passe sans chiffre', () {
      expect(
        () => AuthRepository.validatePassword('motdepasselong'),
        throwsA(isA<AuthException>()),
      );
    });

    test('rejette un mot de passe sans lettre', () {
      expect(
        () => AuthRepository.validatePassword('1234567890'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('friendlyAuthError (SEC-022)', () {
    test('mot de passe refusé par le serveur', () {
      expect(
        friendlyAuthError('Password should be at least 10 characters.'),
        contains('10 caractères'),
      );
      expect(
        friendlyAuthError(
          'Password is known to be weak and easy to guess, please choose a different one.',
        ),
        contains('trop faible'),
      );
    });

    test(
      'email non confirmé : ne conseille plus de désactiver la confirmation',
      () {
        final message = friendlyAuthError('Email not confirmed');
        expect(message, contains('lien reçu'));
        expect(message, isNot(contains('désactivez')));
      },
    );
  });
}
