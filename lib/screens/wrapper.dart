import 'package:flutter/material.dart';
import 'package:team_shaikh_app/screens/authenticate/authenticate.dart';

// Return either home or authenticate widget
class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Return either dashboard or authenticate widget based on auth status.
    return const Authenticate();
  }
}