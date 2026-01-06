import 'package:intl/intl.dart';

class DateUtils {
  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String monthYearFormat = 'MMM yyyy';
  static const String dayMonthFormat = 'dd MMM';
  static const String fullDateFormat = 'EEEE, dd MMMM yyyy';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // Format date to string
  static String formatDate(DateTime date, {String format = dateFormat}) {
    return DateFormat(format).format(date);
  }

  // Parse string to date
  static DateTime? parseDate(String dateString, {String format = dateFormat}) {
    try {
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Get current date
  static DateTime getCurrentDate() {
    return DateTime.now();
  }

  // Get current time
  static DateTime getCurrentTime() {
    return DateTime.now();
  }

  // Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Get start of week
  static DateTime getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  // Get end of week
  static DateTime getEndOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  // Get start of month
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // Get start of year
  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  // Get end of year
  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }

  // Add days to date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  // Subtract days from date
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  // Add months to date
  static DateTime addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }

  // Subtract months from date
  static DateTime subtractMonths(DateTime date, int months) {
    return DateTime(date.year, date.month - months, date.day);
  }

  // Add years to date
  static DateTime addYears(DateTime date, int years) {
    return DateTime(date.year + years, date.month, date.day);
  }

  // Subtract years from date
  static DateTime subtractYears(DateTime date, int years) {
    return DateTime(date.year - years, date.month, date.day);
  }

  // Get difference in days
  static int getDifferenceInDays(DateTime date1, DateTime date2) {
    return date1.difference(date2).inDays;
  }

  // Get difference in hours
  static int getDifferenceInHours(DateTime date1, DateTime date2) {
    return date1.difference(date2).inHours;
  }

  // Get difference in minutes
  static int getDifferenceInMinutes(DateTime date1, DateTime date2) {
    return date1.difference(date2).inMinutes;
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  // Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  // Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // Check if date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  // Check if date is in current week
  static bool isCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = getStartOfWeek(now);
    final endOfWeek = getEndOfWeek(now);
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  // Check if date is in current month
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Check if date is in current year
  static bool isCurrentYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  // Get relative time string
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Get age from birth date
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Get days until date
  static int getDaysUntil(DateTime date) {
    final now = DateTime.now();
    return date.difference(now).inDays;
  }

  // Get days since date
  static int getDaysSince(DateTime date) {
    final now = DateTime.now();
    return now.difference(date).inDays;
  }

  // Check if date is weekend
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  // Check if date is weekday
  static bool isWeekday(DateTime date) {
    return !isWeekend(date);
  }

  // Get next weekday
  static DateTime getNextWeekday(DateTime date) {
    DateTime nextDay = date.add(const Duration(days: 1));
    while (isWeekend(nextDay)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    return nextDay;
  }

  // Get previous weekday
  static DateTime getPreviousWeekday(DateTime date) {
    DateTime previousDay = date.subtract(const Duration(days: 1));
    while (isWeekend(previousDay)) {
      previousDay = previousDay.subtract(const Duration(days: 1));
    }
    return previousDay;
  }

  // Get business days between two dates
  static int getBusinessDays(DateTime startDate, DateTime endDate) {
    int businessDays = 0;
    DateTime currentDate = startDate;
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      if (isWeekday(currentDate)) {
        businessDays++;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return businessDays;
  }

  // Format date for display
  static String formatDateForDisplay(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else if (isCurrentWeek(date)) {
      return formatDate(date, format: 'EEEE');
    } else if (isCurrentYear(date)) {
      return formatDate(date, format: dayMonthFormat);
    } else {
      return formatDate(date, format: dateFormat);
    }
  }

  // Get month name
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  // Get day name
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  // Get short month name
  static String getShortMonthName(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  // Get short day name
  static String getShortDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  // Get time string
  static String getTimeString(DateTime date) {
    return DateFormat(timeFormat).format(date);
  }

  // Get date and time string
  static String getDateTimeString(DateTime date) {
    return DateFormat(dateTimeFormat).format(date);
  }

  // Get full date string
  static String getFullDateString(DateTime date) {
    return DateFormat(fullDateFormat).format(date);
  }

  // Get API date string
  static String getApiDateString(DateTime date) {
    return DateFormat(apiDateFormat).format(date);
  }

  // Get API date time string
  static String getApiDateTimeString(DateTime date) {
    return DateFormat(apiDateTimeFormat).format(date);
  }
}
