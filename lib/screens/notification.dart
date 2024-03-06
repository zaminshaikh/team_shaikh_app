import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/database.dart';

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
        await Navigator.pushReplacementNamed(context, '/login');
      }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(user!.uid, 1);
    // If there is no matching CID, redirect to login page
    if (service == null) {
      if (!mounted) { return; }
      await Navigator.pushReplacementNamed(context, '/login');
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
                  DateTime previousNotificationDate = index > 0 ? (notificationsSnapshot.data![index - 1]['time'] as Timestamp).toDate() : DateTime(0);
                  if (index == 0 || !_isSameDay(previousNotificationDate, (notification['time'] as Timestamp).toDate())) {
                    return _buildNotificationWithDayHeader(notification, previousNotificationDate);
                  }
                  return _buildNotification(notification, true);
                },
                childCount: notificationsSnapshot.data!.length,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildNotificationWithDayHeader(Map<String, dynamic> notification, DateTime previousNotificationDate) {
    final notificationDate = (notification['time'] as Timestamp).toDate();
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 5.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('MMMM d, yyyy').format(notificationDate),
              style: AppTextStyles.xl2(color: AppColors.defaultWhite),
            ),
          ),
        ), // Day header
        _buildNotification(notification, false),
         // Notification
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) => 
    date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
    
  Widget _buildNotification(Map<String, dynamic> notification, bool showDivider){
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
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 5.0, left: 20.0, right: 20.0),
      child: Column(
        children: [
          showDivider ? const Divider(
                color: AppColors.defaultGray500,
          ) : const SizedBox(height: 0,),
          ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.lBold(color: AppColors.defaultWhite),
                ),
                const SizedBox(height: 4), // Add desired spacing between title and subtitle
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
                : const CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.transparent,
                  ),
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
        ],
      ),
    );
  }
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

