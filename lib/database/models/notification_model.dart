import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a notification in the application.
///
/// A `Notif` object contains information about notifications sent to users, such as activity updates,
/// messages, or alerts.
class Notif {
  /// The Client ID (CID) of the parent client associated with this notification.
  final String parentCID;

  /// Unique identifier of the notification.
  final String id;

  /// Identifier of the related activity, if applicable.
  final String? activityId;

  /// The recipient of the notification, if applicable.
  final String? recipient;

  /// The title of the notification.
  final String title;

  /// The body content of the notification.
  final String body;

  /// The message associated with the notification.
  final String message;

  /// Indicates whether the notification has been read.
  final bool isRead;

  /// The type of notification (e.g., 'activity', 'alert').
  final String type;

  /// The timestamp when the notification was created.
  final DateTime time;

  /// Creates a [Notif] instance with the given parameters.
  ///
  /// The [parentCID], [id], [title], [body], [message], [isRead], [type], and [time] parameters are required.
  Notif({
    required this.parentCID,
    required this.id,
    this.activityId,
    this.recipient,
    required this.title,
    required this.body,
    required this.message,
    required this.isRead,
    required this.type,
    required this.time,
  });

  /// Creates a [Notif] instance from a [Map] representation.
  ///
  /// Throws an [ArgumentError] if required fields are missing or null.
  factory Notif.fromMap(Map<String, dynamic> data) {
    if (!data.containsKey('time') ||
        !data.containsKey('isRead') ||
        !data.containsKey('type') ||
        !data.containsKey('id') ||
        !data.containsKey('parentCID') ||
        data['time'] == null ||
        data['isRead'] == null ||
        data['type'] == null ||
        data['id'] == null ||
        data['parentCID'] == null) {
      throw ArgumentError(
          'Missing required fields in data map for notification');
    }
    return Notif(
      parentCID: data['parentCID'],
      id: data['id'] ?? '',
      activityId: data['activityId'] ?? '',
      recipient: data['recipient'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      type: data['type'] ?? '',
      time: (data['time'] as Timestamp).toDate(),
    );
  }

  /// Converts the [Notif] instance into a [Map] representation.
  ///
  /// Useful for encoding data to store in Firestore.
  Map<String, dynamic> toMap() => {
        'activityId': activityId,
        'recipient': recipient,
        'title': title,
        'body': body,
        'message': message,
        'isRead': isRead,
        'type': type,
        'time': time,
      };
}
