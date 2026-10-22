import 'package:aeemg/shared/widgets/ds/aeemg_avatar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AeemgAvatar : initiales et couleur stable pour un même nom', () {
    expect(AeemgAvatar.initialsOf('Mamadou Diallo'), 'MD');
    expect(AeemgAvatar.initialsOf('  awa  '), 'A');
    expect(AeemgAvatar.initialsOf(''), '?');
    expect(
      AeemgAvatar.colorFor('Mamadou Diallo'),
      AeemgAvatar.colorFor('Mamadou Diallo'),
    );
  });
}
