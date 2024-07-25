// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';

class FaceIdPage extends StatefulWidget {
  const FaceIdPage({super.key});

  @override
  _FaceIdPageState createState() => _FaceIdPageState();
}

class _FaceIdPageState extends State<FaceIdPage> with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();

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
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _authenticate(context);
    }
  }

  Future<void> _authenticate(BuildContext context) async {
    bool authenticated = false;
    print('Starting authentication process...');
    
    try {
      print('Attempting to authenticate...');
      authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      print('Authentication attempt completed.');
    } catch (e) {
      print('Error during authentication: $e');
    }

    if (authenticated) {
      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      );
      print('Authenticated successfully');
    } else {
      // Handle failed authentication
      print('Failed to authenticate');
    }
    
    print('Authentication process finished.');
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
                  const SizedBox(height: 80.0), // Add some space between the image and the text
                  Image.asset(
                    'assets/icons/team_shaikh_transparent.png',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 8.0), // Add some space between the image and the text
                  const Text(
                    'The Team Shaikh App Is Locked',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                  const SizedBox(height: 16.0), // Add some space between the image and the text
                  const Text(
                    'Unlock with Face ID to continue',
                    style: TextStyle(
                      fontSize: 18,
                    )
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
                    await _authenticate(context);
                  },
                  child: const Text(
                    'Use Face ID',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.defaultBlue500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // Change the radius as needed
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