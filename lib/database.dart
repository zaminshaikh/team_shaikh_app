import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A class that provides database operations for managing users.
///
/// This class is responsible for linking new users to the database and retrieving user data from the database.
/// It interacts with the 'users' collection in the Firestore database.
class DatabaseService {
  String? cid;
  final String uid;
  static final CollectionReference usersCollection = FirebaseFirestore.instance.collection('testUsers');
  CollectionReference? assetsSubCollection;

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
  static Future<DatabaseService?> fetchCID(String uid, int code) async {
    DatabaseService service = DatabaseService(uid);

    // Access Firestore and get the document
    QuerySnapshot querySnapshot = await usersCollection.where('uid', isEqualTo: uid).get();

    if (querySnapshot.size > 0) {
      // Document found, access the 'cid' field
      service.cid = querySnapshot.docs.first.id;
      switch (code) {
        case 1:
          service.assetsSubCollection = FirebaseFirestore.instance.collection('testUsers').doc(service.cid).collection('assets');
          log('Assets subcollection set to $usersCollection/${service.cid}/assets');
          break; 
        default:
          log('Invalid code');
      }
      // Now you can use 'cid' in your code
      log('CID: ${service.cid}');
    } else {
      log('Document with UID $uid not found in Firestore.');
      return null;
    }

    return service;
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
  ///   print('User linked to database successfully.');
  /// } catch (e) {
  ///   print('Error linking user to database: $e');
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
          'uid': uid,
          'email': email,
          'name': existingData['name'],
          'hapticsOn': existingData['hapticsOn'],
          'notif': existingData['notif'],
          'connectedUsers': existingData['connectedUsers'],
        };

        // Set the document with the updated data
        return await usersCollection.doc(cid).set(updatedData);

      } else {
        throw FirebaseAuthException(
          code: 'document-not-found',
          message: 'Document does not exist for cid: $cid'
        );
      }
      // This throws the exception to the calling method
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuth exceptions
      log('FirebaseAuthException: $e');
      rethrow; // Rethrow to propagate the exception to the caller

    } on FirebaseException catch (e) {
      // Handle Firebase exceptions
      log('FirebaseException: $e');
      rethrow; // Rethrow to propagate the exception to the caller

    } catch (e) {
      // Catch any other exceptions
      log('Error creating/updating: $e', stackTrace: StackTrace.current);
      rethrow; // Rethrow to propagate the exception to the caller
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
    List<Map<String, dynamic>> assets = assetsSnapshot.docs.map((asset) => asset.data() as Map<String, dynamic>).toList();
    return UserWithAssets(info, assets);
  });

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
    if (connectedUsers.isEmpty) {
      return [];
    }
    List<UserWithAssets> connectedUsersWithAssets = [];
    for (String connectedUser in connectedUsers) {
      DocumentSnapshot connectedUserSnapshot = await usersCollection.doc(connectedUser).get();
      Map<String, dynamic> connectedUserData = connectedUserSnapshot.data() as Map<String, dynamic>;
      QuerySnapshot connectedUserAssetsSnapshot = await usersCollection.doc(connectedUser).collection('assets').get();
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
      List<String> subcollections = ['assets', 'notifications', 'activities'];

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
}

/// Represents a user with their information and assets.
class UserWithAssets {
  /// The user's information.
  final Map<String, dynamic> info;

  /// The user's assets.
  final List<Map<String, dynamic>> assets;

  /// Creates a new instance of [UserWithAssets].
  UserWithAssets(this.info, this.assets);
}

