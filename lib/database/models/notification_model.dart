import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String activityId;
  final String recipient;
  final String title;
  final String body;
  final String message;
  final bool isRead;
  final String type;
  final DateTime time;

  Notification({
    required this.activityId,
    required this.recipient,
    required this.title,
    required this.body,
    required this.message,
    required this.isRead,
    required this.type,
    required this.time,
  });

  factory Notification.fromMap(Map<String, dynamic> data) => Notification(
        activityId: data['activityId'],
        recipient: data['recipient'],
        title: data['title'],
        body: data['body'],
        message: data['message'],
        isRead: data['isRead'],
        type: data['type'],
        time: (data['time'] as Timestamp).toDate(),
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
