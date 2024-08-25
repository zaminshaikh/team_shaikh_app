import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'utilities.dart';

/// A class that provides database operations for managing users.
///
/// This class is responsible for linking new users to the database and retrieving user data from the database.
/// It interacts with the 'users' collection in the Firestore database.
  List<String> connectedUsersCids = [];
  bool allConnectedCidsExistInTestUsers = false;
class DatabaseService {
  String? cid;
  final String uid;
  static final CollectionReference usersCollection = FirebaseFirestore.instance.collection(Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION'));
  CollectionReference? assetsSubCollection;
  CollectionReference? activitiesSubCollection; 
  CollectionReference? notificationsSubCollection; 
  CollectionReference? graphPointsSubCollection;

  /// A new instance of [DatabaseService] with the given [cid] and [uid].
  /// 
  /// The [cid] (Client ID) is a unique identifier for the user, and the [uid] (User ID) is the unique identifier for the user's auth account.
  /// The instance is used to link a new user to the database, update user information, and retrieve user data from the database.
  /// 
  /// `DatabaseService.linkNewUser(email)` links a new user to the database using the [cid] and updates the [email]
  /// 
  /// `DatabaseService.users` returns a stream of the 'users' collection in the database
  /// 
  /// `DatabaseService.docExists(cid)` returns a [Future] that completes with a boolean value indicating whether a document exists for the given [cid]`
  /// 
  /// `DatabaseService.docLinked(cid)` returns a [Future] that completes with a boolean value indicating whether a user is linked to the database for the given [cid]
  /// 
  /// For more information on the methods, see the individual method documentation.
  DatabaseService(this.uid);
  DatabaseService.withCID(this.uid, this.cid);


  // Asynchronous factory constructor
  static Future<DatabaseService?> fetchCID(BuildContext context, String uid, int code) async {
    DatabaseService service = DatabaseService(uid);

    // Access Firestore and get the document
    QuerySnapshot querySnapshot = await usersCollection.where('uid', isEqualTo: uid).get();

    log('database.dart: UID $uid found in Firestore.');

    if (querySnapshot.size > 0) {
      // Document found, access the 'cid' field
      service.cid = querySnapshot.docs.first.id;
      switch (code) {
        case 1:
          service.assetsSubCollection = usersCollection.doc(service.cid).collection(Config.get('ASSETS_SUBCOLLECTION'));
          service.graphPointsSubCollection = service.assetsSubCollection?.doc(Config.get('ASSETS_GENERAL_DOC_ID')).collection(Config.get('GRAPHPOINTS_SUBCOLLECTION'));
          break;
        case 2:
          service.activitiesSubCollection = usersCollection.doc(service.cid).collection(Config.get('ACTIVITIES_SUBCOLLECTION'));
          break;
        case 3:
          service.notificationsSubCollection = usersCollection.doc(service.cid).collection(Config.get('NOTIFICATIONS_SUBCOLLECTION'));
          break;
        default:
          log('database.dart: Invalid code');
      }
      // Now you can use 'cid' in your code
      log('database.dart: CID: ${service.cid}');
      log('database.dart: Connected users: ${await service.fetchConnectedCids(service.cid!)}');
      connectedUsersCids = await service.fetchConnectedCids(service.cid!);


    } else {
      log('database.dart: Document with UID $uid not found in Firestore.');
      return null;
    }

    return service;
  }

  // Method to check if all connectedUsersCids exist in the testUsers collection
  Future<bool> checkConnectedUsersExistInTestUsers() async {
    CollectionReference testUsersCollection = FirebaseFirestore.instance.collection('testUsers');

    // List to store CIDs that need to be removed
    List<String> cidsToRemove = [];

    for (String connectedCid in connectedUsersCids) {
      DocumentSnapshot docSnapshot = await testUsersCollection.doc(connectedCid).get();
      if (docSnapshot.exists) {
        log('database.dart: Connected user CID $connectedCid exists in testUsers collection.');
      } else {
        log('database.dart: Connected user CID $connectedCid does NOT exist in testUsers collection.');
        log('database.dart: Marking connected user CID $connectedCid for removal.');
        cidsToRemove.add(connectedCid);
      }
    }

    // Remove CIDs that do not exist in the testUsers collection
    connectedUsersCids.removeWhere((cid) => cidsToRemove.contains(cid));

    // Return true if all connected CIDs exist in the testUsers collection
    return cidsToRemove.isEmpty;
  }


  Future<void> logNotificationIds() async {
    if (notificationsSubCollection == null) {
      log('database.dart: Notifications subcollection is not set');
      return;
    }

    // Fetch the documents from the notifications subcollection
    QuerySnapshot querySnapshot = await notificationsSubCollection!.get();

    // Log the document IDs
    for (var doc in querySnapshot.docs) {
      log('database.dart: Notification document ID: ${doc.id}');
    }
  }

  Future<List<String>> fetchConnectedCids(String cid) async {
    DocumentSnapshot userSnapshot = await usersCollection.doc(cid).get();
    if (userSnapshot.exists) {
      Map<String, dynamic> info = userSnapshot.data() as Map<String, dynamic>;
      List<String> connectedUsers = info['connectedUsers'].cast<String>();
      return connectedUsers;
    } else {
      log('database.dart: No document found with cid: $cid');
      return [];
    }
  }

  // ignore: prefer_expression_function_bodies
Future<void> markAsRead(BuildContext context, String uid, String notificationId) async {
  DatabaseService? service = await DatabaseService.fetchCID(context, uid, 3);
    if (service != null) {
      log('${service.cid}');  
      log('database.dart: cid: ${service.cid}, notificationId: $notificationId');
      DocumentReference docRef = usersCollection.doc(service.cid).collection(Config.get('NOTIFICATIONS_SUBCOLLECTION')).doc(notificationId);
      log('database.dart: docref: $docRef');
      DocumentSnapshot docSnap = await docRef.get();
      if (docSnap.exists) {
        return docRef.update({'isRead': true});
      } else {
        // Check if service.cid is null before calling fetchConnectedCids
        if (service.cid == null) {
          return;
        }
        // Fetch the connected users' cids
        List<String> connectedCids = await fetchConnectedCids(service.cid!);
        
        for (String cid in connectedCids) {
          docRef = usersCollection.doc(cid).collection('notifications').doc(notificationId);
          docSnap = await docRef.get();
          if (docSnap.exists) {
            return docRef.update({'isRead': true});
          } else {
          }
        }
      }
    }
  }

  Future<void> markAllAsRead(BuildContext context) async {
    DatabaseService? service = await DatabaseService.fetchCID(context, uid, 3);
    if (service != null && service.cid != null) {
      await _markNotificationsAsRead(service.cid!);
      List<String> connectedCids = await fetchConnectedCids(uid);
      for (String cid in connectedCids) {
        await _markNotificationsAsRead(cid);
      }
    }
  }

  Future<void> _markNotificationsAsRead(String cid) async {
    CollectionReference notificationsCollection = usersCollection.doc(cid).collection(Config.get('NOTIFICATIONS_SUBCOLLECTION'));
    log('database.dart: notificationsCollection: $notificationsCollection');
    QuerySnapshot querySnapshot = await notificationsCollection.get();
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      DocumentReference docRef = doc.reference;
      await docRef.update({'isRead': true});
    }
  }


