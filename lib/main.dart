import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import '/firebase_options.dart';
import '/screens/wrapper.dart';
import 'screens/authenticate/create_account.dart';
import 'screens/authenticate/login/login.dart';
import 'screens/authenticate/login/forgot_password.dart';
import 'screens/dashboard/dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // test
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

// StatelessWidget representing the entire application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // The build method to define the structure of the app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Title of the application
      title: 'Team Shaikh Investments',

      // Theme data for styling the general background
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 22, 42, 77),
      ),

      // When the app first starts, call the wrapper class which will
      // determine whether to show the home page or the authenticate page
      home: Wrapper(),

      // Routes for different pages in the app
      routes: {
        '/create_account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/dashboard': (context) => DashboardPage(),
        '/analytics': (context) => const AnalyticsPage(),
        '/activity': (context) => const ActivityPage(),
        '/profile': (context) => const ProfilePage(),
      },

    );
  }
}