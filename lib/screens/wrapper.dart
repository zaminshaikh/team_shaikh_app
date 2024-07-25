import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';

// Return either dashboard or authenticate
class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      body: StreamBuilder( 
        stream: FirebaseAuth.instance.userChanges(), // Use stream to update on any changes to the user
        builder: (context, snapshot) {
          // If data is still loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } 
          // Error case
          else if (snapshot.hasError) {
            log('wrapper.dart: StreamBuilder error: ${snapshot.error}');
            return Text('Error: ${snapshot.error}');
          } 
          // User exists case
          else if (snapshot.hasData) {
            // ignore: unused_local_variable
            final user = snapshot.data as User;
            // Check verification status (create_account.dart case)
            // if (user.emailVerified) {
            //   log('wrapper.dart: User email (${user.email}) with uid (${user.uid}) is verified. Returning dashboard...');
            //   return DashboardPage();
            // } else {
            //   log('wrapper.dart: User email is not verified.');
            //   return const CircularProgressIndicator();
            // }
            return const DashboardPage();
          } 
          // Else return login
          log('wrapper.dart: User is not logged in yet.');
          return const LoginPage();
        },
      ),
    );
}