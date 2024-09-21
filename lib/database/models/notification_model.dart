import 'package:cloud_firestore/cloud_firestore.dart';

class Notif {
  final String parentCID;
  final String id;
  final String? activityId;
  final String? recipient;
  final String title;
  final String body;
  final String message;
  final bool isRead;
  final String type;
  final DateTime time;

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

  factory Notif.fromMap(Map<String, dynamic> data) {
    if (!data.containsKey('time') 
      || !data.containsKey('isRead') 
      || !data.containsKey('type') 
      || !data.containsKey('id')
      || !data.containsKey('parentCID')
      || data['time'] == null
      || data['isRead'] == null
      || data['type'] == null
      || data['id'] == null
      || data['parentCID'] == null) {
      throw ArgumentError('Missing required fields in data map');
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
