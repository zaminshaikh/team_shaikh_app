// Flutter and Dart packages
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';

// Firebase packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Third-party packages
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_shaikh_app/components/no-connection.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';

// Local packages
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
  await Firebase.initializeApp();

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
  String? selectedTimeOption;
  double selectedTimeInMinutes = 1.0; // Default value
  Timer? _inactivityTimer;
  bool _isAppLockEnabled = false;

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

    // Load the selected time option and app lock state
    _loadSelectedTimeOption();
    _loadAppLockState();
  }

  Future<void> _loadSelectedTimeOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTimeOption = prefs.getString('selectedTimeOption') ?? '1 minute';
      selectedTimeInMinutes = _getTimeInMinutes(selectedTimeOption!);
      print('Selected time option: $selectedTimeOption');
      print('Timer duration in minutes: $selectedTimeInMinutes');
    });
  }

  Future<void> _loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAppLockEnabled = prefs.getBool('isAppLockEnabled') ?? false;
      print('Bruh Loaded app lock state: $_isAppLockEnabled');
    });
  
    final appState = Provider.of<AuthState>(context, listen: false);
    if (!_isAppLockEnabled) {
      appState.setInitiallyAuthenticated(true);
      print('App lock is disabled. Setting initiallyAuthenticated to true.');
      print('initiallyAuthenticated: ${appState.initiallyAuthenticated}');
    } else {
      appState.setInitiallyAuthenticated(false);
      print('App lock is enabled. Setting initiallyAuthenticated to false.');
    }
  }

  double _getTimeInMinutes(String timeOption) {
    switch (timeOption) {
      case 'Immediately':
        return 0.0;
      case '1 minute':
        return 1.0;
      case '2 minute':
        return 2.0;
      case '5 minute':
        return 5.0;
      case '10 minute':
        return 10.0;
      default:
        return 1.0; // Default to 1 minute if none match
    }
  }

  @override
  void dispose() {
    // Remove this widget from the observer list
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    print('Timer cancelled in dispose');
    super.dispose();
  }

  /// Stream that provides Client data based on authentication state
  Stream<Client?> getClientStream() => FirebaseAuth.instance
        .userChanges()
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
          // Fetch DatabaseService for the authenticated user
          DatabaseService? db = await DatabaseService.fetchCID(user.uid, context);
          if (db == null) {
            // DatabaseService not found
            yield null;
          } else {
            // await db.updateField('lastLoggedIn', Timestamp.now());  
            // Yield Client stream from DatabaseService
            yield* db.getClientStream();
          }
        }
      }});

    @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final appState = Provider.of<AuthState>(context, listen: false);
    print('AppLifecycleState changed: $state');
  
    if (state == AppLifecycleState.resumed) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { return; }
      DatabaseService? db = await DatabaseService.fetchCID(user.uid, context);
      if (db != null) { 
        unawaited(db.updateField('lastLoggedIn', Timestamp.now()));
      }
      
      // Cancel the timer when the app is resumed
      _inactivityTimer?.cancel();
      print('Timer cancelled on app resume');
    } else if ((state == AppLifecycleState.paused ||
                state == AppLifecycleState.inactive ||
                state == AppLifecycleState.hidden) &&
            !appState.hasNavigatedToFaceIDPage &&
            await isAuthenticated() &&
            appState.initiallyAuthenticated &&
            appState.isAppLockEnabled) {
      // Print when all conditions are met
      print('All conditions met: Navigating to FaceIdPage after timer');
  
      // Start a timer for the selected amount of time
      _inactivityTimer?.cancel();
      print('Timer cancelled');
      _inactivityTimer = Timer(Duration(minutes: appState.selectedTimeInMinutes.toInt()), () {
        // Navigate to FaceIdPage when the timer completes
        appState.setHasNavigatedToFaceIDPage(true);
        navigatorKey.currentState?.pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const FaceIdPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
          ),
        );
      });
      print('Timer started for ${appState.selectedTimeInMinutes} minutes');
    } else {
      if (state != AppLifecycleState.paused &&
          state != AppLifecycleState.inactive &&
          state != AppLifecycleState.hidden) {
        print('Condition not met: AppLifecycleState is not paused, inactive, or hidden');
      }
      if (appState.hasNavigatedToFaceIDPage) {
        print('Condition not met: hasNavigatedToFaceIDPage is true');
      }
      if (!(await isAuthenticated())) {
        print('Condition not met: User is not authenticated');
      }
      if (!appState.initiallyAuthenticated) {
        print('Condition not met: initiallyAuthenticated is false');
      }
      if (!appState.isAppLockEnabled) {
        print('Condition not met: isAppLockEnabled is false');
      }
    }
  
    if (appState.justAuthenticated) {
      // Reset navigation flags when the user has just authenticated
      appState.setHasNavigatedToFaceIDPage(false);
      appState.setJustAuthenticated(false);
      print('Reset navigation flags after authentication');
      print('Reset navigation flags after authentication');
    }
  }

  /// Check if the user is authenticated and linked
  Future<bool> isAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { return false; }

    String uid = user.uid;

    DatabaseService db = DatabaseService(uid);

    bool isLinked = await db.isUIDLinked(uid);

    return isLinked;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged.map((result) => result.first),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == ConnectivityResult.none) {
          return MaterialApp(
            home: NoInternetScreen(),
          );
        } 

  
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            return StreamProvider<Client?>(
              key: ValueKey(user?.uid),
              create: (_) => getClientStream(),
              catchError: (context, error) {
                log('main.dart: Error in fetching client stream: $error');
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
                title: 'AGQ Investments',
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
          },
        );
      },
    );


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
      );
}

