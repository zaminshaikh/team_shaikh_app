import 'dart:developer';
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
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {

  // database service instance
  late DatabaseService _databaseService;

  Future<void> _initData() async {

    User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log('User is not logged in');
        Navigator.pushReplacementNamed(context, '/login');
      }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(user!.uid, 1);
    // If there is no matching CID, redirect to login page
    if (service == null) {
      Navigator.pushReplacementNamed(context, '/login');
} else {
      // Otherwise set the database service instance
      _databaseService = service;
      log('Database Service has been initialized with CID: ${_databaseService.cid}');
    }
  }
  
  /// Formats the given amount as a currency string.
  String _currencyFormat(double amount) => NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
    locale: 'en_US',
  ).format(amount);

  String dropdownValue = 'last-year';

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _initData(), // Initialize the database service
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return StreamBuilder<UserWithAssets>(
            stream: _databaseService.getUserWithAssets,
            builder: (context, userSnapshot) {
              // Wait for the user snapshot to have data
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              // Once we have the user snapshot, we can build the activity page
              return StreamBuilder<List<UserWithAssets>>(
                stream: _databaseService.getConnectedUsersWithAssets, // Assuming this is the stream for connected users
                builder: (context, connectedUsers) {
                  if (!connectedUsers.hasData || connectedUsers.data == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _databaseService.getNotifications,
                    builder: (context, notificationsSnapshot) {
                      if (!notificationsSnapshot.hasData || notificationsSnapshot.data == null) {
                        return const Center(
                          child: CircularProgressIndicator(),
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
    String firstName = user.info['name']['first'] as String;
    String lastName = user.info['name']['last'] as String;
    String companyName = user.info['name']['company'] as String;
    Map<String, String> userName = {
      'first': firstName,
      'last': lastName,
      'company': companyName
    };

    // Total assets of one user
    double totalUserAssets = 0.00,
        totalAGQ = 0.00,
        totalAK1 = 0.00,
        totalAssets = 0.00;
    double latestIncome = 0.00;

    // This is a calculation of the total assets of the user only
    for (var asset in user.assets) {
      switch (asset['fund']) {
        case 'AGQ Consulting LLC':
          totalAGQ += asset['total'];
          break;
        case 'AK1 Holdings LP':
          totalAK1 += asset['total'];
          break;
        default:
          latestIncome = (asset['ytd'] as num).toDouble();
          totalAssets += asset['total'];
          totalUserAssets += asset['total'];
      }
    }

    // This calculation is for the total assets of all connected users combined
    for (var user in connectedUsers.data!) {
      for (var asset in user.assets) {
        switch (asset['fund']) {
          case 'AGQ Consulting LLC':
            totalAGQ += asset['total'];
            break;
          case 'AK1 Holdings LP':
            totalAK1 += asset['total'];
            break;
          default:
            totalAssets += asset['total'];
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
                    transitionDuration: Duration(milliseconds: 450),
                    pageBuilder: (_, __, ___) => NotificationPage(),
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset(0.0, 0.0),
                        ).animate(animation),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Container(
                color: Color.fromRGBO(239, 232, 232, 0),
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
                                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
                                  color: Color(0xFF267DB5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '$unreadNotificationsCount',
                                  style: TextStyle(
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
  
    Widget _buildOption(BuildContext context, String title, String value) =>
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => setState(() {
            dropdownValue = value;
            Navigator.pop(context); // Close the bottom sheet
          }),
          child: Container(
            width: double.infinity,
            color: Color.fromRGBO(94, 181, 171, 0),
            child: Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: dropdownValue == value
                    ? AppColors.defaultBlue500
                    : Colors
                        .transparent, // Change the color based on whether the option is selected
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Container(
                padding: EdgeInsets.all(10),
                child: Text(title,
                    style: TextStyle(
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
    fontWeight: FontWeight.bold
  );
  switch (value.toInt()) {
    case 0:
      if (dropdownValue == 'last-week') {
        text = 'Sun';
      } 
      if (dropdownValue == 'last-month') {
        text = '1';
      } 
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Jan';
      } 
      break;
    case 1:
      if (dropdownValue == 'last-week') {
        text = 'Mon';
      } 
      if (dropdownValue == 'last-month') {
        text = '15';
      } 
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Feb';
      } 
      break;
    case 2:
      if (dropdownValue == 'last-week') {
        text = 'Tue';
      } 
      if (dropdownValue == 'last-month') {
        text = '30';
      } 
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Mar';
      } 
      break;
    case 3:
      if (dropdownValue == 'last-week') {
        text = 'Wed';
      } 
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Apr';
      } 
      break;
    case 4:
      if (dropdownValue == 'last-week') {
        text = 'Thu';
      } 
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'May';
      } 
      break;
    case 5:
      if (dropdownValue == 'last-week') {
        text = 'Fri';
      } 
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Jun';
      } 
      break;
    case 6:
      if (dropdownValue == 'last-week') {
        text = 'Sat';
      } 
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Jul';
      } 
      break;
    case 7:
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Aug';
      } 
      break;
    case 8:
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Sep';
      } 
      break;
    case 9:
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Oct';
      } 
      break;
    case 10:
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Nov';
      } 
      break;
    case 11:
      if (dropdownValue == 'last-6-months' || dropdownValue == 'last-year') {
        text = 'Dec';
      } 
      break;
    default:
      return Container();
  }
  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 3,
    child: Text(
      text,
      style: style,
    ),
  );
}

FlTitlesData get titlesData => FlTitlesData(
  topTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: false
      )
    ),
  rightTitles: AxisTitles(
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
        return 11;
      case 'custom-time-period':
        return 0;
      default:
        return 6;
    }
  }


    Widget _buildLineChartSection(double totalUserAssets, double percentageAGQ, double percentageAK1) => Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Container(
        width: double.infinity,
        height: 520,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 30, 41, 59),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
        
            
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'Asset Timeline',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                  ),

                  Spacer(),

                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.defaultBlueGray800,
        builder: (BuildContext context) => SingleChildScrollView(
          child: Container(
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20.0, 0, 0, 0),
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
                              style: TextStyle(
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
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: EdgeInsets.only( right: 10),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: const Color.fromARGB(255, 102, 102, 102),
                                strokeWidth: 0.5,
                              );
                            },
                          ),
                          titlesData: titlesData,

                          borderData: FlBorderData(
                            show: false,
                          ),
                          minX: 0,
                          maxX: maxX(dropdownValue),
                          minY: 0,
                          maxY: 10000,
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                FlSpot(0, 2000),
                                FlSpot(1, 6000),
                                FlSpot(2, 4000),
                                FlSpot(3, 5000),
                                FlSpot(4, 4000),
                                FlSpot(5, 3000),
                              ],
                              isCurved: true,
                              color: AppColors.defaultBlue500,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: AppColors.defaultBlueGray500,
                                    strokeWidth: 0,
                                    strokeColor: Colors.transparent,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.defaultBlue500,
                                    AppColors.defaultBlue500,
                                    AppColors.defaultBlue500.withOpacity(0.2),
                                  ],
                                ),
                                show: true,
                              ),
                            ),
                          ],
                        )
                      ),
                    ),
                  ),
                ],
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
                  SizedBox(width: 20),
                  Text(
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
                    Icon(
                      Icons.circle,
                      size: 20,
                      color: Color.fromARGB(255, 12, 94, 175),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'AGQ Fund',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    Spacer(), // This will push the following widgets to the right
                    Text(
                      '${percentageAGQ.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 20,
                      color: Color.fromARGB(255, 49, 153, 221),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'AK1H Fund',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    Spacer(), // This will push the following widgets to the right
                    Text(
                      '${percentageAK1.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    SizedBox(width: 10),
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
                    DashboardPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: Color.fromRGBO(239, 232, 232, 0),
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
            color: Color.fromRGBO(239, 232, 232, 0),
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
            color: Color.fromRGBO(239, 232, 232, 0),
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
            color: Color.fromRGBO(239, 232, 232, 0),
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