  /// Links a new user to the database using the provided email.
  ///
  /// This method fetches the existing data for the user with the given [cid] (Client ID) from the database. 
  /// Each [cid] corresponds to a document in the 'users' collection in the database.
  /// If the user already exists (determined by the presence of a [uid] in the existing data), an exception is thrown.
  /// Otherwise, the method updates the existing data with the new user's [uid] and [email] and sets the document in the database with the updated data.
  ///
  /// Throws a [FirebaseException] if:
  /// - **No document found**
  ///   - The document does not exist for the given [cid]
  /// - **User already exists**
  ///   - The document we pulled has a non-empty [uid], meaning a user already exists for the given [cid]
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
        Map<String, dynamic> existingData = userSnapshot.data() as Map<String, dynamic>;

        // If the document we pulled has a UID, then the user already exists
        if (existingData['uid'] != '') {
          throw FirebaseAuthException(
            code: 'user-already-exists',
            message: 'User already exists for cid: $cid'
          );
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
          message: 'Document does not exist for cid: $cid'
        );
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
      log('database.dart: Error creating/updating: $e', stackTrace: StackTrace.current);
      rethrow; // Rethrow to propagate the exception to the caller
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
      log('database.dart: Error getting field: $e', stackTrace: StackTrace.current);
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

  /// Returns a stream of [DocumentSnapshot] containing a single user document.
  /// 
  /// This stream will emit a new [DocumentSnapshot] whenever the user document is updated.
  Stream<DocumentSnapshot> get getUser => usersCollection.doc(cid).snapshots();

