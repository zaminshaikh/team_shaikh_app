import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';

// Get Activity Type Text
String getActivityType(Activity activity) {
  switch (activity.type) {
    case 'income':
    case 'profit':
      return 'Profit';
    case 'deposit':
      return 'Deposit';
    case 'withdrawal':
      return 'Withdrawal';
    case 'pending':
      return 'Pending Withdrawal';
    default:
      return 'Error';
  }
}

// Get color based on activity type
Color getActivityColor(String type) {
  switch (type) {
    case 'deposit':
      return AppColors.defaultGreen400;
    case 'withdrawal':
      return AppColors.defaultRed400;
    case 'pending':
      return AppColors.defaultYellow400;
    case 'income':
    case 'profit':
      return AppColors.defaultBlue300;
    default:
      return Colors.white;
  }
}

// Get underlay color based on activity type
Color getUnderlayColor(String type) {
  switch (type) {
    case 'deposit':
      return const Color.fromARGB(255, 21, 52, 57);
    case 'withdrawal':
      return const Color.fromARGB(255, 41, 25, 28);
    case 'pending':
    case 'income':
    case 'profit':
      return const Color.fromARGB(255, 24, 46, 68);
    default:
      return Colors.white;
  }
}

// Get the icon for each activity type
Widget getActivityIcon(String type, {double size = 50.0}) {
  switch (type) {
    case 'deposit':
      return SvgPicture.asset(
        'assets/icons/deposit.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    case 'withdrawal':
      return SvgPicture.asset(
        'assets/icons/withdrawal.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    case 'pending':
      return SvgPicture.asset(
        'assets/icons/pending_withdrawal.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    case 'income':
    case 'profit':
      return SvgPicture.asset(
        
        'assets/icons/variable_income.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    default:
      return Icon(
        Icons.circle,
        color: Colors.transparent,
        size: size,
      );
  }
}

// Helper functions at the top
String getActivityDescription(Activity activity) {
  String action;
  switch (activity.type) {
    case 'deposit':
      action = 'Deposit to your investment at';
      break;
    case 'withdrawal':
      action = 'Withdrawal from your investment at';
      break;
    case 'pending':
      action = 'Pending withdrawal from your investment at';
      break;
    case 'income':
    case 'profit':
      action = 'Profit to your investment at';
      break;
    default:
      action = '';
  }
  return '$action ${activity.fund}';
}
