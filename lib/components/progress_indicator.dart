import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth
import 'package:flutter_svg/svg.dart';
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
          backgroundColor: AppColors.defaultBlueGray800,
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: <Widget>[
                      Text(
                        'Connection Timeout',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/icons/time.svg',
                        width: 24,
                        height: 24,
                        color: Colors.white, // Set the color of the SVG icon
                      ),
                    ],
                  ),
                ),
                const Text(
                  'The connection is taking longer than expected. Please return to the login page and try again.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: () async {
                // Sign out the user
                await FirebaseAuth.instance.signOut();
                // Navigate to the login page or any other desired page
                if (!mounted) {
                  return;
                }
                await Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', (Route<dynamic> route) => false);
              },
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.transparent, // Changed from Color.fromARGB(255, 149, 28, 28)
                  border: Border.all(color: Colors.red), // Added red border
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/logout.svg',
                        color: Colors.red, // Changed from Colors.white
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red, // Changed from Colors.white
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) => Center(child: CustomProgressIndicator());
}