  /// Checks if a document with the given [cid] exists in the users collection.
  /// Returns a [Future] that completes with a boolean value indicating whether the document exists or not.
  /// 
  /// Parameters:
  /// - [cid]: The ID of the document to check.
  /// 
  /// Returns:
  /// - A [Future] that completes with a boolean value indicating whether the document exists or not.
  Future<bool> docExists(String cid) async {
    DocumentSnapshot doc = await usersCollection.doc(cid).get();
    return doc.exists;
  }

  /// Checks if a document with the given [cid] is linked to a user.
  /// Returns a [Future] that completes with a boolean value indicating whether the document is linked or not.
  /// 
  /// Parameters:
  /// - [cid]: The ID of the document to check.
  /// 
  /// Returns:
  /// - A [Future] that completes with a boolean value indicating whether the document is linked or not.
  Future<bool> docLinked(String cid) async {
    DocumentSnapshot doc = await usersCollection.doc(cid).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return data['uid'] != '';
  }

  /// Returns a stream of [QuerySnapshot] containing all the asset documents in the assets subcollection.
  Stream<QuerySnapshot> get getAssets {
    if (assetsSubCollection == null) {
      throw Exception('Assets subcollection not set');
    }
    return assetsSubCollection!.snapshots();
  }

  /// Retrieves a stream of [UserWithAssets] objects.
  ///
  /// This method listens to changes in the document with the specified [cid] in the [usersCollection] collection.
  /// It asynchronously maps the user snapshot to a [UserWithAssets] object, which contains user information and a list of assets.
  /// The assets are retrieved by querying the [assetsSubCollection].
  ///
  /// Returns:
  /// - A [Stream] of [UserWithAssets] objects.
  Stream<UserWithAssets> get getUserWithAssets => usersCollection.doc(cid).snapshots().asyncMap((userSnapshot) async {
    Map<String, dynamic> info = userSnapshot.data() as Map<String, dynamic>;
    QuerySnapshot assetsSnapshot = await assetsSubCollection!.get();
    List<Map<String, dynamic>> assets = assetsSnapshot.docs.map((asset) => {
      ...asset.data() as Map<String, dynamic>,
      'id': asset.id,
    }).toList();
    for (int i = 0; i < assets.length; i++) {
      if (assets[i]['id'] == 'general') {
        assets[i] = {
          ...assets[i],
          'graphPoints': await getGraphPoints,
        };
      }
      // Log the asset after updating
      print('Asset after update: ${assets[i]}');
    }

    return UserWithAssets(info, assets);
  });
  
  Future<List<Map<String, dynamic>>> get getGraphPoints async {
      if (graphPointsSubCollection == null) {
        throw Exception('GraphPoints subcollection not set');
      }

      // Fetch the documents in the graphPoints subcollection
      QuerySnapshot querySnapshot = await graphPointsSubCollection!.get();

      // Convert the documents to a List<Map<String, dynamic>>
      List<Map<String, dynamic>> graphPoints = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return graphPoints;
  }

  /// Retrieves a stream of connected users with their assets.
  ///
  /// This method returns a [Stream] that emits a list of [UserWithAssets] objects.
  /// Each [UserWithAssets] object contains information about a connected user and their associated assets.
  /// The stream is updated whenever there are changes to the connected users or their assets in the database.
  ///
  /// Example usage:
  /// ```dart
  /// Stream<List<UserWithAssets>> connectedUsersStream = getConnectedUsersWithAssets;
  /// connectedUsersStream.listen((connectedUsers) {
  ///   // Handle the list of connected users with their assets
  /// });
  /// ```
  Stream<List<UserWithAssets>> get getConnectedUsersWithAssets => usersCollection.doc(cid).snapshots().asyncMap((userSnapshot) async {
    Map<String, dynamic> info = userSnapshot.data() as Map<String, dynamic>;
    List<String> connectedUsers = info['connectedUsers'].cast<String>();
    if ( connectedUsers.isEmpty ) {
      return [];
    }
    List<UserWithAssets> connectedUsersWithAssets = [];
    for (String connectedUser in connectedUsers) {
      DocumentSnapshot connectedUserSnapshot = await usersCollection.doc(connectedUser).get();
      Map<String, dynamic> connectedUserData = connectedUserSnapshot.data() as Map<String, dynamic>;
      QuerySnapshot connectedUserAssetsSnapshot = await usersCollection.doc(connectedUser).collection(Config.get('ASSETS_SUBCOLLECTION')).get();
      List<Map<String, dynamic>> connectedUserAssets = connectedUserAssetsSnapshot.docs.map((asset) => asset.data() as Map<String, dynamic>).toList();
      connectedUsersWithAssets.add(UserWithAssets(connectedUserData, connectedUserAssets));
    }
    return connectedUsersWithAssets;
  });

