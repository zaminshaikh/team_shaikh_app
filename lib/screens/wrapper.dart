import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';

// Return either home or authenticate
class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: StreamBuilder(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          log('StreamBuilder error: ${snapshot.error}');
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final user = snapshot.data as User;
          if (user.emailVerified) {
            log('wrapper.dart: User email is verified. Returning dashboard...');
            return DashboardPage(key: UniqueKey());
          } else {
            log('wrapper.dart: User email is not verified.');
            return const CircularProgressIndicator();
          }
        } 
        log('wrapper.dart: User is not logged in yet.');
        return const LoginPage();
      },
    ),
  );
}