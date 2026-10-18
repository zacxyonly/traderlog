import 'package:flutter_test/flutter_test.dart';
import 'package:traderlog/services/update_service.dart';

void main() {
  group('UpdateService.compareVersions', () {
    test('newer minor version is greater', () {
      expect(UpdateService.compareVersions('1.1.0', '1.0.0'), greaterThan(0));
    });

    test('same version is equal, build number ignored', () {
      expect(UpdateService.compareVersions('1.1.0+2', '1.1.0'), 0);
    });

    test('compares numerically, not as text', () {
      expect(UpdateService.compareVersions('1.10.0', '1.9.0'), greaterThan(0));
    });

    test('older version is smaller', () {
      expect(UpdateService.compareVersions('1.0.0', '1.1.0'), lessThan(0));
    });

    test('missing segments count as zero', () {
      expect(UpdateService.compareVersions('2', '1.9.9'), greaterThan(0));
    });
  });
}
