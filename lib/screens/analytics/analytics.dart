import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/database.dart';
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
          return buildAnalyticsPage(userSnapshot);
        }
      );
    }
  );  
  
  Scaffold buildAnalyticsPage(AsyncSnapshot<UserWithAssets> userSnapshot) {
    
    UserWithAssets user = userSnapshot.data!;
    String firstName = user.info['name']['first'] as String;
    String lastName = user.info['name']['last'] as String;
    String companyName = user.info['name']['company'] as String;
    Map<String, String> userName = {'first': firstName, 'last': lastName, 'company': companyName};
       
      return Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: <Widget>[
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.all(0.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        // Total assets section

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


  
}

// This is the app bar 
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
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
                  const Text(
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
  }
// This is the horizontal list of connected users
  Container buildHorizontalButtonList() {
    return Container(
      height: 40.0, // Make the buttons a little shorter
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          const SizedBox(width: 20.0), // Add some space before the first button
          ElevatedButton(
            child: const Text(
              'All',
              style: TextStyle(
                fontFamily: 'Titillium Web',
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
          // ... Add more buttons as needed
        ],
      ),                  
    );
  }

// This is the list of activities 
  Padding buildActivityContainer() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Aligns the children to the left
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'November 11',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container( // Container for the list of activities
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: Color.fromARGB(255, 19, 66, 105),
                          size: 50,
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AGQ Consulting LLC',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Fixed Income',
                              style: TextStyle(
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
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '\$1,000.00',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Titillium Web',
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Text(
                                  '2:27 PM',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                                const SizedBox(width: 7), // Add width
                                Container(
                                  height: 15, // You can adjust the height as needed
                                  child: const VerticalDivider(
                                    color: Colors.white,
                                    width: 1,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(width: 7), // Add width
                                const Text(
                                  'John Doe',
                                  style: TextStyle(
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
                    ),
                    const SizedBox(height: 15),
                    const Divider(
                      color: Color.fromARGB(255, 132, 132, 132),
                      thickness: 1,
                    ), // Add a divider between the activities
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// This is the bottom navigation bar 
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
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
              'assets/icons/analytics_filled.png',
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
              'assets/icons/activity_hollowed.png',
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

