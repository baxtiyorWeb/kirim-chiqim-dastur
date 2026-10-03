import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static const List<String> uzbekMonths = [
    'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
    'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr'
  ];

  static const List<String> uzbekMonthsShort = [
    'yan', 'fev', 'mar', 'apr', 'may', 'iyn',
    'iyl', 'avg', 'sent', 'okt', 'noy', 'dek'
  ];

  /// Returns e.g. "Bugun, 08:42" or "Kecha, 17:20" or "22-sent, 16:45"
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final timeStr = DateFormat('HH:mm').format(dateTime);

    final differenceInDays = today.difference(itemDate).inDays;

    if (differenceInDays == 0) {
      return 'Bugun, $timeStr';
    } else if (differenceInDays == 1) {
      return 'Kecha, $timeStr';
    } else {
      final monthName = uzbekMonthsShort[dateTime.month - 1];
      return '${dateTime.day}-$monthName, $timeStr';
    }
  }

  /// Returns e.g. "Bugun, 24-sent 2025" or "24-sentabr 2025"
  static String formatDateWithPrefix(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
    final monthName = uzbekMonthsShort[dateTime.month - 1];

    if (isToday) {
      return 'Bugun, ${dateTime.day}-$monthName ${dateTime.year}';
    } else {
      return '${dateTime.day}-$monthName ${dateTime.year}';
    }
  }

  /// Returns e.g. "Sentabr 2025"
  static String formatMonthYear(DateTime dateTime) {
    final monthName = uzbekMonths[dateTime.month - 1];
    final capitalized = monthName[0].toUpperCase() + monthName.substring(1);
    return '$capitalized ${dateTime.year}';
  }

  /// Short month name like "Apr", "May", "Iyn"
  static String getMonthShortName(int monthIndex) {
    if (monthIndex < 1 || monthIndex > 12) return '';
    final name = uzbekMonthsShort[monthIndex - 1];
    return name[0].toUpperCase() + name.substring(1);
  }
}
