import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:qui_go_au_bled/core/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'fr_FR';
    await initializeDateFormatting('fr_FR');
  });

  group('DateFormatter', () {
    final date = DateTime(2025, 6, 15, 14, 30);

    test('formatDate retourne dd/MM/yyyy', () {
      expect(DateFormatter.formatDate(date), equals('15/06/2025'));
    });

    test('formatDateTime retourne dd/MM/yyyy à HH:mm', () {
      expect(DateFormatter.formatDateTime(date), equals('15/06/2025 à 14:30'));
    });

    test('formatTime retourne HH:mm', () {
      expect(DateFormatter.formatTime(date), equals('14:30'));
    });

    test('formatMonthYear retourne mois année en français', () {
      final result = DateFormatter.formatMonthYear(date);
      expect(result, equals('juin 2025'));
    });

    test('toIso retourne format ISO sans fuseau', () {
      expect(DateFormatter.toIso(date), equals('2025-06-15T14:30:00'));
    });

    test('relativeTime — à l\'instant (< 60s)', () {
      final now = DateTime.now().subtract(const Duration(seconds: 10));
      expect(DateFormatter.relativeTime(now), equals('À l\'instant'));
    });

    test('relativeTime — minutes', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      expect(DateFormatter.relativeTime(past), equals('Il y a 5 min'));
    });

    test('relativeTime — heures', () {
      final past = DateTime.now().subtract(const Duration(hours: 3));
      expect(DateFormatter.relativeTime(past), equals('Il y a 3h'));
    });

    test('relativeTime — jours', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      expect(DateFormatter.relativeTime(past), equals('Il y a 2j'));
    });

    test('isUpcoming — date future', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(DateFormatter.isUpcoming(future), isTrue);
    });

    test('isPast — date passée', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.isPast(past), isTrue);
    });
  });
}
