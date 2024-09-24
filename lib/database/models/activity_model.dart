import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String? id;
  final String? parentDocId;
  final double amount;
  final String fund;
  final String recipient;
  final DateTime time;
  final String type;
  final bool? isDividend;
  final bool? sendNotif;

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

  factory Activity.fromMap(Map<String, dynamic> data) => Activity(
        id: data['id'],
        parentDocId: data['parentDocId'],
        amount: data['amount'].toDouble(),
        fund: data['fund'],
        recipient: data['recipient'],
        time: (data['time'] as Timestamp).toDate(),
        type: data['type'],
        isDividend: data['isDividend'],
        sendNotif: data['sendNotif'],
      );

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
