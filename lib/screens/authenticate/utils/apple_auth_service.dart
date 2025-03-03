import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:team_shaikh_app/components/alert_dialog.dart';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/screens/authenticate/utils/app_state.dart';
import 'package:provider/provider.dart';
import 'dart:developer';

import 'package:team_shaikh_app/database/auth_helper.dart';

class AppleAuthService {
  /// Sign up with Apple account
  Future<void> signUpWithApple(BuildContext context, String cid) async {
    try {
      // Trigger Apple sign in flow
      final credential = await _getAppleCredential();
      if (credential == null) return;

      // Sign in with Firebase
      final userCredential = await _signInWithFirebase(credential);
      if (userCredential == null || userCredential.user == null) return;

      // Process sign-up
      await _processSignUp(context, userCredential, cid);
    } catch (e) {
      log('Error in Apple sign up: $e', stackTrace: StackTrace.current);
      await _showError(context, 'Failed to sign up with Apple: ${e.toString()}');
    }
  }

  /// Get Apple credential
  Future<OAuthCredential?> _getAppleCredential() async {
    try {
      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential
      return OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
    } catch (e) {
      log('Failed to get Apple credential: $e', stackTrace: StackTrace.current);
      return null;
    }
  }

  /// Sign in with Firebase using Apple credential
  Future<UserCredential?> _signInWithFirebase(OAuthCredential credential) async {
    try {
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      log('Firebase sign-in failed: $e', stackTrace: StackTrace.current);
      return null;
    }
  }

  /// Process the sign up after authentication
  Future<void> _processSignUp(
      BuildContext context, UserCredential userCredential, String cid) async {
    User user = userCredential.user!;

    // Check if this is a new user
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    // Initialize database with CID
    final db = DatabaseService.withCID(user.uid, cid);

    // Check if CID exists
    if (!(await db.checkDocumentExists(cid))) {
      await _showError(context,
          'No record found for Client ID $cid. Please contact support.');
      await FirebaseAuth.instance.signOut();
      return;
    }

    // Check if CID is already linked
    if (await db.checkDocumentLinked(cid)) {
      if (!isNewUser) {
        // User is logging in with existing account
        await updateFirebaseMessagingToken(user, context);
        Provider.of<AuthState>(context, listen: false)
            .setInitiallyAuthenticated(true);
        await Navigator.of(context)
            .pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        // Someone else has already linked with this CID
        await _showError(context,
            'This Client ID is already linked to another account. Please use a different Client ID or contact support.');
        await FirebaseAuth.instance.signOut();
      }
      return;
    }

    // Link new user
    await db.linkNewUser(user.email ?? 'Unknown email');
    await updateFirebaseMessagingToken(user, context);

    // Notify user of success
    if (context.mounted) {
      await CustomAlertDialog.showAlertDialog(
        context,
        'Success',
        'Your account has been created and linked successfully.',
        icon: const Icon(Icons.check_circle_outline_rounded,
            color: Colors.green),
      );

      // Update app state and navigate to dashboard
      Provider.of<AuthState>(context, listen: false)
          .setInitiallyAuthenticated(true);
      await Navigator.of(context)
          .pushNamedAndRemoveUntil('/dashboard', (route) => false);
    }
  }

  /// Show error dialog
  Future<void> _showError(BuildContext context, String message) async {
    if (context.mounted) {
      await CustomAlertDialog.showAlertDialog(
        context,
        'Error',
        message,
        icon: const Icon(Icons.error_outline, color: Colors.red),
      );
    }
  }
}
