// app_services.dart

import 'dart:async';
import 'dart:developer';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Third-party
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Local imports
import 'package:team_shaikh_app/screens/utils/push_notification.dart';
import 'package:team_shaikh_app/screens/utils/utilities.dart' show Config; 
import 'package:team_shaikh_app/database/database.dart';

/// Initialize third-party services and configurations
Future<void> initializeServices() async {
  // Ensure screen size is initialized
  await ScreenUtil.ensureScreenSize();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize push notifications
  await PushNotificationService().initialize();

  // Load application configuration
  await Config.loadConfig();

  // Reset Firestore settings to ensure a clean state
  await resetFirestore();
}

/// Reset Firestore settings to ensure a clean state
Future<void> resetFirestore() async {
  // Terminate Firestore to detach any active listeners
  await FirebaseFirestore.instance.terminate();

  // Clear persisted data
  await FirebaseFirestore.instance.clearPersistence();

  // Disable persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}

/// Check if the user is authenticated and linked
Future<bool> isAuthenticated() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  String uid = user.uid;
  DatabaseService db = DatabaseService(uid);
  bool isLinked = await db.isUIDLinked(uid);

  return isLinked;
}