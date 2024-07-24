import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/notification.dart';
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
  final Future<void> _initializeWidgetFuture = Future.value();


  List<Map<String, dynamic>> activities = [];
  String _sorting = 'new-to-old';
  // ignore: prefer_final_fields
  List<String> _typeFilter = ['income', 'deposit', 'withdrawal', 'pending'];
  // ignore: prefer_final_fields
  List<String> _fundsFilter = ['AK1', 'AGQ'];

  DateTimeRange selectedDates = DateTimeRange(
    start: DateTime(1900),
    end: DateTime.now(),
  );

  DatabaseService? _databaseService;

  Future<void> _initData() async {
    // If the user is signed in (which should always be the case on this screen)
    User? user = FirebaseAuth.instance.currentUser;
    // If not, we return to login page
    if (user == null) {
      await Navigator.pushReplacementNamed(context, '/login');
    }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(user!.uid, 1);
    // If there is no matching CID, redirect to login page and alert the user
    if (service == null) {
      if (!mounted) {
        return;
      }
      await CustomAlertDialog.showAlertDialog(
          context,
          'User does not exist error!',
          'The current user is not associated with any account... We will redirect you to the login page to sign in with a valid user.');

      await FirebaseAuth.instance.signOut(); // Sign that user out
      if (!mounted) {
        return;
      }
      await Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Otherwise set the database service instance
      _databaseService = service;
    }
  }

  bool agqIsChecked = true;
  bool ak1IsChecked = true;
  bool isIncomeChecked = true;
  bool isWithdrawalChecked = true;
  bool isPendingWithdrawalChecked = true;
  bool isDepositChecked = true;
  List<String> allUserNames = [];
  List<String> allRecipients = [];
  Map<String, dynamic> userName = {};
  Map<String, bool> userCheckStatus = {};
  List<String> selectedUsers = [];
  List<String> connectedUserNames = [];
  bool allFundsChecked = true;
  bool allUsersChecked = true;

  @override
  void initState() {
    super.initState();
    _initData().then((_) {
      _databaseService!.getUserWithAssets.listen((user) {
        setState(() {
          String firstName = user.info['name']['first'] as String;
          String lastName = user.info['name']['last'] as String;
          String fullName = '$firstName $lastName';
  
          // Assuming allUserNames is a List<String> meant to store user names
          allUserNames.add(fullName);
          allRecipients.add(fullName);

              // Update userCheckStatus for fullName
            userCheckStatus[fullName] = true;
            log('activity.dart: $userCheckStatus');

  
          log('activity.dart: User name: $fullName');
        });
      });
      _databaseService!.getConnectedUsersWithAssets.listen((connectedUsers) {
        setState(() {
          connectedUserNames = connectedUsers.map<String>((user) {
            String firstName = user.info['name']['first'] as String;
            String lastName = user.info['name']['last'] as String;
            return '$firstName $lastName';
          }).toList();
  
          // Update userCheckStatus for each connected user
          for (var userName in connectedUserNames) {
            userCheckStatus[userName] = true;
          }
  
          // Add connectedUserNames to allUserNames
          allUserNames.addAll(connectedUserNames);
          allRecipients.addAll(connectedUserNames);
          log('activity.dart: Connected users: $connectedUserNames');
          log('activity.dart: All users: $allUserNames');
          log('activity.dart: All recipients: $allRecipients');

        });
      });
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _initializeWidgetFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(26.0),
              margin: EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
              decoration: BoxDecoration(
                color: AppColors.defaultBlue500,
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Stack(
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
          stream: _databaseService?.getActivities,
          builder: (context, activitiesSnapshot) {
            if (!activitiesSnapshot.hasData || activitiesSnapshot.data == null) {
              return  Center(
                child: Container(
                  padding: EdgeInsets.all(26.0),
                  margin: EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
                  decoration: BoxDecoration(
                    color: AppColors.defaultBlue500,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Stack(
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
              stream: _databaseService!.getUserWithAssets, // Assuming this is the stream for the user
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return Center(
                    child: Container(
                      padding: EdgeInsets.all(26.0),
                      margin: EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
                      decoration: BoxDecoration(
                        color: AppColors.defaultBlue500,
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Stack(
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
                return StreamBuilder<List<UserWithAssets>>(
                  stream: _databaseService!.getConnectedUsersWithAssets, 
                  builder: (context, connectedUsers) {
                    if (!connectedUsers.hasData || connectedUsers.data == null) {
                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _databaseService!.getNotifications,
                        builder: (context, notificationsSnapshot) {
                          if (!notificationsSnapshot.hasData || notificationsSnapshot.data == null) {
                            return  Center(
                              child: Container(
                                padding: EdgeInsets.all(26.0),
                                margin: EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
                                decoration: BoxDecoration(
                                  color: AppColors.defaultBlue500,
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: Stack(
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
                          // use unreadNotificationsCount as needed
                          return _buildActivitySingleUser(userSnapshot, activitiesSnapshot);
                        }
                      );
                    }
                    log('activity.dart: Connected users: ${connectedUserNames}');
                    log('activity.dart: All checked users: ${userCheckStatus}');
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _databaseService!.getNotifications,
                      builder: (context, notificationsSnapshot) {
                        if (!notificationsSnapshot.hasData || notificationsSnapshot.data == null) {
                          return Center(
                            child: Container(
                              padding: EdgeInsets.all(26.0),
                              margin: EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
                              decoration: BoxDecoration(
                                color: AppColors.defaultBlue500,
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: Stack(
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
                        // use unreadNotificationsCount as needed
                        return _buildActivityWithConnectedUsers(userSnapshot, connectedUsers, activitiesSnapshot);
                      }
                    );
                  },
                );
              },
            );
          },
        );
    });
    
  
  bool _isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;

  dynamic _getActivityType(Map<String, dynamic> activity) {
    switch (activity['type']) {
      case 'income':
        if (activity['fund'] == 'AGQ') {
          return 'Profit';
        }
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

  // Implement sorting on activities based on the user's selection (defaulted to _sorting = 'new-to-old')
  void sort(List<Map<String, dynamic>> activities) {
    try {
      switch (_sorting) {
        case 'new-to-old':
          activities.sort((a, b) => b['time'].compareTo(a['time']));
          break;
        case 'old-to-new':
          activities.sort((a, b) => (a['time']).compareTo(b['time']));
          break;
        case 'low-to-high':
          activities.sort(
              (a, b) => (a['amount']).compareTo((b['amount']).toDouble()));
          break;
        case 'high-to-low':
          activities.sort((a, b) => (b['amount']).compareTo((a['amount'])));
          break;
      }
    } catch (e) {
      if (e is TypeError) {
        // Handle TypeError here (usually casting error)
        log('activity.dart: Caught TypeError: $e');
      } else {
        // Handle other exceptions here
        log('activity.dart: Caught Exception: $e');
      }
    }
  }

  void filter(List<Map<String, dynamic>> activities) {
    activities.removeWhere((element) => !_typeFilter.contains(element['type']));
    activities
        .removeWhere((element) => !_fundsFilter.contains(element['fund']));
    activities.removeWhere((element) =>
        element['time'].toDate().isBefore(selectedDates.start) ||
        element['time'].toDate().isAfter(selectedDates.end));

    if (_typeFilter.isEmpty) {
      _typeFilter = ['income', 'deposit', 'withdrawal', 'pending'];
    }

    if (_fundsFilter.isEmpty) {
      _fundsFilter = ['AK1', 'AGQ'];
    }

    
  }

  List<String> getSelectedFilters() {
    // Ensure default filters are not considered as "selected" filters
    List<String> defaultTypeFilter = ['income', 'deposit', 'withdrawal', 'pending'];
    List<String> defaultFundsFilter = ['AK1', 'AGQ'];

    List<String> selectedFilters = [];

    // Add type filters if they are not the default
    if (_typeFilter.toSet().difference(defaultTypeFilter.toSet()).isNotEmpty) {
      selectedFilters.addAll(_typeFilter);
    }

    // Add funds filters if they are not the default
    if (_fundsFilter.toSet().difference(defaultFundsFilter.toSet()).isNotEmpty) {
      selectedFilters.addAll(_fundsFilter);
    }

    // Add date range filter if it's specified
    String formatDate(DateTime date) => DateFormat('MM/dd/yy').format(date);
    String dateRange = '${formatDate(selectedDates.start)} to ${formatDate(selectedDates.end)}';
    selectedFilters.add(dateRange);
  

    return selectedFilters;
  }

  Scaffold _buildActivitySingleUser(AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<Map<String, dynamic>>> activitiesSnapshot) {
    activities = activitiesSnapshot.data!;
    filter(activities);
    sort(activities);

    return Scaffold(
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
                        return _buildFilterAndSort();
                      } else {
                        final activity = activities[index - 1];
                        return _buildActivityWithDayHeader(activity, index - 1, activities);
                      }
                    },
                    childCount: activities.length + 1,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 150.0),
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

  Scaffold _buildActivityWithConnectedUsers(
      AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers,
      AsyncSnapshot<List<Map<String, dynamic>>> activitiesSnapshot) {
    activities = activitiesSnapshot.data!;

    filter(activities);
    sort(activities);

    bool activitiesExist = activities.isNotEmpty;


    return Scaffold(
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
                        return _buildFilterAndSortForConnectedUsers();
                      } else if (index == 1) {
                        return _buildSelectedOptionsDisplay();
                      } else {
                        final activityIndex = index - 2;
                        if (activityIndex < activities.length) {
                          return _buildActivityWithDayHeader(activities[activityIndex], activityIndex, activities);
                        } else if (!activitiesExist && index == 2) {
                          // If there are no activities after filtering and sorting, show a message
                          return _buildNoActivityMessage();
                        }
                      }
                      return null; // Return null for any index beyond the activities list
                    },
                    childCount: activitiesExist ? activities.length + 2 : 3, // Adjust child count based on activities existence
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 150.0), // Add some space at the bottom
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

  Widget _buildFilterAndSort() => Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 10, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: SvgPicture.asset(
                'assets/icons/filter.svg',
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                height: 24,
                width: 24,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: AppColors.defaultGray200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                elevation: 0,
              ),
              label: const Text(
                'Filter',
                style: TextStyle(
                  color: AppColors.defaultGray200,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Titillium Web',
                ),
              ),
              onPressed: () {
                _buildFilterOptions(context);
              },
            ),
          ),
          const SizedBox(width: 10), // Add some space between the buttons
          Expanded(
            child: ElevatedButton.icon(
              icon: SvgPicture.asset(
                'assets/icons/sort.svg',
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                height: 24,
                width: 24,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: AppColors.defaultGray200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                elevation: 0,
              ),
              label: const Text(
                'Sort',
                style: TextStyle(
                  color: AppColors.defaultGray200,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Titillium Web',
                ),
              ),
              onPressed: () {
                _buildSortOptions(context);
              },
            ),
          ),
        ],
      ),
    );

  Widget _buildFilterAndSortForConnectedUsers() => Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 10, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: SvgPicture.asset(
                'assets/icons/filter.svg',
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                height: 24,
                width: 24,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: AppColors.defaultGray200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                elevation: 0,
              ),
              label: const Text(
                'Filter',
                style: TextStyle(
                  color: AppColors.defaultGray200,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Titillium Web',
                ),
              ),
              onPressed: () {
                _buildFilterOptionsWithConnectedUsers(context);
              },
            ),
          ),
          const SizedBox(width: 10), // Add some space between the buttons
          Expanded(
            child: ElevatedButton.icon(
              icon: SvgPicture.asset(
                'assets/icons/sort.svg',
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                height: 24,
                width: 24,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: AppColors.defaultGray200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                elevation: 0,
              ),
              label: const Text(
                'Sort',
                style: TextStyle(
                  color: AppColors.defaultGray200,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Titillium Web',
                ),
              ),
              onPressed: () {
                _buildSortOptions(context);
              },
            ),
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
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: const Offset(0.0, 0.0),
                        ).animate(animation),
                        child: child,
                      );
                    },
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

  // If the activity is on a new day, we create a header stating the day.
  Widget _buildActivityWithDayHeader(Map<String, dynamic> activity, int index,
      List<Map<String, dynamic>> activities) {
    final activityDate = (activity['time'] as Timestamp).toDate();
    final previousActivityDate = index > 0
        ? (activities[index - 1]['time'] as Timestamp).toDate()
        : null;
    final nextActivityDate = index < activities.length - 1
        ? (activities[index + 1]['time'] as Timestamp).toDate()
        : null;

    bool isLastActivityForTheDay =
        nextActivityDate == null || !_isSameDay(activityDate, nextActivityDate);

    bool isFirstVisibleActivityOfTheDay = previousActivityDate == null ||
        !_isSameDay(activityDate, previousActivityDate) ||
        userCheckStatus[activities[index - 1]['recipient']] != true;

    if (userCheckStatus[activity['recipient']] == true) {
      if (isFirstVisibleActivityOfTheDay) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 25.0, 20.0, 25.0), // Add padding to the top only if it's not the latest date
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  DateFormat('MMMM d, yyyy').format(activityDate),
                  style: const TextStyle(
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
    } else {
      
      return _buildActivity(activity, !isLastActivityForTheDay);

    }
  } 

  
  Widget _buildActivity(
    
    Map<String, dynamic> activity,
      bool showDivider,
    ) {
    if (userCheckStatus[activity['recipient']] == true) {
      // Assuming activity['time'] is a Timestamp object
      Timestamp timestamp = activity['time'];

      // Convert the Timestamp to a DateTime
      DateTime dateTime = timestamp.toDate();

      // Create a new DateFormat for the desired time format
      DateFormat timeFormat = DateFormat('h:mm a');

      // Use the timeFormat to format the dateTime
      String time = timeFormat.format(dateTime);

      // Create a new DateFormat for the desired date format
      DateFormat dateFormat = DateFormat('EEEE, MMM. d, yyyy');

      // Use the dateFormat to format the dateTime
      String date = dateFormat.format(dateTime);

      Color getColorBasedOnActivityType(String activityType) {
        switch (activityType) {
          case 'deposit':
            return AppColors.defaultGreen400;
          case 'withdrawal':
            return AppColors.defaultRed400;
          case 'pending':
            return AppColors.defaultYellow400;
          case 'income':
            return AppColors.defaultBlue300;
          default:
            return AppColors.defaultWhite;
        }
      }

      Color getUnderlayColorBasedOnActivityType(String activityType) {
        switch (activityType) {
          case 'deposit':
            return const Color.fromARGB(255, 21, 52, 57);
          case 'withdrawal':
            return const Color.fromARGB(255, 41, 25, 28);
          case 'pending':
            return const Color.fromARGB(255, 24, 46, 68);
          case 'income':
            return const Color.fromARGB(255, 24, 46, 68);
          default:
            return AppColors.defaultWhite;
        }
      }

      Color getActivityUnderlayColorBasedOnActivityType(String activityType) {
        switch (activityType) {
          case 'deposit':
            return const Color.fromARGB(255, 34, 66, 73);
          case 'withdrawal':
            return const Color.fromARGB(255, 63, 52, 67);
          case 'pending':
            return const Color.fromARGB(255, 32, 58, 83);
          case 'income':
            return const Color.fromARGB(255, 32, 58, 83);
          default:
            return AppColors.defaultWhite;
        }
      }

      Widget getIconBasedOnActivityType(String activityType, {double size = 50.0}) {
            switch (activityType) {
              case 'deposit':
                return SvgPicture.asset(
                  'assets/icons/deposit.svg',
                  color: getColorBasedOnActivityType(activityType),
                  height: size,
                  width: size,
                );
              case 'withdrawal':
                return SvgPicture.asset(
                  'assets/icons/withdrawal.svg',
                  color: getColorBasedOnActivityType(activityType),
                  height: size,
                  width: size,
                );
              case 'pending':
                return SvgPicture.asset(
                  'assets/icons/pending_withdrawal.svg',
                  color: getColorBasedOnActivityType(activityType),
                  height: size,
                  width: size,
                );
              case 'income':
                return SvgPicture.asset(
                  'assets/icons/variable_income.svg',
                  color: getColorBasedOnActivityType(activityType),
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
          
        return Column(
          children: [
              GestureDetector(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 5.0, 15.0, 5.0),
                  child: Container(
                    color: const Color.fromRGBO(1,1,1,0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.circle,
                                  color: getUnderlayColorBasedOnActivityType(activity['type']),
                                  size: 70,
                                ),
                                getIconBasedOnActivityType(activity['type']),
                              ]
                            ),
                        ),
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
                              _getActivityType(activity),
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
                                '${activity['type'] == 'withdrawal' ? '-' : ''}${currencyFormat(activity['amount'].toDouble())}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: getColorBasedOnActivityType(activity['type']),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Titillium Web',
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                                SvgPicture.asset(
                                  'assets/icons/line.svg',
                                  color: Colors.white,
                                  height: 15,
                                ),
                                Text(
                                  activity['recipient'] ,
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
                
                ),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor:
                        Colors.transparent, // Make the background transparent
                    builder: (BuildContext context) => ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                          child: FractionallySizedBox(
                            heightFactor: 0.67,
                            child: Container(
                              color: AppColors.defaultBlueGray800,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 15, left: 10),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.arrow_back_ios_new_rounded,
                                              color: Color.fromARGB(171, 255, 255, 255),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(0, 5, 0, 10),
                                      child: Text(
                                        'Activity Details', // Your title here
                                        style: TextStyle(
                                            fontSize: 25.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'Titillium Web'),
                                      ),
                                    ),
                                    Text(
                                      '${activity['type'] == 'withdrawal' ? '-' : ''}${currencyFormat(activity['amount'].toDouble())}',
                                      style: TextStyle(
                                        fontSize: 30,
                                        color: getColorBasedOnActivityType(
                                            activity['type']),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Titillium Web',
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Center(
                                      child: Text(
                                        '${() {
                                          switch (activity['type']) {
                                            case 'deposit':
                                              return 'Deposit to your investment at';
                                            case 'withdrawal':
                                              return 'Withdrawal from your investment at';
                                            case 'pending':
                                              return 'Pending withdrawal from your investment at';
                                            case 'income':
                                              return 'Profit to your investment at';
                                            default:
                                              return '';
                                          }
                                        }()} ${activity['fund']}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontFamily: 'Titillium Web',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          getIconBasedOnActivityType(activity['type'], size: 35),
                                          const SizedBox(width: 5),
                                          Text(
                                            _getActivityType(activity),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: getColorBasedOnActivityType(
                                                  activity['type']),
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(18, 0, 18, 0),
                                      child: Row(
                                        children: [
                                          Stack(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                color: getActivityUnderlayColorBasedOnActivityType(activity['type']),
                                                size: 50,
                                              ),
                                              Positioned.fill(
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: SvgPicture.asset(
                                                    'assets/icons/activity_description.svg',
                                                    color: getColorBasedOnActivityType(activity['type']),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Description',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Titillium Web',
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Wrap(
                                                  children: [
                                                    Text(
                                                      '${() {
                                                        switch (activity['type']) {
                                                          case 'deposit':
                                                            return 'Deposit to your investment at';
                                                          case 'withdrawal':
                                                            return 'Withdrawal from your investment at';
                                                          case 'pending':
                                                            return 'Pending withdrawal from your investment at';
                                                          case 'income':
                                                            return 'Profit to your investment at';
                                                          default:
                                                            return '';
                                                        }
                                                      }()} ${activity['fund']}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                        fontFamily: 'Titillium Web',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                                      child: Divider(
                                        color: Colors.white,
                                        thickness: 0.2,
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(18, 0, 18, 0),
                                      child: Row(
                                        children: [
                                          Stack(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                color: getActivityUnderlayColorBasedOnActivityType(activity['type']),
                                                size: 50,
                                              ),
                                              Positioned.fill(
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: SvgPicture.asset(
                                                    'assets/icons/activity_date.svg',
                                                    color: getColorBasedOnActivityType(activity['type'])
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Date',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Titillium Web',
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Wrap(
                                                  children: [
                                                    Text(
                                                      date,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                        fontFamily: 'Titillium Web',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                                      child: Divider(
                                        color: Colors.white,
                                        thickness: 0.2,
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(18, 0, 18, 0),
                                      child: Row(
                                        children: [
                                          Stack(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                color: getActivityUnderlayColorBasedOnActivityType(activity['type']),
                                                size: 50,
                                              ),
                                              Positioned.fill(
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: SvgPicture.asset(
                                                    'assets/icons/activity_user.svg',
                                                    color: getColorBasedOnActivityType(activity['type'])
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Recipient',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Titillium Web',
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Wrap(
                                                  children: [
                                                    Text(
                                                      activity['recipient'],
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        color: Colors.white,
                                                        fontFamily: 'Titillium Web',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ));
              },
            ),
            if (showDivider)
              const Padding(
                padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                child: Divider(
                  color: Color.fromARGB(255, 132, 132, 132),
                  thickness: 0.2,
                ),
              )
          ],
        );
    } else {
      }

    return Container();  
}

  void updateUserCheckStatus(String userName, bool isChecked) {
      setState(() {
        userCheckStatus[userName] = isChecked;

        selectedUsers = userCheckStatus.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

        log('activity.dart: selectedUsers: $selectedUsers');

        // Re-evaluate allUsersChecked after updating userCheckStatus
        allUsersChecked = userCheckStatus.values.every((status) => status);
      });
    }

    void deselectAllUsers() {
      setState(() {
        userCheckStatus.updateAll((key, value) => false);
        selectedUsers.clear(); // Clear the list of selected users
        allUsersChecked = false; // Set allUsersChecked to false
      });
    }

    void deselectSpecificUser(String userName) {
      setState(() {
        if (userCheckStatus.containsKey(userName)) {
          userCheckStatus[userName] = false;
          selectedUsers.remove(userName); // Remove the user from the list of selected users
        }
      });
    }

    void selectAllUsers() {
      setState(() {
        userCheckStatus.updateAll((key, value) => true);
        selectedUsers = userCheckStatus.keys.toList(); // Add all users to the list of selected users
        allUsersChecked = true; // Set allUsersChecked to true
      });
    }

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
              'assets/icons/analytics_hollowed.svg',
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
              'assets/icons/activity_filled.svg',
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
      
  bool isFilterSelected = false;

  void _buildFilterOptions(BuildContext context) {
    /// Edits the filter based on the value of `value`
    ///
    /// If `value` is true, it adds `key` to filter, if false it removes
    /// `code` specifies which filter to edit; 1 for fund, 2 for type
    void editFilter(int code, bool value, String key) {
        setState(() {
          isFilterSelected = value;
        });
      switch (code) {
        case 1:
          if (value) {
            if (!_fundsFilter.contains(key)) {
              _fundsFilter.add(key);
            }
          } else {
            _fundsFilter.remove(key);
          }
          break;
        case 2:
          if (value) {
            if (!_typeFilter.contains(key)) {
              _typeFilter.add(key);
            }
          } else {
            _typeFilter.remove(key);
          }
          break;
      }
    }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: const Color.fromRGBO(0, 0, 0, 0.001),
          child: GestureDetector(
            onTap: () {},
            child: DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.8,
              maxChildSize: 0.8,
              builder: (_, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.defaultBlueGray800,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5, bottom: 5),
                        child: Icon(
                          Icons.remove,
                          color: Colors.transparent,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: 3, // Increased by 2 to accommodate the title and the new ListView
                          itemBuilder: (_, index) {
                            if (index == 0) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(25.0),
                                  child: Text(
                                    'Filter Activity', // Your title here
                                    style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Titillium Web'),
                                  ),
                                ),
                              );
                            } else if (index == 1) {
                              return SizedBox(
                                height: MediaQuery.of(context).size.height * 0.9, // Set the height to 90% of the screen height
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: GestureDetector(
                                        onTap: () async {
                                          // Implement your filter option 1 functionality here
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
                                            setState(() {
                                              selectedDates = dateTimeRange;
                                            });
                                          }
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          child: const Row(
                                            children: [
                                              Text('By Time Period', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Titillium Web')),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                                      child: ExpansionTile(
                                        title: const Row(
                                          children: [
                                            Text('By Fund', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Titillium Web')),
                                            SizedBox(width: 10), // Add some spacing between the title and the date
                                          ],
                                        ),
                                        iconColor: Colors.white,
                                        collapsedIconColor: Colors.white,
                                        children: [
                                          StatefulBuilder(
                                            builder: (BuildContext context, StateSetter setState) => Column(
                                              children: <Widget>[
                                                CheckboxListTile(
                                                  title: const Text(
                                                    'AGQ Consulting LLC',
                                                    style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                  ),
                                                  value: agqIsChecked,
                                                  onChanged: (bool? value) {
                                                    editFilter(1, value!, 'AGQ');
                                                    setState(() {
                                                      agqIsChecked = value;
                                                    });
                                                  },
                                                ),
                                                CheckboxListTile(
                                                  title: const Text(
                                                    'AK1 Holdings LP',
                                                    style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                  ),
                                                  value: ak1IsChecked,
                                                  onChanged: (bool? value) {
                                                    editFilter(1, value!, 'AK1');
                                                    setState(() {
                                                      ak1IsChecked = value;
                                                    });
                                                  },
                                                ),
                                              ], 
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                                      child: ExpansionTile(
                                        title: const Row(
                                          children: [
                                            Text('By Type of Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Titillium Web')),
                                            SizedBox(width: 10), // Add some spacing between the title and the date
                                          ],
                                        ),
                                        iconColor: Colors.white,
                                        collapsedIconColor: Colors.white,
                                        children: [
                                          StatefulBuilder(
                                            builder: (BuildContext context, StateSetter setState) => Column(
                                              children: <Widget>[
                                                CheckboxListTile(
                                                  title: const Text(
                                                    'Profit',
                                                    style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                  ),
                                                  value: isIncomeChecked,
                                                  onChanged: (bool? value) {
                                                    editFilter(2, value!, 'income');
                                                    setState(() {
                                                      isIncomeChecked = value;
                                                    });
                                                  },
                                                ),
                                                CheckboxListTile(
                                                  title: const Text(
                                                    'Withdrawal',
                                                    style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                  ),
                                                  value: isWithdrawalChecked,
                                                  onChanged: (bool? value) {
                                                    editFilter(2, value!, 'withdrawal');
                                                    setState(() {
                                                      isWithdrawalChecked = value;
                                                    });
                                                  },
                                                ),
                                                CheckboxListTile(
                                                  title: const Text(
                                                    'Deposit',
                                                    style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                  ),
                                                  value: isDepositChecked,
                                                  onChanged: (bool? value) {
                                                    editFilter(2, value!, 'deposit');
                                                    setState(() {
                                                      isDepositChecked = value;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              } else if (index == 2) {
                              return Container(
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: Container(
                              color: AppColors.defaultBlueGray800,
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.defaultBlue500, // This is the background color
                                ),
                                child: const Text('Apply', style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  fontFamily: 'Titillium Web')),
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Implement your apply functionality here
                                  setState(() {
                                    log('activity.dart: $_fundsFilter');
                                    log('activity.dart: $_typeFilter');
                                    filter(activities);
                                  });
                                } // Close the bottom sheet,
                              ),
                            ),
                          ),
                          GestureDetector(
                            child: Container(
                              color: Colors.transparent,
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons.close, color: Colors.white),
                                    Text('Clear', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Titillium Web')),
                                  ],
                                ),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _typeFilter = ['income', 'deposit', 'withdrawal', 'pending'];
      
                                _fundsFilter = ['AK1', 'AGQ'];
      
                                selectedDates = DateTimeRange(
                                  start: DateTime(1900),
                                  end: DateTime.now(),
                                );
      
      
                                agqIsChecked = true;
                                ak1IsChecked = true;
      
                                isIncomeChecked = true;
                                isWithdrawalChecked = true;
                                isPendingWithdrawalChecked = true;
                                isDepositChecked = true;
                              });
      
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );

}

  void _buildFilterOptionsWithConnectedUsers(BuildContext context) {
    /// Edits the filter based on the value of `value`
    ///
    /// If `value` is true, it adds `key` to filter, if false it removes
    /// `code` specifies which filter to edit; 1 for fund, 2 for type
    void editFilter(int code, bool value, String key) {
        setState(() {
          isFilterSelected = value;
        });
      switch (code) {
        case 1:
          if (value) {
            if (!_fundsFilter.contains(key)) {
              _fundsFilter.add(key);
            }
          } else {
            _fundsFilter.remove(key);
          }
          break;
        case 2:
          if (value) {
            if (!_typeFilter.contains(key)) {
              _typeFilter.add(key);
            }
          } else {
            _typeFilter.remove(key);
          }
          break;
      }
    }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: const Color.fromRGBO(0, 0, 0, 0.001),
          child: GestureDetector(
            onTap: () {},
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.8,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.defaultBlueGray800,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5, bottom: 5),
                        child: Icon(
                          Icons.remove,
                          color: Colors.transparent,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: 3, // Increased by 2 to accommodate the title and the new ListView
                          itemBuilder: (_, index) {
                            if (index == 0) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(25.0),
                                  child: Text(
                                    'Filter Activity', // Your title here
                                    style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Titillium Web'),
                                  ),
                                ),
                              );
                            } else if (index == 1) {
                              return SizedBox(
                                height: MediaQuery.of(context).size.height * 0.9, // Set the height to 90% of the screen height
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: GestureDetector(
                                        onTap: () async {
                                          // Implement your filter option 1 functionality here
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
                                            setState(() {
                                              selectedDates = dateTimeRange;
                                            });
                                          }
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          child: const Row(
                                            children: [
                                              Text('By Time Period', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Titillium Web')),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                                      child: ExpansionTile(
                                        title: const Row(
                                          children: [
                                            Text('By Fund', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Titillium Web')),
                                            SizedBox(width: 10), // Add some spacing between the title and the date
                                          ],
                                        ),
                                        iconColor: Colors.white,
                                        collapsedIconColor: Colors.white,
                                        children: [
                                          StatefulBuilder(
                                            builder: (BuildContext context, StateSetter setState) => Column(
                                              children: <Widget>[
                                                CheckboxListTile(
                                                  title: const Text(
                                                    'AGQ Consulting LLC',
                                                    style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                  ),
                                                  value: agqIsChecked,
                                                  onChanged: (bool? value) {
                                                    // If trying to uncheck, and the other checkbox is not checked, show the dialog instead of changing the state
                                                    if (value == false && !ak1IsChecked) {
                                                      CustomAlertDialog.showAlertDialog(
                                                        context,
                                                        'Action Required',
                                                        'At least one fund must be selected at all times.',
                                                        icon: const Icon(Icons.error_outline, color: Colors.red),
                                                      );
                                                    } else {
                                                      // Proceed with the state change if the new value is true or the other checkbox is checked
                                                      editFilter(1, value!, 'AGQ');
                                                      setState(() {
                                                        agqIsChecked = value;
                                                      });
                                                    }
                                                  },
                                                ),
                                                CheckboxListTile(
                                                  title: const Text(
                                                    'AK1 Holdings LP',
                                                    style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                  ),
                                                  value: ak1IsChecked,
                                                  onChanged: (bool? value) {
                                                    if (value == false && !agqIsChecked) {
                                                      // Show dialog if trying to uncheck the last remaining checkbox
                                                      CustomAlertDialog.showAlertDialog(
                                                        context,
                                                        'Action Required',
                                                        'At least one fund must be selected at all times.',
                                                        icon: const Icon(Icons.error_outline, color: Colors.red),
                                                      );
                                                    } else if (value != null) {
                                                      // Proceed with updating the filter and checkbox state
                                                      editFilter(1, value, 'AK1');
                                                      setState(() {
                                                        ak1IsChecked = value;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                                      child: ExpansionTile(
                                        title: const Row(
                                          children: [
                                            Text('By Type of Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Titillium Web')),
                                            SizedBox(width: 10), // Add some spacing between the title and the date
                                          ],
                                        ),
                                        iconColor: Colors.white,
                                        collapsedIconColor: Colors.white,
                                        children: [
                                          StatefulBuilder(
                                            builder: (BuildContext context, StateSetter setState) => Column(
                                              children: <Widget>[
                                                CheckboxListTile(
                                                  title: const Text(
                                                    'Profit',
                                                    style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                  ),
                                                  value: isIncomeChecked,
                                                  onChanged: (bool? value) {
                                                    if (value != null && !value && !isWithdrawalChecked && !isDepositChecked) {
                                                      CustomAlertDialog.showAlertDialog(
                                                        context,
                                                        'Action Required',
                                                        'At least one type of activity must be selected at all times.',
                                                        icon: const Icon(Icons.error_outline, color: Colors.red),
                                                      );
                                                    } else {
                                                      editFilter(2, value!, 'income');
                                                      setState(() {
                                                        isIncomeChecked = value;
                                                      });
                                                    }
                                                  },
                                                ),
                                                CheckboxListTile(
                                                  title: const Text(
                                                    'Withdrawal',
                                                    style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                  ),
                                                  value: isWithdrawalChecked,
                                                  onChanged: (bool? value) {
                                                    if (value != null && !value && !isIncomeChecked && !isDepositChecked) {
                                                      CustomAlertDialog.showAlertDialog(
                                                        context,
                                                        'Action Required',
                                                        'At least one type of activity must be selected at all times.',
                                                        icon: const Icon(Icons.error_outline, color: Colors.red),
                                                      );
                                                    } else {
                                                      editFilter(2, value!, 'withdrawal');
                                                      setState(() {
                                                        isWithdrawalChecked = value;
                                                      });
                                                    }
                                                  },
                                                ),
                                                CheckboxListTile(
                                                  title: const Text(
                                                    'Deposit',
                                                    style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                  ),
                                                  value: isDepositChecked,
                                                  onChanged: (bool? value) {
                                                    if (value != null && !value && !isIncomeChecked && !isWithdrawalChecked) {
                                                      CustomAlertDialog.showAlertDialog(
                                                        context,
                                                        'Action Required',
                                                        'At least one type of activity must be selected at all times.',
                                                        icon: const Icon(Icons.error_outline, color: Colors.red),
                                                      );
                                                    } else {
                                                      editFilter(2, value!, 'deposit');
                                                      setState(() {
                                                        isDepositChecked = value;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),      
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                                      child: ExpansionTile(
                                        title: const Row(
                                          children: [
                                            Text('By Users', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Titillium Web')),
                                            SizedBox(width: 10), // Add some spacing between the title and the date
                                          ],
                                        ),
                                        iconColor: Colors.white,
                                        collapsedIconColor: Colors.white,
                                        children: allUserNames.map((userName) {
                                          return StatefulBuilder(
                                            builder: (BuildContext context, StateSetter setState) {
                                              return CheckboxListTile(
                                                title: Text(
                                                  userName,
                                                  style: const TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                                ),
                                                value: userCheckStatus[userName],
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    userCheckStatus[userName] = value!;
                                                    updateUserCheckStatus(userName, value);
                                                  });
                                                  log('activity.dart: Connected User Names: $connectedUserNames');
                                                  // Handle the change event here
                                                },
                                              );
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              } else if (index == 2) {
                              return Container(
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: Container(
                              color: AppColors.defaultBlueGray800,
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.defaultBlue500, // This is the background color
                                ),
                                child: const Text('Apply', style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  fontFamily: 'Titillium Web')),
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Implement your apply functionality here
                                  setState(() {
                                    log('activity.dart: $_fundsFilter');
                                    log('activity.dart: $_typeFilter');
                                    filter(activities);
                                  });
                                } // Close the bottom sheet,
                              ),
                            ),
                          ),
                          GestureDetector(
                            child: Container(
                              color: Colors.transparent,
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons.close, color: Colors.white),
                                    Text('Clear', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Titillium Web')),
                                  ],
                                ),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _typeFilter = ['income', 'deposit', 'withdrawal', 'pending'];
      
                                _fundsFilter = ['AK1', 'AGQ'];
      
                                selectedUsers = allUserNames;
                                allUsersChecked = true;
                                selectAllUsers();
      
                                selectedDates = DateTimeRange(
                                  start: DateTime(1900),
                                  end: DateTime.now(),
                                );
      
      
      
                                agqIsChecked = true;
                                ak1IsChecked = true;
      
                                isIncomeChecked = true;
                                isWithdrawalChecked = true;
                                isPendingWithdrawalChecked = true;
                                isDepositChecked = true;
                              });
      
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );

}

  void _buildSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make the background transparent
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
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      const SizedBox(
                          height: 20.0), // Add some space at the top
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sort By',
                            style: TextStyle(
                                fontSize: 22.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Titillium Web'),
                          ),
                        ),
                      ),
                      const SizedBox(
                          height:
                              20.0), // Add some space between the title and the options
                      _buildOption(context, 'Date: New to Old (Default)',
                          'new-to-old'),
                      _buildOption(context, 'Date: Old to New', 'old-to-new'),
                      _buildOption(
                          context, 'Amount: Low to High', 'low-to-high'),
                      _buildOption(
                          context, 'Amount: High to Low', 'high-to-low'),
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
  }

  Widget _buildOption(BuildContext context, String title, String value) =>
      Padding(
        padding: const EdgeInsets.all(4.0),
        child: GestureDetector(
          onTap: () => setState(() {
            _sorting = value;
            Navigator.pop(context); // Close the bottom sheet
          }),
          child: Container(
            width: double.infinity,
            color: const Color.fromRGBO(94, 181, 171, 0),
            child: Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: _sorting == value
                    ? AppColors.defaultBlue500
                    : Colors
                        .transparent, // Change the color based on whether the option is selected
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        fontFamily: 'Titillium Web')),
                ),
            ),
          ),
        ),
      );
      
    // Helper method to build fund buttons
    Widget _buildFundButton(String fundName) {
      return ButtonTheme(
        minWidth: 0, // Min width set to 0
        padding: EdgeInsets.zero, // Remove padding
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.defaultBlueGray700,
            borderRadius: BorderRadius.circular(15), // Adjust the radius as needed
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
          child: Text(
            fundName, // Button text
            style: const TextStyle(
              color: AppColors.defaultBlueGray100,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Titillium Web',
            ),
          ),
        ),
      );
    }

    // Helper method to build activity type buttons
    Widget _buildActivityTypeButton(String activityType) {
      return ButtonTheme(
        minWidth: 0, // Min width set to 0
        padding: EdgeInsets.zero, // Remove padding
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.defaultBlueGray700,
            borderRadius: BorderRadius.circular(15), // Adjust the radius as needed
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adjust padding as needed
          child: Text(
            activityType, // Button text
            style: const TextStyle(
              color: AppColors.defaultBlueGray100,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Titillium Web',
            ),
          ),
        ),
      );
    }

  Widget _buildNoActivityMessage() {
    return const Padding(
      padding: EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 50,
            color: Colors.grey,
            
          ),
          Text(
            'No Activities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8), // Provides spacing between the text widgets
          Text(
            'Please adjust your filters to view activities.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedOptionsDisplay() {
    String getButtonText(DateTime startDate, DateTime endDate) {
      // Define the start of the range as January 1, 1900
      DateTime startOfRange = DateTime(1900, 1, 1);
      // Normalize start and end dates to remove time part for accurate comparison
      // Get today's date for comparison
      DateTime today = DateTime.now();
      // Normalize today's date to remove time part
      DateTime todayDate = DateTime(today.year, today.month, today.day);

      // Check if the selected range is exactly from 01/01/1900 and includes today's date or is in the future
      bool isAllTime = selectedDates.start == startOfRange &&
                   (selectedDates.end == todayDate) || selectedDates.end.isAfter(todayDate);
      if (isAllTime) {


        return 'All Time';
      } else {
        // Format the dates as strings for display
        String formattedStartDate = '${selectedDates.start.month}/${selectedDates.start.day}/${selectedDates.start.year}';
        String formattedEndDate = '${selectedDates.end.month}/${selectedDates.end.day}/${selectedDates.end.year}';
        return '$formattedStartDate - $formattedEndDate';
      }
    }

    String buttonText = getButtonText(selectedDates.start, selectedDates.end);
    return Column(
      
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            children: [
            // Display the selected filter options
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  child: Container(
                    color: Colors.transparent,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        children: [

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Sort: ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Titillium Web',
                                ),
                              ),
                              const Spacer(),
                              Container(
                                color: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () {
                                    _buildSortOptions(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min, // Use MainAxisSize.min for a compact row
                                      children: <Widget>[
                                        Text(
                                          _sorting == 'new-to-old'
                                              ? 'Date: New to Old'
                                              : _sorting == 'old-to-new'
                                                  ? 'Date: Old to New'
                                                  : _sorting == 'low-to-high'
                                                      ? 'Amount: Low to High'
                                                      : 'Amount: High to Low',
                                          style: const TextStyle(
                                            color: AppColors.defaultBlue300,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Titillium Web',
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SvgPicture.asset(
                                          'assets/icons/sort.svg',
                                          colorFilter: const ColorFilter.mode(AppColors.defaultBlue300, BlendMode.srcIn),
                                          height: 20,
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    _buildSortOptions(context);
                  },
                ),
              ),
              

              Row(
                children: [
                  const Text(
                    'Filters: ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                  Expanded(
                  child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                          stops: [0.0, 0.1, 0.9, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                          GestureDetector(
                            onTap: () {
                              _buildFilterOptionsWithConnectedUsers(context);
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  color: const Color.fromARGB(255, 17, 24, 39),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0), // Equal padding for Date Range Button
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.defaultBlueGray700,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    child: Text(
                                      buttonText,
                                      style: const TextStyle(
                                        color: AppColors.defaultBlueGray100,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Titillium Web',
                                      ),
                                    ),
                                  ),
                                ),
                                if (allUsersChecked)
                                  Padding(
                                    padding: const EdgeInsets.all(4.0), // Equal padding for All Connected Users Button
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.defaultBlueGray700,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      child: const Text(
                                        'All Connected Users',
                                        style: TextStyle(
                                          color: AppColors.defaultBlueGray100,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Titillium Web',
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!allUsersChecked)
                                  Padding(
                                    padding: const EdgeInsets.all(4.0), // Equal padding for each selected user button
                                    child: Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: selectedUsers.map((userName) => Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.defaultBlueGray700,
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        child: Text(
                                          userName,
                                          style: const TextStyle(
                                            color: AppColors.defaultBlueGray100,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Titillium Web',
                                          ),
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                                // For Funds Button(s) and Type of Activity Button(s), wrap each _buildFundButton and _buildActivityTypeButton call in a Padding widget
                                if (_fundsFilter.contains('AGQ') && !_fundsFilter.contains('AK1'))
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: _buildFundButton('AGQ'),
                                  ),
                                if (_fundsFilter.contains('AK1') && !_fundsFilter.contains('AGQ'))
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: _buildFundButton('AK1'),
                                  ),
                                if (_fundsFilter.contains('AK1') && _fundsFilter.contains('AGQ'))
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: _buildFundButton('All Funds'),
                                  ),
                                // Repeat the same pattern for Type of Activity Button(s)
                                if (_typeFilter.contains('income') && _typeFilter.contains('deposit') && _typeFilter.contains('withdrawal'))
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: _buildActivityTypeButton('All Activity Types'),
                                  ),
                                // Continue wrapping each button with Padding as shown above for the rest of the conditions
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ],
          ),
        ),

          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Divider(
              color: Color.fromARGB(255, 126, 123, 123),
              thickness: 0.5,
            ),
          ),

      ],
    );
    
  }

}
