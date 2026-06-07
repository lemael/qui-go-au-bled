import 'package:flutter_test/flutter_test.dart';
import 'package:qui_go_au_bled/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('returns null for valid email', () {
        expect(Validators.email('test@example.com'), isNull);
        expect(Validators.email('user.name+tag@domain.co'), isNull);
      });

      test('returns error for empty email', () {
        expect(Validators.email(''), isNotNull);
        expect(Validators.email(null), isNotNull);
      });

      test('returns error for invalid email format', () {
        expect(Validators.email('notanemail'), isNotNull);
        expect(Validators.email('@domain.com'), isNotNull);
        expect(Validators.email('user@'), isNotNull);
      });
    });

    group('password', () {
      test('returns null for valid password', () {
        expect(Validators.password('MyPass123'), isNull);
        expect(Validators.password('abcdefgh'), isNull);
      });

      test('returns error for short password', () {
        expect(Validators.password('short'), isNotNull);
        expect(Validators.password('1234567'), isNotNull);
      });

      test('returns error for empty password', () {
        expect(Validators.password(''), isNotNull);
        expect(Validators.password(null), isNotNull);
      });
    });

    group('confirmPassword', () {
      test('returns null when passwords match', () {
        expect(Validators.confirmPassword('MyPass123', 'MyPass123'), isNull);
      });

      test('returns error when passwords do not match', () {
        expect(
          Validators.confirmPassword('MyPass123', 'DifferentPass'),
          isNotNull,
        );
      });
    });

    group('phone', () {
      test('returns null for valid phone', () {
        expect(Validators.phone('+33612345678'), isNull);
        expect(Validators.phone('0612345678'), isNull);
        expect(Validators.phone('+213555123456'), isNull);
      });

      test('returns error for invalid phone', () {
        expect(Validators.phone('abc'), isNotNull);
        expect(Validators.phone('123'), isNotNull);
      });
    });

    group('weight', () {
      test('returns null for valid weight', () {
        expect(Validators.weight('20'), isNull);
        expect(Validators.weight('0.5'), isNull);
        expect(Validators.weight('50'), isNull);
      });

      test('returns error for weight > 50', () {
        expect(Validators.weight('51'), isNotNull);
        expect(Validators.weight('100'), isNotNull);
      });

      test('returns error for zero or negative weight', () {
        expect(Validators.weight('0'), isNotNull);
        expect(Validators.weight('-5'), isNotNull);
      });

      test('returns error for non-numeric weight', () {
        expect(Validators.weight('abc'), isNotNull);
      });
    });

    group('price', () {
      test('returns null for valid price', () {
        expect(Validators.price('5'), isNull);
        expect(Validators.price('10.5'), isNull);
      });

      test('returns error for zero or negative price', () {
        expect(Validators.price('0'), isNotNull);
        expect(Validators.price('-1'), isNotNull);
      });
    });
  });
}
