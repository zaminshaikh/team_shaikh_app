// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:developer';
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
    print('analytics.dart: Last six months: ${months.reversed.toList()}');
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
    print('analytics.dart: Last week range: $formattedStart - $formattedEnd');
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
    print('analytics.dart: Last year range: $formattedStart - $formattedEnd');
    return '$formattedStart - $formattedEnd';
  }

  List<String> _calculateLastYearMonths() {
    List<String> months = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 13; i++) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('MM').format(month));
    }
    print('analytics.dart: Last 12 months: ${months.reversed.toList()}');
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
        log('analytics.dart: User is not logged in');
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
      log('analytics.dart: Database Service has been initialized with CID: ${_databaseService.cid}');
    }
  }
  
  /// Formats the given amount as a currency string.

  String dropdownValue = 'last-year';
  
  List<FlSpot> spots = [];
  List<DateTime> foundSpotsDatesInLastSixMonths = [];
  List<DateTime> foundSpotsDatesInLastWeek = [];
  List<DateTime> foundSpotsDatesInLastMonth = [];


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
        log('analytics.dart: graphPoints found: $graphPoints');
    
        bool spotAssignedZero = false; // Initialize spotAssignedZero
        bool pointAssignedLastCase = false; // Initialize pointAssignedLastCase
    
        // Convert the graphPoints array into a list of FlSpot objects
        spots = graphPoints.map((point) {
          DateTime dateTime = (point['time'] as Timestamp).toDate();
          double xValue = -1.0; // Assign an initial value to xValue
    
          if (dropdownValue == 'last-year') {
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
              print('Day difference: $dayDifference');
              print('Calculated xValue: $xValue');
              if (dayDifference == 0) {
                spotAssignedZero = true;
                print('spotAssignedZero: $spotAssignedZero');
              }
              if (dayDifference == 365) {
                pointAssignedLastCase = true;
                print('pointAssignedLastCase: $pointAssignedLastCase');
              }
            }          
            if (!found) {
              return null; // Return null if the point is not from the last week
            }
          
            if (pointAssignedLastCase) { // Step 3: Print the message
              print('Point assigned in the last case');
            } else {
              print('Point not assigned in the last case');
            } 
          }          

          else if (dropdownValue == 'last-6-months') {
            // Clear the list and set once when the dropdown value is selected
          
            bool found = false;
            DateTime normalizedDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
            DateTime now = DateTime.now();
            DateTime sixMonthsAgo = DateTime(now.year, now.month - 5, now.day);
            DateTime endOfsixMonthsAgo = DateTime(now.year, now.month, now.day);
          
            // Check if normalizedDateTime is within the last 6 months
            if (normalizedDateTime.isAfter(sixMonthsAgo.subtract(const Duration(days: 1))) && normalizedDateTime.isBefore(endOfsixMonthsAgo.add(const Duration(days: 1)))) {
              found = true;
              int dayDifference = normalizedDateTime.difference(sixMonthsAgo).inDays;
              int totalDays = endOfsixMonthsAgo.difference(sixMonthsAgo).inDays + 1; // Calculate total days in the last 6 months
              xValue = (dayDifference / totalDays) * 5; // Scale day to the range 0-12
              print('Day difference: $dayDifference');
              print('Calculated xValue: $xValue');
              print('Specific date for this spot: $normalizedDateTime');
              if (dayDifference == 0) {
                spotAssignedZero = true;
                print('spotAssignedZero: $spotAssignedZero');
              }
              if (dayDifference == 365) {
                pointAssignedLastCase = true;
                print('pointAssignedLastCase: $pointAssignedLastCase');
              }
            }
          
            if (!found) {
              return null; // Return null if the point is not from the last 6 months
            }
          
            // Ensure endOfsixMonthsAgo is added at the end only once
          }
          
          else if (dropdownValue == 'last-month') {
            bool found = false;
            DateTime now = DateTime.now();
            DateTime startOfLastMonth = DateTime(now.year, now.month - 1, now.day);
            DateTime endOfLastMonth = DateTime(now.year, now.month, now.day);
              if (!foundSpotsDatesInLastMonth.contains(startOfLastMonth)) {
                foundSpotsDatesInLastMonth.add(startOfLastMonth);
              }

            // Print the specific range of dates
            print('Start of last month: $startOfLastMonth');
            print('End of last month: $endOfLastMonth');
          
            // Normalize dateTime to only include the date part
            DateTime normalizedDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
            print('Normalized dateTime: $normalizedDateTime');
          
            // Check if normalizedDateTime is within the last month
            if (normalizedDateTime.isAfter(startOfLastMonth.subtract(const Duration(days: 1))) && normalizedDateTime.isBefore(endOfLastMonth.add(const Duration(days: 1)))) {
              int totalDays = endOfLastMonth.difference(startOfLastMonth).inDays + 1; // Calculate total days in the last month
              int day = normalizedDateTime.difference(startOfLastMonth).inDays + 1; // Calculate the day of the month
              print('Day: $day, Total days: $totalDays');
              if (!foundSpotsDatesInLastMonth.contains(normalizedDateTime)) {
                foundSpotsDatesInLastMonth.add(normalizedDateTime);
              }
          
              found = true;
              xValue = 2 * (day - 1) / (totalDays - 1); // Scale day to the range 0-2
              print('xValue: $xValue');
              if (day == 1) {
                spotAssignedZero = true;
              }
            } else {
              print('$normalizedDateTime Date is not within the last month');
            }
          
            if (!found) {
              print('Point not found in the last month');
              return null; // Return null if the point is not from the last month
            }
            if (!foundSpotsDatesInLastMonth.contains(endOfLastMonth)) {
              foundSpotsDatesInLastMonth.add(endOfLastMonth);
            }
          
            // Sort the dates in chronological order
            foundSpotsDatesInLastMonth.sort((a, b) => a.compareTo(b));
          
            print('Added today\'s date: $endOfLastMonth'); // Print the added date
            print('Found spots dates in the last week: $foundSpotsDatesInLastMonth');

          }

          else if (dropdownValue == 'last-week') {
            bool found = false;
            DateTime now = DateTime.now();
            DateTime startOfLastWeek = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
            DateTime endOfLastWeek = DateTime(now.year, now.month, now.day);
              if (!foundSpotsDatesInLastWeek.contains(startOfLastWeek)) {
                foundSpotsDatesInLastWeek.add(startOfLastWeek);
              }

          
            // Normalize dateTime to only include the date part
            DateTime normalizedDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
          
            // Check if normalizedDateTime is within the last week
            if (normalizedDateTime.isAfter(startOfLastWeek.subtract(const Duration(days: 1))) && normalizedDateTime.isBefore(endOfLastWeek.add(const Duration(days: 1)))) {
              found = true;
              print('Found date: $normalizedDateTime'); // Print the found date
              int dayDifference = normalizedDateTime.difference(startOfLastWeek).inDays;
              xValue = dayDifference.toDouble(); // Scale day to the range 0-6
          
              if (!foundSpotsDatesInLastWeek.contains(normalizedDateTime)) {
                foundSpotsDatesInLastWeek.add(normalizedDateTime);
              }
          
              if (dayDifference == 0) {
                spotAssignedZero = true;
                print('spotAssignedZero: $spotAssignedZero');
              }
              if (dayDifference == 6) {
                pointAssignedLastCase = true;
                print('pointAssignedLastCase: $pointAssignedLastCase');
              }
            }
          
            if (!found) {
              return null; // Return null if the point is not from the last week
            }
          
            if (pointAssignedLastCase) { // Step 3: Print the message
              print('Point assigned in the last case');
            } else {
              print('Point not assigned in the last case');
            }
          
            // Add today's date at the end of foundSpotsDatesInLastWeek
            if (!foundSpotsDatesInLastWeek.contains(endOfLastWeek)) {
              foundSpotsDatesInLastWeek.add(endOfLastWeek);
            }
          
            // Sort the dates in chronological order
            foundSpotsDatesInLastWeek.sort((a, b) => a.compareTo(b));
          
            print('Added today\'s date: $endOfLastWeek'); // Print the added date
            print('Found spots dates in the last week: $foundSpotsDatesInLastWeek');
          }

          else if (dropdownValue == 'custom-time-period') {
            bool found = false;
            final int numberOfDays = lastCustomRange.end.difference(lastCustomRange.start).inDays + 1;
            print('analytics.dart: Number of days: $numberOfDays');
            
            // Normalize dateTime to only include the date part
            DateTime normalizedDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
            
            // Check if normalizedDateTime is within the custom date range
            if (normalizedDateTime.isAfter(firstCustomDate) && normalizedDateTime.isBefore(lastCustomDate)) {
              found = true;
              foundSpotsDatesInLastSixMonths.add(normalizedDateTime);
              print('Found date: $normalizedDateTime within the custom date range');
              print('$normalizedDateTime has an amount of ${point['amount'].toDouble()}');
              
              // Calculate the position of the specific date within the custom range
              int dayDifference = normalizedDateTime.difference(firstCustomDate).inDays;
              
              // Scale this position to the maxX value
              double calculatedXValue = (dayDifference / numberOfDays) * maxX(dropdownValue);
              if (numberOfDays <= 7) {
                xValue = calculatedXValue.roundToDouble() + 1;
              } else {
                xValue = calculatedXValue;
              }
              print('Calculated xValue: $xValue');
            }          
            if (!found) {
              return null; // Return null if the point is not from the custom date range
            }
          }
          return FlSpot(xValue, point['amount'].toDouble());
        }).where((spot) => spot != null).cast<FlSpot>().toList();
    
        // Check if spotAssignedZero is false and add a point at the origin
        if (!spotAssignedZero && spots.isNotEmpty) {
          spots.insert(0, FlSpot(0, 0)); 
          print(spots);
        }
        
        // Check if pointAssignedLastCase is false and add a point at the last spot's xValue
        if (!pointAssignedLastCase && spots.isNotEmpty) {
          double lastXValue = maxX(dropdownValue); // Assuming the last case xValue is 6 for 'last-week'
          double lastAmount = spots.last.y;
          spots.add(FlSpot(lastXValue, lastAmount));
          print('Added last case spot: (${lastXValue}, ${lastAmount})');
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
    log('analytics.dart: Total AGQ: $totalAGQ, Total AK1: $totalAK1, Total Assets: $totalAssets, Total User Assets: $totalUserAssets, AGQ: $percentageAGQ, Percentage AK1: $percentageAK1');

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
      return result == result.toInt() ? result.toInt().toString() + 'M' : result.toStringAsFixed(1) + 'M';
    } else if (value >= 1000 && value < 1000000) {
      double result = value / 1000;
      return result == result.toInt() ? result.toInt().toString() + 'K' : result.toStringAsFixed(1) + 'K';
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
  
  Widget _buildOption(BuildContext context, String title, String value) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () async {
            setState(() {
              foundSpotsDatesInLastSixMonths.clear();
              print('Found spots dates cleared: $foundSpotsDatesInLastSixMonths');
            });

            if (value == 'custom-time-period') {
              print('Custom time period selected');
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
                print('Date range selected: ${dateTimeRange.start} to ${dateTimeRange.end}');
                final DateFormat formatter = DateFormat('MMMM dd, yyyy');
                final String formattedStart = formatter.format(dateTimeRange.start);
                final String formattedEnd = formatter.format(dateTimeRange.end);
                print('Formatted date range: $formattedStart to $formattedEnd');


                final DateTime startDate = dateTimeRange.start;
                final DateTime endDate = dateTimeRange.end;


 
                setState(() {
                  firstCustomDate = startDate;
                  lastCustomDate = endDate;
                  lastCustomRange = dateTimeRange;
                  dropdownValue = 'custom-time-period';
                  lastCustomDateRange = '$formattedStart - $formattedEnd';
                });
                Navigator.pop(context); // Close the bottom sheet
              } else {
                print('Date range selection was canceled');
              }
            } else {
              setState(() {
                dropdownValue = value;
                print('Selected value: $dropdownValue');
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
        if (lastCustomRange != null) {
          final int numberOfDays = lastCustomRange.end.difference(lastCustomRange.start).inDays + 1;
          final int numberOfMonths = lastCustomRange.end.month - lastCustomRange.start.month + 
                                     (lastCustomRange.end.year - lastCustomRange.start.year) * 12;
          print('analytics.dart: Number of days: $numberOfDays, Number of months: $numberOfMonths');
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
        if (lastCustomRange != null) {
          double numberOfDays = lastCustomRange.end.difference(lastCustomRange.start).inDays + 0;
          if (numberOfDays == 0) {
          print('analytics.dart: Number of days: $numberOfDays');
            return 1;
          }
          if (numberOfDays >= 12) {
          print('analytics.dart: Number of days: $numberOfDays');
            return 2; 
          }
          print('analytics.dart: Number of days: $numberOfDays');
          return numberOfDays;
        } else {
          return 0; // Return 0 if lastCustomRange is null
        }
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
  for (DateTime date = startDate; date.isBefore(endDate) || date.isAtSameMomentAs(endDate); date = date.add(Duration(days: 1))) {
    if (!existingDates.contains(date.toIso8601String())) {
      dates.add(date);
    }
  }

  // Sort dates again after adding missing dates
  dates.sort((a, b) => a.compareTo(b));
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
                      maxY: 10000000,
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
                              // Ensure foundSpotsDatesInLastWeek is sorted
                              foundSpotsDatesInLastWeek.sort((a, b) => a.compareTo(b));
                      
                              DateTime now = DateTime.now();
                              DateTime startOfLastWeek = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
                              DateTime endOfLastWeek = DateTime(now.year, now.month, now.day);
                      
                              // Ensure the dates range from startOfLastWeek to endOfLastWeek
                              ensureEnoughDates(foundSpotsDatesInLastWeek, startOfLastWeek, endOfLastWeek);
                            }
                            if (dropdownValue == 'last-month') {
                              // Ensure foundSpotsDatesInLastWeek is sorted
                              foundSpotsDatesInLastMonth.sort((a, b) => a.compareTo(b));
                      
                              DateTime now = DateTime.now();
                              DateTime startOfLastMonth = DateTime(now.year, now.month - 1, now.day);
                              DateTime endOfLastMonth = DateTime(now.year, now.month, now.day);
                      
                              // Ensure the dates range from startOfLastWeek to endOfLastWeek
                            }
                      
                            return touchedSpots.map((barSpot) {
                              final flSpot = barSpot;
                              final yValue = flSpot.y;
                      
                              // Format the y-value as currency
                              final formattedYValue = NumberFormat.currency(symbol: '\$').format(yValue);
                      
                              return LineTooltipItem(
                                formattedYValue,
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
                    displayText = '${timeline.lastWeekRange}';
                    break;
                  case 'last-month':
                    displayText = '${timeline.lastMonthRange}';
                    break;
                  case 'last-6-months':
                    displayText = '${timeline.lastSixMonthsRange}';
                    break;
                  case 'last-year':
                    displayText = '${timeline.lastYearRange}';
                    break;
                  case 'custom-time-period':
                    displayText = '$lastCustomDateRange';
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
                              Column(
                                children: [
                                  const SizedBox(height: 25),
                                  Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.circle,
                                        size: 20,
                                        color: AppColors.defaultBlue500,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
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
