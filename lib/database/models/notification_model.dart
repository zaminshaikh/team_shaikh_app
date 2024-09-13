import 'package:cloud_firestore/cloud_firestore.dart';

class CNotification {
  final String? activityId;
  final String? recipient;
  final String title;
  final String body;
  final String message;
  final bool? isRead;
  final String? type;
  final DateTime? time;

  CNotification({
    required this.activityId,
    this.recipient,
    required this.title,
    required this.body,
    required this.message,
    this.isRead,
    required this.type,
    required this.time,
  });

  factory CNotification.fromMap(Map<String, dynamic> data) => CNotification(
        activityId: data['activityId'] ?? '',
        recipient: data['recipient'] ?? '',
        title: data['title'] ?? '',
        body: data['body'] ?? '',
        message: data['message'] ?? '',
        isRead: data['isRead'] ?? false,
        type: data['type'] ?? '',
        time: data['time'] != null ? (data['time'] as Timestamp).toDate() : null,
      );

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
