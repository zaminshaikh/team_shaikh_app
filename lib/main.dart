// Import Flutter Library
import 'package:flutter/material.dart';

// Import firebase_core
import 'package:firebase_core/firebase_core.dart';

// Import our firebase dart file
import 'package:team_shaikh_app/firebase_options.dart';

// Import Create Account Page
import 'screens/Welcome/createAccount.dart';

// Import Login Page
import 'screens/Welcome/Login/login.dart';

// Import Forgot Password Page
import 'screens/Welcome/Login/forgotPassword.dart';

// Import Forgot Password Page
import 'screens/Dashboard/dashboard.dart';

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
      title: 'Mansa',

      // Theme data for styling the general background
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 22, 42, 77),
      ),

      // Initial route so the app navigates to the create_account page when the app starts
      initialRoute: '/create_account',

      // Routes for different pages in the app
      routes: {
        '/create_account': (context) => CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/forgot_password': (context) => ForgotPasswordPage(),
        '/dashboard': (context) => DashboardPage(),
      },
    );
  }
}