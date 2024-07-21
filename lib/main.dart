import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import '/firebase_options.dart';
import '/screens/wrapper.dart';
import 'screens/authenticate/create_account.dart';
import 'screens/authenticate/login/login.dart';
import 'screens/authenticate/login/forgot_password.dart';
import 'screens/dashboard/dashboard.dart';
import 'utilities.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  await Config.loadConfig();
  runApp(const MyApp());
}

// StatelessWidget representing the entire application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // The build method to define the structure of the app
  @override
  Widget build(BuildContext context) => MaterialApp(
      // Title of the application
      title: 'Team Shaikh Investments',

      // Theme data for styling the general background
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 17, 24, 39),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontFamily: 'Titillium Web', fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white, fontFamily: 'Titillium Web', fontWeight: FontWeight.bold),
          titleSmall: TextStyle(color: Colors.white, fontFamily: 'Titillium Web', fontWeight: FontWeight.bold),
          labelLarge: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          labelMedium: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          labelSmall: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          displayLarge: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          displayMedium: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          displaySmall: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          headlineLarge: TextStyle(color: Colors.white, fontFamily: 'Titillium Web', fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontFamily: 'Titillium Web', fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.white, fontFamily: 'Titillium Web', fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          bodySmall: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          // Add other text styles if needed
        ),
      ),
      // When the app first starts, call the wrapper class which will
      // determine whether to show the home page or the authenticate page
      home: const Wrapper(),

      // Routes for different pages in the app
      routes: {
        '/create_account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/dashboard': (context) => DashboardPage(),
        '/analytics': (context) => const AnalyticsPage(),
        '/activity': (context) => const ActivityPage(),
        '/profile': (context) => const ProfilePage(),
        '/notification': (context) => const NotificationPage(),
      },

    );
}