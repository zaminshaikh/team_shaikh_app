import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/screens/authenticate/initial_face_id.dart';
import 'package:team_shaikh_app/screens/authenticate/onboarding.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/authenticate/utils/app_state.dart';
import 'package:team_shaikh_app/app_services.dart';
import 'dart:developer';

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
                        log('AuthCheck: AppLock FutureBuilder error: ${appLockSnapshot.error}');
                        return Center(
                            child: Text('Error: ${appLockSnapshot.error}'));
                      } else if (appLockSnapshot.hasData) {
                        final isAppLockEnabled = appLockSnapshot.data!;
                        if (!isAppLockEnabled) {
                          log('AuthCheck: App lock disabled -> DashboardPage');
                          return const DashboardPage();
                        }
                        log('AuthCheck: App lock enabled -> InitialFaceIdPage');
                        return const InitialFaceIdPage();
                      } else {
                        return const InitialFaceIdPage();
                      }
                    },
                  );
                } else {
                  log('AuthCheck: User not authenticated or linked -> OnboardingPage');
                  return const OnboardingPage();
                }
              },
            );
          } else {
            log('AuthCheck: User is not logged in -> OnboardingPage');
            return const OnboardingPage();
          }
        },
      );
}