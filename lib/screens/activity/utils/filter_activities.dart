import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';

void filterActivities(List<Activity> activities, List<String> typeFilter,
    List<String> fundsFilter, DateTimeRange selectedDates) {
  activities.removeWhere((activity) => !typeFilter.contains(activity.type));
  activities.removeWhere((activity) => !fundsFilter.contains(activity.fund));
  activities.removeWhere((activity) =>
      activity.time.isBefore(selectedDates.start) ||
      activity.time.isAfter(selectedDates.end));

  if (typeFilter.isEmpty) {
    typeFilter = ['income', 'profit', 'deposit', 'withdrawal', 'pending'];
  }

  if (fundsFilter.isEmpty) {
    fundsFilter = ['AK1', 'AGQ'];
  }
}

List<String> getSelectedFilters(List<String> fundsFilter, List<String> typeFilter,
    DateTimeRange selectedDates) {
  // Ensure default filters are not considered as "selected" filters
  List<String> defaultTypeFilter = [
    'income',
    'profit',
    'deposit',
    'withdrawal',
    'pending'
  ];
  List<String> defaultFundsFilter = ['AK1', 'AGQ'];

  List<String> selectedFilters = [];

  // Add type filters if they are not the default
  if (typeFilter.toSet().difference(defaultTypeFilter.toSet()).isNotEmpty) {
    selectedFilters.addAll(typeFilter);
  }

  // Add funds filters if they are not the default
  if (fundsFilter.toSet().difference(defaultFundsFilter.toSet()).isNotEmpty) {
    selectedFilters.addAll(fundsFilter);
  }

  // Add date range filter if it's specified
  String formatDate(DateTime date) => DateFormat('MM/dd/yy').format(date);
  String dateRange =
      '${formatDate(selectedDates.start)} to ${formatDate(selectedDates.end)}';
  selectedFilters.add(dateRange);

  return selectedFilters;
}
