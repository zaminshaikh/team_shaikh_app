// activity_filter_modal.dart

import 'package:flutter/material.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';
import 'package:team_shaikh_app/screens/utils/utilities.dart';

/// A modal widget for filtering activities.
class ActivityFilterModal extends StatefulWidget {
  final List<String> typeFilter;
  final List<String> recipientsFilter;
  final List<String> allRecipients;

  // NEW: for Parent Name filter
  final List<String> parentsFilter;
  final List<String> allParents;

  final DateTimeRange selectedDates;

  // Updated: onApply now must return parentsFilter as well
  final Function(
    List<String> typeFilter,
    List<String> recipientsFilter,
    List<String> parentsFilter,
    DateTimeRange selectedDates,
  ) onApply;

  const ActivityFilterModal({
    Key? key,
    required this.typeFilter,
    required this.recipientsFilter,
    required this.allRecipients,

    // NEW
    required this.parentsFilter,
    required this.allParents,

    required this.selectedDates,
    required this.onApply,
  }) : super(key: key);

  @override
  _ActivityFilterModalState createState() => _ActivityFilterModalState();
}

class _ActivityFilterModalState extends State<ActivityFilterModal> {
  late List<String> _typeFilter;
  late List<String> _recipientsFilter;

  // NEW
  late List<String> _parentsFilter;

  late DateTimeRange _selectedDates;

  @override
  void initState() {
    super.initState();
    _typeFilter = List.from(widget.typeFilter);
    _recipientsFilter = List.from(widget.recipientsFilter);
    _parentsFilter = List.from(widget.parentsFilter); // NEW
    _selectedDates = widget.selectedDates;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
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
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        children: [
                          _buildTimePeriodFilter(),
                          _buildFilter(
                            'By Type of Activity',
                            ['profit', 'withdrawal', 'deposit'],
                            _typeFilter,
                          ),
                          _buildFilter(
                            'By Recipients',
                            widget.allRecipients,
                            _recipientsFilter,
                          ),
                          
                          // NEW: Parent Name filter
                          _buildFilter(
                            'By Parent Name',
                            widget.allParents,
                            _parentsFilter,
                          ),
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
      );

  /// Builds the time period filter option.
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
                _selectedDates = dateTimeRange;
              });
            }
          },
          child: Container(
            color: Colors.transparent,
            child: const Text(
              'By Time Period',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Titillium Web',
              ),
            ),
          ),
        ),
      );

  /// Builds a filter section with checkboxes.
  Widget _buildFilter(
    String title,
    List<String> items,
    List<String> filterList,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Titillium Web',
            ),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: items
              .map(
                (item) => _buildCheckbox(
                  toTitleCase(item),
                  item,
                  filterList,
                ),
              )
              .toList(),
        ),
      );

  /// Builds an individual checkbox for the filter.
  Widget _buildCheckbox(
    String title,
    String filterKey,
    List<String> filterList,
  ) {
    bool isChecked = filterList.contains(filterKey);
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.white,
            fontFamily: 'Titillium Web',
          ),
        ),
        activeColor: AppColors.defaultBlue500,
        value: isChecked,
        onChanged: (bool? value) {
          setState(() {
            isChecked = value ?? false;
            if (isChecked) {
              // Special case if filterKey is 'profit'
              if (filterKey == 'profit') {
                filterList.add('income');
              }
              filterList.add(filterKey);
            } else {
              if (filterKey == 'profit') {
                filterList.remove('income');
              }
              filterList.remove(filterKey);
            }
          });
        },
      ),
    );
  }

  /// Builds the apply and clear buttons for the filter modal.
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
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(
                    _typeFilter,
                    _recipientsFilter,
                    _parentsFilter,  // NEW
                    _selectedDates,
                  );
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
                    SizedBox(width: 5),
                    Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              setState(() {
                // Reset everything to defaults
                _typeFilter = ['income', 'profit', 'deposit', 'withdrawal'];
                _recipientsFilter = List.from(widget.allRecipients);

                // NEW: reset the parents filter
                _parentsFilter = List.from(widget.allParents);

                _selectedDates = DateTimeRange(
                  start: DateTime(1900),
                  end: DateTime.now().add(const Duration(days: 30)),
                );
              });
              Navigator.pop(context);
              widget.onApply(
                _typeFilter,
                _recipientsFilter,
                _parentsFilter, // NEW
                _selectedDates,
              );
            },
          ),
        ],
      );
}