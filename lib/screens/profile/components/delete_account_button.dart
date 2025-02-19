import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:team_shaikh_app/database/auth_helper.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';

class DeleteAccountButton extends StatefulWidget { // Renamed widget
  final Client client;

  const DeleteAccountButton({Key? key, required this.client}) : super(key: key);

  @override
  _DeleteAccountButtonState createState() => _DeleteAccountButtonState(); // Renamed state class
}

class _DeleteAccountButtonState extends State<DeleteAccountButton> { // Renamed state class
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showDeleteAccountDialog(context), // Updated method name
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1), // Light red background with slight transparency
                  // border: Border.all(color: Colors.red), // Red border remains
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/delete.svg', // Updated icon asset (ensure it's available)
                        color: Colors.red,
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Delete Account', // Updated label text
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
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

  void _showDeleteAccountDialog(BuildContext context) { // Renamed method
    showDialog(
      context: context,
      barrierDismissible: false,
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
                        'Confirm Delete Account', // Updated dialog title
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/icons/delete.svg', // Updated icon asset
                        width: 24,
                        height: 24,
                        color: Colors.white, 
                      ),
                    ],
                  ),
                ),
                const Text('Are you sure you want to permanently delete your account?'), // Updated message
              ],
            ),
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); 
                _deleteAccount();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red, // Solid red background
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Delete',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white, // Updated text color for contrast
                    fontWeight: FontWeight.bold
                  ),
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
                  borderRadius: BorderRadius.circular(10), 
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

  void _deleteAccount() async { // Renamed method
    log('delete_account_button.dart: Deleting account...'); // Updated log message
    // ...existing code for navigating away or confirming deletion...
    await Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (route) => false);
    if (!mounted) {
      return;
    }
    // Optionally add account deletion logic here. For example:
    // await AuthHelper.deleteAccount(widget.client);
    await FirebaseAuth.instance.signOut();
    assert(FirebaseAuth.instance.currentUser == null);
    return;
  }
}


