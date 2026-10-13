import 'package:aeemg/core/utils/phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeE164', () {
    test('conserve un numéro déjà au format E.164', () {
      expect(normalizeE164('+224620000000'), '+224620000000');
    });

    test('retire espaces, points, tirets et parenthèses', () {
      expect(normalizeE164(' +224 (620) 00-00.00 '), '+224620000000');
    });

    test('convertit le préfixe international 00', () {
      expect(normalizeE164('00224620000000'), '+224620000000');
    });

    test('refuse un numéro sans indicatif pays', () {
      expect(normalizeE164('620 00 00 00'), isNull);
    });

    test('refuse un numéro trop court, trop long ou non numérique', () {
      expect(normalizeE164('+2246'), isNull);
      expect(normalizeE164('+2246200000000000'), isNull);
      expect(normalizeE164('+22462000abc'), isNull);
      expect(normalizeE164('+0224620000000'), isNull);
      expect(normalizeE164(''), isNull);
    });
  });
}
