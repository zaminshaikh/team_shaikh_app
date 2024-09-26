import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a data point for graphing financial information over time.
///
/// A `GraphPoint` contains the timestamp and amount for plotting graphs, as well as optional
/// fields for cash flow and account name.
class GraphPoint {
  /// The timestamp of the data point.
  final DateTime time;

  /// The monetary amount at the given time.
  final double amount;

  /// The cash flow at the given time, if applicable.
  final double? cashflow;

  /// The account name associated with the data point, if applicable.
  final String? account;

  /// Creates a [GraphPoint] instance with the given parameters.
  ///
  /// The [time] and [amount] parameters are required.
  GraphPoint({
    required this.time,
    required this.amount,
    this.cashflow,
    this.account,
  });

  /// Creates a [GraphPoint] instance from a [Map] representation.
  ///
  /// Typically used when decoding data from Firestore.
  /// Throws an [ArgumentError] if required fields are missing or null.
  factory GraphPoint.fromMap(Map<String, dynamic> data) {
    if (!data.containsKey('time') ||
        !data.containsKey('amount') ||
        data['time'] == null ||
        data['amount'] == null) {
      throw ArgumentError('Time and Amount must not be null');
    }

    return GraphPoint(
      time: (data['time'] as Timestamp).toDate(),
      amount: (data['amount'] as num).toDouble(),
      cashflow: data['cashflow'] != null
          ? (data['cashflow'] as num).toDouble()
          : null,
      account: data['account'],
    );
  }

  /// Converts the [GraphPoint] instance into a [Map] representation.
  Map<String, dynamic> toMap() => {
        'time': time,
        'amount': amount,
        'cashflow': cashflow,
        'account': account,
      };
}