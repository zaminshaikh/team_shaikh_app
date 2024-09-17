// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, use_build_context_synchronously
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:team_shaikh_app/components/custom_bottom_navigation_bar.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/activity/components/activity_app_bar.dart';
import 'package:team_shaikh_app/screens/activity/components/no_activities_body.dart';
import 'package:team_shaikh_app/screens/activity/utils/filter_activities.dart';
import 'package:team_shaikh_app/screens/activity/utils/sort_activities.dart';
import 'package:team_shaikh_app/utilities.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);
  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<Activity> activities = [];
  SortOrder _order = SortOrder.newToOld;
  List<String> _typeFilter = ['income', 'profit', 'deposit', 'withdrawal', 'pending'];
  List<String> _fundsFilter = ['AK1', 'AGQ'];

  DateTimeRange selectedDates = DateTimeRange(
    start: DateTime(1900),
    end: DateTime.now(),
  );

  Map<String, bool> userCheckStatus = {};
  List<String> selectedUsers = [];
  bool allUsersChecked = true;
  bool isFilterSelected = false;

  Client? client;

  // Date formatters
  final DateFormat timeFormat = DateFormat('h:mm a');
  final DateFormat dateFormat = DateFormat('EEEE, MMM. d, yyyy');
  final DateFormat dayHeaderFormat = DateFormat('MMMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _validateAuth();
  }

  Future<void> _validateAuth() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null && mounted) {
      log('dashboard.dart: User is not logged in');
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
    activities = List.from(client?.activities ?? []);

    // Collect connected users' activities if any
    if (client?.connectedUsers != null && client!.connectedUsers!.isNotEmpty) {
      final connectedUserActivities = client!.connectedUsers!
          .where((user) => user != null)
          .expand((user) => user!.activities ?? [].cast<Activity>());
      activities.addAll(connectedUserActivities);
    }

    filterActivities(activities, _typeFilter, _fundsFilter, selectedDates);
    sortActivities(activities, _order);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              ActivityAppBar(client: client!),
              SliverPadding(
                padding: const EdgeInsets.only(top: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return _buildFilterAndSort();
                      } else if (index == 1) {
                        return _buildSelectedOptionsDisplay();
                      } else if (activities.isEmpty && index == 2) {
                        return buildNoActivityMessage();
                      } else {
                        int activityIndex = index - 2;
                        if (activityIndex < activities.length) {
                          final activity = activities[activityIndex];
                          return _buildActivityWithDayHeader(activity, activityIndex, activities);
                        } else {
                          return null;
                        }
                      }
                    },
                    childCount: activities.isEmpty ? 3 : activities.length + 2,
                  ),
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
            child: CustomBottomNavigationBar(currentItem: NavigationItem.activity),
          ),
        ],
      ),
    );
  }

  // Build methods
  Widget _buildFilterAndSort() => Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 10, 20, 10),
      child: Row(
        children: [
          _buildFilterButton(),
          const SizedBox(width: 10),
          _buildSortButton(),
        ],
      ),
    );

  Widget _buildFilterButton() => Expanded(
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
    );

  Widget _buildSortButton() => Expanded(
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
    );

  Widget _buildActivityWithDayHeader(
      Activity activity, int index, List<Activity> activities) {
    final activityDate = activity.time;
    final previousActivityDate = index > 0 ? activities[index - 1].time : null;
    final nextActivityDate = index < activities.length - 1 ? activities[index + 1].time : null;

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

  Widget _buildActivity(Activity activity, bool showDivider) {
    String time = timeFormat.format(activity.time);
    // String date = dateFormat.format(activity.time);

    return Column(
      children: [
        GestureDetector(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30.0, 5.0, 15.0, 5.0),
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  _buildActivityIcon(activity),
                  _buildActivityDetails(activity),
                  const Spacer(),
                  _buildActivityAmountAndTime(activity, time),
                ],
              ),
            ),
          ),
          onTap: () {
            _showActivityDetailsModal(context, activity);
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
  }

  Widget _buildActivityIcon(Activity activity) => Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.circle,
            color: getUnderlayColor(activity.type),
            size: 50,
          ),
          getActivityIcon(activity.type),
        ],
      ),
    );

  Widget _buildActivityDetails(Activity activity) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity.fund,
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
            color: getActivityColor(activity.type),
            fontWeight: FontWeight.bold,
            fontFamily: 'Titillium Web',
          ),
        ),
      ],
    );

  Widget _buildActivityAmountAndTime(Activity activity, String time) => Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${activity.type == 'withdrawal' ? '-' : ''}${currencyFormat(activity.amount.toDouble())}',
            style: TextStyle(
              fontSize: 18,
              color: getActivityColor(activity.type),
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
              activity.recipient,
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
    );

  // Activity details modal
  void _showActivityDetailsModal(BuildContext context, Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                  _buildModalHeader(context),
                  _buildModalBody(activity),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context) => Column(
      children: [
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
            'Activity Details',
            style: TextStyle(
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Titillium Web'),
          ),
        ),
      ],
    );

  Widget _buildModalBody(Activity activity) {
    String date = dateFormat.format(activity.time);
    return Column(
      children: [
        Text(
          '${activity.type == 'withdrawal' ? '-' : ''}${currencyFormat(activity.amount.toDouble())}',
          style: TextStyle(
            fontSize: 30,
            color: getActivityColor(activity.type),
            fontWeight: FontWeight.bold,
            fontFamily: 'Titillium Web',
          ),
        ),
        const SizedBox(height: 15),
        Center(
          child: Text(
            getActivityDescription(activity),
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
              getActivityIcon(activity.type, size: 35),
              const SizedBox(width: 5),
              Text(
                getActivityType(activity),
                style: TextStyle(
                  fontSize: 16,
                  color: getActivityColor(activity.type),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        _buildModalDetailSection(
          icon: SvgPicture.asset(
            'assets/icons/activity_description.svg',
            color: getActivityColor(activity.type),
          ),
          title: 'Description',
          content: getActivityDescription(activity),
          underlayColor: getUnderlayColor(activity.type),
        ),
        const Divider(color: Colors.white, thickness: 0.2),
        _buildModalDetailSection(
          icon: SvgPicture.asset(
            'assets/icons/activity_date.svg',
            color: getActivityColor(activity.type),
          ),
          title: 'Date',
          content: date,
          underlayColor: getUnderlayColor(activity.type),
        ),
        const Divider(color: Colors.white, thickness: 0.2),
        _buildModalDetailSection(
          icon: SvgPicture.asset(
            'assets/icons/activity_user.svg',
            color: getActivityColor(activity.type),
          ),
          title: 'Recipient',
          content: activity.recipient,
          underlayColor: getUnderlayColor(activity.type),
        ),
      ],
    );
  }

  Widget _buildModalDetailSection({
    required Widget icon,
    required String title,
    required String content,
    required Color underlayColor,
  }) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Row(
        children: [
          Stack(
            children: [
              Icon(
                Icons.circle,
                color: underlayColor,
                size: 50,
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: icon,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Titillium Web',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  // Filter and sort options
  void _buildFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: const Color.fromRGBO(0, 0, 0, 0.001),
          child: GestureDetector(
            onTap: () {},
            child: DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.8,
              maxChildSize: 0.8,
              builder: (_, controller) => Container(
                decoration: const BoxDecoration(
                  color: AppColors.defaultBlueGray800,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.0),
                    topRight: Radius.circular(25.0),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    const Icon(Icons.remove, color: Colors.transparent),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(25.0),
                        child: Text(
                          'Filter Activity',
                          style: TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Titillium Web'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        children: [
                          _buildTimePeriodFilter(),
                          _buildActivityTypeFilter(),
                        ],
                      ),
                    ),
                    _buildFilterApplyButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePeriodFilter() => ListTile(
      title: GestureDetector(
        onTap: () async {
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
          child: const Text('By Time Period',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Titillium Web')),
        ),
      ),
    );

  Widget _buildActivityTypeFilter() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: ExpansionTile(
        title: const Text('By Type of Activity',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Titillium Web')),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: [
          _buildActivityTypeCheckbox('Profit', 'income'),
          _buildActivityTypeCheckbox('Withdrawal', 'withdrawal'),
          _buildActivityTypeCheckbox('Deposit', 'deposit'),
        ],
      ),
    );

  Widget _buildActivityTypeCheckbox(String title, String filterKey) {
    bool isChecked = _typeFilter.contains(filterKey);
    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(
            fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
      ),
      value: isChecked,
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _typeFilter.add(filterKey);
          } else {
            _typeFilter.remove(filterKey);
          }
        });
      },
    );
  }

  Widget _buildFilterApplyButtons() => Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.defaultBlue500,
              ),
              child: const Text('Apply',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Titillium Web')),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  filterActivities(activities, _fundsFilter, _typeFilter, selectedDates);
                });
              },
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
                  Text('Clear',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Titillium Web')),
                ],
              ),
            ),
          ),
          onTap: () {
            setState(() {
              _typeFilter = ['income', 'profit', 'deposit', 'withdrawal', 'pending'];
              _fundsFilter = ['AK1', 'AGQ'];
              selectedDates = DateTimeRange(
                start: DateTime(1900),
                end: DateTime.now(),
              );
            });
            Navigator.pop(context);
          },
        ),
      ],
    );

  void _buildSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => SingleChildScrollView(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: Container(
            color: AppColors.defaultBlueGray800,
            child: Column(
              children: [
                const SizedBox(height: 20.0),
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
                const SizedBox(height: 20.0),
                _buildSortOption('Date: New to Old (Default)', SortOrder.newToOld),
                _buildSortOption('Date: Old to New', SortOrder.oldToNew),
                _buildSortOption('Amount: Low to High', SortOrder.lowToHigh),
                _buildSortOption('Amount: High to Low', SortOrder.highToLow),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, SortOrder value) => ListTile(
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18, fontFamily: 'Titillium Web'),
      ),
      onTap: () {
        setState(() {
          _order = value;
          Navigator.pop(context);
        });
      },
    );

  Widget _buildSelectedOptionsDisplay() {
    String buttonText = getButtonText(selectedDates.start, selectedDates.end);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            children: [
              _buildSortDisplay(),
              _buildFilterDisplay(buttonText),
            ],
          ),
        ),
        const Divider(
          color: Color.fromARGB(255, 126, 123, 123),
          thickness: 0.5,
        ),
      ],
    );
  }

  Widget _buildSortDisplay() => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Text(
                  'Sort: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
                      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _getSortOrderText(),
                            style: const TextStyle(
                              color: AppColors.defaultBlue300,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                          const SizedBox(width: 10),
                          SvgPicture.asset(
                            'assets/icons/sort.svg',
                            colorFilter: const ColorFilter.mode(
                                AppColors.defaultBlue300, BlendMode.srcIn),
                            height: 18,
                            width: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap: () {
          _buildSortOptions(context);
        },
      ),
    );

  Widget _buildFilterDisplay(String buttonText) => Row(
      children: [
        const Text(
          'Filters: ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Titillium Web',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(buttonText),
                // Add more filter chips as needed
              ],
            ),
          ),
        ),
      ],
    );

  Widget _buildFilterChip(String label) => Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.defaultBlueGray700,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.defaultBlueGray100,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Titillium Web',
          ),
        ),
      ),
    );

  // Helper methods
  String getButtonText(DateTime startDate, DateTime endDate) {
    DateTime startOfRange = DateTime(1900, 1, 1);
    DateTime today = DateTime.now();
    DateTime todayDate = DateTime(today.year, today.month, today.day);

    bool isAllTime = selectedDates.start == startOfRange &&
        (selectedDates.end == todayDate || selectedDates.end.isAfter(todayDate));
    if (isAllTime) {
      return 'All Time';
    } else {
      String formattedStartDate =
          '${selectedDates.start.month}/${selectedDates.start.day}/${selectedDates.start.year}';
      String formattedEndDate =
          '${selectedDates.end.month}/${selectedDates.end.day}/${selectedDates.end.year}';
      return '$formattedStartDate - $formattedEndDate';
    }
  }

  String _getSortOrderText() {
    switch (_order) {
      case SortOrder.newToOld:
        return 'Date: New to Old';
      case SortOrder.oldToNew:
        return 'Date: Old to New';
      case SortOrder.lowToHigh:
        return 'Amount: Low to High';
      case SortOrder.highToLow:
        return 'Amount: High to Low';
      default:
        return '';
    }
  }

  String getActivityDescription(Activity activity) {
    String action;
    switch (activity.type) {
      case 'deposit':
        action = 'Deposit to your investment at';
        break;
      case 'withdrawal':
        action = 'Withdrawal from your investment at';
        break;
      case 'pending':
        action = 'Pending withdrawal from your investment at';
        break;
      case 'income':
      case 'profit':
        action = 'Profit to your investment at';
        break;
      default:
        action = '';
    }
    return '$action ${activity.fund}';
  }

  String getActivityType(Activity activity) {
    switch (activity.type) {
      case 'deposit':
        return 'Deposit';
      case 'withdrawal':
        return 'Withdrawal';
      case 'pending':
        return 'Pending Withdrawal';
      case 'income':
      case 'profit':
        return 'Profit';
      default:
        return '';
    }
  }

  Color getActivityColor(String activityType) {
    switch (activityType) {
      case 'deposit':
        return AppColors.defaultGreen400;
      case 'withdrawal':
        return AppColors.defaultRed400;
      case 'pending':
        return AppColors.defaultYellow400;
      case 'income':
      case 'profit':
        return AppColors.defaultBlue300;
      default:
        return AppColors.defaultWhite;
    }
  }

  Color getUnderlayColor(String activityType) {
    switch (activityType) {
      case 'deposit':
        return const Color.fromARGB(255, 21, 52, 57);
      case 'withdrawal':
        return const Color.fromARGB(255, 41, 25, 28);
      case 'pending':
      case 'income':
      case 'profit':
        return const Color.fromARGB(255, 24, 46, 68);
      default:
        return AppColors.defaultWhite;
    }
  }

  Widget getActivityIcon(String activityType, {double size = 50.0}) {
    String assetName;
    switch (activityType) {
      case 'deposit':
        assetName = 'assets/icons/deposit.svg';
        break;
      case 'withdrawal':
        assetName = 'assets/icons/withdrawal.svg';
        break;
      case 'pending':
        assetName = 'assets/icons/pending_withdrawal.svg';
        break;
      case 'income':
      case 'profit':
        assetName = 'assets/icons/variable_income.svg';
        break;
      default:
        return Icon(Icons.circle, color: Colors.transparent, size: size);
    }
    return SvgPicture.asset(
      assetName,
      color: getActivityColor(activityType),
      height: size,
      width: size,
    );
  }
}
