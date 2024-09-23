import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/push_notification.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/authenticate/initial_face_id.dart';
import 'package:team_shaikh_app/screens/authenticate/onboarding.dart';
import 'package:team_shaikh_app/screens/notifications/notifications.dart';
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
  
    // Terminate Firestore to detach any active listeners
  await FirebaseFirestore.instance.terminate();

  // Clear persisted data
  await FirebaseFirestore.instance.clearPersistence();

  // Optionally disable persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => AuthState(),
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
  AuthState? appState;
  late final Stream<Client?> clientStream;

  @override
  void initState() {
    super.initState();
    clientStream = getClientStream();
    WidgetsBinding.instance.addObserver(this);
    appState?.setHasNavigatedToFaceIDPage(false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Stream<Client?> getClientStream() => FirebaseAuth.instance
        .authStateChanges()
        .asyncExpand((User? user) async* {
      if (user == null) {
        yield null;
      } else {
        NewDB? db = await NewDB.fetchCID(user.uid);
        if (db == null) {
          yield null;
        } else {
          yield* db.getClientStream();
        }
      }
    });

   @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Update the lifecycle state
    final appState = Provider.of<AuthState>(context, listen: false);

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
  Widget build(BuildContext context) => StreamProvider<Client?>.value(
      value: clientStream,
      initialData: null,
      child: MaterialApp(
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
      ),
    );
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  Future<DatabaseService?> _fetchDatabaseService(
      BuildContext context, String uid) async => await DatabaseService.fetchCID(context, uid, 1);
      
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .userChanges(), // Stream that listens for changes in the user's authentication state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
            strokeWidth: 6.0,
          ); // Show a loading indicator while waiting for the authentication state
        } else if (snapshot.hasError) {
          log('main.dart: StreamBuilder error: ${snapshot.error}'); // Log any errors that occur during the stream
          return Text(
              'Error: ${snapshot.error}'); // Show an error message if there is an error in the stream
        } else if (snapshot.hasData) {
          final user =
              snapshot.data!; // Get the authenticated user from the snapshot
          log('main.dart: User is logged in as ${user.email}'); // Log the user's email
          return FutureBuilder<DatabaseService?>(
            future: _fetchDatabaseService(context, user.uid),
            builder: (context, serviceSnapshot) {
              if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                  strokeWidth: 6.0,
                ); // Show a loading indicator while waiting for the Firestore query
              } else if (serviceSnapshot.hasError) {
                log('main.dart: Firestore query error: ${serviceSnapshot.error}'); // Log any errors that occur during the Firestore query
                return Text(
                    'Error: ${serviceSnapshot.error}'); // Show an error message if there is an error in the Firestore query
              } else if (serviceSnapshot.hasData &&
                  serviceSnapshot.data != null) {
                log('main.dart: UID found in Firestore.'); // Log that the UID was found in Firestore
                return const InitialFaceIdPage(); // If the UID is found, show the FaceIdPage
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
