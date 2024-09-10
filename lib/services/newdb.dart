import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utilities.dart';
import 'package:rxdart/rxdart.dart';

class Client {
  final String cid;
  final String uid;
  final String firstName;
  final String lastName;
  final String companyName;
  final String address;
  final DateTime? dob;
  final String phoneNumber;
  final String appEmail;
  final String initEmail;
  final DateTime? firstDepositDate;
  final List<String> beneficiaries;
  final List<Client>? connectedUsers;
  final double totalAssets;
  final double ytd;
  final double totalYTD;

  List<Notification>? notifications;
  List<Activity>? activities;
  List<GraphPoint>? graphPoints;
  final Assets assets;

  Client({
    required this.cid,
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.companyName,
    required this.address,
    required this.dob,
    required this.phoneNumber,
    required this.appEmail,
    required this.initEmail,
    required this.firstDepositDate,
    required this.beneficiaries,
    required this.connectedUsers,
    required this.totalAssets,
    required this.ytd,
    required this.totalYTD,
    this.notifications,
    this.activities,
    this.graphPoints,
    required this.assets,
  });

  factory Client.fromMap(Map<String, dynamic> data) => Client(
        cid: data['cid'],
        uid: data['uid'],
        firstName: data['firstName'],
        lastName: data['lastName'],
        companyName: data['companyName'],
        address: data['address'],
        dob: (data['dob'] as Timestamp?)?.toDate(),
        phoneNumber: data['phoneNumber'],
        appEmail: data['appEmail'],
        initEmail: data['initEmail'],
        firstDepositDate: (data['firstDepositDate'] as Timestamp?)?.toDate(),
        beneficiaries: List<String>.from(data['beneficiaries']),
        connectedUsers: List<Client>.from(
            data['connectedUsers'].map((cid) => getClient(cid))),
        totalAssets: data['totalAssets'],
        ytd: data['ytd'],
        totalYTD: data['totalYTD'],
        activities: (data['activities'] as List<dynamic>?)
            ?.map((e) => Activity.fromMap(e))
            .toList(),
        graphPoints: (data['graphPoints'] as List<dynamic>?)
            ?.map((e) => GraphPoint.fromMap(e))
            .toList(),
        assets: Assets.fromMap(data['assets']),
      );

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
        'assets': assets.toMap(),
      };
}

//TODO: Implement this on to return the client from the database
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
        amount: data['amount'],
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

class Assets {
  final AssetDetails agq;
  final AssetDetails ak1;

  Assets({
    required this.agq,
    required this.ak1,
  });

  factory Assets.fromMap(Map<String, dynamic> data) => Assets(
        agq: AssetDetails.fromMap(data['agq']),
        ak1: AssetDetails.fromMap(data['ak1']),
      );

  Map<String, dynamic> toMap() => {
        'agq': agq.toMap(),
        'ak1': ak1.toMap(),
      };
}

class AssetDetails {
  final double personal;
  final double company;
  final double trad;
  final double roth;
  final double sep;
  final double nuviewTrad;
  final double nuviewRoth;

  AssetDetails({
    required this.personal,
    required this.company,
    required this.trad,
    required this.roth,
    required this.sep,
    required this.nuviewTrad,
    required this.nuviewRoth,
  });

  factory AssetDetails.fromMap(Map<String, dynamic> data) => AssetDetails(
        personal: data['personal'],
        company: data['company'],
        trad: data['trad'],
        roth: data['roth'],
        sep: data['sep'],
        nuviewTrad: data['nuviewTrad'],
        nuviewRoth: data['nuviewRoth'],
      );

  Map<String, dynamic> toMap() => {
        'personal': personal,
        'company': company,
        'trad': trad,
        'roth': roth,
        'sep': sep,
        'nuviewTrad': nuviewTrad,
        'nuviewRoth': nuviewRoth,
      };
}

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

