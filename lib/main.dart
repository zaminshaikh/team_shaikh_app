// ignore_for_file: prefer_expression_function_bodies

import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:team_shaikh_app/push_notification.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/authenticate/welcome.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import '/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/authenticate/create_account.dart';
import 'screens/authenticate/login/login.dart';
import 'screens/authenticate/login/forgot_password.dart';
import 'screens/dashboard/dashboard.dart';
import 'dart:developer';
import 'utilities.dart';
import 'package:team_shaikh_app/screens/authenticate/faceid.dart';
import 'package:team_shaikh_app/screens/authenticate/app_state.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PushNotificationService().initialize();
  await Config.loadConfig();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => AppState(),
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}


class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  AppState? appState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appState?.setHasNavigatedToFaceIDPage(false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
// Update the lifecycle state
    final appState = Provider.of<AppState>(context, listen: false);
  
    if ((state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) &&
        !appState.hasNavigatedToFaceIDPage &&
        isAuthenticated()) { // Check if the user is authenticated
      // appState.setHasNavigatedToFaceIDPage(true);
      // navigatorKey.currentState?.pushReplacement(
      //   PageRouteBuilder(
      //     pageBuilder: (context, animation, secondaryAnimation) => const FaceIdPage(),
      //     transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      //   ),
      // );
    } else {
      if (appState.justAuthenticated) {
        appState.setHasNavigatedToFaceIDPage(false);
        appState.setJustAuthenticated(false);
      }
      if (appState.hasNavigatedToFaceIDPage) {
      } else {
      }
    }
  }

  bool isAuthenticated() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          boldText: false, textScaler: const TextScaler.linear(1),
        ),
        child: child!,
      ),
      title: 'Team Shaikh Investments',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 17, 24, 39),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          titleMedium: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          titleSmall: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          labelLarge: TextStyle(
              color: Colors.white, fontFamily: 'Titillium Web'),
          labelMedium: TextStyle(
              color: Colors.white, fontFamily: 'Titillium Web'),
          labelSmall: TextStyle(
              color: Colors.white, fontFamily: 'Titillium Web'),
          displayLarge: TextStyle(
              color: Colors.white, fontFamily: 'Titillium Web'),
          displayMedium: TextStyle(
              color: Colors.white, fontFamily: 'Titillium Web'),
          displaySmall: TextStyle(
              color: Colors.white, fontFamily: 'Titillium Web'),
          headlineLarge: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(
              color: Colors.white,
              fontFamily: 'Titillium Web',
              fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(
              color: Colors.white, fontFamily: 'Titillium Web'),
          bodyMedium: TextStyle(
              color: Colors.white, fontFamily: 'Titillium Web'),
          bodySmall: TextStyle(
              color: Colors.white, fontFamily: 'Titillium Web'),
        ),
      ),
      home: const AuthChecker(),
      routes: {
        '/create_account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/analytics': (context) => const AnalyticsPage(),
        '/activity': (context) => const ActivityPage(),
        '/profile': (context) => const ProfilePage(),
        '/notification': (context) => const NotificationPage(),
        '/onboarding': (context) => const OnboardingPage(),
      },
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(), // Stream that listens for changes in the user's authentication state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Show a loading indicator while waiting for the authentication state
        } else if (snapshot.hasError) {
          log('wrapper.dart: StreamBuilder error: ${snapshot.error}'); // Log any errors that occur during the stream
          return Text('Error: ${snapshot.error}'); // Show an error message if there is an error in the stream
        } else if (snapshot.hasData) {
          final user = snapshot.data!; // Get the authenticated user from the snapshot
          log('wrapper.dart: User is logged in as ${user.email}'); // Log the user's email
          return const DashboardPage(); // If the user is authenticated, show the FaceIdPage
        } else {
          log('wrapper.dart: User is not logged in yet.'); // Log that the user is not logged in
          return const OnboardingPage(); // If the user is not authenticated, show the OnboardingPage
        }
      },
    );
  }
}
