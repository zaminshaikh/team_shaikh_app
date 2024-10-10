// ignore_for_file: library_private_types_in_public_api, empty_catches

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:team_shaikh_app/main.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'dart:async';
import 'package:team_shaikh_app/screens/authenticate/utils/app_state.dart';
import 'package:provider/provider.dart';

class FaceIdPage extends StatefulWidget {
  const FaceIdPage({super.key});

  @override
  _FaceIdPageState createState() => _FaceIdPageState();
}

class _FaceIdPageState extends State<FaceIdPage> with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  AuthState? appState;
  MyAppState? myAppState;
  bool authenticated = false;

  @override
  void initState() {
    super.initState();
    myAppState = MyAppState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appState = Provider.of<AuthState>(context, listen: false);
    myAppState = context.findAncestorStateOfType<MyAppState>();
  }

  @override
  void dispose() {
    // Print a message to indicate that the FaceIdPage is being disposed

    // Check if myAppState is not null
    if (myAppState != null) {
      // Print the appState value from myAppState
    } else {
      // Print a message to indicate that myAppState is null
    }

    // Reset the hasNavigatedToFaceIDPage value to false after disposing the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authenticated) {
        appState?.setHasNavigatedToFaceIDPage(false);
      } else {}
    });

    // Remove the observer for this widget's lifecycle events
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isAuthenticating) {
        _isAuthenticating =
            true; // Set the flag to true to prevent multiple calls
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState?.setHasNavigatedToFaceIDPage(true);
          if (mounted) {
            _authenticate(context).then((_) {
              _isAuthenticating =
                  false; // Reset the flag after authentication completes
            });
          }
        });
      }
    }
  }

  Future<void> _authenticate(BuildContext context) async {
    if (!mounted) return;

    setState(() {
      _isAuthenticating = true;
    });

    authenticated = false;

    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {}

    if (authenticated) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const DashboardPage(fromFaceIdPage: true),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        ).then((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appState?.setHasNavigatedToFaceIDPage(false);
            appState?.setJustAuthenticated(true);
          });
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState?.setHasNavigatedToFaceIDPage(false);
        });
      }
    } else {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState?.setHasNavigatedToFaceIDPage(false);
        });
        setState(() {
          _isAuthenticating = false;
        });
      }
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
                      onPressed: _isAuthenticating
                          ? null
                          : () async {
                              await _authenticate(context);
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
