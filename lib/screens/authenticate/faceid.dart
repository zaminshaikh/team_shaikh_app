import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:team_shaikh_app/main.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'dart:async';
import 'package:team_shaikh_app/screens/authenticate/app_state.dart';
import 'package:provider/provider.dart';

class FaceIdPage extends StatefulWidget {
  const FaceIdPage({super.key});

  @override
  _FaceIdPageState createState() => _FaceIdPageState();
}

class _FaceIdPageState extends State<FaceIdPage> with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  final Completer<void> _navigationCompleter = Completer<void>();
  AppState? appState;
  MyAppState? myAppState;
  bool authenticated = false;

  @override
  void initState() {
    super.initState();
    print('FaceIdPage initialized');
    myAppState = MyAppState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appState = Provider.of<AppState>(context, listen: false);
    myAppState = context.findAncestorStateOfType<MyAppState>();
  }
  
  @override
  void dispose() {
    // Print a message to indicate that the FaceIdPage is being disposed
    print('FaceIdPage disposed');
    
    // Check if myAppState is not null
    if (myAppState != null) {
      // Print the appState value from myAppState
      print('From FaceIdPage dispose: myAppState value: ${myAppState?.appState}');
    } else {
      // Print a message to indicate that myAppState is null
      print('myAppState is null in dispose');
    }
  
    // Reset the hasNavigatedToFaceIDPage value to false after disposing the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authenticated) {
        appState?.setHasNavigatedToFaceIDPage(false);
        print('hasNavigatedToFaceIDPage reset to false in dispose');
      } else {
        print('User is not authenticated, hasNavigatedToFaceIDPage not reset');
      }
    });
  
    // Remove the observer for this widget's lifecycle events
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('AppLifecycleState changed: $state');
    if (state == AppLifecycleState.resumed) {
      if (!_isAuthenticating) {
        _isAuthenticating = true; // Set the flag to true to prevent multiple calls
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState?.setHasNavigatedToFaceIDPage(true);
          print('hasNavigatedToFaceIDPage reset to true in didChangeAppLifecycleState');
          _authenticate(context).then((_) {
            _isAuthenticating = false; // Reset the flag after authentication completes
          });
        });
      }
    }
  }
  
  Future<void> _authenticate(BuildContext context) async {
    if (!mounted) return;

    setState(() {
      _isAuthenticating = true;
    });

    print('Authentication started');
    authenticated = false;

    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      print('Authentication result: $authenticated');
    } catch (e) {
      print('Authentication error: $e');
    }

    if (authenticated) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          print('User authenticated');
          print('_isAuthenticating: $_isAuthenticating');
        });
      }
    
      if (mounted) {
        print('Widget is mounted, navigating to DashboardPage');
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardPage(fromFaceIdPage: true),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
          ),
        ).then((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appState?.setHasNavigatedToFaceIDPage(false);
            appState?.setJustAuthenticated(true);
            print('hasNavigatedToFaceIDPage reset to false in MyAppState');
          });
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState?.setHasNavigatedToFaceIDPage(false);
          print('Widget is not mounted');
        });
      }
    } else {
      print('User failed to authenticate');
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
  Widget build(BuildContext context) {
    return Scaffold(
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
                        'The Team Shaikh App Is Locked',
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
                            print('Face ID button pressed');
                            await _authenticate(context);
                          },
                    child: const Text(
                      'Use Face ID',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.defaultBlue500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
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
}
