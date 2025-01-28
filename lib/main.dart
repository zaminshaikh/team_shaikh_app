// main.dart

// Flutter and Dart packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Firebase packages

// Third-party packages
import 'package:provider/provider.dart';

// Local components
import 'package:team_shaikh_app/screens/authenticate/utils/app_state.dart';

// === Import the new file with your 3 functions ===
import 'package:team_shaikh_app/app_services.dart'
    show initializeServices;
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