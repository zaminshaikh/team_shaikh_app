// main.dart

// Flutter and Dart packages
import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Firebase packages
import 'package:firebase_auth/firebase_auth.dart';

// Third-party packages
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local components
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/screens/authenticate/create_account/create_account.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/authenticate/initial_face_id.dart';
import 'package:team_shaikh_app/screens/authenticate/onboarding.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:team_shaikh_app/screens/authenticate/login/forgot_password.dart';
import 'package:team_shaikh_app/screens/authenticate/utils/faceid.dart';
import 'package:team_shaikh_app/screens/authenticate/utils/app_state.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/notifications/notifications.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import 'package:team_shaikh_app/screens/utils/push_notification.dart';
import 'package:team_shaikh_app/screens/utils/utilities.dart';

// === Import the new file with your 3 functions ===
import 'package:team_shaikh_app/app_services.dart'
    show initializeServices, isAuthenticated;
import 'package:team_shaikh_app/screens/authenticate/auth_check.dart';
import 'package:team_shaikh_app/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services and configurations
  await initializeServices();

  // Lock device orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthState(),
      child: const MyApp(),
    ),
  );
}