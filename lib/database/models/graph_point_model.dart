import 'package:cloud_firestore/cloud_firestore.dart';

class GraphPoint {
  final DateTime time;
  final double amount;
  final double? cashflow;
  final double? account;

  GraphPoint({
    required this.time,
    required this.amount,
    this.cashflow,
    this.account
  });

  factory GraphPoint.fromMap(Map<String, dynamic> data) {
    if (!data.containsKey('time') || !data.containsKey('amount') || data['time'] == null || data['amount'] == null) {
      throw ArgumentError('Time and Amount must not be null');
    }
    
    return GraphPoint(
        time: (data['time'] as Timestamp).toDate(),
        amount: data['amount'].toDouble(),
        cashflow: data['cashflow'],
        account: data['account']
      );
  }

  Map<String, dynamic> toMap() => {
        'time': time,
        'amount': amount,
        'cashflow': cashflow,
        'account': account
      };
}