/// Check if the user is authenticated and linked
Future<bool> isAuthenticated() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) { return false; }

  String uid = user.uid;

  DatabaseService db = DatabaseService(uid);

  bool isLinked = await db.isUIDLinked(uid);

  return isLinked;
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  late Future<bool> _isAuthenticatedAndVerifiedFuture;
  late Future<bool> _loadAppLockStateFuture;

  @override
  void initState() {
    super.initState();
    _isAuthenticatedAndVerifiedFuture = isAuthenticatedAndVerified();
    _loadAppLockStateFuture = _loadAppLockState();
  }

  Future<bool> _loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAppLockEnabled') ?? false;
  }

  /// Check if the user is authenticated, email verified, and linked
  Future<bool> isAuthenticatedAndVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    await user.reload(); // Ensure the latest user state

    // if (!user.emailVerified) {
    //   return false;
    // }

    String uid = user.uid;

    DatabaseService db = DatabaseService(uid);

    bool isLinked = await db.isUIDLinked(uid);

    return isLinked;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomProgressIndicator());
        } else if (snapshot.hasError) {
          log('AuthCheck: StreamBuilder error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          log('AuthCheck: User is logged in as ${user.email}');

          // Use the stored future
          return FutureBuilder<bool>(
            future: _isAuthenticatedAndVerifiedFuture,
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                log('AuthCheck: FutureBuilder waiting for authentication check.');
                return const Center(child: CustomProgressIndicator());
              } else if (authSnapshot.hasError) {
                log('AuthCheck: FutureBuilder error: ${authSnapshot.error}');
                return Center(child: Text('Error: ${authSnapshot.error}'));
              } else if (authSnapshot.hasData && authSnapshot.data == true) {
                // Now proceed to check app lock state
                return FutureBuilder<bool>(
                  future: _loadAppLockStateFuture,
                  builder: (context, appLockSnapshot) {
                    if (appLockSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CustomProgressIndicator());
                    } else if (appLockSnapshot.hasError) {
                      log('AuthCheck: FutureBuilder error: ${appLockSnapshot.error}');
                      return Center(
                          child: Text('Error: ${appLockSnapshot.error}'));
                    } else if (appLockSnapshot.hasData) {
                      final isAppLockEnabled = appLockSnapshot.data!;
                      if (!isAppLockEnabled) {
                        log('AuthCheck: App lock is disabled. Navigating to DashboardPage.');
                        return const DashboardPage();
                      }
                      log('AuthCheck: App lock is enabled. Navigating to InitialFaceIdPage.');
                      return const InitialFaceIdPage();
                    } else {
                      return const InitialFaceIdPage();
                    }
                  },
                );
              } else {
                log('AuthCheck: User is not authenticated or linked. Navigating to OnboardingPage.');
                // FirebaseAuth.instance.currentUser?.delete();
                return const OnboardingPage();
              }
            },
          );
        } else {
          log('AuthCheck: User is not logged in yet.');
          return const OnboardingPage();
        }
      },
    );
}

