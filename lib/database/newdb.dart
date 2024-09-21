import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool isConnectedUser = false;
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
    isConnectedUser = true;
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
  Stream<Client?> getClientStream() {
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
          return db.getClientStream().asBroadcastStream();
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
      Stream<List<Notif?>> notificationsStream = notificationsSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                try {
                  return Notif.fromMap(<String, dynamic>{
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                    'parentCID': cid
                  });
                } catch (e) {
                  log('database.dart: Error creating Notif from map: $e');
                  return null;
                }
              })
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
              List<Notif?> notifications,
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
          notifications: notifications.whereType<Notif>().toList(),
          graphPoints: graphPoints,
          connectedUsers: connectedUsers.whereType<Client>().toList(),
        );
      });
    } catch (e) {
      log('database.dart: Error in getClientStream: $e');
      return Stream.value(null);
    }
  }

    /// Returns a field from the user document.
  ///
  /// Parameters:
  /// - [uid]: The ID of the user.
  /// - [fieldName]: The name of the field to retrieve.
  ///
  /// Returns:
  /// - A Future that completes with the value of the specified field.
  Future<dynamic> getField(String fieldName) async {
    try {
      DocumentSnapshot userDoc = await usersCollection.doc(cid).get();
      if (userDoc.exists) {
        if ((userDoc.data() as Map<String, dynamic>).containsKey(fieldName)) {
          return userDoc.get(fieldName);
        } else {
          return null; // Field does not exist
        }
      } else {
        throw Exception('User document does not exist');
      }
    } catch (e) {
      log('database.dart: Error getting field: $e',
          stackTrace: StackTrace.current);
      return null;
    }
  }

    /// Updates a field in the user document.
  ///
  /// Parameters:
  /// - [fieldName]: The name of the field to update.
  /// - [newValue]: The new value to set for the field.
  ///
  /// Returns:
  /// - A Future that completes when the field is updated.
  Future<void> updateField(String fieldName, dynamic newValue) async {
    try {
      await usersCollection.doc(cid).update({fieldName: newValue});
    } catch (e) {
      throw Exception('Error updating field: $e');
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    if (cid == null) {
      log('CID is null');
      return false;
    } else if (notificationsSubCollection == null) {
      setSubCollections(this);
    }
    if (notificationsSubCollection == null) {
      log('notificationsSubCollection is null, try checking the path.');
      return false;
    } 
    try {
      DocumentReference docRef = notificationsSubCollection!.doc(notificationId);

      DocumentSnapshot docSnap = await docRef.get();

      if (docSnap.exists) {
        await docRef.update({'isRead': true});
        return true;
      }
    } catch (e) {
      log('Error updating notification: $e');
    }
    return false;
  }

  Future<bool> markAllNotificationsAsRead() async {
      if (cid == null) {
        log('CID is null');
        return false;
      } else if (notificationsSubCollection == null) {
        setSubCollections(this);
      }
      if (notificationsSubCollection == null) {
        log('notificationsSubCollection is null, try checking the path.');
        return false;
      }
      try {
        DocumentSnapshot clientSnapshot = await usersCollection.doc(cid).get();
        QuerySnapshot querySnapshot = await notificationsSubCollection!.get();

        List<Future> futures = [];

        if (querySnapshot.size > 0) {
          for (DocumentSnapshot doc in querySnapshot.docs) {
            futures.add(doc.reference.update({'isRead': true}));
          }
        }

        Map<String, dynamic>? clientData =
            clientSnapshot.data() as Map<String, dynamic>?;
        if (clientData != null && clientData['connectedUsers'] != null) {
          for (String connectedCid in clientData['connectedUsers']) {
            futures.add(
                NewDB.withCID('', connectedCid).markAllNotificationsAsRead());
          }
        }

        await Future.wait(futures);
        return true;
      } catch (e) {
        log('Error updating notifications: $e');
      }
      return false;
    }

  
}
