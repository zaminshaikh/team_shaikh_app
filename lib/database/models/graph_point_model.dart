import 'package:cloud_firestore/cloud_firestore.dart';

class GraphPoint {
  final DateTime? time;
  final double? amount;
  final double? cashflow;
  final double? account;

  GraphPoint({
    this.time,
    this.amount,
    this.cashflow,
    this.account
  });

  factory GraphPoint.fromMap(Map<String, dynamic> data) => GraphPoint(
        time: (data['time'] as Timestamp?)?.toDate(),
        amount: data['amount']?.toDouble(),
        cashflow: data['cashflow'],
        account: data['account']
      );

  Map<String, dynamic> toMap() => {
        'time': time,
        'amount': amount,
        'cashflow': cashflow,
        'account': account
      };
}
