import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {

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

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _initData(), // Initialize the database service
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: _databaseService.getNotifications,
        builder: (context, notificationsSnapshot) {
          // Wait for the user snapshot to have data
          if (!notificationsSnapshot.hasData || notificationsSnapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          // Once we have the user snapshot, we can build the activity page
          return _buildNotificationPage(notificationsSnapshot);
        }
      );
    }
  );  
  
  Scaffold _buildNotificationPage(AsyncSnapshot<List<Map<String, dynamic>>> notificationsSnapshot) => Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: <Widget>[
                _buildAppBar(context),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      Map<String, dynamic> notification = notificationsSnapshot.data![index];
                      String title;
                      String route = '/notification';
                      switch (notification['type']) {
                        case 'activity':
                          title = 'New Activity';
                          route = '/activity';
                          break;
                        case 'statement':
                          title = 'New Statement';
                          route = '/profile';
                          break;
                        default:
                          title = 'New Notification';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 5.0, left: 20.0, right: 20.0),
                        child: Column(
                          children: [
                            ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: AppTextStyles.lBold(color: AppColors.defaultWhite),
                                  ),
                                  SizedBox(height: 4), // Add desired spacing between title and subtitle
                                  Text(
                                    notification['message'],
                                    style: AppTextStyles.xsRegular(color: AppColors.defaultWhite),
                                  ),
                                ],
                              ),
                              trailing: !notification['isRead']
                                  ? const CircleAvatar(
                                      radius: 8,
                                      backgroundColor: AppColors.defaultBlue300,
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                              dense: true,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, route);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.defaultBlue300,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                ),
                                child: Text(
                                  'View More',
                                  style: AppTextStyles.lBold(color: AppColors.defaultWhite),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15.0),
                            const Divider(color: AppColors.defaultGray500),
                          ],
                        ),
                      );
                    },
                    childCount: notificationsSnapshot.data!.length,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// This is the app bar 
  SliverAppBar _buildAppBar(context) => SliverAppBar(
    backgroundColor: const Color.fromARGB(255, 30, 41, 59),
    toolbarHeight: 80,
    expandedHeight: 0,
    snap: false,
    floating: true,
    pinned: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
    flexibleSpace: const SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 60.0, right: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
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
          child: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 30.0),
            onPressed: () {},
          )
        ),
      ],
    );

