// ignore_for_file: prefer_expression_function_bodies

import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/push_notification.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/authenticate/initial_face_id.dart';
import 'package:team_shaikh_app/screens/authenticate/onboarding.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import 'package:team_shaikh_app/database/newdb.dart';
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
        isAuthenticated() &&
        (appState.initiallyAuthenticated)) {
      // Check if the user was initially authenticated

      appState.setHasNavigatedToFaceIDPage(true);
      navigatorKey.currentState?.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const FaceIdPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              child,
        ),
      );
    } else {
      if (appState.hasNavigatedToFaceIDPage) {}
      if (!isAuthenticated()) {}
      if (!appState.initiallyAuthenticated) {}

      if (appState.justAuthenticated) {
        appState.setHasNavigatedToFaceIDPage(false);
        appState.setJustAuthenticated(false);
      }
      if (appState.hasNavigatedToFaceIDPage) {
      } else {}
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
          boldText: false,
          textScaler: const TextScaler.linear(1),
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
          labelLarge:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          labelMedium:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          labelSmall:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          displayLarge:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          displayMedium:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          displaySmall:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
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
          bodyLarge:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          bodyMedium:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
          bodySmall:
              TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
        ),
      ),
      home: const AuthCheck(),
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

class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  Future<NewDB?> _fetchDatabaseService(
      BuildContext context, String uid) async {
    return await NewDB.fetchCID(context, uid, 1);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .userChanges(), // Stream that listens for changes in the user's authentication state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomProgressIndicator(); // Show a loading indicator while waiting for the authentication state
        } else if (snapshot.hasError) {
          log('main.dart: StreamBuilder error: ${snapshot.error}'); // Log any errors that occur during the stream
          return Text(
              'Error: ${snapshot.error}'); // Show an error message if there is an error in the stream
        } else if (snapshot.hasData) {
          final user =
              snapshot.data!; // Get the authenticated user from the snapshot
          log('main.dart: User is logged in as ${user.email}'); // Log the user's email
          return FutureBuilder<NewDB?>(
            future: _fetchDatabaseService(context, user.uid),
            builder: (context, serviceSnapshot) {
              if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                return const CustomProgressIndicator(); // Show a loading indicator while waiting for the Firestore query
              } else if (serviceSnapshot.hasError) {
                log('main.dart: Firestore query error: ${serviceSnapshot.error}'); // Log any errors that occur during the Firestore query
                return Text(
                    'Error: ${serviceSnapshot.error}'); // Show an error message if there is an error in the Firestore query
              } else if (serviceSnapshot.hasData) {
                NewDB? db = serviceSnapshot.data;
                
                // Debug print to check if db is null or valid
                if (db == null) {
                  log('main.dart: NewDB is null for UID ${user.uid}');
                  return const OnboardingPage();
                } else {
                  log('main.dart: NewDB is successfully retrieved for UID ${user.uid}');
                  return StreamProvider<Client?>(
                    create: (_) {
                      print('Starting client stream');
                      return db.getClientStream();
                    },
                    initialData: null,
                    child: const InitialFaceIdPage(),
                  );
                }
              } else {
                log('main.dart: UID: ${user.uid} not found in Firestore.'); // Log that the UID was not found in Firestore
                return const OnboardingPage(); // If the UID is not found, show the OnboardingPage
              }
            },
          );
        } else {
          log('main.dart: User is not logged in yet.'); // Log that the user is not logged in
          return const OnboardingPage(); // If the user is not authenticated, show the OnboardingPage
        }
      },
    );
  }
}
