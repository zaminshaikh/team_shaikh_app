import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);
  @override
  _NotificationPageState createState() => _NotificationPageState();
}
String uid = '';

class _NotificationPageState extends State<NotificationPage> {

  // database service instance
  late DatabaseService _databaseService;
  

  Future<void> _initData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('notification.dart: User is not logged in');
      await Navigator.pushReplacementNamed(context, '/login');
    }
    // Define uid as a string
    uid = user!.uid;

    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(uid, 3);
    // If there is no matching CID, redirect to login page
    if (service == null) {
      if (!mounted) { return; }
      await Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Otherwise set the database service instance
      _databaseService = service;
      log('notification.dart: Database Service has been initialized with CID: ${_databaseService.cid}');

      // Call the logNotificationIds method
      await _databaseService.logNotificationIds();
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
          // If there are no notifications, display a message
          if (notificationsSnapshot.data!.isEmpty) {
            return Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  _buildAppBar(context),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SvgPicture.asset(
                            'assets/icons/empty_notifications.svg',
                          ),
                          const Text(
                            'No notifications.',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Titillium Web',
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Once we have the user snapshot, we can build the activity page
          // use unreadNotificationsCount as needed
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
            const SliverToBoxAdapter(
              child: SizedBox(height: 150),
            ),
          ],
        ),
      ],
    ),
    floatingActionButton: _buildMarkAllAsReadButton(notificationsSnapshot),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );

  Widget _buildMarkAllAsReadButton(AsyncSnapshot<List<Map<String, dynamic>>> notificationsSnapshot) {
    // Assuming notifications is your list of notifications
    bool hasUnreadNotifications = notificationsSnapshot.data!.any((notification) => !notification['isRead'] );

    if (!hasUnreadNotifications) {
      return Container(); // Return an empty container if there are no unread notifications
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.bottomCenter, // Align to bottom center
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Adjust padding as needed
            child: ElevatedButton(
              onPressed: () async {
                DatabaseService service = DatabaseService(uid);
                await service.markAllAsRead();
                setState(() {
                  // Refresh the page
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.defaultBlue500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add padding to the button
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min, // Add this
                children: [
                  Icon(Icons.checklist_rounded, color: Colors.white),
                  Text(
                    ' Mark All As Read',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNotificationWithDayHeader(Map<String, dynamic> notification, DateTime previousNotificationDate) {
    final notificationDate = (notification['time'] as Timestamp).toDate();
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
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
    Widget route;
    Color? color = Colors.grey[200];
    switch (notification['type']) {
      case 'activity':
        title = 'New Activity';
        route = const ActivityPage(); // replace with your actual Activity page widget
        break;
      case 'statement':
        title = 'New Statement';
        route = const ProfilePage(); // replace with your actual Profile page widget
        break;
      default:
        title = 'New Notification';
        route = const NotificationPage(); // replace with your actual Notification page widget
        break;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: Column(
            children: [
              Container(
              decoration: BoxDecoration(
                color: !notification['isRead'] ? color?.withOpacity(0.05) : null,
                borderRadius: BorderRadius.circular(15.0), // Set the border radius
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                            const SizedBox(height: 4), // Add desired spacing between title and subtitle
                            Text(
                              notification['message'],
                              style: AppTextStyles.xsRegular(color: AppColors.defaultWhite),
                            ),
                            const SizedBox(height: 4), // Add desired spacing between message and ID
                            Text(
                              'ID: ${notification['id']}', // Display the document ID
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
                          onPressed: () async {
                            try {
                              // Mark the notification as read
                              DatabaseService databaseService = DatabaseService(uid);
                              await databaseService.markAsRead(notification['id']);
                
                              await Navigator.pushReplacement(context, PageRouteBuilder(
                                pageBuilder: (context, animation1, animation2) => route,
                                transitionDuration: Duration.zero,
                              ));
                            } catch (e) {
                              if (e is FirebaseException && e.code == 'not-found') {
                                print('The document was not found');
                                print('Notification ID: ${notification['id']}');
                                print('UID: $uid');
                              } else {
                                rethrow;
                              }
                            }
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
                ),
              ),

              if (showDivider)
              const Padding(
                padding: EdgeInsets.all(5),
                child: Divider(color: AppColors.defaultWhite),
              ),
            ],
          ),
        ),
      ],
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
    // TODO(@zaminshaikh): Implement the settings button (commented out below).
      // actions: [
      //   Padding(
      //     padding: const EdgeInsets.only(right: 10.0),
      //     child: IconButton(
      //       icon: const Icon(Icons.settings, color: Colors.white, size: 30.0),
      //       onPressed: () {},
      //     )
      //   ),
      // ],
    );

}