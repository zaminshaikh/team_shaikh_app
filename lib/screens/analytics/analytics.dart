// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'package:team_shaikh_app/utilities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:intl/intl.dart';


class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

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
    lastDayOfPreviousMonth = firstDayOfCurrentMonth.subtract(const Duration(days: 1));
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
      days: (endOfLastMonth.difference(startOfLastMonth).inDays / 2).round()
    ));
    
    String formattedStart = DateFormat('MMM d').format(startOfLastMonth);
    String formattedMid = DateFormat('MMM d').format(midOfLastMonth);
    String formattedEnd = DateFormat('MMM dd').format(endOfLastMonth);
    
    return [formattedStart, formattedMid, formattedEnd];
  }

  String _calculateLastSixMonthsRange() {
    DateTime now = DateTime.now();
    DateTime startOfSixMonthsAgo = DateTime(now.year, now.month - 5, now.day);
    DateTime endOfLastMonth = now;
    String formattedStart = DateFormat('MMMM dd, yyyy').format(startOfSixMonthsAgo);
    String formattedEnd = DateFormat('MMMM dd, yyyy').format(endOfLastMonth);
    return '$formattedStart - $formattedEnd';
  }

  String _calculateLastYearRange() {
    DateTime now = DateTime.now();
    DateTime startOfLastYear = DateTime(now.year - 1, now.month, now.day);
    DateTime endOfLastYear = now;
    String formattedStart = DateFormat('MMMM dd, yyyy').format(startOfLastYear);
    String formattedEnd = DateFormat('MMMM dd, yyyy').format(endOfLastYear);
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

}

class _AnalyticsPageState extends State<AnalyticsPage> {

  
  Timeline timeline = Timeline();

  // database service instance
  late DatabaseService _databaseService;

