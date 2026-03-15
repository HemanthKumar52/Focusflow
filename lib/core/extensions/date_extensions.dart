import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) && isBefore(endOfWeek);
  }

  bool get isPast => isBefore(DateTime.now());

  String get friendlyDate {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    if (isYesterday) return 'Yesterday';
    if (isThisWeek) return DateFormat('EEEE').format(this);
    if (year == DateTime.now().year) return DateFormat('MMM d').format(this);
    return DateFormat('MMM d, y').format(this);
  }

  String get friendlyTime => DateFormat('h:mm a').format(this);

  String get friendlyDateTime => '$friendlyDate at $friendlyTime';

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}
