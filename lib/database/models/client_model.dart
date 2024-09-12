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
  final List<Client>? connectedUsers;
  final double totalAssets;
  final double ytd;
  final double totalYTD;

  List<Notification>? notifications;
  List<Activity>? activities;
  List<GraphPoint>? graphPoints;
  final Assets? assets;

  Client({
    required this.cid,
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.appEmail,
    required this.totalAssets,
    required this.ytd,
    required this.totalYTD,
    this.companyName,
    this.address,
    this.dob,
    this.phoneNumber,
    this.initEmail,
    this.firstDepositDate,
    this.beneficiaries,
    this.connectedUsers,
    this.notifications,
    this.activities,
    this.graphPoints,
    this.assets,
  });

  factory Client.fromMap(Map<String, dynamic> data, {String? cid}) => Client(
        cid: data['cid'] ?? cid ?? '',
        uid: data['uid'],
        firstName: data['name']['first'] ?? '',
        lastName: data['name']['last'] ?? '',
        companyName: data['name']['company'] ?? '',
        address: data['address'],
        dob: (data['dob'] as Timestamp?)?.toDate(),
        phoneNumber: data['phoneNumber'],
        appEmail: data['appEmail'],
        initEmail: data['initEmail'],
        firstDepositDate: (data['firstDepositDate'] as Timestamp?)?.toDate(),
        beneficiaries: List<String>.from(data['beneficiaries']),
        connectedUsers: List<Client>.from(
            data['connectedUsers'].map((cid) => getClient(cid))),
        totalAssets: (data['totalAssets'] ?? 0 as num).toDouble(),
        ytd: (data['ytd'] ?? 0 as num).toDouble(),
        totalYTD: (data['totalYTD'] ?? 0 as num).toDouble(),
        // activities: (data['activities'] as List<dynamic>?)
        //     ?.map((e) => Activity.fromMap(e))
        //     .toList(),
        // graphPoints: (data['graphPoints'] as List<dynamic>?)
        //     ?.map((e) => GraphPoint.fromMap(e))
        //     .toList(),
        // assets: data['assets'] ? Assets.fromMap(data['assets']) : null,
      );

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
        ytd = 0.0,
        totalYTD = 0.0,
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
        'ytd': ytd,
        'totalYTD': totalYTD,
        'activities': activities?.map((e) => e.toMap()).toList(),
        'graphPoints': graphPoints?.map((e) => e.toMap()).toList(),
        'assets': assets?.toMap(),
      };
}

Client getClient(cid) => Client(
      cid: cid,
      uid: '',
      firstName: '',
      lastName: '',
      companyName: '',
      address: '',
      dob: null,
      phoneNumber: '',
      appEmail: '',
      initEmail: '',
      firstDepositDate: null,
      beneficiaries: [],
      connectedUsers: [],
      totalAssets: 0,
      ytd: 0,
      totalYTD: 0,
      activities: [],
      graphPoints: [],
      notifications: [],
      assets: Assets(
        agq: AssetDetails(
          personal: 0,
          company: 0,
          trad: 0,
          roth: 0,
          sep: 0,
          nuviewTrad: 0,
          nuviewRoth: 0,
        ),
        ak1: AssetDetails(
          personal: 0,
          company: 0,
          trad: 0,
          roth: 0,
          sep: 0,
          nuviewTrad: 0,
          nuviewRoth: 0,
        ),
      ),
    );
