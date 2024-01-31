import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';

// Return either home or authenticate
class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context, snapshot) {
          // user is logged in
          // if (snapshot.hasData) {
          //   return DashboardPage();
          // }

          // // user is not logged in
          // else {
            return const LoginPage();
          //}

        }
      ),
    );
  }
}