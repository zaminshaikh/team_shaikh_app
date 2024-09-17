import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team_shaikh_app/database.dart';
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

  NewDB(this.uid);
  NewDB.connectedUser(this.cid) {
    setSubCollections(this);
  }
  NewDB.withCID(this.uid, this.cid);

  // Asynchronous factory constructor
  static Future<NewDB?> fetchCID(String uid) async {
    NewDB service = NewDB(uid);

    // Access Firestore and get the document
    QuerySnapshot querySnapshot =
        await usersCollection.where('uid', isEqualTo: uid).get();

    if (querySnapshot.size > 0) {
      log('database.dart: UID $uid found in Firestore.');

      // Document found, access the 'cid' field
      QueryDocumentSnapshot snapshot = querySnapshot.docs.first;
      service.cid = snapshot.id;

      // Cast snapshot.data() to Map<String, dynamic>
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      // Check if 'connectedUsers' field exists before trying to access it
      if (data.containsKey('connectedUsers')) {
        service.connectedUsersCIDs = data['connectedUsers'] ?? [];
      } else {
        log('database.dart: Field "connectedUsers" does not exist in document.');
        service.connectedUsersCIDs = []; // Or handle this case as needed
      }

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
    if (cid == null) {
      return Stream.value(null);
    }

    try {
      // Stream for the main client document
      Stream<DocumentSnapshot> clientDocumentStream =
          usersCollection.doc(cid).snapshots();

      Stream<List<Client?>> connectedUsersStream;
      if (!isConnectedUser &&
          connectedUsersCIDs != null &&
          connectedUsersCIDs!.isNotEmpty) {
        connectedUsersStream =
            Rx.combineLatestList(connectedUsersCIDs!.map((cid) {
          NewDB db = NewDB.connectedUser(cid);
          return db.getClientStream(isConnectedUser: true).asBroadcastStream();
        }).toList())
                .asBroadcastStream();
      } else {
        connectedUsersStream = Stream.value([null]);
      }

      // Stream for the activities subcollection
      Stream<List<Activity>> activitiesStream = activitiesSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map(
                  (doc) => Activity.fromMap(doc.data() as Map<String, dynamic>))
              .toList());

      // Stream for the assets subcollection (assuming a single document in assets)
      Stream<Assets> assetsStream =
          assetsSubCollection!.snapshots().map((snapshot) {
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
      Stream<List<Notif>> notificationsStream = notificationsSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Notif.fromMap(doc.data() as Map<String, dynamic>))
              .toList());

      // Stream for the graphPoints subcollection
      Stream<List<GraphPoint>> graphPointsStream = graphPointsSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) =>
                  GraphPoint.fromMap(doc.data() as Map<String, dynamic>))
              .toList());

      return Rx.combineLatest6(
          clientDocumentStream,
          activitiesStream,
          assetsStream,
          notificationsStream,
          graphPointsStream,
          connectedUsersStream, (DocumentSnapshot clientDoc,
              List<Activity> activities,
              Assets assets,
              List<Notif> notifications,
              List<GraphPoint> graphPoints,
              List<Client?> connectedUsers) {
        final clientData = clientDoc.data() as Map<String, dynamic>?;

        if (clientData == null) {
          log('clientDoc.data() is null for cid: ${cid ?? 'unknown'}');
          return Client.empty();
        }

        return Client.fromMap(
          cid: cid,
          clientData,
          activities: activities,
          assets: assets,
          notifications: notifications,
          graphPoints: graphPoints,
          connectedUsers: connectedUsers.whereType<Client>().toList(),
        );
      });
    } catch (e) {
      log('database.dart: Error in getClientStream: $e');
      return Stream.value(null);
    }
  }
}
