import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';

void filterActivities(List<Activity> activities, List<String> typeFilter,
    List<String> recipientsFilter, DateTimeRange selectedDates) {
  activities.removeWhere((activity) => !typeFilter.contains(activity.type));
  activities.removeWhere((activity) => !recipientsFilter.contains(activity.recipient));
  activities.removeWhere((activity) =>
      activity.time.isBefore(selectedDates.start) ||
      activity.time.isAfter(selectedDates.end));

  if (typeFilter.isEmpty) {
    typeFilter = ['income', 'profit', 'deposit', 'withdrawal', 'pending'];
  }

  if (recipientsFilter.isEmpty) {
    recipientsFilter = []; // Assuming no default recipients filter
  }
}

List<String> getSelectedFilters(List<String> recipientsFilter, List<String> typeFilter,
    DateTimeRange selectedDates) {
  // Ensure default filters are not considered as "selected" filters
  List<String> defaultTypeFilter = [
    'income',
    'profit',
    'deposit',
    'withdrawal',
    'pending'
  ];

  List<String> selectedFilters = [];

  // Add type filters if they are not the default
  if (typeFilter.toSet().difference(defaultTypeFilter.toSet()).isNotEmpty) {
    selectedFilters.addAll(typeFilter);
  }

  // Add recipients filters if they are not empty
  if (recipientsFilter.isNotEmpty) {
    selectedFilters.addAll(recipientsFilter);
  }

  // Add date range filter if it's specified
  String formatDate(DateTime date) => DateFormat('MM/dd/yy').format(date);
  String dateRange =
      '${formatDate(selectedDates.start)} to ${formatDate(selectedDates.end)}';
  selectedFilters.add(dateRange);

  return selectedFilters;
}