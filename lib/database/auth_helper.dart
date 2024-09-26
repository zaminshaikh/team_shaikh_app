import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:team_shaikh_app/components/alert_dialog.dart';

/// Deletes any user currently in the Firebase Auth buffer.
Future<void> deleteUserInBuffer() async {
  if (FirebaseAuth.instance.currentUser != null) {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        await FirebaseAuth.instance.signOut();
      } else {
        log('Error deleting user: $e', stackTrace: StackTrace.current);
      }
    }
    log('User after delete: ${FirebaseAuth.instance.currentUser ?? 'deleted'}');
  }
}

/// Handles FirebaseAuthException and displays an error message.
void handleFirebaseAuthException(
    BuildContext context, FirebaseAuthException e, String email) {
  String errorMessage = 'Failed to sign up. Please try again.';
  switch (e.code) {
    case 'email-already-in-use':
      errorMessage =
          'Email $email is already in use. Please use a different email.';
      log('Email is already connected to a different CID.');
      break;
    case 'invalid-email':
      errorMessage = '"$email" is not a valid email format. Please try again.';
      log('Invalid email format.');
      break;
    case 'weak-password':
      errorMessage = 'The password provided is too weak.';
      log('Weak password.');
      break;
    default:
      log('FirebaseAuthException: $e');
  }
  CustomAlertDialog.showAlertDialog(context, 'Error', errorMessage,
      icon: const Icon(Icons.error, color: Colors.red));
}

/// Updates Firebase Messaging token.
Future<void> updateFirebaseMessagingToken(User user) async {
  // Implementation for updating the Firebase Messaging token.
  // Replace with your actual code as needed.
}
