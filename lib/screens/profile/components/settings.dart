// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/authenticate/welcome.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/utilities.dart';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}


class _SettingsPageState extends State<SettingsPage> {
  final Future<void> _initializeWidgetFuture = Future.value();

  // database service instance
  DatabaseService? _databaseService;

  Future<void> _initData() async {

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('settings.dart: User is not logged in');
      await Navigator.pushReplacementNamed(context, '/login');
    }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(context, user!.uid, 1);
    // If there is no matching CID, redirect to login page
    // ignore: duplicate_ignore
    if (service == null) {
      // ignore: use_build_context_synchronously
      await Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Otherwise set the database service instance
      _databaseService = service;
      log('Database Service has been initialized with CID: ${_databaseService?.cid}');
    }
  }
  
    String? cid;
  static final CollectionReference usersCollection = FirebaseFirestore.instance.collection('testUsers');


  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _initializeWidgetFuture, // Initialize the database service
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(26.0),
              margin: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
              decoration: BoxDecoration(
                color: AppColors.defaultBlue500,
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: const Stack(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 6.0,
                  ),
                ],
              ),
            ),
          );
        }
        return StreamBuilder<UserWithAssets>(
          stream: _databaseService?.getUserWithAssets,
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData || userSnapshot.data == null) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(26.0),
                  margin: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
                  decoration: BoxDecoration(
                    color: AppColors.defaultBlue500,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: const Stack(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 6.0,
                      ),
                    ],
                  ),
                ),
              );
            }
            // Fetch connected users before building the settings page
            return StreamBuilder<List<UserWithAssets>>(
              stream: _databaseService?.getConnectedUsersWithAssets, // Assuming this is the correct stream
              builder: (context, connectedUsersSnapshot) {

                if (!connectedUsersSnapshot.hasData || connectedUsersSnapshot.data!.isEmpty) {
                  // If there is no connected users, we build the dashboard for a single user
                  return buildsettingsPage(context, userSnapshot, connectedUsersSnapshot);
                }
                // Once we have the connected users, proceed to fetch notifications
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _databaseService?.getNotifications,
                  builder: (context, notificationsSnapshot) {
                    if (!notificationsSnapshot.hasData || notificationsSnapshot.data == null) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(26.0),
                          margin: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
                          decoration: BoxDecoration(
                            color: AppColors.defaultBlue500,
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: const Stack(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 6.0,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    unreadNotificationsCount = notificationsSnapshot.data!.where((notification) => !notification['isRead']).length;
                    // Now that we have all necessary data, build the settings page
                    return buildsettingsPageWithConnectedUsers(context, userSnapshot, connectedUsersSnapshot);
                  }
                );
              }
            );
          }
        );
      }
    );  
    
    void signUserOut(BuildContext context) async {
    ('settings.dart: Signing out...');
    await FirebaseAuth.instance.signOut();
    assert(FirebaseAuth.instance.currentUser == null);


    

    // Async gap mounted widget check
    if (!mounted){
      log('settings.dart: No longer mounted!');
      return;
    }

    // Pop the current page and go to login
    await Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => const OnboardingPage(),
        transitionDuration: Duration.zero,
      ),
      (route) => false,
    );  }
  
  
  DateTime? dob;
  String? userDob;

  String? email;
  String? userEmail;

  DateTime? firstDepositDate;
  String? userFirstDepositDate;

  String? initEmail;
  String? phoneNumber;
  String? address;
  String? firstName;
  String? lastName;
  String? companyName;
  String userName = '';
  double totalUserAssets = 0.00, totalAGQ = 0.00, totalAK1 = 0.00, totalAssets = 0.00;
  String? assets;
  double latestIncome = 0.00;
  String? beneficiaryFirstName;
  String? beneficiaryLastName;
  String? beneficiary;
  String? appEmail;


List<String> userDobs = [];
List<String> userEmails = [];
List<String> userFirstDepositDates = [];
List<String> initEmails = [];
List<String> phoneNumbers = [];
List<String> addresses = [];
List<String> beneficiaryFirstNames = [];
List<String> beneficiaryLastNames = [];
List<String> beneficiaries = [];
List<String> appEmails = [];
List<String> firstNames = [];
List<String> lastNames = [];
List<String> companyNames = [];
List<String> userNames = [];
List<double> totalUserAssetsList = [];
List<double> totalAGQList = [];
List<double> totalAK1List = [];
List<String> totalAssetsList = [];
List<double> latestIncomes = [];
List<String> assetsFormatted = [];

  bool hapticsSwitchValue = false;
  bool activitySwitchValue = false;
  bool statementsSwitchValue = false;
  List<String> connectedUserNames = [];
  List<String> connectedUserCids = [];



  @override
  void initState() {
    super.initState();
    fetchConnectedCids(_databaseService?.cid ?? '$cid');
        _initData().then((_) {
      _databaseService?.getConnectedUsersWithAssets.listen((connectedUsers) {
        if (mounted) {
          setState(() {
            connectedUserNames = connectedUsers.map<String>((user) {
              String firstName = user.info['name']['first'] as String;
              String lastName = user.info['name']['last'] as String;
              Map<String, String> userName = {
                'first': firstName,
                'last': lastName,
              };
              return userName.values.join(' ');
            }).toList();
          });
        }
      });
    });

  }

    Future<List<String>> fetchConnectedCids(String cid) async {
    DocumentSnapshot userSnapshot = await usersCollection.doc(cid).get();
    if (userSnapshot.exists) {
      Map<String, dynamic> info = userSnapshot.data() as Map<String, dynamic>;
      List<String> connectedUsers = info['connectedUsers'].cast<String>();
      connectedUserCids = connectedUsers;
      return connectedUsers;
    } else {
      return [];
    }
  }
