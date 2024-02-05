import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

/// A class that provides database operations for managing users.
///
/// This class is responsible for linking new users to the database and retrieving user data from the database.
/// It interacts with the 'users' collection in the Firestore database.
class DatabaseService {
  
  String? cid;
  final String uid;
  static final CollectionReference usersCollection = FirebaseFirestore.instance.collection('testUsers');


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
  static Future<DatabaseService> fetchCID(String uid) async {
    DatabaseService service = DatabaseService(uid);

    // Access Firestore and get the document
    QuerySnapshot querySnapshot = await usersCollection.where('uid', isEqualTo: uid).get();

    if (querySnapshot.size > 0) {
      // Document found, access the 'cid' field
      service.cid = querySnapshot.docs.first.id;
      // Now you can use 'cid' in your code
      log('CID: ${service.cid}');
    } else {
      log('Document with UID $uid not found in Firestore.');
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
  Stream<DocumentSnapshot> get getUser {
    return usersCollection.doc(cid).snapshots();
  }

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

  


  
}
