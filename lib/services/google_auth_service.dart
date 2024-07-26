import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/material.dart'; // For Navigator
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/utilities.dart';

bool showAlert = false;

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    debugPrint('GoogleAuthService: Starting Google sign-in process.');

    try {
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount == null) {
        debugPrint('GoogleAuthService: Google sign-in aborted by user.');
        return null;
      }
      debugPrint('GoogleAuthService: Google sign-in successful.');

      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
      debugPrint('GoogleAuthService: Google authentication obtained.');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      debugPrint('GoogleAuthService: Firebase credential created.');

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint('GoogleAuthService: Firebase sign-in successful.');

      // Check if the uid exists in Firestore
      final User? user = userCredential.user;
      if (user != null) {
        final DatabaseService? service = await DatabaseService.fetchCID(context, user.uid, 1);
        if (service == null) {
          debugPrint('GoogleAuthService: UID does not exist in Firestore. Redirecting to login.');
          showAlert = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
          return null;
        }
      } else {
        debugPrint('GoogleAuthService: User UID is null. Redirecting to login.');
        showAlert = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
        return null;
      }

      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );

      return userCredential;
    } catch (e) {
      debugPrint('GoogleAuthService: Error during Google sign-in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    debugPrint('GoogleAuthService: Starting sign-out process.');

    try {
      await _googleSignIn.signOut();
      debugPrint('GoogleAuthService: Google sign-out successful.');

      await _auth.signOut();
      debugPrint('GoogleAuthService: Firebase sign-out successful.');
    } catch (e) {
      debugPrint('GoogleAuthService: Error during sign-out: $e');
      rethrow;
    }
  }
}