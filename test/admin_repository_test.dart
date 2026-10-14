import 'package:aeemg/features/admin/data/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AdminRepository.deletionErrorMessage (SEC-023)', () {
    test('reprend le message de refus de admin-delete-user', () {
      const e = FunctionException(
        status: 403,
        details: {
          'error': 'Seul un super_admin peut supprimer un administrateur',
        },
      );
      expect(
        AdminRepository.deletionErrorMessage(e),
        'Seul un super_admin peut supprimer un administrateur',
      );
    });

    test('message générique si la réponse ne contient pas d\'erreur', () {
      const e = FunctionException(
        status: 500,
        details: 'Internal Server Error',
      );
      expect(
        AdminRepository.deletionErrorMessage(e),
        'Suppression impossible (erreur 500).',
      );
    });
  });
}
