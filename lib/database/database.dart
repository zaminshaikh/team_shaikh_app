import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';
import 'package:team_shaikh_app/database/models/graph_point_model.dart';
import 'package:team_shaikh_app/database/models/notification_model.dart';
import 'package:team_shaikh_app/database/models/assets_model.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:team_shaikh_app/screens/utils/utilities.dart';

/// A service class for interacting with the Firestore database.
///
/// This class handles operations related to the user's data in Firestore,
/// such as fetching client data, updating fields, and managing notifications.
class DatabaseService {
  String? cid; // Client ID: Document ID in Firestore
  String? uid; // User ID: Firebase Auth UID

  // Flag to indicate if the user is connected to another user  
  // This is so we don't fetch the connected user's connected users and avoid infinite recursion
  bool isConnectedUser = false; 

  static final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection(Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION'));

  CollectionReference? assetsSubCollection;
  CollectionReference? activitiesSubCollection;
  CollectionReference? notificationsSubCollection;
  CollectionReference? graphPointsSubCollection;
  List<dynamic>? connectedUsersCIDs;

  /// Constructs a [DatabaseService] instance with the given [uid].
  DatabaseService(this.uid);

  /// Constructs a [DatabaseService] instance for a connected user with the given [cid].
  DatabaseService.connectedUser(this.cid) {
    setSubCollections(this);
    isConnectedUser = true;
  }

  /// Constructs a [DatabaseService] instance with the given [uid] and [cid].
  DatabaseService.withCID(this.uid, this.cid);

  /// Asynchronously creates a [DatabaseService] instance by fetching the [cid] for the given [uid].
  ///
  /// Returns a [Future] that completes with a [DatabaseService] instance or `null` if the [uid] is not found.
  /// Each user in Firestore has a document with a unique [uid] field. If the [uid] is found, the method fetches the [cid] and connected users from the document.
  static Future<DatabaseService?> fetchCID(String uid) async {
    DatabaseService db = DatabaseService(uid);

    // Access Firestore and get the document
    QuerySnapshot querySnapshot =
        await usersCollection.where('uid', isEqualTo: uid).get();

    if (querySnapshot.size > 0) {
      log('database.dart: UID $uid found in Firestore.');

      // Document found, access the 'cid' field
      QueryDocumentSnapshot snapshot = querySnapshot.docs.first;
      db.cid = snapshot.id;

      // Cast snapshot.data() to Map<String, dynamic>
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      // Check if 'connectedUsers' field exists before trying to access it
      if (data.containsKey('connectedUsers')) {
        db.connectedUsersCIDs = data['connectedUsers'] ?? [];
      } else {
        log('database.dart: Field "connectedUsers" does not exist in document.');
        db.connectedUsersCIDs = []; // Or handle this case as needed
      }

      setSubCollections(db);
    } else {
      log('database.dart: Document with UID $uid not found in Firestore.');
      return null;
    }

    return db;
  }

  /// Sets the sub-collections for the given [DatabaseService] instance.
  ///
  /// This includes assets, activities, notifications, and graph points sub-collections.
  static void setSubCollections(DatabaseService db) {
    db.assetsSubCollection = usersCollection
        .doc(db.cid)
        .collection(Config.get('ASSETS_SUBCOLLECTION'));
    db.graphPointsSubCollection = db.assetsSubCollection
        ?.doc(Config.get('ASSETS_GENERAL_DOC_ID'))
        .collection(Config.get('GRAPHPOINTS_SUBCOLLECTION'));
    db.activitiesSubCollection = usersCollection
        .doc(db.cid)
        .collection(Config.get('ACTIVITIES_SUBCOLLECTION'));
    db.notificationsSubCollection = usersCollection
        .doc(db.cid)
        .collection(Config.get('NOTIFICATIONS_SUBCOLLECTION'));
  }

  /// Returns a stream that listens to changes in the user's client data and sub-collections.
  ///
  /// The stream emits [Client] objects containing updated client data whenever changes occur.
  Stream<Client?> getClientStream() {
    if (cid == null) {
      return Stream.value(null);
    }

    log('database.dart: Fetching client stream for CID: $cid');

    try {
      // Stream for the main client document
      Stream<DocumentSnapshot> clientDocumentStream =
          usersCollection.doc(cid).snapshots();

      // Stream for connected users
      Stream<List<Client?>> connectedUsersStream;
      if (!isConnectedUser &&
          connectedUsersCIDs != null &&
          connectedUsersCIDs!.isNotEmpty) {
        connectedUsersStream =
            Rx.combineLatestList(connectedUsersCIDs!.map((connectedCid) {
          DatabaseService db = DatabaseService.connectedUser(connectedCid);
          return db.getClientStream().asBroadcastStream();
        }).toList())
                .asBroadcastStream();
      } else {
        connectedUsersStream = Stream.value([null]);
      }

      // Stream for the activities sub-collection
      Stream<List<Activity>> activitiesStream = activitiesSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map(
                  (doc) => Activity.fromMap(doc.data() as Map<String, dynamic>))
              .toList());

      // Stream for the assets sub-collection
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

      // Stream for the notifications sub-collection
      Stream<List<Notif?>> notificationsStream = notificationsSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
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
              }).toList());

      // Stream for the graphPoints sub-collection
      Stream<List<GraphPoint?>> graphPointsStream = graphPointsSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                try {
                  return GraphPoint.fromMap(doc.data() as Map<String, dynamic>);
                } catch (e) {
                  log('database.dart: Error creating GraphPoint from map: $e');
                  return null;
                }
              }).toList());

      // Combine all the streams into a single stream emitting Client objects
      return Rx.combineLatest6(
          clientDocumentStream,
          activitiesStream,
          assetsStream,
          notificationsStream,
          graphPointsStream,
          connectedUsersStream, (
        DocumentSnapshot clientDoc,
        List<Activity> activities,
        Assets assets,
        List<Notif?> notifications,
        List<GraphPoint?> graphPoints,
        List<Client?> connectedUsers,
      ) {
        final clientData = clientDoc.data() as Map<String, dynamic>?;

        if (clientData == null) {
          log('clientDoc.data() is null for cid: ${cid ?? 'unknown'}');
          return Client.empty();
        }

        // Filter out null values and sort the graphPoints
        List<GraphPoint> filteredGraphPoints =
            graphPoints.whereType<GraphPoint>().toList();
        filteredGraphPoints.sort((a, b) => a.time.compareTo(b.time));

        return Client.fromMap(
          cid: cid,
          clientData,
          activities: activities,
          assets: assets,
          notifications: notifications.whereType<Notif>().toList(), // Filter out null values
          graphPoints: filteredGraphPoints,
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
  /// - [fieldName]: The name of the field to retrieve.
  ///
  /// Returns:
  /// - A [Future] that completes with the value of the specified field, or `null` if the field does not exist.
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
  /// - A [Future] that completes when the field is updated.
  Future<void> updateField(String fieldName, dynamic newValue) async {
    try {
      await usersCollection.doc(cid).update({fieldName: newValue});
    } catch (e) {
      throw Exception('Error updating field: $e');
    }
  }

  /// Marks a specific notification as read.
  ///
  /// Parameters:
  /// - [notificationId]: The ID of the notification to mark as read.
  ///
  /// Returns:
  /// - A [Future] that completes with `true` if successful, `false` otherwise.
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
      DocumentReference docRef =
          notificationsSubCollection!.doc(notificationId);

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

  /// Marks all notifications as read for the current user and connected users.
  ///
  /// Returns:
  /// - A [Future] that completes with `true` if successful, `false` otherwise.
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
          futures.add(DatabaseService.withCID('', connectedCid)
              .markAllNotificationsAsRead());
        }
      }

      await Future.wait(futures);
      return true;
    } catch (e) {
      log('Error updating notifications: $e');
    }
    return false;
  }

  /// Links a new user to the database using the provided email.
  ///
  /// This method fetches the existing data for the user with the given [cid] (Client ID) from the database.
  /// Each [cid] corresponds to a document in the 'users' collection in the database.
  /// If the user already exists (determined by the presence of a [uid] in the existing data), an exception is thrown.
  /// Otherwise, the method updates the existing data with the new user's [uid] and [email] and sets the document in the database with the updated data.
  ///
  /// Throws a [FirebaseException] if:
  /// - **No document found**: The document does not exist for the given [cid].
  /// - **User already exists**: The document we pulled has a non-empty [uid], meaning a user already exists for the given [cid].
  ///
  /// Catches any other unhandled exceptions and logs an error message.
  ///
  /// Parameters:
  /// - [email]: The email of the new user to be linked to the database.
  ///
  /// Usage:
  /// ```dart
  /// try {
  ///   DatabaseService db = new DatabaseService(cid, uid);
  ///   await db.linkUserToDatabase(email, cid);
  ///   log('database.dart: User linked to database successfully.');
  /// } catch (e) {
  ///   log('database.dart: Error linking user to database: $e');
  /// }
  /// ```
  ///
  /// Returns a [Future] that completes when the document is successfully set in the database.
  Future linkNewUser(String email) async {
    try {
      // Fetch existing data
      DocumentSnapshot userSnapshot = await usersCollection.doc(cid).get();

      // Check if the document exists
      if (userSnapshot.exists) {
        // Get existing data
        Map<String, dynamic> existingData =
            userSnapshot.data() as Map<String, dynamic>;

        // If the document we pulled has a UID, then the user already exists
        if (existingData['uid'] != '') {
          throw FirebaseAuthException(
              code: 'user-already-exists',
              message: 'User already exists for cid: $cid');
        }
        // Update new fields and keep old ones from snapshot
        Map<String, dynamic> updatedData = {
          ...existingData,
          'uid': uid,
          'email': email,
          'appEmail': email,
        };

        // Set the document with the updated data
        await usersCollection.doc(cid).set(updatedData);

        log('database.dart: User $uid has been linked with document $cid in Firestore');

        return;
      } else {
        throw FirebaseAuthException(
            code: 'document-not-found',
            message: 'Document does not exist for cid: $cid');
      }
      // This throws the exception to the calling method
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuth exceptions
      log('database.dart: FirebaseAuthException: $e');
      rethrow; // Rethrow to propagate the exception to the caller
    } on FirebaseException catch (e) {
      // Handle Firebase exceptions
      log('database.dart: FirebaseException: $e');
      rethrow; // Rethrow to propagate the exception to the caller
    } catch (e) {
      // Catch any other exceptions
      log('database.dart: Error creating/updating: $e',
          stackTrace: StackTrace.current);
      rethrow; // Rethrow to propagate the exception to the caller
    }
  }

  /// Returns a stream of [DocumentSnapshot] containing a single user document.
  ///
  /// This stream will emit a new [DocumentSnapshot] whenever the user document is updated.
  Stream<DocumentSnapshot> get getUser => usersCollection.doc(cid).snapshots();

  /// Checks if a document with the given [cid] exists in the users collection.
  ///
  /// Returns a [Future] that completes with `true` if the document exists, `false` otherwise.
  ///
  /// Parameters:
  /// - [cid]: The ID of the document to check.
  Future<bool> docExists(String cid) async {
    DocumentSnapshot doc = await usersCollection.doc(cid).get();
    return doc.exists;
  }

  /// Checks if a document with the given [cid] is linked to a user.
  ///
  /// Returns a [Future] that completes with `true` if the document is linked, `false` otherwise.
  ///
  /// Parameters:
  /// - [cid]: The ID of the document to check.
  Future<bool> docLinked(String cid) async {
    DocumentSnapshot doc = await usersCollection.doc(cid).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return data['uid'] != '';
  }
}