class NewDB {
  String? cid;
  final String uid;
  static final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection(Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION'));
  CollectionReference? assetsSubCollection;
  CollectionReference? activitiesSubCollection;
  CollectionReference? notificationsSubCollection;
  CollectionReference? graphPointsSubCollection;

  /// A new instance of [NewDB] with the given [cid] and [uid].
  ///
  /// The [cid] (Client ID) is a unique identifier for the user, and the [uid] (User ID) is the unique identifier for the user's auth account.
  /// The instance is used to link a new user to the database, update user information, and retrieve user data from the database.
  ///
  /// `DBNew.linkNewUser(email)` links a new user to the database using the [cid] and updates the [email]
  ///
  /// `DBNew.users` returns a stream of the 'users' collection in the database
  ///
  /// `DBNew.docExists(cid)` returns a [Future] that completes with a boolean value indicating whether a document exists for the given [cid]`
  ///
  /// `DBNew.docLinked(cid)` returns a [Future] that completes with a boolean value indicating whether a user is linked to the database for the given [cid]
  ///
  /// For more information on the methods, see the individual method documentation.
  NewDB(this.uid);
  NewDB.withCID(this.uid, this.cid);

  // Asynchronous factory constructor
  static Future<NewDB?> fetchCID(
      BuildContext context, String uid, int code) async {
    NewDB service = NewDB(uid);

    // Access Firestore and get the document
    QuerySnapshot querySnapshot =
        await usersCollection.where('uid', isEqualTo: uid).get();

    if (querySnapshot.size > 0) {
      log('database.dart: UID $uid found in Firestore.');
      // Document found, access the 'cid' field
      service.cid = querySnapshot.docs.first.id;
          service.assetsSubCollection = usersCollection
              .doc(service.cid)
              .collection(Config.get('ASSETS_SUBCOLLECTION'));
          service.graphPointsSubCollection = service.assetsSubCollection
              ?.doc(Config.get('ASSETS_GENERAL_DOC_ID'))
              .collection(Config.get('GRAPHPOINTS_SUBCOLLECTION'));
          service.activitiesSubCollection = usersCollection
              .doc(service.cid)
              .collection(Config.get('ACTIVITIES_SUBCOLLECTION'));
          service.notificationsSubCollection = usersCollection
              .doc(service.cid)
              .collection(Config.get('NOTIFICATIONS_SUBCOLLECTION'));
      // Now you can use 'cid' in your code
      // log('database.dart: CID: ${service.cid}');
      // log('database.dart: Connected users: ${await service.fetchConnectedCids(service.cid!)}');
    } else {
      log('database.dart: Document with UID $uid not found in Firestore.');
      return null;
    }

    return service;
  }

    // Stream that listens to changes in the user's client data and subcollections
  Stream<Client?> getClientStream() {
    if (cid == null) {
      throw Exception('CID is not initialized.');
    }

    // Stream for the main client document
    Stream<DocumentSnapshot> clientDocumentStream =
        usersCollection.doc(cid).snapshots();

    // Stream for the activities subcollection
    Stream<List<Activity>> activitiesStream = activitiesSubCollection!
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromMap(doc.data() as Map<String, dynamic>))
            .toList());

    // Stream for the notifications subcollection
    Stream<List<Notification>> notificationsStream = notificationsSubCollection!
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Notification.fromMap(doc.data() as Map<String, dynamic>))
            .toList());

    // Stream for the graphPoints subcollection
    Stream<List<GraphPoint>> graphPointsStream = graphPointsSubCollection!
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
                (doc) => GraphPoint.fromMap(doc.data() as Map<String, dynamic>))
            .toList());

    // Stream for the assets subcollection (assuming a single document in assets)
    Stream<Assets> assetsStream = assetsSubCollection!
        .doc(Config.get('ASSETS_GENERAL_DOC_ID'))
        .snapshots()
        .map((doc) => Assets.fromMap(doc.data() as Map<String, dynamic>));

    // Combine all streams to emit a new Client object whenever any part changes
    return Rx.combineLatest5(
      clientDocumentStream,
      activitiesStream,
      notificationsStream,
      graphPointsStream,
      assetsStream,
      (DocumentSnapshot clientDoc,
          List<Activity> activities,
          List<Notification> notifications,
          List<GraphPoint> graphPoints,
          Assets assets) {
        if (clientDoc.exists) {
          Map<String, dynamic> clientData =
              clientDoc.data() as Map<String, dynamic>;

          return Client(
            cid: clientData['cid'],
            uid: clientData['uid'],
            firstName: clientData['firstName'],
            lastName: clientData['lastName'],
            companyName: clientData['companyName'],
            address: clientData['address'],
            dob: (clientData['dob'] as Timestamp?)?.toDate(),
            phoneNumber: clientData['phoneNumber'],
            appEmail: clientData['appEmail'],
            initEmail: clientData['initEmail'],
            firstDepositDate:
                (clientData['firstDepositDate'] as Timestamp?)?.toDate(),
            beneficiaries: List<String>.from(clientData['beneficiaries']),
            connectedUsers: clientData['connectedUsers'] != null
                ? List<Client>.from(
                    clientData['connectedUsers'].map((cid) => getClient(cid)))
                : null,
            totalAssets: clientData['totalAssets'],
            ytd: clientData['ytd'],
            totalYTD: clientData['totalYTD'],
            activities: activities,
            notifications: notifications,
            graphPoints: graphPoints,
            assets: assets,
          );
        } else {
          return null;
        }
      },
    );
  }
}
