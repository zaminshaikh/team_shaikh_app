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

  bool _isSameDay(DateTime date1, DateTime date2) => 
    date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
    
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

  Scaffold _buildActivityScreen(AsyncSnapshot<List<Map<String, dynamic>>> activitiesSnapshot) => Scaffold(
    body: Stack(
      children: [
        CustomScrollView(
          slivers: <Widget>[
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.only(top: 20.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return _buildSearchBar();
                    } else if (index == 1) {
                      return _buildHorizontalButtonList([]); // Add your button list here
                    } else {
                      final activities = activitiesSnapshot.data!;
                      activities.sort((a, b) => b['time'].compareTo(a['time'])); // Sort the list by time in reverse order
                      final activity = activities[index - 2]; // Subtract 2 because the first index is used by the search bar and the second by the button list
                      return _buildActivityWithDayHeader(activity, index - 2, activities);
                    }
                  },
                  childCount: activitiesSnapshot.data!.length + 2, // Add 2 to include the search bar and the button list
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: const SizedBox(height: 150.0), // Add some space at the bottom
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomNavBar(),
        ),
      ],
    ),
  );  
  
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
                  'Activity',
                  style: const TextStyle(
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
          padding: const EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/notification');
            },
            child: Image.asset(
              'assets/icons/notification_bell.png',
              color: Colors.white,
              height: 32,
              width: 32,
            ),
          ),
        ),
      ],
    );
  
  // If the activity is on a new day, we create a header stating the day.
  Widget _buildActivityWithDayHeader(Map<String, dynamic> activity, int index, List<Map<String, dynamic>> activities) {
    final activityDate = (activity['time'] as Timestamp).toDate();
    final previousActivityDate = index > 0 ? (activities[index - 1]['time'] as Timestamp).toDate() : null;
    final nextActivityDate = index < activities.length - 1 ? (activities[index + 1]['time'] as Timestamp).toDate() : null;
    final firstActivityDate = (activities[0]['time'] as Timestamp).toDate();

    bool isLastActivityForTheDay = nextActivityDate == null || !_isSameDay(activityDate, nextActivityDate);
    bool isLatestDate = _isSameDay(activityDate, firstActivityDate);

    if (previousActivityDate == null || !_isSameDay(activityDate, previousActivityDate)) {
      return Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(20.0, isLatestDate ? 20.0 : 40.0, 20.0, 25.0), // Add padding to the top only if it's not the latest date
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('MMMM d, yyyy').format(activityDate),
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ),
          ), // Day header
          _buildActivity(activity, !isLastActivityForTheDay), // Activity
        ],
      );
    } else {
      return _buildActivity(activity, !isLastActivityForTheDay);
    }
  }
  
  Widget _buildActivity(Map<String, dynamic> activity, bool showDivider, ) { 

        // Assuming activity['time'] is a Timestamp object
        Timestamp timestamp = activity['time'];

        // Convert the Timestamp to a DateTime
        DateTime dateTime = timestamp.toDate();

        // Create a new DateFormat for the desired time format
        DateFormat format = DateFormat('h:mm a'); 

        // Use the format to format the dateTime
        String time = format.format(dateTime);

        Color getColorBasedOnActivityType(String activityType) {
          switch (activityType) {
            case 'deposit':
              return Colors.green;
            case 'withdrawal':
              return Colors.red;
            case 'income':
              return Colors.blue;
            default:
              return Colors.blue;
          }
        }
        
      return Column(
        children: [
          
          Padding(
            padding: EdgeInsets.fromLTRB(25.0, 5.0, 25.0, 5.0),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: getColorBasedOnActivityType(activity['type']),
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
                      style: TextStyle(
                        fontSize: 15,
                        color: getColorBasedOnActivityType(activity['type']),
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
                        style: TextStyle(
                          fontSize: 18,
                          color: getColorBasedOnActivityType(activity['type']),
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
                            fontSize: 13,
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
                            fontSize: 13,
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
            ),
          ),
          
          if (showDivider)
            Padding(
              padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
              child: const Divider(
                color: Color.fromARGB(255, 132, 132, 132),
                thickness: 0.2,
              ),
            )
        ],
      );
    }

  Container _buildHorizontalButtonList(List<Map<String, String>> users) => Container(
    height: 35.0, 
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: <Widget>[
        const SizedBox(width: 20.0), // Add some space before the first button
        ElevatedButton(
          child: const Text(
            'All',
            style: TextStyle(
              fontFamily: 'Titillium Web',
              fontSize: 16,
              color: Colors.white, // Make the text white
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          onPressed: () {
            // Implement your button functionality here
          },
        ),
        const SizedBox(width: 10.0), // Add some space between the buttons
        ...users.map((user) => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: ElevatedButton(
            child: Text(
              '${user['first']} ${user['last']}',
              style: const TextStyle(
                fontFamily: 'Titillium Web',
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            onPressed: () {
              // Implement your button functionality here
            },
          ),
        )).toList(),
      ],
    ),
  );

  // This is the search bar area 
    Padding _buildSearchBar() => Padding(
      padding: const EdgeInsets.fromLTRB(20.0,10,20,25),
      child: Container(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50.0, // Set the height of the TextField
                child: TextField(
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Titillium Web',
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(5.0), // Add padding to TextField
                    hintText: 'Search by title',
                    hintStyle: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    prefixIcon: Image.asset(
                      'assets/icons/search_icon.png',
                      color: Colors.white,
                      height: 24,
                      width: 24,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Image.asset(
                'assets/icons/filter.png',
                color: Colors.white,
                height: 24,
                width: 24,
              ),
              onPressed: () {
                // Implement your filter functionality here
              },
            ),
            IconButton(
              icon: Image.asset(
                'assets/icons/sort.png',
                color: Colors.white,
                height: 24,
                width: 24,
              ),
              onPressed: () {
                // Implement your sort functionality here
              },
            ),
          ],
        ),
      ),
    );

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
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            },
            child: Image.asset(
              'assets/icons/dashboard_hollowed.png',
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const AnalyticsPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            },
            child: Image.asset(
              'assets/icons/analytics_hollowed.png',
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ActivityPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );},
            child: Image.asset(
              'assets/icons/activity_filled.png',
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            },
            child: Image.asset(
              'assets/icons/profile_hollowed.png',
              height: 50,
            ),
          ),
        ],
      ),
    );

}



