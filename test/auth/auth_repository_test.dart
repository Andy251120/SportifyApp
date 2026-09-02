import 'package:flutter_test/flutter_test.dart';
import 'package:sport_super_app/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository.normalizeVietnamPhone', () {
    test('0-prefixed -> +84', () {
      expect(AuthRepository.normalizeVietnamPhone('0912 345 678'),
          '+84912345678');
    });
    test('84-prefixed -> +84', () {
      expect(AuthRepository.normalizeVietnamPhone('84912345678'), '+84912345678');
    });
    test('already E.164 unchanged', () {
      expect(
          AuthRepository.normalizeVietnamPhone('+84912345678'), '+84912345678');
    });
    test('strips separators', () {
      expect(AuthRepository.normalizeVietnamPhone('090-123-4567'),
          '+84901234567');
    });
  });
}
