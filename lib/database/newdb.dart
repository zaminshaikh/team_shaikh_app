import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';
import 'package:team_shaikh_app/database/models/graph_point_model.dart';
import 'package:team_shaikh_app/database/models/notification_model.dart';
import 'package:team_shaikh_app/database/models/assets_model.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import '../utilities.dart';
import 'package:rxdart/rxdart.dart';

class NewDB {
  String? cid;
  String? uid;
  static final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection(Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION'));
  CollectionReference? assetsSubCollection;
  CollectionReference? activitiesSubCollection;
  CollectionReference? notificationsSubCollection;
  CollectionReference? graphPointsSubCollection;
  List<dynamic>? connectedUsersCIDs;

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
  NewDB.connectedUser(this.cid) {
    setSubCollections(this);
  }
  NewDB.withCID(this.uid, this.cid);

  // Asynchronous factory constructor
  static Future<NewDB?> fetchCID(
      BuildContext context, String uid) async {
    NewDB service = NewDB(uid);

    // Access Firestore and get the document
    QuerySnapshot querySnapshot =
        await usersCollection.where('uid', isEqualTo: uid).get();

    if (querySnapshot.size > 0) {
      log('database.dart: UID $uid found in Firestore.');
      // Document found, access the 'cid' field
      service.cid = querySnapshot.docs.first.id;
      service.connectedUsersCIDs = querySnapshot.docs.first['connectedUsers'] ?? [];
      setSubCollections(service);

    } else {
      log('database.dart: Document with UID $uid not found in Firestore.');
      return null;
    }

    return service;
  }

  static void setSubCollections(NewDB service) {
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
  }
  



  // Stream that listens to changes in the user's client data and subcollections
  Stream<Client?> getClientStream({bool isConnectedUser = false}) {
    print('CLIENT STREAM CALLED');
    if (this.cid == null) {
      throw Exception('CID is not initialized.');
    }

    try {
      
      // Stream for the main client document
      Stream<DocumentSnapshot> clientDocumentStream =
          usersCollection.doc(cid).snapshots();

      Stream<List<Client?>> connectedUsersStream;
      if (!isConnectedUser && connectedUsersCIDs != null && connectedUsersCIDs!.isNotEmpty) {
         connectedUsersStream = Rx.combineLatestList(
            connectedUsersCIDs!
                .map((cid) {
                  NewDB db = NewDB.connectedUser(cid);
                  return db.getClientStream(isConnectedUser: true)
                    .asBroadcastStream();
                })
                .toList()).asBroadcastStream();
      } else {
        connectedUsersStream = Stream.value([Client.empty()]);
      }

      // Stream for the activities subcollection
      Stream<List<Activity>> activitiesStream = activitiesSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Activity.fromMap(doc.data() as Map<String, dynamic>))
              .toList());

      // Stream for the assets subcollection (assuming a single document in assets)
      Stream<Assets> assetsStream = assetsSubCollection!.snapshots().map((snapshot) {

        Map<String, Fund> funds = {};
        Map<String, dynamic> general = {};

        for (var doc in snapshot.docs) {
          if (doc.id == 'general') {
            general = doc.data() as Map<String, dynamic>;
          } else {
            funds[doc.id] = Fund.fromMap(doc.data() as Map<String, dynamic>);
          }
        }

        return Assets.fromMap(funds, general);
      });

      // Stream for the notifications subcollection
      Stream<List<CNotification>> notificationsStream =
          notificationsSubCollection!.snapshots().map((snapshot) => snapshot
              .docs
              .map((doc) =>
                  CNotification.fromMap(doc.data() as Map<String, dynamic>))
              .toList());

      
      // // Stream for the graphPoints subcollection
      Stream<List<GraphPoint>> graphPointsStream = graphPointsSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map(
                  (doc) => GraphPoint.fromMap(doc.data() as Map<String, dynamic>))
              .toList());


        return Rx.combineLatest6(
          clientDocumentStream, 
          activitiesStream, 
          assetsStream, 
          notificationsStream, 
          graphPointsStream,
          connectedUsersStream,
          (DocumentSnapshot clientDoc, 
          List<Activity> activities, 
          Assets assets, 
          List<CNotification> notifications, 
          List<GraphPoint> graphPoints, 
          List<Client?> connectedUsers
          ) => 
            Client.fromMap(
              clientDoc.data() as Map<String, dynamic>, 
              cid: cid, 
              activities: activities, 
              assets: assets, 
              notifications: notifications, 
              graphPoints: graphPoints,
              connectedUsers: connectedUsers.whereType<Client>().toList(),
              // connectedUsers.whereType<Client>().toList() // Filter out null values
            )
      );
    } catch (e) {
      log('database.dart: Error in getClientStream: $e');
      return Stream.value(null);
    }
  }
}
