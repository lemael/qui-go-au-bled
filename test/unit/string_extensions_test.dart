import 'package:flutter_test/flutter_test.dart';
import 'package:qui_go_au_bled/core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions', () {
    group('capitalize', () {
      test('capitalizes first letter', () {
        expect('hello'.capitalize, equals('Hello'));
        expect('HELLO'.capitalize, equals('Hello'));
      });

      test('handles empty string', () {
        expect(''.capitalize, equals(''));
      });
    });

    group('titleCase', () {
      test('converts to title case', () {
        expect('hello world'.titleCase, equals('Hello World'));
      });
    });

    group('initials', () {
      test('returns initials for full name', () {
        expect('Jean Dupont'.initials, equals('JD'));
        expect('Marie'.initials, equals('M'));
      });

      test('handles single word', () {
        expect('Ali'.initials, equals('A'));
      });

      test('handles multiple words', () {
        expect('Jean Paul Dupont'.initials, equals('JD'));
      });
    });

    group('isValidEmail', () {
      test('returns true for valid email', () {
        expect('test@example.com'.isValidEmail, isTrue);
      });

      test('returns false for invalid email', () {
        expect('notanemail'.isValidEmail, isFalse);
      });
    });

    group('truncate', () {
      test('truncates long strings', () {
        const text = 'Hello World Flutter';
        expect(text.truncate(10), equals('Hello Worl...'));
      });

      test('does not truncate short strings', () {
        const text = 'Short';
        expect(text.truncate(10), equals('Short'));
      });
    });
  });

  group('NullableStringExtension', () {
    test('isNullOrEmpty returns true for null', () {
      String? value;
      expect(value.isNullOrEmpty, isTrue);
    });

    test('isNullOrEmpty returns true for empty string', () {
      expect(''.isNullOrEmpty, isTrue);
    });

    test('isNullOrEmpty returns false for non-empty string', () {
      expect('hello'.isNullOrEmpty, isFalse);
    });
  });
}
