import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an activity or transaction in the application.
///
/// An `Activity` can be any financial transaction such as a deposit, withdrawal, or dividend payment.
/// It contains details about the transaction amount, the fund involved, the recipient, and other relevant information.
class Activity {
  /// Unique identifier of the activity.
  final String? id;

  /// Identifier of the parent document, if applicable.
  final String? parentDocId;

  /// The monetary amount of the activity.
  final double amount;

  /// The fund associated with the activity.
  final String fund;

  /// The recipient of the activity.
  final String recipient;

  /// The timestamp when the activity occurred.
  final DateTime time;

  /// The type of activity (e.g., 'deposit', 'withdrawal', 'profit').
  final String type;

  /// Indicates if the activity is a dividend.
  final bool? isDividend;

  /// Indicates if a notification should be sent for this activity.
  final bool? sendNotif;

  /// Creates an [Activity] instance with the given parameters.
  ///
  /// The [amount], [fund], [recipient], [time], and [type] parameters are required.
  Activity({
    this.id,
    this.parentDocId,
    required this.amount,
    required this.fund,
    required this.recipient,
    required this.time,
    required this.type,
    this.isDividend,
    this.sendNotif,
  });

  /// Creates an [Activity] instance from a [Map] representation.
  ///
  /// Typically used when decoding data from Firestore.
  factory Activity.fromMap(Map<String, dynamic> data) => Activity(
        id: data['id'],
        parentDocId: data['parentDocId'],
        amount: (data['amount'] as num).toDouble(),
        fund: data['fund'],
        recipient: data['recipient'],
        time: (data['time'] as Timestamp).toDate(),
        type: data['type'],
        isDividend: data['isDividend'],
        sendNotif: data['sendNotif'],
      );

  /// Converts the [Activity] instance into a [Map] representation.
  ///
  /// Useful for encoding data to store in Firestore.
  Map<String, dynamic> toMap() => {
        'id': id,
        'parentDocId': parentDocId,
        'amount': amount,
        'fund': fund,
        'recipient': recipient,
        'time': time,
        'type': type,
        'isDividend': isDividend,
        'sendNotif': sendNotif,
      };
}
