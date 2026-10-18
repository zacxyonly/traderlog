import 'package:flutter_test/flutter_test.dart';
import 'package:traderlog/models/app_settings.dart';
import 'package:traderlog/utils/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('hash never contains the PIN and verifies correctly', () {
      final h = PinHasher.hash('1234');
      expect(h.startsWith('v1:'), true);
      expect(h.contains('1234'), false);
      expect(PinHasher.verify('1234', h), true);
      expect(PinHasher.verify('1235', h), false);
      expect(PinHasher.verify('', h), false);
    });

    test('same PIN produces different hashes (random salt)', () {
      expect(PinHasher.hash('0000'), isNot(PinHasher.hash('0000')));
    });

    test('fixed salt is deterministic', () {
      final salt = List<int>.generate(16, (i) => i);
      expect(PinHasher.hash('4321', salt: salt), PinHasher.hash('4321', salt: salt));
    });

    test('legacy plaintext values still verify and are detected', () {
      expect(PinHasher.isHashed('1234'), false);
      expect(PinHasher.verify('1234', '1234'), true);
      expect(PinHasher.verify('9999', '1234'), false);

      final legacy = AppSettings.fromDatabaseMap({'pin_code': '1234'});
      expect(legacy.isPinSet, true);
      expect(legacy.hasLegacyPlainPin, true);

      final migrated = legacy.copyWith(pinHash: PinHasher.hash('1234'));
      expect(migrated.hasLegacyPlainPin, false);
      expect(PinHasher.verify('1234', migrated.pinHash), true);
    });

    test('malformed or empty stored values never verify', () {
      expect(PinHasher.verify('1234', null), false);
      expect(PinHasher.verify('1234', ''), false);
      expect(PinHasher.verify('1234', 'v1:onlytwo'), false);
      expect(PinHasher.verify('1234', 'v1:!!!:???'), false);
    });

    test('database map stores the hash under the existing pin_code key', () {
      final s = AppSettings(pinHash: PinHasher.hash('2468'));
      final map = s.toDatabaseMap();
      expect(map['pin_code'], s.pinHash);
      expect(map['pin_code']!.contains('2468'), false);
    });
  });
}
