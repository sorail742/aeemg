import 'package:aeemg/core/services/adhan_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdhanService.exactOrInexact (SEC-025)', () {
    test('alarme exacte quand l\'utilisateur l\'a autorisée', () {
      expect(
        AdhanService.exactOrInexact(true),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    });

    test('repli sur une alarme approximative sinon, sans échec', () {
      expect(
        AdhanService.exactOrInexact(false),
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });
  });
}
