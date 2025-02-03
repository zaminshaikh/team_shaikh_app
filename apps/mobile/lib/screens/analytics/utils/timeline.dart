import 'package:intl/intl.dart';

class Timeline {
  late DateTime now;
  late DateTime firstDayOfCurrentMonth;
  late DateTime lastDayOfPreviousMonth;
  late int daysInLastMonth;
  late List<String> lastSixMonths;
  late List<String> lastYearMonths;
  late String lastWeekRange;
  late String lastMonthRange;
  late String lastSixMonthsRange;
  late String lastYearRange;
  late List<String> lastWeekDays;
  late List<String> lastMonthDays;

  Timeline() {
    now = DateTime.now();
    firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    lastDayOfPreviousMonth =
        firstDayOfCurrentMonth.subtract(const Duration(days: 1));
    daysInLastMonth = lastDayOfPreviousMonth.day;
    lastSixMonths = _calculateLastSixMonths();
    lastWeekRange = _calculateLastWeekRange();
    lastMonthRange = _calculateLastMonthRange();
    lastSixMonthsRange = _calculateLastSixMonthsRange();
    lastYearRange = _calculateLastYearRange();
    lastWeekDays = _calculateLastWeekDays();
    lastMonthDays = _calculateLastMonthDays();
    lastYearMonths = _calculateLastYearMonths();
  }

  List<String> _calculateLastSixMonths() {
    List<String> months = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('MMM').format(month));
    }
    return months.reversed.toList(); // Reverse to get the months in order
  }

  List<String> _calculateLastWeekDays() {
    DateTime now = DateTime.now();
    return List.generate(7, (index) {
      DateTime day = now.subtract(Duration(days: 6 - index));
      return DateFormat('EEE').format(day);
    });
  }

  String _calculateLastWeekRange() {
    DateTime now = DateTime.now();
    // Calculate the start of the range (7 days ago)
    DateTime startOfRange = now.subtract(const Duration(days: 6));
    // Calculate the end of the range (today)
    DateTime endOfRange = now;
    String formattedStart = DateFormat('MMMM dd, yyyy').format(startOfRange);
    String formattedEnd = DateFormat('MMMM dd, yyyy').format(endOfRange);
    return '$formattedStart - $formattedEnd';
  }

  String _calculateLastMonthRange() {
    DateTime now = DateTime.now();
    DateTime startOfLastMonth = DateTime(now.year, now.month - 1, now.day);
    DateTime endOfLastMonth = DateTime(now.year, now.month, now.day);
    String formattedStart = DateFormat('MMMM d, yyyy').format(startOfLastMonth);
    String formattedEnd = DateFormat('MMMM dd, yyyy').format(endOfLastMonth);
    return '$formattedStart - $formattedEnd';
  }

  List<String> _calculateLastMonthDays() {
    DateTime now = DateTime.now();
    DateTime startOfLastMonth = DateTime(now.year, now.month - 1, now.day);
    DateTime endOfLastMonth = DateTime(now.year, now.month, now.day);

    // Calculate the midpoint date
    DateTime midOfLastMonth = startOfLastMonth.add(Duration(
        days:
            (endOfLastMonth.difference(startOfLastMonth).inDays / 2).round()));

    String formattedStart = DateFormat('MMM d').format(startOfLastMonth);
    String formattedMid = DateFormat('MMM d').format(midOfLastMonth);
    String formattedEnd = DateFormat('MMM dd').format(endOfLastMonth);

    return [formattedStart, formattedMid, formattedEnd];
  }

  String _calculateLastSixMonthsRange() {
    DateTime now = DateTime.now();
    DateTime startOfSixMonthsAgo = DateTime(now.year, now.month - 5, now.day);
    DateTime endOfLastMonth = now;
    String formattedStart =
        DateFormat('MMMM dd, yyyy').format(startOfSixMonthsAgo);
    String formattedEnd = DateFormat('MMMM dd, yyyy').format(endOfLastMonth);
    return '$formattedStart - $formattedEnd';
  }

  String _calculateLastYearRange() {
    DateTime now = DateTime.now();
    DateTime startOfCurrentYear = DateTime(now.year, 1, 1);
    DateTime endOfCurrentYear = now;
    String formattedStart =
        DateFormat('MMMM dd, yyyy').format(startOfCurrentYear);
    String formattedEnd = DateFormat('MMMM dd, yyyy').format(endOfCurrentYear);
    return '$formattedStart - $formattedEnd';
  }

  List<String> _calculateLastYearMonths() {
    List<String> months = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 13; i++) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('MM').format(month));
    }
    return months.reversed.toList(); // Reverse to get the months in order
  }

  // Method to get labels for each month in the last year
  List<String> getLastYearMonthLabel() {
    List<String> labels = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      DateTime date = DateTime(now.year, now.month - i, 1);
      labels.add(DateFormat('MM/yy').format(date));
    }
    return labels.reversed.toList(); // Reverse to get chronological order
  }

  // Method to get labels for each day in the last week
  List<String> getLastWeekDayLabel() {
    List<String> labels = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: i));
      labels.add(DateFormat('EEE').format(date));
    }
    return labels.reversed.toList(); // Reverse to get chronological order
  }

  // Method to get labels for each month in the last six months
  List<String> getLastSixMonthsLabel() {
    List<String> labels = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      DateTime date = DateTime(now.year, now.month - i, 1);
      labels.add(DateFormat('MM/yy').format(date));
    }
    return labels.reversed.toList(); // Reverse to get chronological order
  }

  // Method to get labels for each day in the last month
  List<String> getLastMonthDayLabel() {
    List<String> labels = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      DateTime date = now.subtract(Duration(days: i));
      labels.add(DateFormat('MMM dd').format(date));
    }
    return labels.reversed.toList(); // Reverse to get chronological order
  }
}
