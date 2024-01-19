import 'package:flutter/material.dart';
import 'package:team_shaikh_app/screens/authenticate/authenticate.dart';
import 'package:team_shaikh_app/screens/authenticate/create_account.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';

// Return either home or authenticate widget
class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Return either dashboard or authenticate widget based on auth status.
    return  CreateAccountPage();
  }
}