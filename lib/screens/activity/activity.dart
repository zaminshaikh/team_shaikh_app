// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/utilities.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';


class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);
  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  int selectedIndex = 0;
  List<String> icons = [
    'assets/icons/dashboard_hollowed.png',
    'assets/icons/analytics_hollowed.png',
    'assets/icons/activity_filled.png',
    'assets/icons/profile_hollowed.png',
  ];

  late DatabaseService _databaseService;

  Future<void> _initData() async {
    // If the user is signed in (which should always be the case on this screen)
    User? user = FirebaseAuth.instance.currentUser;
    // If not, we return to login page
    if (user == null) {
      log('User is not logged in');
      await Navigator.pushReplacementNamed(context, '/login');
    }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(user!.uid, 1);
    // If there is no matching CID, redirect to login page and alert the user
    if (service == null) {
      log('No CID exists for user ${user.uid}... redirecting to login page');
      await CustomAlertDialog.showAlertDialog(context, 'User does not exist error!', 
        'The current user is not associated with any account... We will redirect you to the login page to sign in with a valid user.');
      await FirebaseAuth.instance.signOut(); // Sign that user out
      await Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Otherwise set the database service instance
      _databaseService = service;
      log('Database Service has been initialized with CID: ${_databaseService.cid}');
    }
  }

  dynamic getActivityType(Map<String, dynamic> activity) {
    switch(activity['type']){
      case 'income':
        if (activity['fund'] == 'AGQ Consulting LLC')
          return 'Fixed Income';
        return 'Dividend Payment';
      case 'deposit':
        return 'Deposit';
      case 'withdrawal':
        return 'Withdrawal';
      case 'pendingWithdrawal':
        return 'Pending Withdrawal...';
      default:
        return 'Error';
    }

  }

  Scaffold _buildActivityScreen(AsyncSnapshot<List<Map<String, dynamic>>> activitiesSnapshot) => Scaffold(
    body: CustomScrollView(
      slivers: <Widget>[
        _buildAppBar(),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final activities = activitiesSnapshot.data!;
              activities.sort((a, b) => b['time'].compareTo(a['time'])); // Sort the list by time in reverse order
              final activity = activities[index];
              return _buildActivityWithDayHeader(activity, index, activities);
            },
            childCount: activitiesSnapshot.data!.length,
          ),
        ),
      ],
    ),
    bottomNavigationBar: _buildBottomNavBar(),
  );

  /// If the activity is on a new day, we create a header stating the day.
  Widget _buildActivityWithDayHeader(Map<String, dynamic> activity, int index, List<Map<String, dynamic>> activities) {
    final activityDate = (activity['time'] as Timestamp).toDate();
    final previousActivityDate = index > 0 ? (activities[index - 1]['time'] as Timestamp).toDate() : null;

    if (previousActivityDate == null || !_isSameDay(activityDate, previousActivityDate)) {
      return Column(
        children: <Widget>[
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(activityDate),
            textAlign: TextAlign.left,
            style: const TextStyle(color: AppColors.defaultWhite),
            ), // Day header
          _buildActivity(activity), // Activity
        ],
      );
    } else {
      return _buildActivity(activity);
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) => 
    date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  
  Widget _buildBottomNavBar() => Container(
    margin: const EdgeInsets.only(bottom: 50, right: 20, left: 20),
        height: 80,
        padding: const EdgeInsets.only(right: 30, left: 30),
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
          children: List.generate(
            icons.length,
            (i) => GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = i;
                });

                switch (icons[i]) {
                  case 'assets/icons/analytics_hollowed.png':
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const AnalyticsPage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                      ),
                    );
                    break;

                  case 'assets/icons/dashboard_hollowed.png':
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                      ),
                    );
                    break;

                  case 'assets/icons/activity_hollowed.png':
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const ActivityPage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                      ),
                    );
                    break;

                  case 'assets/icons/profile_hollowed.png':
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                      ),
                    );
                    break;
                }

              },

              child: Image.asset(
                i == selectedIndex && icons[i] == 'assets/icons/dashboard_hollowed.png'
                  ? 'assets/icons/dashboard_hollowed.png'
                  : icons[i],
                height: 50,
              ),       
            ),
          ),
        ),    
      );

  Widget _buildActivity(Map<String, dynamic> activity) { 
        // Assuming activity['time'] is a Timestamp object
    Timestamp timestamp = activity['time'];

    // Convert the Timestamp to a DateTime
    DateTime dateTime = timestamp.toDate();

    // Create a new DateFormat for the desired time format
    DateFormat format = DateFormat('hh:mm a');

    // Use the format to format the dateTime
    String time = format.format(dateTime);
    
    return Row(
      children: [
        Icon(
          Icons.circle,
          color: Color.fromARGB(255, 19, 66, 105),
          size: 50,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity['fund'],
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Titillium Web',
              ),
            ),
            const SizedBox(height: 5),
            Text(
              getActivityType(activity),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                currencyFormat(activity['amount'].toDouble()),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ),
            SizedBox(height: 5),
            Row(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontFamily: 'Titillium Web',
                  ),
                ),
                SizedBox(width: 7), // Add width
                Container(
                  height: 15, // You can adjust the height as needed
                  child: const VerticalDivider(
                    color: Colors.white,
                    width: 1,
                    thickness: 1,
                  ),
                ),
                SizedBox(width: 7), // Add width
                Text(
                  activity['recipient'],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar() => const SliverAppBar(
    backgroundColor: Color.fromARGB(255, 30, 41, 59),
    automaticallyImplyLeading: false,
    expandedHeight: 80,
    floating: true,
    snap: true,
    pinned: true,
    flexibleSpace: SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 23,
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
        padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 10.0),
        child: Icon(
          Icons.notifications_none_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    ],
  );
  
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _initData(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: _databaseService.getActivities,
        builder: (context, activitiesSnapshot) {
          if (activitiesSnapshot.hasData){
            return _buildActivityScreen(activitiesSnapshot);
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        } 
      );
    }
  );
}