  Future<void> duplicateDocument(String newDocId) async {
    // Get a reference to the old document
    DocumentReference oldDoc = usersCollection.doc(cid);

    // Read the data from the old document
    Map<String, dynamic>? oldData = (await oldDoc.get()).data() as Map<String, dynamic>?;

    // Check if the old document exists
    if (oldData != null) {
      // Get a reference to the new document
      DocumentReference newDoc = usersCollection.doc(newDocId);

      // Write the data to the new document
      await newDoc.set(oldData);

      // List of subcollections to duplicate
      List<String> subcollections = [Config.get('ASSETS_SUBCOLLECTION'), Config.get('NOTIFICATIONS_SUBCOLLECTION'), Config.get('ACTIVITIES_SUBCOLLECTION')];

      // Duplicate each subcollection
      for (String subcollection in subcollections) {
        // Get a reference to the old subcollection
        CollectionReference oldSubcollection = oldDoc.collection(subcollection);

        // Get all documents in the old subcollection
        QuerySnapshot querySnapshot = await oldSubcollection.get();

        // Duplicate each document in the subcollection
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          // Get a reference to the new subcollection
          CollectionReference newSubcollection = newDoc.collection(subcollection);

          // Write the data to the new document in the subcollection
          await newSubcollection.doc(doc.id).set(doc.data());
        }
      }
    }
  }

  Future<void> replaceSubcollections(String targetCid) async {
    // Get a reference to the source and target documents
    DocumentReference sourceDoc = usersCollection.doc(cid);
    DocumentReference targetDoc = usersCollection.doc(targetCid);

    // List of subcollections to replace
    List<String> subcollections = [Config.get('ASSETS_SUBCOLLECTION'), Config.get('NOTIFICATIONS_SUBCOLLECTION'), Config.get('ACTIVITIES_SUBCOLLECTION')];

    // Replace each subcollection
    for (String subcollection in subcollections) {
      // Get a reference to the source and target subcollections
      CollectionReference sourceSubcollection = sourceDoc.collection(subcollection);
      CollectionReference targetSubcollection = targetDoc.collection(subcollection);

      // Get all documents in the source subcollection
      QuerySnapshot querySnapshot = await sourceSubcollection.get();

      // Delete all documents in the target subcollection
      QuerySnapshot targetQuerySnapshot = await targetSubcollection.get();
      for (QueryDocumentSnapshot doc in targetQuerySnapshot.docs) {
        await targetSubcollection.doc(doc.id).delete();
      }

      // Copy each document from the source subcollection to the target subcollection
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await targetSubcollection.doc(doc.id).set(doc.data());
      }
    }
  }

  Stream<List<Map<String, dynamic>>> get getActivities => usersCollection.doc(cid).snapshots().asyncMap((userSnapshot) async {
    Map<String, dynamic> info = userSnapshot.data() as Map<String, dynamic>;

    var connectedUsers = List<String>.from(info['connectedUsers'] ?? []);
    var allUsers = [cid, ...connectedUsers];
    var allActivities = await Future.wait(allUsers.map((userId) async {
      var snapshots = await usersCollection.doc(userId).collection(Config.get('ACTIVITIES_SUBCOLLECTION')).get();
      return snapshots.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['amount'] = data['amount']?.toDouble();
        return data;
      }).toList();
    }));

    return allActivities.expand((x) => x).toList();
  });
  
    Stream<List<Map<String, dynamic>>> get getNotifications => usersCollection.doc(cid).collection(Config.get('NOTIFICATIONS_SUBCOLLECTION')).orderBy('time', descending: true).snapshots().asyncMap((snapshot) async => snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      data['id'] = doc.id; 
      return data;
      }).toList());
}



class BasicUser {
  /// The user's information.
  final Map<String, dynamic> info;
  BasicUser(this.info);
}

/// Represents a user with their information and assets.
class UserWithAssets extends BasicUser{
  final List<Map<String, dynamic>> assets;
  /// Creates a new instance of [UserWithAssets].
  UserWithAssets(Map<String, dynamic> info, this.assets) : super(info);
}

