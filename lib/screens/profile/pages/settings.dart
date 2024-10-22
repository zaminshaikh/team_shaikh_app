// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_shaikh_app/components/alert_dialog.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';
import 'package:team_shaikh_app/screens/profile/components/logout_button.dart';
import 'dart:developer';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Client? client;
  bool activitySwitchValue = false;
  bool statementsSwitchValue = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    client = Provider.of<Client?>(context);
    _loadSwitchValue();
  }

  @override
  Widget build(BuildContext context) {
    return buildsettingsPage();
  }

  void _loadSwitchValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      statementsSwitchValue = prefs.getBool('statementsSwitchValue') ?? false;
      activitySwitchValue = prefs.getBool('activitySwitchValue') ?? false;
    });
  }

  void _saveSwitchValue(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

// This is the selected button, initially set to an empty string
  // Assuming these fields are part of the `user.info` map
  Scaffold buildsettingsPage() {
    if (client == null) {
      return const Scaffold(
        body: CustomProgressIndicatorPage(),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.all(0.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _settings(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // This is the settings section
  Column _settings() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Activity',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Let me know about new activity within my portfolio.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CupertinoSwitch(
                              // This bool value toggles the switch.
                              value: activitySwitchValue,
                              activeColor: CupertinoColors.activeBlue,
                              onChanged: (bool? value) {
                                // This is called when the user toggles the switch.
                                setState(() {
                                  activitySwitchValue = value ?? false;
                                  _saveSwitchValue('activitySwitchValue',
                                      activitySwitchValue);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Statement',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Let me know when I recieve a new statement.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CupertinoSwitch(
                              // This bool value toggles the switch.
                              value: statementsSwitchValue,
                              activeColor: CupertinoColors.activeBlue,
                              onChanged: (bool? value) {
                                setState(() {
                                  statementsSwitchValue = value ?? false;
                                  _saveSwitchValue('statementsSwitchValue',
                                      statementsSwitchValue);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                const Divider(
                  color: Colors.white,
                  thickness: 0.2,
                  height: 20,
                ),

                const SizedBox(height: 15),

                // Security Section with options to change email and password
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Security',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          FirebaseAuth.instance.currentUser?.email ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Column(
                  children: [
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            TextEditingController emailController =
                                TextEditingController();

                            Widget buildCloseButton(BuildContext context) {
                              return Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.close,
                                      color: Colors.white),
                                ),
                              );
                            }

                            Widget buildIconArt() {
                              return SvgPicture.asset(
                                'assets/icons/change_email_and_password_icon_art.svg',
                                // Optional: You can specify width, height, color, etc. if needed
                              );
                            }

                            Widget buildEmailInputSection(
                                TextEditingController emailController) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Change Email',
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'You are changing the email associated with your account.',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Email',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: emailController,
                                    readOnly:
                                        false, // Ensure this is false to allow typing
                                    keyboardType: TextInputType
                                        .emailAddress, // Add this line to bring up email keyboard
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web'),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email',
                                      hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontFamily: 'Titillium Web'),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(11)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(11),
                                        borderSide: const BorderSide(
                                            color: Colors.blue, width: 2),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 14),
                                    ),
                                  ),
                                ],
                              );
                            }

                            Widget buildContinueButton(BuildContext context,
                                TextEditingController emailController) {
                              return ElevatedButton(
                                onPressed: () async {
                                  try {
                                    // Get the new email from the controller
                                    String newEmail =
                                        emailController.text.trim();

                                    // Get the current user
                                    var user =
                                        FirebaseAuth.instance.currentUser;

                                    if (user != null) {
                                      // Send email verification to the new email address
                                      await user.updateEmail(newEmail);
                                      await user.sendEmailVerification();

                                      // Show a message to inform the user to check their email for verification.
                                      await CustomAlertDialog.showAlertDialog(
                                        context,
                                        'Email Change Requested',
                                        'Please check your email for a verification link. You need to verify the new email address before it takes effect.',
                                      );
                                    }
                                  } catch (e) {
                                    // log the error for debugging
                                    log('settings.dart: Error updating email: $e');

                                    // Handle error, display a message, etc.
                                    await CustomAlertDialog.showAlertDialog(
                                      context,
                                      'Error',
                                      'Error updating email: $e',
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                      255, 30, 75, 137), // Updated from primary
                                  foregroundColor: Colors.white, // Text color
                                  splashFactory: NoSplash.splashFactory,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 15),
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Titillium Web'),
                                ),
                              );
                            }

                            AlertDialog buildsettingsDialog(
                                BuildContext context,
                                TextEditingController emailController) {
                              return AlertDialog(
                                backgroundColor: AppColors.defaultBlueGray800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      buildCloseButton(context),
                                      const SizedBox(height: 20),
                                      buildIconArt(),
                                      const SizedBox(height: 30),
                                      buildEmailInputSection(emailController),
                                      const SizedBox(height: 20),
                                      buildContinueButton(
                                          context, emailController),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return buildsettingsDialog(
                                context, emailController);
                          },
                        );
                      },
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Change Email',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            TextEditingController passwordController =
                                TextEditingController();

                            Widget buildCloseButton(BuildContext context) {
                              return Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.close,
                                      color: Colors.white),
                                ),
                              );
                            }

                            Widget buildIconArt() {
                              return SvgPicture.asset(
                                'assets/icons/change_email_and_password_icon_art.svg',
                                // Optional: You can specify width, height, color, etc. if needed
                              );
                            }

                            Widget buildPasswordInputSection(
                                TextEditingController passwordController) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Change Password',
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'You are changing the password associated with your account.',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'New Password',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web'),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: passwordController,
                                    obscureText:
                                        true, // Ensure this is true for password fields
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web'),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your new password',
                                      hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontFamily: 'Titillium Web'),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(11)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(11),
                                        borderSide: const BorderSide(
                                            color: Colors.blue, width: 2),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 14),
                                    ),
                                  ),
                                ],
                              );
                            }

                            Widget buildContinueButton(BuildContext context,
                                TextEditingController passwordController) {
                              return ElevatedButton(
                                onPressed: () async {
                                  try {
                                    // Get the new password from the controller
                                    String newPassword =
                                        passwordController.text.trim();

                                    // Get the current user
                                    var user =
                                        FirebaseAuth.instance.currentUser;

                                    if (user != null) {
                                      // Update the user's password
                                      await user.updatePassword(newPassword);

                                      // Show a message to inform the user that the password has been changed.
                                      await CustomAlertDialog.showAlertDialog(
                                        context,
                                        'Success',
                                        'Your password has been updated successfully.',
                                        icon: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: Colors.green,
                                          size: 28,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    // log the error for debugging
                                    log('settings.dart: Error updating password: $e');

                                    // Handle error, display a message, etc.
                                    await CustomAlertDialog.showAlertDialog(
                                      context,
                                      'Error',
                                      'Error updating password: $e',
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                      255, 30, 75, 137), // Updated from primary
                                  foregroundColor:
                                      Colors.white, // Updated from onPrimary
                                  splashFactory: NoSplash.splashFactory,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 15),
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Titillium Web'),
                                ),
                              );
                            }

                            AlertDialog buildsettingsDialog(
                                BuildContext context,
                                TextEditingController passwordController) {
                              return AlertDialog(
                                backgroundColor: AppColors.defaultBlueGray800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      buildCloseButton(context),
                                      const SizedBox(height: 20),
                                      buildIconArt(),
                                      const SizedBox(height: 30),
                                      buildPasswordInputSection(
                                          passwordController),
                                      const SizedBox(height: 20),
                                      buildContinueButton(
                                          context, passwordController),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return buildsettingsDialog(
                                context, passwordController);
                          },
                        );
                      },
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

                const Divider(
                  color: Colors.white,
                  thickness: 0.2,
                  height: 20,
                ),

                const SizedBox(height: 15),

                const Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Log out of your account.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
          LogoutButton(client: client!),
          const SizedBox(height: 50),
        ],
      );

  // This is the app bar
  SliverAppBar _buildAppBar(context) => SliverAppBar(
        backgroundColor: const Color.fromARGB(255, 30, 41, 59),
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        expandedHeight: 0,
        snap: false,
        floating: true,
        pinned: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: const SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 60.0, right: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 27,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
