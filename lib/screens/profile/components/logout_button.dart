import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:team_shaikh_app/database/auth_helper.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';

class LogoutButton extends StatefulWidget {
  final Client client;

  const LogoutButton({Key? key, required this.client}) : super(key: key);

  @override
  _LogoutButtonState createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showLogoutDialog(context),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 149, 28, 28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/logout.svg',
                        color: Colors.white,
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
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
                        'Confirm Logout',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/icons/logout.svg',
                        width: 24,
                        height: 24,
                        color: Colors.white, 
                      ),
                    ],
                  ),
                ),
                const Text('Are you sure you want to log out?'),
              ],
            ),
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); 
                _logout(context); 
              },
              child: Container(
                width: double.infinity, 
                padding: const EdgeInsets.symmetric(vertical: 10), 
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 149, 28, 28),
                  borderRadius: BorderRadius.circular(20), 
                ),
                child: const Text(
                  'Logout',
                  textAlign: TextAlign.center, 
                ),
              ),
            ),
            const SizedBox(height: 10), 
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); 
              },
              child: Container(
                width: double.infinity, 
                padding: const EdgeInsets.symmetric(vertical: 10), 
                decoration: BoxDecoration(
                  color: Colors.transparent, 
                  border: Border.all(
                    color: Colors.white, 
                    width: 1, 
                  ),
                  borderRadius: BorderRadius.circular(20), 
                ),
                child: const Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white, 
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }




  void _logout(BuildContext context) async {
    DatabaseService? db = DatabaseService.withCID(
        FirebaseAuth.instance.currentUser!.uid, widget.client.cid);
    List<dynamic>? tokens =
        await db.getField('tokens') as List<dynamic>? ?? [];
    // Get the current token
    String currentToken =
        await FirebaseMessaging.instance.getToken() ?? '';
    tokens.remove(currentToken);
    // Update the list of tokens in the database for the user
    await db.updateField('tokens', tokens);
    signUserOut(context);
  }

  void signUserOut(BuildContext context) async {
    log('Profiles.dart: Signing out...');

    await deleteFirebaseMessagingToken(FirebaseAuth.instance.currentUser, context);
    await FirebaseAuth.instance.signOut();
    assert(FirebaseAuth.instance.currentUser == null);

    // Async gap mounted widget check
    if (mounted) {
      // Pop the current page and go to login
      await Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}


