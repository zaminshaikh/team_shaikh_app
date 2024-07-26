import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:team_shaikh_app/screens/authenticate/welcome.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/authenticate/faceid.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> with WidgetsBindingObserver {
  bool _hasNavigatedToFaceIdPage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('WrapperState: Observer added');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    print('WrapperState: Observer removed when app is in background.');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('WrapperState: AppLifecycleState changed to $state');
    if (state == AppLifecycleState.resumed) {
      print('App is in foreground.');
    } else if (state == AppLifecycleState.inactive) {
      if (!_hasNavigatedToFaceIdPage) {
        _hasNavigatedToFaceIdPage = true;
        Future.delayed(Duration.zero, () {
          if (context != null) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => FaceIdPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
              ),
            );
          }
        });
      }
      print('App is in background.');
      _hasNavigatedToFaceIdPage = false; // Reset the flag when the app goes to the background
    } else if (state == AppLifecycleState.paused) {
      print('App is in background.');
      _hasNavigatedToFaceIdPage = false; // Reset the flag when the app goes to the background
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            return const DashboardPage();
          } else {
            log('wrapper.dart: User is not logged in yet.');
            return const OnboardingPage();
          }
        },
      ),
  }
}
