import 'package:aeemg/shared/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

// Matrice rôles × helpers (ADR-0008, SEC-021). Doit rester identique au test pgTAP
// supabase/tests/006_sec021_matrice_roles.test.sql : (is_staff, is_admin, is_treasurer).
const _matrice = <String, (bool, bool, bool)>{
  'super_admin': (true, true, true),
  'admin': (true, true, true),
  'moderator': (true, false, false),
  'treasurer': (false, false, true),
  'section_lead': (true, false, false),
  'member': (false, false, false),
  'volunteer': (false, false, false),
  'visitor': (false, false, false),
};

MemberProfile _profil(String role) => MemberProfile.fromJson({
  'id': '00000000-0000-0000-0000-000000000001',
  'full_name': 'Test',
  'role': role,
  'created_at': '2026-10-13T00:00:00Z',
});

void main() {
  for (final MapEntry(key: role, value: (staff, admin, tresorier))
      in _matrice.entries) {
    test('$role : isStaff=$staff, isAdmin=$admin, isTreasurer=$tresorier', () {
      final p = _profil(role);
      expect(p.isStaff, staff);
      expect(p.isAdmin, admin);
      expect(p.isTreasurer, tresorier);
    });
  }

  test('le rôle déprécié staff ne donne aucun droit', () {
    final p = _profil('staff');
    expect(p.isStaff, isFalse);
    expect(p.isAdmin, isFalse);
    expect(p.isTreasurer, isFalse);
  });
}
