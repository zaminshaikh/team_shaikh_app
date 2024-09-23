double calculateXValue(DateTime dateTime, String dropdownValue) {
  DateTime now = DateTime.now();
  DateTime startDate;
  double totalPeriod;
  double maxXValue = maxX(dropdownValue);

  switch (dropdownValue) {
    case 'last-week':
      startDate = now.subtract(const Duration(days: 6));
      totalPeriod = 7;
      break;
    case 'last-month':
      startDate = DateTime(now.year, now.month - 1, now.day);
      totalPeriod = 30;
      break;
    case 'last-6-months':
      startDate = DateTime(now.year, now.month - 5, now.day);
      totalPeriod = 180;
      break;
    case 'last-year':
      startDate = DateTime(now.year, 1, 1);
      totalPeriod = 365;
      break;
    default:
      return -1.0;
  }

  if (dateTime.isBefore(startDate) || dateTime.isAfter(now)) {
    return -1.0;
  }

  double dayDifference = dateTime.difference(startDate).inDays.toDouble();
  return (dayDifference / totalPeriod) * maxXValue;
}

DateTime calculateDateTimeFromXValue(double xValue, String dropdownValue) {
  DateTime now = DateTime.now();
  DateTime startDate;
  DateTime endDate;
  double totalPeriod;
  double maxXValue = maxX(dropdownValue);

  switch (dropdownValue) {
    case 'last-week':
      startDate = now.subtract(const Duration(days: 6));
      endDate = now;
      break;
    case 'last-month':
      startDate = now.subtract(const Duration(days: 29));
      endDate = now;
      break;
    case 'last-6-months':
      startDate = DateTime(now.year, now.month - 5, now.day);
      endDate = now;
      break;
    case 'last-year':
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
      totalPeriod = 365;
      break;
    default:
      return DateTime.now();
  }

  totalPeriod = endDate.difference(startDate).inDays.toDouble();

  double dayDifference = (xValue / maxXValue) * totalPeriod;

  // Use microseconds to handle fractional days
  int microsecondsDifference =
      (dayDifference * Duration.microsecondsPerDay).round();
  DateTime dateTime =
      startDate.add(Duration(microseconds: microsecondsDifference));

  return dateTime;
}

double maxX(String dropdownValue) {
  switch (dropdownValue) {
    case 'last-week':
      return 6; // 7 days (0 to 6)
    case 'last-month':
      return 29; // 30 days (0 to 29)
    case 'last-6-months':
      return 5; // 6 months (0 to 5)
    case 'last-year':
      return 11; // 12 months (0 to 11)
    default:
      return 6;
  }
}

String abbreviateNumber(double value) {
  if (value >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(1)}M';
  } else if (value >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(1)}K';
  } else {
    return value.toStringAsFixed(0);
  }
}

double calculateMaxY(double value) {
  double increment = 1.0;
  if (value >= 100000000) {
    increment = 10000000;
  } else if (value >= 10000000) {
    increment = 1000000;
  } else if (value >= 1000000) {
    increment = 100000;
  } else if (value >= 100000) {
    increment = 10000;
  } else if (value >= 10000) {
    increment = 1000;
  } else if (value >= 1000) {
    increment = 100;
  } else if (value >= 500) {
    increment = 50;
  }
  return ((value / increment).ceil() * increment).toDouble();
}

double getBottomTitleInterval(String dropdownValue) {
  switch (dropdownValue) {
    case 'last-week':
      return maxX(dropdownValue) / 2; // Label every day
    case 'last-month':
      return maxX(dropdownValue) / 2; // Start and end of the month
    case 'last-6-months':
      return maxX(dropdownValue) / 2.5; // Adjust as needed
    case 'last-year':
      return maxX(dropdownValue) / 2; // Start, middle, end
    default:
      return 1;
  }
}

double calculateHorizontalInterval(double maxValue) => maxValue / 15;
