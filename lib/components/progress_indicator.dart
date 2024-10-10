import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth
import 'package:team_shaikh_app/screens/utils/resources.dart';

class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 6.0,
      );
}

class CustomProgressIndicatorPage extends StatefulWidget {
  const CustomProgressIndicatorPage({Key? key}) : super(key: key);

  @override
  _CustomProgressIndicatorPageState createState() =>
      _CustomProgressIndicatorPageState();
}

class _CustomProgressIndicatorPageState
    extends State<CustomProgressIndicatorPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Start a timer for 5 seconds
    _timer = Timer(const Duration(seconds: 5), () {
      // After 5 seconds, show the dialog
      _showTimeoutDialog();
    });
  }

  @override
  void dispose() {
    // Cancel the timer if the widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap the button to dismiss
      builder: (BuildContext context) => AlertDialog(
          title: const Text('Connection Timeout'),
          content: const Text(
            'The connection is taking longer than expected. Please return to the login page and try again.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Continue'),
              onPressed: () async {
                // Sign out the user
                await FirebaseAuth.instance.signOut();
                // Navigate to the login page or any other desired page
                if (!mounted) { return; }
                await Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.all(26.0),
          margin: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
          decoration: BoxDecoration(
            color: AppColors.defaultBlue500,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: const Stack(
            children: [
              CustomProgressIndicator(),
            ],
          ),
        ),
      );
}
