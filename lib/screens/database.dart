import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final String cid;
  final String uid;

  DatabaseService(this.cid, this.uid);

  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('testUsers');

  Future updateUserData(String email) async {
    try {
      // Fetch existing data
      DocumentSnapshot userSnapshot = await usersCollection.doc(cid).get();
      
      // Check if the document exists
      if (userSnapshot.exists) {
        // Get existing data
        Map<String, dynamic> existingData = userSnapshot.data() as Map<String, dynamic>;
        
        // Update fields, including "connectedUsers"
        Map<String, dynamic> updatedData = {
          'uid': uid,
          'email': email,
          'name': existingData['name'],
          'hapticsOn': existingData['hapticsOn'],
          'notif': existingData['notif'],
          'connectedUsers': existingData['connectedUsers'], // Update the connectedUsers array
        };

        // Set the document with the updated data
        return await usersCollection.doc(cid).set(updatedData);
      } else {
        log('Document does not exist for CID: $cid');
      }
    } catch (e) {
      log('Error creating/updating: $e', stackTrace: StackTrace.current);
    }
  }

  Stream<QuerySnapshot> get users {
    return usersCollection.snapshots();
  }

  
}

