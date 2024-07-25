import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'dart:developer';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class AuthService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticateWithBiometrics() async {
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics &&
        await auth.isDeviceSupported();

    if (canAuthenticateWithBiometrics) {
      try {
        return await auth.authenticate(
          localizedReason: 'Authenticate to access',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      } catch (e) {
        log('$e');
        return false;
      }
    } else {
      return false;
    }
  }
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  @override
  void initState() {
	super.initState();
	WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
	WidgetsBinding.instance.removeObserver(this);
	super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
	if (state == AppLifecycleState.resumed) {
	  // App is resumed - check for authentication
	  _authService.authenticateWithBiometrics().then((isAuthenticated) {
		if (!isAuthenticated) {
		  // Handle authentication failure or redirect to a locked screen
		  log('Authentication failed');
		}
	  });
	}
  }

  @override
  Widget build(BuildContext context) => const MaterialApp(
	  home: DashboardPage(), // Your example page
	);
}