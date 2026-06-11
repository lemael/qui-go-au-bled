import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final DateFormat _dateTimeFormat =
      DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'fr_FR');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'fr_FR');
  static final DateFormat _isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss", 'fr_FR');

  static String formatDate(DateTime date) => _dateFormat.format(date);

  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime);

  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

  static String formatMonthYear(DateTime date) =>
      _monthYearFormat.format(date);

  static String toIso(DateTime dateTime) => _isoFormat.format(dateTime);

  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return 'À l\'instant';
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    }
    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    }
    return formatDate(dateTime);
  }

  static bool isUpcoming(DateTime date) => date.isAfter(DateTime.now());

  static bool isPast(DateTime date) => date.isBefore(DateTime.now());
}
