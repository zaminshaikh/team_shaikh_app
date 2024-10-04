// Flutter and Dart packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer';

// Firebase packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Third-party packages
import 'package:provider/provider.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';

// Local packages
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/screens/authenticate/create_account/create_account.dart';
import 'package:team_shaikh_app/utils/push_notification.dart';
import 'package:team_shaikh_app/utils/utilities.dart';
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
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services and configurations
  await _initializeServices();

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

/// Initialize third-party services and configurations
Future<void> _initializeServices() async {
  // Ensure screen size is initialized
  await ScreenUtil.ensureScreenSize();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize push notifications
  await PushNotificationService().initialize();

  // Load application configuration
  await Config.loadConfig();

  // Reset Firestore settings to ensure a clean state
  await _resetFirestore();
}

/// Reset Firestore settings to ensure a clean state
Future<void> _resetFirestore() async {
  // Terminate Firestore to detach any active listeners
  await FirebaseFirestore.instance.terminate();

  // Clear persisted data
  await FirebaseFirestore.instance.clearPersistence();

  // Disable persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late final Stream<Client?> clientStream;

  @override
  void initState() {
    super.initState();

    // Add this widget as an observer to the WidgetsBinding instance
    WidgetsBinding.instance.addObserver(this);

    // Reset navigation flags when the app initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AuthState>(context, listen: false);
      appState.setHasNavigatedToFaceIDPage(false);
    });
  }

  @override
  void dispose() {
    // Remove this widget from the observer list
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Stream that provides Client data based on authentication state
  Stream<Client?> getClientStream() => FirebaseAuth.instance
        .authStateChanges()
        .asyncExpand((User? user) async* {
      if (user == null) {
        // User is not authenticated
        yield null;
      } else {
        // Fetch DatabaseService for the authenticated user
        DatabaseService? db = await DatabaseService.fetchCID(user.uid, context);
        if (db == null) {
          // DatabaseService not found
          yield null;
        } else {
          // Yield Client stream from DatabaseService
          yield* db.getClientStream();
        }
      }
    });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appState = Provider.of<AuthState>(context, listen: false);
  
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden) &&
        !appState.hasNavigatedToFaceIDPage &&
        isAuthenticated() &&
        appState.initiallyAuthenticated) {
      // Navigate to FaceIdPage when app goes into background, and user is authenticated
      appState.setHasNavigatedToFaceIDPage(true);
      navigatorKey.currentState?.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const FaceIdPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              child,
        ),
      );
      print('Navigated to FaceIdPage: All conditions met');
    } else {
      if (!(state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden)) {
        print('Condition not met: AppLifecycleState is not paused, inactive, or hidden');
      }
      if (appState.hasNavigatedToFaceIDPage) {
        print('Condition not met: hasNavigatedToFaceIDPage is true');
      }
      if (!isAuthenticated()) {
        print('Condition not met: User is not authenticated');
      }
      if (!appState.initiallyAuthenticated) {
        print('Condition not met: initiallyAuthenticated is false');
      }
    }
  
    if (appState.justAuthenticated) {
      // Reset navigation flags when the user has just authenticated
      appState.setHasNavigatedToFaceIDPage(false);
      appState.setJustAuthenticated(false);
      print('Reset navigation flags after authentication');
    }
  }







  /// Check if the user is authenticated
  bool isAuthenticated() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, authSnapshot) {
      final user = authSnapshot.data;
      return StreamProvider<Client?>(
          key: ValueKey(user?.uid),
          create: (_) => getClientStream(),
          catchError: (context, error) {
            log('Error: $error');
            return null;
          },
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
            theme: _buildAppTheme(),
            // home: const AuthCheck(),
            routes: {
              '/': (context) => const AuthCheck(),
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
    });

  /// Build the application theme
  ThemeData _buildAppTheme() => ThemeData(
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
        labelLarge: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
        labelMedium:
            TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
        labelSmall: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
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
        bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
        bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
        bodySmall: TextStyle(color: Colors.white, fontFamily: 'Titillium Web'),
      ),
    );
}
class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  /// Fetch DatabaseService for the given UID
  Future<DatabaseService?> _fetchDatabaseService(String uid, BuildContext context) async {
    return await DatabaseService.fetchCID(uid, context);
  }

    @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
      // Stream that listens for changes in the user's authentication state
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting for the authentication state
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Log and display any errors
          log('AuthCheck: StreamBuilder error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          // User is authenticated
          final user = snapshot.data!;
          log('AuthCheck: User is logged in as ${user.email}');
          return const InitialFaceIdPage();
        } else {
          // User is not authenticated
          log('AuthCheck: User is not logged in yet.');
          return const OnboardingPage();
        }
      },
    );
}