  Future<void> _initData() async {

    User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await Navigator.pushReplacementNamed(context, '/login');
      }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(context, user!.uid, 1);
    // If there is no matching CID, redirect to login page
    if (service == null) {
      await Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Otherwise set the database service instance
      _databaseService = service;
    }
  }
  
  /// Formats the given amount as a currency string.

  String dropdownValue = 'last-year';

  double maxAmount = 0.0;
  
  List<FlSpot> spots = [];
  List<DateTime> foundSpotsDatesInLastSixMonths = [];
  List<DateTime> foundSpotsDatesInLastWeek = [];
  List<DateTime> foundSpotsDatesInLastMonth = [];

  List<DateTime> unfoundLastYearDates = [];
  List<Map<String, dynamic>> unfoundLastYearPoints = [];
  double unfoundLastYearAmount = 0.0;

  List<DateTime> unfoundLastWeekDates = [];
  List<Map<String, dynamic>> unfoundLastWeekPoints = [];
  double unfoundLastWeekAmount = 0.0;

  List<DateTime> unfoundLastMonthDates = [];
  List<Map<String, dynamic>> unfoundLastMonthPoints = [];
  double unfoundLastMonthAmount = 0.0;

  List<DateTime> unfoundLastSixMonthsDates = [];
  List<Map<String, dynamic>> unfoundLastSixMonthsPoints = [];
  double unfoundLastSixMonthsAmount = 0.0;

  List<DateTime> unfoundCustomDates = [];
  List<Map<String, dynamic>> unfoundCustomPoints = [];
  double unfoundCustomAmount = 0.0;



  List<double> lastYearxValues = [];
  List<DateTime> lastYearDates = [];

  List<double> lastMonthxValues = [];
  List<DateTime> lastMonthDates = [];

  List<double> lastSixMonthsxValues = [];
  List<DateTime> lastSixMonthsDates = [];

  List<double> lastWeekxValues = [];
  List<DateTime> lastWeekDates = [];

  List<double> customxValues = [];
  List<DateTime> customDates = [];

  


  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _initData(), // Initialize the database service
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(26.0),
              margin: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
              decoration: BoxDecoration(
                color: AppColors.defaultBlue500,
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: const Stack(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 6.0,
                  ),
                ],
              ),
            ),
          );
        }
        return StreamBuilder<UserWithAssets>(
            stream: _databaseService.getUserWithAssets,
            builder: (context, userSnapshot) {
              // Wait for the user snapshot to have data
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(26.0),
                    margin: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
                    decoration: BoxDecoration(
                      color: AppColors.defaultBlue500,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: const Stack(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 6.0,
                        ),
                      ],
                    ),
                  ),
                );
              }
              // Once we have the user snapshot, we can build the activity page
              return StreamBuilder<List<UserWithAssets>>(
                stream: _databaseService.getConnectedUsersWithAssets, // Assuming this is the stream for connected users
                builder: (context, connectedUsers) {
                  if (!connectedUsers.hasData || connectedUsers.data == null) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(26.0),
                        margin: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
                        decoration: BoxDecoration(
                          color: AppColors.defaultBlue500,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: const Stack(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 6.0,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _databaseService.getNotifications,
                    builder: (context, notificationsSnapshot) {
                      if (!notificationsSnapshot.hasData || notificationsSnapshot.data == null) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(26.0),
                            margin: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
                            decoration: BoxDecoration(
                              color: AppColors.defaultBlue500,
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: const Stack(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 6.0,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      unreadNotificationsCount = notificationsSnapshot.data!.where((notification) => !notification['isRead']).length;
                      return buildAnalyticsPage(userSnapshot, connectedUsers);
                    }
                  );
                },
              );
            });
      });

  Scaffold buildAnalyticsPage(AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {
    UserWithAssets user = userSnapshot.data!;
    // Total assets of one user
    double totalUserAssets = 0.00,
        totalAGQ = 0.00,
        totalAK1 = 0.00,
        totalAssets = 0.00;

    // This is a calculation of the total assets of the user only
    for (var asset in user.assets) {
      switch (asset['fund']) {
        case 'AGQ':
          totalAGQ += asset['total'];
          break;
        case 'AK1':
          totalAK1 += asset['total'];
          break;
        default:
          totalUserAssets += asset['total'] ?? 0;
          totalAssets += asset['total'] ?? 0;
      }
    }
    // Find the asset with graphPoints and print them
    for (var asset in user.assets) {
      if (asset.containsKey('graphPoints')) {
        List<Map<String, dynamic>> graphPoints = List<Map<String, dynamic>>.from(asset['graphPoints']);
    
        bool spotAssignedZero = false; // Initialize spotAssignedZero
        bool pointAssignedLastCase = false; // Initialize pointAssignedLastCase
    
        // Convert the graphPoints array into a list of FlSpot objects
        spots = graphPoints.map((point) {
          DateTime dateTime = (point['time'] as Timestamp).toDate();
          double xValue = -1.0; // Assign an initial value to xValue
    
          if (dropdownValue == 'custom-time-period') {
            bool found = false;
            DateTime normalizedDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
            DateTime startDate = DateTime(lastCustomRange.start.year, lastCustomRange.start.month, lastCustomRange.start.day);
            DateTime endDate = DateTime(lastCustomRange.end.year, lastCustomRange.end.month, lastCustomRange.end.day);
          
          
            // Check if normalizedDateTime is within the custom date range
            if (normalizedDateTime.isAfter(startDate.subtract(const Duration(days: 1))) && normalizedDateTime.isBefore(endDate.add(const Duration(days: 1)))) {
              found = true;
              int dayDifference = normalizedDateTime.difference(startDate).inDays;
              int totalDays = endDate.difference(startDate).inDays + 1; // Calculate total days in the custom period
              xValue = (dayDifference / totalDays) * maxX(dropdownValue); // Scale day to the range 0-maxX
          
          
              // Use sets to ensure unique values
              Set<DateTime> uniqueDates = customDates.toSet();
              Set<double> uniqueXValues = customxValues.toSet();
          
              uniqueDates.add(normalizedDateTime);
              uniqueXValues.add(xValue);
          
          
              if (!uniqueXValues.contains(0)) {
                uniqueXValues.add(0);
              }
              if (!uniqueXValues.contains(maxX(dropdownValue))) {
                uniqueXValues.add(maxX(dropdownValue));
              }
              if (!uniqueDates.contains(startDate)) {
                uniqueDates.add(startDate);
              }
              if (!uniqueDates.contains(endDate)) {
                uniqueDates.add(endDate);
              }
          
              // Convert sets back to lists
              customDates = uniqueDates.toList();
              customxValues = uniqueXValues.toList();
          
              customDates.sort((a, b) => a.compareTo(b));
              customxValues.sort((a, b) => a.compareTo(b));
          
          
              if (dayDifference == 0) {
                spotAssignedZero = true;
              }
              if (dayDifference == totalDays) {
                pointAssignedLastCase = true;
              }
            }
          
            if (!found) {
              unfoundCustomDates.add(normalizedDateTime);
              unfoundCustomPoints.add(point); // Add the point to the list of unfound points
            }
          
            // Ensure startDate and endDate are always in customDates
            if (!customDates.contains(startDate)) {
              customDates.add(startDate);
            }
            if (!customDates.contains(endDate)) {
              customDates.add(endDate);
            }
          
            // Ensure 0 is always in customxValues
            if (!customxValues.contains(0)) {
              customxValues.add(0);
            }
          
            // Sort the dates in order
            unfoundCustomDates.sort((a, b) => a.compareTo(b));
          
            // Print the last date in the list
            if (unfoundCustomDates.isNotEmpty) {
              DateTime lastUnfoundDate = unfoundCustomDates.last;
          
              // Find the corresponding point for the last unfound date
              var lastUnfoundPoint = unfoundCustomPoints[unfoundCustomDates.indexOf(lastUnfoundDate)];
          
          
              // Ensure the amount is correctly accessed and parsed
              if (lastUnfoundPoint.containsKey('amount')) {
                double amount = lastUnfoundPoint['amount'].toDouble();
                unfoundCustomAmount = amount; // Ensure unfoundCustomPeriodAmount is set correctly
              }
            }
          
            // Ensure both lists have the same length
            if (customDates.length == customxValues.length) {
              // Combine dates and xValues into a list of tuples
              List<MapEntry<DateTime, double>> combinedList = [];
              for (int i = 0; i < customDates.length; i++) {
                combinedList.add(MapEntry(customDates[i], customxValues[i]));
              }
          
              // Sort the combined list by date and then by xValue
              combinedList.sort((a, b) {
                int dateComparison = a.key.compareTo(b.key);
                if (dateComparison != 0) {
                  return dateComparison;
                } else {
                  return a.value.compareTo(b.value);
                }
              });
          
              // Extract sorted dates and xValues back into their respective lists
              customDates = combinedList.map((entry) => entry.key).toList();
              customxValues = combinedList.map((entry) => entry.value).toList();
          
            } else {
            }
          }
          
          else if (dropdownValue == 'last-6-months') {
            print('Last 6 months selected');
            // Clear the list and set once when the dropdown value is selected
            bool found = false;
            DateTime normalizedDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
            DateTime now = DateTime.now();
            DateTime sixMonthsAgo = DateTime(now.year, now.month - 5, now.day);
            DateTime endOfsixMonthsAgo = DateTime(now.year, now.month, now.day);
          
            print('Normalized DateTime: $normalizedDateTime');
            print('Now: $now');
            print('Six Months Ago: $sixMonthsAgo');
            print('End of Six Months Ago: $endOfsixMonthsAgo');
          
            // Check if normalizedDateTime is within the last 6 months
            if (normalizedDateTime.isAfter(sixMonthsAgo.subtract(const Duration(days: 1))) && normalizedDateTime.isBefore(endOfsixMonthsAgo.add(const Duration(days: 1)))) {
              found = true;
              int dayDifference = normalizedDateTime.difference(sixMonthsAgo).inDays;
              int totalDays = endOfsixMonthsAgo.difference(sixMonthsAgo).inDays + 1; // Calculate total days in the last 6 months
              xValue = (dayDifference / totalDays) * 5; // Scale day to the range 0-12
          
              print('Day Difference: $dayDifference');
              print('Total Days: $totalDays');
              print('xValue: $xValue');
          
              // Use sets to ensure unique values
              Set<DateTime> uniqueDates = lastSixMonthsDates.toSet();
              Set<double> uniqueXValues = lastSixMonthsxValues.toSet();
          
              uniqueDates.add(normalizedDateTime);
              uniqueXValues.add(xValue);
          
              print('Unique Dates: $uniqueDates');
              print('Unique X Values: $uniqueXValues');
          
              if (!uniqueXValues.contains(0)) {
                uniqueXValues.add(0);
              }
              if (!uniqueXValues.contains(maxX(dropdownValue))) {
                uniqueXValues.add(maxX(dropdownValue));
              }
              if (!uniqueDates.contains(sixMonthsAgo)) {
                uniqueDates.add(sixMonthsAgo);
              }
              if (!uniqueDates.contains(endOfsixMonthsAgo)) {
                uniqueDates.add(endOfsixMonthsAgo);
              }
          
              // Convert sets back to lists
              lastSixMonthsDates = uniqueDates.toList();
              lastSixMonthsxValues = uniqueXValues.toList();
          
              lastSixMonthsDates.sort((a, b) => a.compareTo(b));
              lastSixMonthsxValues.sort((a, b) => a.compareTo(b));
          
              print('Sorted Last Six Months Dates: $lastSixMonthsDates');
              print('Sorted Last Six Months X Values: $lastSixMonthsxValues');
          
              if (dayDifference == 0) {
                spotAssignedZero = true;
              }
              if (dayDifference == 365) {
                pointAssignedLastCase = true;
              }
            }
          
            if (!found) {
              unfoundLastSixMonthsDates.add(normalizedDateTime);
              unfoundLastSixMonthsPoints.add(point); // Add the point to the list of unfound points
              print('Point not found in last 6 months: $normalizedDateTime');
            }
          
            // Sort the dates in order
            unfoundLastSixMonthsDates.sort((a, b) => a.compareTo(b));
            print('Unfound Last Six Months Dates: $unfoundLastSixMonthsDates');
          
            // Print the last date in the list
            if (unfoundLastSixMonthsDates.isNotEmpty) {
              DateTime lastUnfoundDate = unfoundLastSixMonthsDates.last;
          
              // Find the corresponding point for the last unfound date
              var lastUnfoundPoint = unfoundLastSixMonthsPoints[unfoundLastSixMonthsDates.indexOf(lastUnfoundDate)];
          
              print('Last Unfound Date: $lastUnfoundDate');
              print('Last Unfound Point: $lastUnfoundPoint');
          
              // Ensure the amount is correctly accessed and parsed
              if (lastUnfoundPoint.containsKey('amount')) {
                double amount = lastUnfoundPoint['amount'].toDouble();
                unfoundLastSixMonthsAmount = amount; // Ensure unfoundLastYearAmount is set correctly
                print('Unfound Last Six Months Amount: $unfoundLastSixMonthsAmount');
              } else {
                print('Last Unfound Point does not contain amount');
              }
            }
          
            // Ensure both lists have the same length
            if (lastSixMonthsDates.length == lastSixMonthsxValues.length) {
              // Combine dates and xValues into a list of tuples
              List<MapEntry<DateTime, double>> combinedList = [];
              for (int i = 0; i < lastSixMonthsDates.length; i++) {
                combinedList.add(MapEntry(lastSixMonthsDates[i], lastSixMonthsxValues[i]));
              }
          
              // Sort the combined list by date and then by xValue
              combinedList.sort((a, b) {
                int dateComparison = a.key.compareTo(b.key);
                if (dateComparison != 0) {
                  return dateComparison;
                } else {
                  return a.value.compareTo(b.value);
                }
              });
          
              // Extract sorted dates and xValues back into their respective lists
              lastSixMonthsDates = combinedList.map((entry) => entry.key).toList();
              lastSixMonthsxValues = combinedList.map((entry) => entry.value).toList();
          
              print('Final Sorted Last Six Months Dates: $lastSixMonthsDates');
              print('Final Sorted Last Six Months X Values: $lastSixMonthsxValues');
          
              // Print the index values of lastSixMonthsDates and lastSixMonthsxValues
              for (int i = 0; i < lastSixMonthsDates.length; i++) {
                print('Index $i: Date ${lastSixMonthsDates[i]}, X Value ${lastSixMonthsxValues[i]}');
              }
            } else {
              print('Error: lastSixMonthsDates and lastSixMonthsxValues lists have different lengths');
            }
          
            // Ensure a point at x=0 is added if there are no points in the last 6 months
            if (!spotAssignedZero) {
              if (!lastSixMonthsDates.contains(sixMonthsAgo)) {
                lastSixMonthsDates.add(sixMonthsAgo);
              }
              if (!lastSixMonthsDates.contains(endOfsixMonthsAgo)) {
                lastSixMonthsDates.add(endOfsixMonthsAgo);
              }
              if (!lastSixMonthsxValues.contains(0)) {
                lastSixMonthsxValues.add(0);
              }
              lastSixMonthsDates.sort((a, b) => a.compareTo(b));
              lastSixMonthsxValues.sort((a, b) => a.compareTo(b));
          
              print('Added point at x=0');
              print('Final Last Six Months Dates: $lastSixMonthsDates');
              print('Final Last Six Months X Values: $lastSixMonthsxValues');
            }
          }

          else if (dropdownValue == 'last-year') {
            bool found = false;
            DateTime now = DateTime.now();
            bool isLeapYear = (now.year % 4 == 0 && now.year % 100 != 0) || (now.year % 400 == 0);
            int daysToSubtract = isLeapYear ? 366 : 365;
            DateTime startOfLastYear = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
            DateTime endOfLastWeek = DateTime(now.year, now.month, now.day);
          
            // Normalize dateTime to only include the date part
            DateTime normalizedDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
          
            // Check if normalizedDateTime is within the last year
            if (normalizedDateTime.isAfter(startOfLastYear.subtract(const Duration(days: 1))) && normalizedDateTime.isBefore(endOfLastWeek.add(const Duration(days: 1)))) {
              found = true;
              int dayDifference = normalizedDateTime.difference(startOfLastYear).inDays;
              xValue = (dayDifference / 365) * 12; // Scale day to the range 0-12
              if (!lastYearxValues.contains(0)) {
                lastYearxValues.add(0);
              }
              if (!lastYearxValues.contains(maxX(dropdownValue))) {
                lastYearxValues.add(maxX(dropdownValue));
              }
              if (!lastYearDates.contains(startOfLastYear)) {
                lastYearDates.add(startOfLastYear);
              }
          
              // Add xValue and date to the lists if the date is not already present
              if (!lastYearDates.contains(normalizedDateTime)) {
                lastYearxValues.add(xValue);
                lastYearDates.add(normalizedDateTime);
              }
              lastYearxValues.sort((a, b) => a.compareTo(b));
              lastYearDates.sort((a, b) => a.compareTo(b));
          
              if (dayDifference == 0) {
                spotAssignedZero = true;
              }
              if (dayDifference == 365) {
                pointAssignedLastCase = true;
              }
            }
          
            if (!found) {
              unfoundLastYearDates.add(normalizedDateTime);
              unfoundLastYearPoints.add(point); // Add the point to the list of unfound points
              // return null; // Return null if the point is not from the last year
            }
          
            if (pointAssignedLastCase) { // Step 3: Print the message
            } else {
            }
          
            // Sort the dates in order
            unfoundLastYearDates.sort((a, b) => a.compareTo(b));
          
            // Print the list of dates
          
            // Print the last date in the list
            if (unfoundLastYearDates.isNotEmpty) {
              DateTime lastUnfoundDate = unfoundLastYearDates.last;
          
              // Find the corresponding point for the last unfound date
              var lastUnfoundPoint = unfoundLastYearPoints[unfoundLastYearDates.indexOf(lastUnfoundDate)];
          
              // Debugging: Check the structure of the point
          
              // Ensure the amount is correctly accessed and parsed
              if (lastUnfoundPoint.containsKey('amount')) {
                double amount = lastUnfoundPoint['amount'].toDouble();
                unfoundLastYearAmount = amount; // Ensure unfoundLastYearAmount is set correctly
              } else {
              }
            }
          
            // Add today's date at the end of lastYearDates if not already present
            DateTime today = DateTime(now.year, now.month, now.day);
            if (!lastYearDates.contains(today)) {
              lastYearDates.add(today);
            }
          
            // Combine dates and xValues into a list of tuples
            List<MapEntry<DateTime, double>> combinedList = [];
            for (int i = 0; i < lastYearDates.length; i++) {
              combinedList.add(MapEntry(lastYearDates[i], lastYearxValues[i]));
            }
          
            // Sort the combined list by date and then by xValue
            combinedList.sort((a, b) {
              int dateComparison = a.key.compareTo(b.key);
              if (dateComparison != 0) {
                return dateComparison;
              } else {
                return a.value.compareTo(b.value);
              }
            });
          
            // Extract sorted dates and xValues back into their respective lists
            lastYearDates = combinedList.map((entry) => entry.key).toList();
            lastYearxValues = combinedList.map((entry) => entry.value).toList();
          
            // Print the index values of lastYearDates and lastYearxValues
            for (int i = 0; i < lastYearDates.length; i++) {
            }
          }

          else if (dropdownValue == 'last-month') {
            bool found = false;
            DateTime now = DateTime.now();
            DateTime startOfLastMonth = DateTime(now.year, now.month - 1, now.day);
            DateTime endOfLastMonth = DateTime(now.year, now.month, now.day);
          
          
            // Normalize dateTime to only include the date part
            DateTime normalizedDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
          
            // Check if normalizedDateTime is within the last month
            if (normalizedDateTime.isAfter(startOfLastMonth.subtract(const Duration(days: 1))) && normalizedDateTime.isBefore(endOfLastMonth.add(const Duration(days: 1)))) {
              int totalDays = endOfLastMonth.difference(startOfLastMonth).inDays + 1; // Calculate total days in the last month
              int day = normalizedDateTime.difference(startOfLastMonth).inDays + 1; // Calculate the day of the month
          
          
              found = true;
              xValue = 2 * (day - 1) / (totalDays - 1); // Scale day to the range 0-2
          
              // Use sets to ensure unique values
              Set<DateTime> uniqueDates = lastMonthDates.toSet();
              Set<double> uniqueXValues = lastMonthxValues.toSet();
          
              uniqueDates.add(normalizedDateTime);
              uniqueXValues.add(xValue);
              uniqueDates.add(startOfLastMonth);
              uniqueDates.add(endOfLastMonth);
              uniqueXValues.add(0);
              uniqueXValues.add(2);
          
              // Convert sets back to lists
              lastMonthDates = uniqueDates.toList();
              lastMonthxValues = uniqueXValues.toList();
          
          
              lastMonthDates.sort((a, b) => a.compareTo(b));
              lastMonthxValues.sort((a, b) => a.compareTo(b));
          
          
              if (day == 1) {
                spotAssignedZero = true;
              }
            } else {
              unfoundLastMonthDates.add(normalizedDateTime);
              unfoundLastMonthPoints.add(point); // Add the point to the list of unfound points
          
          
            }
          
            // Sort the dates in order
            unfoundLastMonthDates.sort((a, b) => a.compareTo(b));
          
            // Print the last date in the list
            if (unfoundLastMonthDates.isNotEmpty) {
              DateTime lastUnfoundDate = unfoundLastMonthDates.last;
          
              // Find the corresponding point for the last unfound date
              var lastUnfoundPoint = unfoundLastMonthPoints[unfoundLastMonthDates.indexOf(lastUnfoundDate)];
          
              // Ensure the amount is correctly accessed and parsed
              if (lastUnfoundPoint.containsKey('amount')) {
                double amount = lastUnfoundPoint['amount'].toDouble();
                unfoundLastMonthAmount = amount; // Ensure unfoundLastYearAmount is set correctly
              }
            }
          
            // Ensure both lists have the same length before combining
            if (lastMonthDates.length == lastMonthxValues.length) {
              // Combine dates and xValues into a list of tuples
              List<MapEntry<DateTime, double>> combinedList = [];
              for (int i = 0; i < lastMonthDates.length; i++) {
                combinedList.add(MapEntry(lastMonthDates[i], lastMonthxValues[i]));
              }
          
              // Sort the combined list by date and then by xValue
              combinedList.sort((a, b) {
                int dateComparison = a.key.compareTo(b.key);
                if (dateComparison != 0) {
                  return dateComparison;
                } else {
                  return a.value.compareTo(b.value);
                }
              });
          
              // Extract sorted dates and xValues back into their respective lists
              lastMonthDates = combinedList.map((entry) => entry.key).toList();
              lastMonthxValues = combinedList.map((entry) => entry.value).toList();
          
          
              // Print the index values of lastMonthDates and lastMonthxValues
              for (int i = 0; i < lastMonthDates.length; i++) {
              }
            } else {
            }
          }

          else if (dropdownValue == 'last-week') {
            bool found = false;
            DateTime now = DateTime.now();
            DateTime startOfLastWeek = now.subtract(Duration(days: 6));
            DateTime endOfLastWeek = now;
          
          
            // Normalize dates to remove the time component
            DateTime normalizedStartOfLastWeek = DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day);
            DateTime normalizedEndOfLastWeek = DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day);
          
            // Normalize dateTime to only include the date part
            DateTime normalizedDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
          
            // Check if normalizedDateTime is within the last week
            if (normalizedDateTime.isAfter(normalizedStartOfLastWeek) && normalizedDateTime.isBefore(normalizedEndOfLastWeek.add(const Duration(days: 1)))) {
              int totalDays = endOfLastWeek.difference(startOfLastWeek).inDays + 1; // Calculate total days in the last week
              int day = normalizedDateTime.difference(startOfLastWeek).inDays; // Calculate the day of the week, starting from 0
          
          
              found = true;
              xValue = day.toDouble(); // Scale day to the range 0-6
          
              // Use sets to ensure unique values
              Set<DateTime> uniqueDates = lastWeekDates.map((date) => DateTime(date.year, date.month, date.day)).toSet();
              Set<double> uniqueXValues = lastWeekxValues.toSet();
          
              DateTime normalizedDate = DateTime(normalizedDateTime.year, normalizedDateTime.month, normalizedDateTime.day);
              uniqueDates.add(normalizedDate);
              uniqueXValues.add(xValue);
          
              if (!uniqueXValues.contains(0)) {
                uniqueXValues.add(0);
              }
              if (!uniqueXValues.contains(6)) {
                uniqueXValues.add(6);
              }
              if (!uniqueDates.contains(normalizedStartOfLastWeek)) {
                uniqueDates.add(normalizedStartOfLastWeek);
              }
              if (!uniqueDates.contains(normalizedEndOfLastWeek)) {
                uniqueDates.add(normalizedEndOfLastWeek);
              }
          
              // Convert sets back to lists
              lastWeekDates = uniqueDates.toList();
              lastWeekxValues = uniqueXValues.toList();
          
          
              lastWeekDates.sort((a, b) => a.compareTo(b));
              lastWeekxValues.sort((a, b) => a.compareTo(b));
          
          
              if (xValue == 0) {
                spotAssignedZero = true;
              }
            } else {
              unfoundLastWeekDates.add(normalizedDateTime);
              unfoundLastWeekPoints.add(point); // Add the point to the list of unfound points
          
          
              // Sort the dates in chronological order
              unfoundLastWeekDates.sort((a, b) => a.compareTo(b));
          
              // Print the last date in the list
              if (unfoundLastWeekDates.isNotEmpty) {
                DateTime lastUnfoundDate = unfoundLastWeekDates.last;
          
                // Find the corresponding point for the last unfound date
                var lastUnfoundPoint = unfoundLastWeekPoints[unfoundLastWeekDates.indexOf(lastUnfoundDate)];
          
                // Ensure the amount is correctly accessed and parsed
                if (lastUnfoundPoint.containsKey('amount')) {
                  double amount = lastUnfoundPoint['amount'].toDouble();
                  unfoundLastWeekAmount = amount; // Ensure unfoundLastYearAmount is set correctly
                } else {
                  unfoundLastWeekAmount = 0.0;
                }
              } else {
                unfoundLastWeekAmount = 0.0;
              }
            }
          
            // Ensure both lists have the same length before combining
            if (lastWeekDates.length == lastWeekxValues.length) {
              // Combine dates and xValues into a list of tuples
              List<MapEntry<DateTime, double>> combinedList = [];
              for (int i = 0; i < lastWeekDates.length; i++) {
                combinedList.add(MapEntry(lastWeekDates[i], lastWeekxValues[i]));
              }
          
          
              // Sort the combined list by date and then by xValue
              combinedList.sort((a, b) {
                int dateComparison = a.key.compareTo(b.key);
                if (dateComparison != 0) {
                  return dateComparison;
                } else {
                  return a.value.compareTo(b.value);
                }
              });
          
              // Extract sorted dates and xValues back into their respective lists
              lastWeekDates = combinedList.map((entry) => entry.key).toList();
              lastWeekxValues = combinedList.map((entry) => entry.value).toList();
          
          
              // Print the index values of lastWeekDates and lastWeekxValues
              for (int i = 0; i < lastWeekDates.length; i++) {
              }
            } else {
            }
          
            // Ensure a point at x=0 is added if there are no points in the last week
            if (!found) {
              if (!lastWeekDates.contains(normalizedStartOfLastWeek)) {
                lastWeekDates.add(normalizedStartOfLastWeek);
              }
              lastWeekxValues.add(0);
              lastWeekDates.sort((a, b) => a.compareTo(b));
              lastWeekxValues.sort((a, b) => a.compareTo(b));
            }
          
            // Filter out any points that are not in the range 0-6
            List<MapEntry<DateTime, double>> filteredList = [];
            for (int i = 0; i < lastWeekDates.length; i++) {
              if (lastWeekxValues[i] >= 0 && lastWeekxValues[i] <= 6) {
                filteredList.add(MapEntry(lastWeekDates[i], lastWeekxValues[i]));
              } else {
              }
            }
          
            // Extract filtered dates and xValues back into their respective lists
            lastWeekDates = filteredList.map((entry) => entry.key).toList();
            lastWeekxValues = filteredList.map((entry) => entry.value).toList();
          
          }
          
          return FlSpot(xValue, point['amount'].toDouble());
          }).where((spot) => spot != null).cast<FlSpot>().toList();
          
          // Print and remove spots with xValue of -1
          spots.removeWhere((spot) {
            if (spot.x < 0) {
              return true;
            }
            return false;
          });
          
          // Determine the amount based on the dropdownValue
          double amount;
          if (dropdownValue == 'last-week') {
            amount = unfoundLastWeekAmount;
          } else if (dropdownValue == 'last-month') {
            amount = unfoundLastMonthAmount;
          } else if (dropdownValue == 'last-6-months') {
            amount = unfoundLastSixMonthsAmount;
          } else {
            amount = unfoundLastYearAmount;
          }
          
          // Check if spotAssignedZero is false and add a point at the origin
          if (!spotAssignedZero) {
            spots.insert(0, FlSpot(0, amount)); 
          }          
          
          // Check if pointAssignedLastCase is false and add a point at the last spot's xValue
          if (!pointAssignedLastCase && spots.isNotEmpty) {
            double lastXValue = maxX(dropdownValue); 
            
            // Find the spot with the highest x-value
            double lastAmount = spots.reduce((a, b) => a.x > b.x ? a : b).y;
            
            spots.add(FlSpot(lastXValue, lastAmount));
          }
          
          // Sort the spots by x-value
          spots.sort((a, b) => a.x.compareTo(b.x));

          if (spots.isNotEmpty) {
            maxAmount = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
          }
          
          break; // Assuming you only need the first asset with graphPoints
        }
      }


    // This calculation is for the total assets of all connected users combined
    for (var user in connectedUsers.data!) {
      for (var asset in user.assets) {
        switch (asset['fund']) {
          case 'AGQ':
            totalAGQ += asset['total'];
            break;
          case 'AK1':
            totalAK1 += asset['total'];
            break;
          default:
            totalAssets += asset['total'] ?? 0;
          }
      }
    }

    double percentageAGQ = totalAGQ / totalAssets * 100; // Percentage of AGQ
    double percentageAK1 = totalAK1 / totalAssets * 100; // Percentage of AK1

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // Line chart section
                      _buildLineChartSection(totalUserAssets, percentageAGQ, percentageAK1),
                      // Assets structure section
                      _buildAssetsStructureSection(
                          totalAssets, percentageAGQ, percentageAK1),
                      const SizedBox(height: 132),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(context),
          ),
        ],
      ),    
    );  
  }

  String _abbreviateNumber(double value) {
    if (value >= 1000000) {
      double result = value / 1000000;
      return result == result.toInt() ? '${result.toInt()}M' : '${result.toStringAsFixed(1)}M';
    } else if (value >= 1000 && value < 1000000) {
      double result = value / 1000;
      return result == result.toInt() ? '${result.toInt()}K' : '${result.toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
    
  SliverAppBar _buildAppBar() => SliverAppBar(
  backgroundColor: const Color.fromARGB(255, 30, 41, 59),
  automaticallyImplyLeading: false,
  toolbarHeight: 80,
  expandedHeight: 0,
  snap: false,
  floating: true,
  pinned: true,
  flexibleSpace: const SafeArea(
    child: Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.0, right: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 27,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
        ),
        
      ],
    ),
  ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5.0, bottom: 5.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 450),
                    pageBuilder: (_, __, ___) => const NotificationPage(),
                    transitionsBuilder: (_, animation, __, child) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: const Offset(0.0, 0.0),
                        ).animate(animation),
                        child: child,
                      ),
                  ),
                );
              },
              child: Container(
                color: const Color.fromRGBO(239, 232, 232, 0),
                padding: const EdgeInsets.all(10.0),
                child: ClipRect(
                  child: Stack(
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.transparent, // Change this color to the one you want
                                width: 0.3, // Adjust width to your need
                              ),
                              shape: BoxShape.rectangle, // or BoxShape.rectangle if you want a rectangle
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/bell.svg',
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                height: 32,
                              ),
                            ),
                          ),
                      Positioned(
                        right: 0,
                        top: 5,
                        child: unreadNotificationsCount > 0
                            ? Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF267DB5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '$unreadNotificationsCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Titillium Web',
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Container(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
  );
  
  String lastCustomDateRange = '';
  DateTimeRange lastCustomRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
  DateTime lastCustomDate = DateTime.now();
  DateTime firstCustomDate = DateTime.now();

    void onCustomRangeSelected(DateTimeRange newCustomRange) {
      customDates.clear();
      customxValues.clear();
      unfoundCustomDates.clear();
      unfoundCustomPoints.clear();
  
    // Update with the new selected range
    lastCustomRange = newCustomRange;
  
  }
  
  Widget _buildOption(BuildContext context, String title, String value) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () async {
            setState(() {
            });

            if (value == 'custom-time-period') {
              final DateTimeRange? dateTimeRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(3000),
                builder: (BuildContext context, Widget? child) => Theme(
                  data: Theme.of(context).copyWith(
                    scaffoldBackgroundColor: AppColors.defaultGray500,
                    textTheme: const TextTheme(
                      headlineMedium: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                        fontSize: 20,
                      ),
                      bodyMedium: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Titillium Web',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  child: child!,
                ),
              );
              if (dateTimeRange != null) {
                final DateFormat formatter = DateFormat('MMMM dd, yyyy');
                final String formattedStart = formatter.format(dateTimeRange.start);
                final String formattedEnd = formatter.format(dateTimeRange.end);


                final DateTime startDate = dateTimeRange.start;
                final DateTime endDate = dateTimeRange.end;


 
                setState(() {
                  onCustomRangeSelected(dateTimeRange);

                  firstCustomDate = startDate;
                  lastCustomDate = endDate;
                  lastCustomRange = dateTimeRange;
                  dropdownValue = 'custom-time-period';
                  lastCustomDateRange = '$formattedStart - $formattedEnd';
                });
                Navigator.pop(context); // Close the bottom sheet
              } else {
              }
            } else {
              setState(() {
                dropdownValue = value;
                Navigator.pop(context); // Close the bottom sheet
              });
            }
          },
          child: Container(
            width: double.infinity,
            color: const Color.fromRGBO(94, 181, 171, 0),
            child: Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: dropdownValue == value
                    ? AppColors.defaultBlue500
                    : Colors.transparent, // Change the color based on whether the option is selected
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Titillium Web')),
              ),
            ),
          ),
        ),
      );
  
  String text = '';
  
  Widget bottomTitlesWidget(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
  
    if (dropdownValue == 'custom-time-period') {
      final int numberOfDays = lastCustomRange.end.difference(lastCustomRange.start).inDays + 1;
                final DateTime firstDate = lastCustomRange.start;

      if (numberOfDays == 0) {
        text = DateFormat('MMM dd yy').format(firstDate); // Format the first date
      } else if (numberOfDays <= 12) {
        if (value.toInt() < numberOfDays) {
          final DateTime date = lastCustomRange.start.add(Duration(days: value.toInt()));
          if (numberOfDays == 7) {
            text = DateFormat('EEE').format(date); // Format to 'EEE' for day names if days are exactly 7
          } else if (numberOfDays <= 4) {
            text = DateFormat('MMM dd').format(date); // Format to 'MMM dd yyyy' if days are 6 or less
          } else {
            text = DateFormat('d').format(date); // Format to get the day of the month
          }
        } else {
          text = DateFormat('MMM dd yyyy').format(firstDate);
        }
      } else if (numberOfDays > 12) {
        final int numberOfDays = lastCustomRange.end.difference(lastCustomRange.start).inDays + 1;
        final int numberOfMonths = lastCustomRange.end.month - lastCustomRange.start.month + 
                                   (lastCustomRange.end.year - lastCustomRange.start.year) * 12;
        final DateTime firstDate = lastCustomRange.start;
        final DateTime middleDate = lastCustomRange.start.add(Duration(days: numberOfDays ~/ 2));
        final DateTime lastDate = lastCustomRange.end;
  
        
          switch (value.toInt()) {
            case 0:
              text = DateFormat('MMM dd, yy').format(firstDate); // Format the first date
              break;
            case 1:
              text = DateFormat('MMM dd').format(middleDate); // Format the middle date
              break;
            case 2:
              text = DateFormat('MMM dd, yy').format(lastDate); // Format the last date
              break;
            default:
              text = '';
          }
        
            }
    } else {
    
    switch (value.toInt()) {
        case 0:
          if (dropdownValue == 'last-week') {
            text = timeline.lastWeekDays[0];
          }
          if (dropdownValue == 'last-month') {
            text = timeline.lastMonthDays[0];
          }
          if (dropdownValue == 'last-6-months') {
            text = timeline.lastSixMonths[0];
          }
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[0];
          }
          break;
        case 1:
          if (dropdownValue == 'last-week') {
            text = timeline.lastWeekDays[1];
          }
          if (dropdownValue == 'last-month') {
            text = timeline.lastMonthDays[1];
          }
          if (dropdownValue == 'last-6-months') {
            text = timeline.lastSixMonths[1];
          }
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[1];
          }
          break;
        case 2:
          if (dropdownValue == 'last-week') {
            text = timeline.lastWeekDays[2];
          }
          if (dropdownValue == 'last-month') {
            text = timeline.lastMonthDays[2];
          }
          if (dropdownValue == 'last-6-months') {
            text = timeline.lastSixMonths[2];
          }
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[2];
          }
          break;
        case 3:
          if (dropdownValue == 'last-week') {
            text = timeline.lastWeekDays[3];
          }
          if (dropdownValue == 'last-6-months') {
            text = timeline.lastSixMonths[3];
          }
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[3];
          }
          break;
        case 4:
          if (dropdownValue == 'last-week') {
            text = timeline.lastWeekDays[4];
          }
          if (dropdownValue == 'last-6-months') {
            text = timeline.lastSixMonths[4];
          }
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[4];
          }
          break;
        case 5:
          if (dropdownValue == 'last-week') {
            text = timeline.lastWeekDays[5];
          }
          if (dropdownValue == 'last-6-months') {
            text = timeline.lastSixMonths[5];
          }
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[5];
          }
          break;
        case 6:
          if (dropdownValue == 'last-week') {
            text = timeline.lastWeekDays[6];
          }
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[6];
          }
          break;
        case 7:
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[7];
          }
          break;
        case 8:
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[8];
          }
          break;
        case 9:
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[9];
          }
          break;
        case 10:
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[10];
          }
          break;
        case 11:
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[11];
          }
          break;
        case 12:
          if (dropdownValue == 'last-year') {
            text = timeline.lastYearMonths[12];
          }
          break;
        default:
          return const Text('');
      }
    }
  
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 3,
      child: Column(
        children: [
          Text(
            text,
            style: style,
          ),
        ],
      ),
    );
  }

  FlTitlesData get titlesData => FlTitlesData(
      topTitles: const AxisTitles(
        sideTitles: SideTitles(
          showTitles: false
        )
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50, // Adjust this value as needed
          getTitlesWidget: (value, meta) {
            if (value == 0) {
              return const Text(''); // Skip the minimum y label
            }
            return Text(_abbreviateNumber(value));
          },
        ),
      ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(
        showTitles: false
        )
      ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1,
        getTitlesWidget: bottomTitlesWidget,
      ),
    ),
  );

  String getDropdownValueName(String dropDownValue) {
    switch (dropDownValue) {
      case 'last-week':
        return 'Last Week';
      case 'last-month':
        return 'Last Month';
      case 'last-6-months':
        return 'Last 6 Months';
      case 'last-year':
        return 'Last Year';
      case 'custom-time-period':
        return 'Custom';
      default:
        return 'Unknown';
    }
  }

  double maxX(String dropdownValue) {
    switch (dropdownValue) {
      case 'last-week':
        return 6;
      case 'last-month':
        return 2;
      case 'last-6-months':
        return 5;
      case 'last-year':
        return 12;
      case 'custom-time-period':
        double numberOfDays = lastCustomRange.end.difference(lastCustomRange.start).inDays + 0;
        if (numberOfDays == 0) {
          return 1;
        }
        if (numberOfDays >= 12) {
          return 2; 
        }
        return numberOfDays;
              default:
        return 6;
    }
  }

  void ensureEnoughDates(List<DateTime> dates, DateTime startDate, DateTime endDate) {
  // Ensure dates are sorted
  dates.sort((a, b) => a.compareTo(b));

  // Create a set of existing dates for quick lookup
  final existingDates = dates.map((date) => date.toIso8601String()).toSet();

  // Iterate from startDate to endDate and add missing dates
  for (DateTime date = startDate; date.isBefore(endDate) || date.isAtSameMomentAs(endDate); date = date.add(const Duration(days: 1))) {
    if (!existingDates.contains(date.toIso8601String())) {
      dates.add(date);
    }
  }

  // Sort dates again after adding missing dates
  dates.sort((a, b) => a.compareTo(b));
}

  double roundToNearest(double value) {
    
    if (value >= 100000000) {
      double result = (value / 100000000).round() * 100000000;
      return result;
    } else if (value >= 10000000) {
      double result = (value / 10000000).round() * 10000000;
      return result;
    } else if (value >= 1000000) {
      double result = (value / 1000000).round() * 1000000;
      return result;
    } else if (value >= 100000) {
      double result = (value / 100000).round() * 100000;
      return result;
    } else if (value >= 10000) {
      double result = (value / 10000).round() * 10000;
      return result;
    } else if (value >= 1000) {
      double result = (value / 1000).round() * 1000;
      return result;
    } else if (value >= 500) {
      double result = (value / 500).round() * 500;
      return result;
    } else {
      double result = value.round().toDouble();
      return result;
    }
  }

  double calculateMaxY(double maxAmount) {
    double roundedMaxAmount = roundToNearest(maxAmount);
    double maxY = (roundedMaxAmount * 1.5).roundToDouble();

    if (maxY >= 10000000) {
      maxY = (maxY / 10000000).round() * 10000000;
    } else if (maxY >= 1000000) {
      maxY = (maxY / 1000000).round() * 1000000;
    } else if (maxY >= 100000) {
      maxY = (maxY / 100000).round() * 100000;
    } else if (maxY >= 10000) {
      maxY = (maxY / 10000).round() * 10000;
    } else if (maxY >= 1000) {
      maxY = (maxY / 1000).round() * 1000;
    }

    return maxY;
  }

    // ignore: unused_element
    Widget _buildLineChartSection(double totalUserAssets, double percentageAGQ, double percentageAK1) => Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 30, 41, 59),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
        
            
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  const Text(
                    'Asset Timeline',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.defaultBlueGray800,
                      builder: (BuildContext context) => SingleChildScrollView(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                          child: Container(
                            color: AppColors.defaultBlueGray800,
                            child: Wrap(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                          height: 20.0), // Add some space at the top
                                      const Padding(
                                        padding: EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Choose Time Period',
                                            style: TextStyle(
                                                fontSize: 22.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontFamily: 'Titillium Web'),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20.0), // Add some space between the title and the options
                                      _buildOption(context, 'Last Week', 'last-week'),
                                      _buildOption(context, 'Last Month', 'last-month'),
                                      _buildOption(context, 'Last 6 Months', 'last-6-months'),
                                      _buildOption(context, 'Last Year', 'last-year'),
                                      _buildOption(context, 'Customize Time Period', 'custom-time-period'),
                                      const SizedBox(
                                          height: 20.0), // Add some space at the bottom
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color.fromARGB(121, 255, 255, 255),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          children: [
                            Text(
                              getDropdownValueName(dropdownValue),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 25, color: Color.fromARGB(212, 255, 255, 255)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
        
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(right: 20, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Color.fromARGB(255, 102, 102, 102),
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: titlesData,
                      borderData: FlBorderData(
                        show: false,
                      ),
                      minX: 0,
                      maxX: maxX(dropdownValue),
                      minY: 0,
                      maxY: calculateMaxY(maxAmount),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true, // Set to true to enable curves
                          curveSmoothness: 0.15, // Adjust this value to control the smoothness (0.0 to 1.0)
                          color: AppColors.defaultBlue300,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.defaultBlue300, // Blue color for the circle
                              strokeWidth: 2, // Width of the white outline
                              strokeColor: Colors.white, // White color for the outline
                            ),
                          ),
                          belowBarData: BarAreaData(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.defaultBlue300,
                                AppColors.defaultBlue500,
                                AppColors.defaultBlue500.withOpacity(0.2),
                              ],
                            ),
                            show: true,
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: AppColors.defaultBlueGray100,
                          tooltipRoundedRadius: 16.0,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            if (dropdownValue == 'last-week') {
                              foundSpotsDatesInLastWeek.sort((a, b) => a.compareTo(b));
                              DateTime now = DateTime.now();
                              DateTime startOfLastWeek = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
                              DateTime endOfLastWeek = DateTime(now.year, now.month, now.day);
                              ensureEnoughDates(foundSpotsDatesInLastWeek, startOfLastWeek, endOfLastWeek);
                            } else if (dropdownValue == 'last-month') {
                              foundSpotsDatesInLastMonth.sort((a, b) => a.compareTo(b));
                              DateTime now = DateTime.now();
                              DateTime startOfLastMonth = DateTime(now.year, now.month - 1, now.day);
                              DateTime endOfLastMonth = DateTime(now.year, now.month, now.day);
                              ensureEnoughDates(foundSpotsDatesInLastMonth, startOfLastMonth, endOfLastMonth);
                            } else if (dropdownValue == 'last-6-months') {
                              DateTime now = DateTime.now();
                              DateTime startOfLast6Months = DateTime(now.year, now.month - 6, now.day);
                              DateTime endOfLast6Months = DateTime(now.year, now.month, now.day);
                            } else if (dropdownValue == 'custom-time-period') {
                              // Handle custom time period
                              customDates.sort((a, b) => a.compareTo(b));
                            }
                      
                            return touchedSpots.map((barSpot) {
                              final flSpot = barSpot;
                              final yValue = flSpot.y;
                              final xValue = flSpot.x;
                      
                              if (dropdownValue == 'last-week') {
                                if (!lastWeekxValues.contains(xValue)) {
                                  lastWeekxValues.add(xValue);
                                  lastWeekDates.add(DateTime.now().subtract(Duration(days: (6 - xValue.toInt()))));
                                }
                              } else if (dropdownValue == 'last-month') {
                                if (!lastMonthxValues.contains(xValue)) {
                                  lastMonthxValues.add(xValue);
                                  DateTime now = DateTime.now();
                                  DateTime startOfLastMonth = DateTime(now.year, now.month - 1, now.day);
                                  lastMonthDates.add(startOfLastMonth.add(Duration(days: xValue.toInt())));
                                }
                              } else if (dropdownValue == 'last-6-months') {
                                if (!lastSixMonthsxValues.contains(xValue)) {
                                  lastSixMonthsxValues.add(xValue);
                                  lastSixMonthsDates.add(DateTime.now().subtract(Duration(days: (180 - xValue.toInt()))));
                                }
                              } else if (dropdownValue == 'custom-time-period') {
                                if (!customxValues.contains(xValue)) {
                                  customxValues.add(xValue);
                                  if (xValue.toInt() < customDates.length) {
                                    customDates.add(customDates[xValue.toInt()]); // Assuming customDates is already populated with the correct dates
                                  } else {
                                  }
                                }
                              } else {
                                if (!lastYearxValues.contains(xValue)) {
                                  lastYearxValues.add(xValue);
                                  DateTime now = DateTime.now();
                                  DateTime startOfLastYear = DateTime(now.year - 1, now.month, now.day);
                                  lastYearDates.add(startOfLastYear.add(Duration(days: xValue.toInt())));
                                }
                              }
                      
                              int index;
                              if (dropdownValue == 'last-week') {
                                index = lastWeekxValues.indexOf(xValue);
                              } else if (dropdownValue == 'last-month') {
                                index = lastMonthxValues.indexOf(xValue);
                              } else if (dropdownValue == 'last-6-months') {
                                index = lastSixMonthsxValues.indexOf(xValue);
                              } else if (dropdownValue == 'custom-time-period') {
                                index = customxValues.indexOf(xValue);
                              } else {
                                index = lastYearxValues.indexOf(xValue);
                              }
                      
                              DateTime correspondingDate;
                              if (dropdownValue == 'last-week') {
                                correspondingDate = lastWeekDates[index];
                              } else if (dropdownValue == 'last-month') {
                                correspondingDate = lastMonthDates[index];
                              } else if (dropdownValue == 'last-6-months') {
                                correspondingDate = lastSixMonthsDates[index];
                              } else if (dropdownValue == 'custom-time-period') {
                                correspondingDate = customDates[index];
                              } else {
                                correspondingDate = lastYearDates[index];
                              }
                      
                              final formattedYValue = NumberFormat.currency(symbol: '\$').format(yValue);
                              final formattedDate = DateFormat('MMM, dd').format(correspondingDate);
                      
                              return LineTooltipItem(
                                '$formattedYValue\n$formattedDate',
                                const TextStyle(
                                  color: AppColors.defaultBlue300,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Titillium Web',
                                  fontSize: 16,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.defaultBlue500,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    'Total assets timeline',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                ],
              ),
            ), 
            const SizedBox(height: 40),
            Builder(
              builder: (context) {
                String displayText;
                switch (dropdownValue) {
                  case 'last-week':
                    displayText = timeline.lastWeekRange;
                    break;
                  case 'last-month':
                    displayText = timeline.lastMonthRange;
                    break;
                  case 'last-6-months':
                    displayText = timeline.lastSixMonthsRange;
                    break;
                  case 'last-year':
                    displayText = timeline.lastYearRange;
                    break;
                  case 'custom-time-period':
                    displayText = lastCustomDateRange;
                    break;
                  default:
                    displayText = 'Select a range';
                }
                return GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.defaultBlueGray800,
                      builder: (BuildContext context) => SingleChildScrollView(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                          child: Container(
                            color: AppColors.defaultBlueGray800,
                            child: Wrap(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                          height: 20.0), // Add some space at the top
                                      const Padding(
                                        padding: EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Choose Time Period',
                                            style: TextStyle(
                                                fontSize: 22.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontFamily: 'Titillium Web'),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20.0), // Add some space between the title and the options
                                      _buildOption(context, 'Last Week', 'last-week'),
                                      _buildOption(context, 'Last Month', 'last-month'),
                                      _buildOption(context, 'Last 6 Months', 'last-6-months'),
                                      _buildOption(context, 'Last Year', 'last-year'),
                                      _buildOption(context, 'Customize Time Period', 'custom-time-period'),
                                      const SizedBox(
                                          height: 20.0), // Add some space at the bottom
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      );
                    },
                  child: Container(
                    color: Colors.transparent,
                    child: Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Column(
                          children: [
                            Text(
                              displayText,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                                fontStyle: FontStyle.italic
                              ),
                            ),
                            if (spots.isEmpty) // Check if spots is empty
                              const Column(
                                children: [
                                  SizedBox(height: 25),
                                  Row(
                                    children: [
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.circle,
                                        size: 20,
                                        color: AppColors.defaultBlue500,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'No data available for this time period',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Titillium Web',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );


  Widget _buildAssetsStructureSection(double totalUserAssets, double percentageAGQ, double percentageAK1) => Container(
    width: double.infinity,
    height: 520,
    padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 30, 41, 59),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [

        const SizedBox(height: 10),
        
        const Row(
          children: [
            SizedBox(width: 5),
            Text(
              'Assets Structure',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Titillium Web',
              ),
            )
          ],
          
        ),
        
        const SizedBox(height: 60),

        Container(
          width: 250,
          height: 250,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: 120,
                  centerSpaceRadius: 100,
                  sectionsSpace: 10,
                  sections: [
                    PieChartSectionData(
                      color: const Color.fromARGB(255,12,94,175),
                      radius: 25,
                      value: percentageAGQ,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      color: const Color.fromARGB(255,49,153,221),
                      radius: 25,
                      value: percentageAK1,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [ 
                                      
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  
                    Text(
                      currencyFormat(totalUserAssets),
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
        
        const Row(
          children: [
            SizedBox(width: 30),
            Text(
              'Type',
              style: TextStyle(
                fontSize: 16, 
                color: Color.fromARGB(255, 216, 216, 216), 
                fontFamily: 'Titillium Web', 
              ),
            ),
            Spacer(), // This will push the following widgets to the right
            Text(
              '%',
              style: TextStyle(
                fontSize: 16, 
                color: Color.fromARGB(255, 216, 216, 216), 
                fontFamily: 'Titillium Web', 
              ),
            ),
            SizedBox(width: 10),
          ],
        ),
                
        const SizedBox(height: 5),

        const Divider(
          thickness: 1.2,
          height: 1,
          color: Color.fromARGB(255, 102, 102, 102), 
          
        ),
      
        const SizedBox(height: 10),

        Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 20,
                      color: Color.fromARGB(255, 12, 94, 175),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AGQ Fund',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const Spacer(), // This will push the following widgets to the right
                    Text(
                      '${percentageAGQ.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 20,
                      color: Color.fromARGB(255, 49, 153, 221),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AK1 Fund',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const Spacer(), // This will push the following widgets to the right
                    Text(
                      '${percentageAK1.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ],
            )
              
      ],
    ),
  );


// This is the bottom navigation bar 
  Widget _buildBottomNavigationBar(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 30, right: 20, left: 20),
    height: 80,
    padding: const EdgeInsets.only(right: 10, left: 10),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 30, 41, 59),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          spreadRadius: 8,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const DashboardPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: const Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/dashboard_hollowed.svg',
              height: 22,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const AnalyticsPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: const Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/analytics_filled.svg',
              height: 25,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ActivityPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: const Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/activity_hollowed.svg',
              height: 22,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ProfilePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: const Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/profile_hollowed.svg',
              height: 22,
            ),
          ),
        ),
      ],
    ),
  );
}
