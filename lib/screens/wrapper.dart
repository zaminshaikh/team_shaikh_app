import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:team_shaikh_app/screens/authenticate/welcome.dart';
import 'package:team_shaikh_app/screens/authenticate/faceid.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WrapperState createState() => _WrapperState();
}

  var isLoggedIn = false;


bool previousUserLoggedIn = false;

class _WrapperState extends State<Wrapper> with WidgetsBindingObserver {
  bool _hasNavigatedToFaceIdPage = false;

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
    } else if (state == AppLifecycleState.inactive) {
      if (!_hasNavigatedToFaceIdPage && _isUserLoggedIn()) {
        _hasNavigatedToFaceIdPage = true;
        Future.delayed(Duration.zero, () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const FaceIdPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
            ),
          );
                });
      }
    } else if (state == AppLifecycleState.paused) {
      _hasNavigatedToFaceIdPage = false; // Reset the flag when the app goes to the background
    }
  }
  
  bool _isUserLoggedIn() => isLoggedIn;


  @override
  Widget build(BuildContext context) => Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            log('wrapper.dart: StreamBuilder error: ${snapshot.error}');
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final user = snapshot.data as User;
            previousUserLoggedIn = true;
            log('wrapper.dart: User is logged in as ${user.email}');
            email = user.email;

            return const LoginPage();
          } else {
            log('wrapper.dart: User is not logged in yet.');
            return const OnboardingPage();
          }
        },
      ),
    );
}
