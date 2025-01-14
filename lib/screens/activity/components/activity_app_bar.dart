import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/activity/utils/filter_activities.dart';
import 'package:team_shaikh_app/screens/activity/utils/sort_activities.dart';
import 'package:team_shaikh_app/screens/notifications/notifications.dart';
import 'package:team_shaikh_app/screens/activity/components/filter_modal.dart';
import 'package:team_shaikh_app/screens/activity/components/sort_modal.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';
import 'package:intl/intl.dart';

class ActivityAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Client client;

  const ActivityAppBar({
    Key? key,
    required this.client, required void Function() onFilterPressed, required void Function() onSortPressed,
  }) : super(key: key);

  @override
  _ActivityAppBarState createState() => _ActivityAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 80);
}

class _ActivityAppBarState extends State<ActivityAppBar> {
  List<Activity> activities = [];
  List<String> allRecipients = [];

  // Initialize filters and sort order
  SortOrder _order = SortOrder.newToOld;
  List<String> _typeFilter = ['income', 'profit', 'deposit', 'withdrawal'];
  List<String> _recipientsFilter = [];
  DateTimeRange selectedDates = DateTimeRange(
    start: DateTime(1900),
    end: DateTime.now().add(Duration(days: 30)),
  );

  @override
  Widget build(BuildContext context) => SliverAppBar(
        backgroundColor: const Color.fromARGB(255, 30, 41, 59),
        automaticallyImplyLeading: false,
        toolbarHeight: widget.preferredSize.height,
        expandedHeight: 0,
        snap: false,
        floating: true,
        pinned: true,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationPage(),
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
                                    child: (widget.client.numNotifsUnread ?? 0) > 0
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
                                              '${widget.client.numNotifsUnread}',
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
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showFilterModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                            decoration: BoxDecoration(
                              color: AppColors.defaultBlueGray900, // Set button color
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/filter.svg',
                                    colorFilter: const ColorFilter.mode(AppColors.defaultGray100, BlendMode.srcIn), // Make icon transparent
                                    height: 24,
                                    width: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Filter',
                                    style: TextStyle(
                                      color: AppColors.defaultGray100, // Set text color
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: 'Titillium Web',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showSortModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                            decoration: BoxDecoration(
                              color: AppColors.defaultBlueGray900, // Set button color
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/sort.svg',
                                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    height: 24,
                                    width: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Sort',
                                    style: TextStyle(
                                      color: AppColors.defaultGray200,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: 'Titillium Web',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );

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