// ignore_for_file: library_private_types_in_public_api, empty_catches, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

import 'package:team_shaikh_app/screens/authenticate/utils/app_state.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';

class InitialFaceIdPage extends StatefulWidget {
  const InitialFaceIdPage({super.key});

  @override
  _InitialFaceIdPageState createState() => _InitialFaceIdPageState();
}

class _InitialFaceIdPageState extends State<InitialFaceIdPage>
    with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initialAuthenticate(BuildContext context) async {
    if (!mounted) return;

    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        final appState = Provider.of<AuthState>(context, listen: false);
        appState.setInitiallyAuthenticated(true); // Set the flag

        // Set hasTransitioned to false
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasTransitioned', false);

        await Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                 const DashboardPage(fromFaceIdPage: true),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        );
      }
    } catch (e) {
      // Handle authentication error if needed
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80.0),
                      Image.asset(
                        'assets/icons/team_shaikh_transparent.png',
                        height: 120,
                        width: 120,
                      ),
                      const SizedBox(height: 8.0),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Team Shaikh App Locked',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Unlock with Face ID to continue',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _initialAuthenticate(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.defaultBlue500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text(
                        'Use Face ID',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
