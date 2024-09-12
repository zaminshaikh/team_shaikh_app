import 'package:cloud_firestore/cloud_firestore.dart';

class GraphPoint {
  final DateTime? time;
  final double? amount;

  GraphPoint({
    this.time,
    this.amount,
  });

  factory GraphPoint.fromMap(Map<String, dynamic> data) => GraphPoint(
        time: (data['time'] as Timestamp?)?.toDate(),
        amount: data['amount'],
      );

  Map<String, dynamic> toMap() => {
        'time': time,
        'amount': amount,
      };
}
