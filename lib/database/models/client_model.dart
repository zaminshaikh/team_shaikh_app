import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team_shaikh_app/database/models/graph_point_model.dart';
import 'package:team_shaikh_app/database/models/assets_model.dart';
import 'package:team_shaikh_app/database/models/notification_model.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';

class Client {
  
  final String cid;
  final String uid;
  final String firstName;
  final String lastName;
  final String? companyName;
  final String? address;
  final DateTime? dob;
  final String? phoneNumber;
  final String? appEmail;
  final String? initEmail;
  final DateTime? firstDepositDate;
  final List<String>? beneficiaries;
  final List<Client?>? connectedUsers;
  final double? totalAssets;
  final int? numNotifsUnread;
  final List<String>? recipients;
  List<Notif>? notifications;
  List<Activity>? activities;
  List<GraphPoint>? graphPoints;
  final Assets? assets;



  Client({
    required this.cid,
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.appEmail,
    this.totalAssets,
    this.companyName,
    this.address,
    this.dob,
    this.phoneNumber,
    this.initEmail,
    this.firstDepositDate,
    this.beneficiaries,
    this.numNotifsUnread,
    this.connectedUsers,
    this.notifications,
    this.activities,
    this.graphPoints,
    this.assets,
    this.recipients,
  });


  factory Client.fromMap(Map<String, dynamic>? data,
      {String? cid,
      List<Activity>? activities,
      Assets? assets,
      List<Notif>? notifications,
      List<GraphPoint>? graphPoints,
      List<Client?>? connectedUsers}) {
    if (data == null) {
      return Client.empty();
    }

    return Client(
      cid: data['cid'] ?? cid ?? '',
      uid: data['uid'] ?? '',
      firstName: data['name']?['first'] ?? '',
      lastName: data['name']?['last'] ?? '',
      companyName: data['name']?['company'] ?? '',
      address: data['address'] ?? '',
      dob: (data['dob'] as Timestamp?)?.toDate(),
      phoneNumber: data['phoneNumber'] ?? '',
      appEmail: data['appEmail'] ?? '',
      initEmail: data['initEmail'] ?? '',
      firstDepositDate: (data['firstDepositDate'] as Timestamp?)?.toDate(),
      beneficiaries: List<String>.from(data['beneficiaries'] ?? []),
      numNotifsUnread: notifications?.where((notif) => notif.isRead != null && !notif.isRead!).length,
      recipients: activities?.map((activity) => activity.recipient).toSet().toList(),
      connectedUsers: connectedUsers ?? [],
      activities: activities ?? [],
      graphPoints: graphPoints ?? [],
      assets: assets,
      notifications: notifications ?? [],
    );
  }

  // Empty constructor
  Client.empty()
      : cid = '',
        uid = '',
        firstName = '',
        lastName = '',
        companyName = '',
        address = '',
        dob = null,
        phoneNumber = '',
        appEmail = '',
        initEmail = '',
        firstDepositDate = null,
        beneficiaries = [],
        connectedUsers = [],
        totalAssets = 0.0,
        numNotifsUnread = 0,
        recipients = [],
        notifications = [],
        activities = [],
        graphPoints = [],
        assets = Assets.empty();

  Map<String, dynamic> toMap() => {
        'cid': cid,
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'companyName': companyName,
        'address': address,
        'dob': dob,
        'phoneNumber': phoneNumber,
        'appEmail': appEmail,
        'initEmail': initEmail,
        'firstDepositDate': firstDepositDate,
        'beneficiaries': beneficiaries,
        'connectedUsers': connectedUsers,
        'totalAssets': totalAssets,
        'activities': activities?.map((e) => e.toMap()).toList(),
        'graphPoints': graphPoints?.map((e) => e.toMap()).toList(),
        'assets': assets?.toMap(),
      };
}
