// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, use_build_context_synchronously, prefer_expression_function_bodies
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:team_shaikh_app/components/custom_bottom_navigation_bar.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/utils/resources.dart';
import 'package:team_shaikh_app/screens/activity/components/activity_app_bar.dart';
import 'package:team_shaikh_app/screens/activity/components/activity_details_modal.dart';
import 'package:team_shaikh_app/screens/activity/components/activity_list_item.dart';
import 'package:team_shaikh_app/screens/activity/components/no_activities_body.dart';
import 'package:team_shaikh_app/screens/activity/utils/filter_activities.dart';
import 'package:team_shaikh_app/screens/activity/utils/sort_activities.dart';
import 'package:team_shaikh_app/utils/utilities.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);
  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  Client? client;
  List<Activity> activities = [];
  List<String> allRecipients = [];

  // Initiliaze filters and sort
  SortOrder _order = SortOrder.newToOld;
  List<String> _typeFilter =  [
      'income',
      'profit',
      'deposit',
      'withdrawal',
    ];
  List<String> _recipientsFilter = [];
  DateTimeRange selectedDates = DateTimeRange(
    start: DateTime(1900),
    end: DateTime.now(),
  );

  Map<String, bool> userCheckStatus = {};
  List<String> selectedUsers = [];

  // Date formatters
  final DateFormat timeFormat = DateFormat('h:mm a');
  final DateFormat dateFormat = DateFormat('EEEE, MMM. d, yyyy');
  final DateFormat dayHeaderFormat = DateFormat('MMMM d, yyyy');

  Future<void> _validateAuth() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null && mounted) {
      log('dashboard.dart: User is not logged in');
      await Navigator.pushReplacementNamed(context, '/login');
    }
  }
  
  @override
  void initState() {
    super.initState();
    _validateAuth();
    // Initialize _recipientsFilter after allRecipients is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _recipientsFilter = List.from(allRecipients);
      });
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    client = Provider.of<Client?>(context);
  }

  @override
  Widget build(BuildContext context) {
    activities = List.from(client?.activities ?? []);
    allRecipients = List.from(client?.recipients ?? []);

    // Collect connected users' activities if any
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

    filterActivities(activities, _typeFilter, _recipientsFilter, selectedDates);
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
                          return _buildActivityWithDayHeader(
                              activity, activityIndex, activities);
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
            child:
                CustomBottomNavigationBar(currentItem: NavigationItem.activity),
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
            _showFilterModal(context);
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

  Widget _buildActivity(Activity activity, bool showDivider) {

    return Column(
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
  }

  void _showActivityDetailsModal(BuildContext context, Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          ActivityDetailsModal(activity: activity),
    );
  }
  // Filter and sort options
  void _showFilterModal(BuildContext context) {
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
                          _buildFilter('By Type of Activity',
                              ['profit', 'withdrawal', 'deposit'], _typeFilter),
                          _buildFilter('By Recipients', allRecipients,
                              _recipientsFilter),
                        ],
                      ),
                    ),
                    _buildFilterApplyClearButtons(),
                    const SizedBox(height: 40),
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

  Widget _buildFilter(
          String title, List<String> items, List<String> filterList) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: ExpansionTile(
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Titillium Web')),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: items
              .map(
                  (item) => _buildCheckbox(toTitleCase(item), item, filterList))
              .toList(),
        ),
      );

  Widget _buildCheckbox(
      String title, String filterKey, List<String> filterList) {
    bool isChecked = filterList.contains(filterKey);
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return CheckboxListTile(
          title: Text(
            title,
            style: const TextStyle(
                fontSize: 16.0,
                color: Colors.white,
                fontFamily: 'Titillium Web'),
          ),
          activeColor: AppColors.defaultBlue500, 
          value: isChecked,
          onChanged: (bool? value) {
            setState(() {
              isChecked = value!;
              if (value == true) {
                if (filterKey == 'profit') {
                  filterList.add('income');
                }
                filterList.add(filterList.contains(filterKey.toLowerCase()) 
                    ? filterKey.toLowerCase() 
                    : filterKey);
              } else {
                if (filterKey == 'profit') {
                  filterList.remove('income');
                }
                filterList.remove(filterList.contains(filterKey.toLowerCase())
                    ? filterKey.toLowerCase()
                    : filterKey);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildFilterApplyClearButtons() => Column(
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
                    filterActivities(
                        activities, _typeFilter, _recipientsFilter, selectedDates);
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
                _typeFilter = [
                  'income',
                  'profit',
                  'deposit',
                  'withdrawal',
                ];
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

  Widget _buildFilterDisplay(List<String> buttonTexts) {
      return Row(
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
          SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children:
                    buttonTexts.map((text) => _buildFilterChip(text)).toList(),
              ),
            ),
          ),
        ],
      );
    }

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
                _buildSortOption(
                    'Date: New to Old (Default)', SortOrder.newToOld),
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
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color:
                _order == value ? AppColors.defaultBlue500 : Colors.transparent,
            borderRadius:
                BorderRadius.circular(15), // Adjust the radius as needed
          ),
          child: Text(
            title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                fontFamily: 'Titillium Web'),
          ),
        ),
        onTap: () {
          setState(() {
            _order = value;
            Navigator.pop(context);
          });
        },
      );

  Widget _buildSelectedOptionsDisplay() {
    String dateButtonText =
        getDateButtonText(selectedDates.start, selectedDates.end);
    String typeButtonText = getTypeButtonText(_typeFilter);
    String recipientsButtonText = getRecipientsButtonText(_recipientsFilter, allRecipients);
    List<String> buttons = [dateButtonText, typeButtonText, recipientsButtonText];
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
              _buildFilterDisplay(buttons),
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

  String getDateButtonText(DateTime startDate, DateTime endDate) {
    DateTime startOfRange = DateTime(1900, 1, 1);
    DateTime today = DateTime.now();
    DateTime todayDate = DateTime(today.year, today.month, today.day);

    bool isAllTime = selectedDates.start == startOfRange &&
        (selectedDates.end == todayDate ||
            selectedDates.end.isAfter(todayDate));
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

  String getTypeButtonText(List<String> typeFilter) {
      // List of all possible activity types
      List<String> allTypes = ['profit', 'deposit', 'withdrawal'];

      if (allTypes.every((type) => typeFilter.contains(type))) {
        return 'All Types';
      } else if (typeFilter.isEmpty) {
        return 'No Types Selected';
      } else {
        // Filter out 'income' and convert types to title case for display
        List<String> displayTypes = typeFilter
            .where((type) => type != 'income')
            .map((type) => toTitleCase(type))
            .toList();
        return displayTypes.join(', ');
      }
    }

  String getRecipientsButtonText(List<String> recipientsFilter, List<String> allRecipients) {
    if (allRecipients.every((recipient) => recipientsFilter.contains(recipient))) {
      return 'All Recipients';
    } else if (recipientsFilter.isEmpty) {
      return 'No Recipients Selected';
    } else {
      return recipientsFilter.join(', ');
    }
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
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, bottom: 5),
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
}