// This is the selected button, initially set to an empty string
  // Assuming these fields are part of the `user.info` map
  Scaffold buildsettingsPage(
    
    BuildContext context,
      AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {

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

  Scaffold buildsettingsPageWithConnectedUsers(
    BuildContext context,
      AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {
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
  Padding _settings() => Padding(
      padding: const EdgeInsets.fromLTRB(20,0,20,20),

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
                              TextEditingController emailController = TextEditingController();


                              Widget buildCloseButton(BuildContext context) {
                                return Align(
                                  alignment: Alignment.topRight,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Icon(Icons.close, color: Colors.white),
                                  ),
                                );
                              }

                              Widget buildIconArt() {
                                return SvgPicture.asset(
                                  'assets/icons/change_email_and_password_icon_art.svg',
                                  // Optional: You can specify width, height, color, etc. if needed
                                );
                              }

                              Widget buildEmailInputSection(TextEditingController emailController) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Change Email',
                                      style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Titillium Web'),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'You are changing the email associated with your account.',
                                      style: TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'Titillium Web'),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Email',
                                      style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: emailController,
                                      readOnly: false, // Ensure this is false to allow typing
                                      keyboardType: TextInputType.emailAddress, // Add this line to bring up email keyboard
                                      style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your email',
                                        hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Titillium Web'),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(11),
                                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                                      ),
                                    ),
                                  ],
                                );
                              }                              

                              Widget buildContinueButton(BuildContext context, TextEditingController emailController) {
                                return ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      // Get the new email from the controller
                                      String newEmail = emailController.text.trim();

                                      // Get the current user
                                      var user = FirebaseAuth.instance.currentUser;

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
                                    backgroundColor: const Color.fromARGB(255, 30, 75, 137), // Updated from primary
                                    foregroundColor: Colors.white, // Text color
                                    splashFactory: NoSplash.splashFactory,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Titillium Web'),
                                  ),
                                );
                              }

                              AlertDialog buildsettingsDialog(BuildContext context, TextEditingController emailController) {
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
                                        buildContinueButton(context, emailController),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              return buildsettingsDialog(context, emailController);
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
                              TextEditingController passwordController = TextEditingController();

                              Widget buildCloseButton(BuildContext context) {
                                return Align(
                                  alignment: Alignment.topRight,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Icon(Icons.close, color: Colors.white),
                                  ),
                                );
                              }

                              Widget buildIconArt() {
                                return SvgPicture.asset(
                                  'assets/icons/change_email_and_password_icon_art.svg',
                                  // Optional: You can specify width, height, color, etc. if needed
                                );
                              }

                              Widget buildPasswordInputSection(TextEditingController passwordController) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Change Password',
                                      style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Titillium Web'),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'You are changing the password associated with your account.',
                                      style: TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'Titillium Web'),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'New Password',
                                      style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: passwordController,
                                      obscureText: true, // Ensure this is true for password fields
                                      style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your new password',
                                        hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Titillium Web'),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(11),
                                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              Widget buildContinueButton(BuildContext context, TextEditingController passwordController) {
                                return ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      // Get the new password from the controller
                                      String newPassword = passwordController.text.trim();

                                      // Get the current user
                                      var user = FirebaseAuth.instance.currentUser;

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
                                    backgroundColor: const Color.fromARGB(255, 30, 75, 137), // Updated from primary
                                    foregroundColor: Colors.white, // Updated from onPrimary
                                    splashFactory: NoSplash.splashFactory,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Titillium Web'),
                                  ),
                                );
                              }

                              AlertDialog buildsettingsDialog(BuildContext context, TextEditingController passwordController) {
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
                                        buildPasswordInputSection(passwordController),
                                        const SizedBox(height: 20),
                                        buildContinueButton(context, passwordController),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return buildsettingsDialog(context, passwordController);
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
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          List<dynamic>? tokens = await _databaseService!.getField('tokens') as List<dynamic>? ?? [];
                          // Get the current token
                          String currentToken = await FirebaseMessaging.instance.getToken() ?? '';
                          tokens.remove(currentToken);
                          // Update the list of tokens in the database for the user
                          await _databaseService!.updateField('tokens', tokens);
                          signUserOut(context);
                        },
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 149, 28, 28),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Center(
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),


        ],
              
      ),
      
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
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
