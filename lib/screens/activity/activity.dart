import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:team_shaikh_app/components/custom_bottom_navigation_bar.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';
import 'package:team_shaikh_app/screens/activity/components/activity_app_bar.dart';
import 'package:team_shaikh_app/screens/activity/components/activity_details_modal.dart';
import 'package:team_shaikh_app/screens/activity/components/activity_list_item.dart';
import 'package:team_shaikh_app/screens/activity/components/filter_modal.dart';
import 'package:team_shaikh_app/screens/activity/components/no_activities_body.dart';
import 'package:team_shaikh_app/screens/activity/components/sort_modal.dart';
import 'package:team_shaikh_app/screens/activity/utils/activity_styles.dart';
import 'package:team_shaikh_app/screens/activity/utils/filter_activities.dart';
import 'package:team_shaikh_app/screens/activity/utils/sort_activities.dart';
import 'package:team_shaikh_app/screens/utils/utilities.dart';
import 'dart:developer';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  Client? client;
  List<Activity> activities = [];
  List<String> allRecipients = [];

  // Initialize filters and sort order
  SortOrder _order = SortOrder.newToOld;
  List<String> _typeFilter = ['income', 'profit', 'deposit', 'withdrawal'];
  List<String> _recipientsFilter = [];
  DateTimeRange selectedDates = DateTimeRange(
    start: DateTime(1900),
    end: DateTime.now().add(const Duration(days: 30)),
  );

  // Date formatter for day headers
  final DateFormat dayHeaderFormat = DateFormat('MMMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _validateAuth();

    // Initialize recipients filter after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _recipientsFilter = List.from(allRecipients);
      });
    });
  }

  /// Validates if the user is authenticated; if not, redirects to the login page.
  Future<void> _validateAuth() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null && mounted) {
      log('ActivityPage: User is not logged in');
      await Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    client = Provider.of<Client?>(context);
  }

  @override
  Widget build(BuildContext context) {
    if (client == null) {
      return const CustomProgressIndicatorPage();
    }

    // Retrieve activities and recipients
    _retrieveActivitiesAndRecipients();

    // Filter and sort activities
    filterActivities(activities, _typeFilter, _recipientsFilter, selectedDates);
    sortActivities(activities, _order);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              // Pass the callbacks for Filter & Sort to the AppBar
              ActivityAppBar(
                client: client!,
                onFilterPressed: () => _showFilterModal(context),
                onSortPressed: () => _showSortModal(context),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildListContent(context, index),
                  // Notice we no longer build the filter/sort row in the list:
                  // the childCount changes accordingly
                  childCount: activities.isEmpty ? 2 : activities.length + 1,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 150.0),
              ),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child:
                CustomBottomNavigationBar(currentItem: NavigationItem.activity),
          ),
        ],
      ),
    );
  }

  /// Retrieves activities and recipients from the client and connected users.
  void _retrieveActivitiesAndRecipients() {
    activities = List.from(client?.activities ?? []);
    allRecipients = List.from(client?.recipients ?? []);

    if (client?.connectedUsers != null && client!.connectedUsers!.isNotEmpty) {
      final connectedUserActivities = client!.connectedUsers!
          .where((user) => user != null)
          .expand((user) => user!.activities ?? [].cast<Activity>());
      final connectedUserRecipients = client!.connectedUsers!
          .where((user) => user != null)
          .expand((user) => user!.recipients ?? [].cast<String>());
      activities.addAll(connectedUserActivities);
      allRecipients.addAll(connectedUserRecipients);
    }
  }

  /// Builds the content of the list based on the index.
  Widget? _buildListContent(BuildContext context, int index) {
    // We removed the index == 0 filter/sort row check 
    // because it is now in the AppBar
    if (activities.isEmpty && index == 0) {
      return buildNoActivityMessage();
    } else {
      int activityIndex = activities.isEmpty ? index - 1 : index;
      if (activityIndex < 0 || activityIndex >= activities.length) {
        return null;
      }
      final activity = activities[activityIndex];
      return _buildActivityWithDayHeader(activity, activityIndex);
    }
  }

  /// Builds an activity item with a day header if necessary.
  Widget _buildActivityWithDayHeader(Activity activity, int index) {
    final activityDate = activity.time;
    final previousActivityDate = index > 0 ? activities[index - 1].time : null;
    final nextActivityDate =
        index < activities.length - 1 ? activities[index + 1].time : null;

    bool isLastActivityForTheDay =
        nextActivityDate == null || !isSameDay(activityDate, nextActivityDate);

    bool isFirstVisibleActivityOfTheDay = previousActivityDate == null ||
        !isSameDay(activityDate, previousActivityDate);

    List<Widget> widgets = [];

    if (isFirstVisibleActivityOfTheDay) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 25.0, 20.0, 25.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              dayHeaderFormat.format(activityDate),
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
          ),
        ),
      );
    }

    widgets.add(_buildActivity(activity, !isLastActivityForTheDay));

    return Column(
      children: widgets,
    );
  }

  /// Builds an individual activity item.
  Widget _buildActivity(Activity activity, bool showDivider) => Column(
        children: [
          ActivityListItem(
            activity: activity,
            onTap: () => _showActivityDetailsModal(context, activity),
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

  /// Shows the activity details modal.
  void _showActivityDetailsModal(BuildContext context, Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          ActivityDetailsModal(activity: activity),
    );
  }

  /// Shows the filter modal.
  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityFilterModal(
        typeFilter: _typeFilter,
        recipientsFilter: _recipientsFilter,
        allRecipients: allRecipients,
        selectedDates: selectedDates,
        onApply: (typeFilter, recipientsFilter, selectedDates) {
          setState(() {
            _typeFilter = typeFilter;
            _recipientsFilter = recipientsFilter;
            this.selectedDates = selectedDates;
            filterActivities(
                activities, _typeFilter, _recipientsFilter, selectedDates);
          });
        },
      ),
    );
  }

  /// Shows the sort modal.
  void _showSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivitySortModal(
        currentOrder: _order,
        onSelect: (order) {
          setState(() {
            _order = order;
            sortActivities(activities, _order);
          });
        },
      ),
    );
  }
}