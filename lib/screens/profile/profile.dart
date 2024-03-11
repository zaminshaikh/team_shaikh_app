import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'dart:developer';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  // database service instance
  late DatabaseService _databaseService;

  Future<void> _initData() async {

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('User is not logged in');
      Navigator.pushReplacementNamed(context, '/login');
    }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(user!.uid, 1);
    // If there is no matching CID, redirect to login page
    if (service == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Otherwise set the database service instance
      _databaseService = service;
      log('Database Service has been initialized with CID: ${_databaseService.cid}');
    }
  }
  
  /// Formats the given amount as a currency string.
  String _currencyFormat(double amount) => NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
    locale: 'en_US',
  ).format(amount);


  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _initData(), // Initialize the database service
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          //child: CircularProgressIndicator(),
        );
      }
      return StreamBuilder<UserWithAssets>(
        stream: _databaseService.getUserWithAssets,
        builder: (context, userSnapshot) {
          // Wait for the user snapshot to have data
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(
              //child: CircularProgressIndicator(),
            );
          }
          // Once we have the user snapshot, we can build the activity page
          return buildProfilePage(context, userSnapshot);
        }
      );
    }
  );  


  Future<void> signUserOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  bool switchValue = false;

  @override
  void initState() {
    super.initState();
    _selectedButton = 'settings';
  }

// This is the selected button, initially set to an empty string
  String _selectedButton = '';

// This is the row with buttons
  Widget _buildButtonRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          SizedBox(width: 20), // Add initial width

          // Settings button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              side: BorderSide(
                color: _selectedButton == 'settings' ? AppColors.defaultBlue500 : AppColors.defaultBlueGray700,
              ),
              backgroundColor: _selectedButton == 'settings' ? AppColors.defaultBlue500 : Colors.transparent,
            ),
            child: Row(
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    color: _selectedButton == 'settings' ? Colors.white : AppColors.defaultBlueGray500,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.settings,
                  color: _selectedButton == 'settings' ? Colors.white : AppColors.defaultBlueGray500,
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _selectedButton = 'settings';
              });
            },
          ),
          
          SizedBox(width: 10), // Add width
          
          // Statements and Documents button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              side: BorderSide(
                color: _selectedButton == 'statementsAndDocuments' ? AppColors.defaultBlue500 : AppColors.defaultBlueGray700,
              ),
              backgroundColor: _selectedButton == 'statementsAndDocuments' ? AppColors.defaultBlue500 : Colors.transparent,
            ),
            child: Row(
              children: [
                Text(
                  'Statements and Documents',
                  style: TextStyle(
                    color: _selectedButton == 'statementsAndDocuments' ? Colors.white : AppColors.defaultBlueGray500,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.description, // Add the icon here
                  color: _selectedButton == 'statementsAndDocuments' ? Colors.white : AppColors.defaultBlueGray500,
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _selectedButton = 'statementsAndDocuments';
              });
            },
          ),
          
          SizedBox(width: 10), // Add width
          
          // Help Center button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              side: BorderSide(
                color: _selectedButton == 'helpCenter' ? AppColors.defaultBlue500 : AppColors.defaultBlueGray700,
              ),
              backgroundColor: _selectedButton == 'helpCenter' ? AppColors.defaultBlue500 : Colors.transparent,
            ),
            child: Row(
              children: [
                Text(
                  'Help Center',
                  style: TextStyle(
                    color: _selectedButton == 'helpCenter' ? Colors.white : AppColors.defaultBlueGray500,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.help, // Add the icon here
                  color: _selectedButton == 'helpCenter' ? Colors.white : AppColors.defaultBlueGray500,
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _selectedButton = 'helpCenter';
              });
            },
          ),

          SizedBox(width: 10), // Add width

          // Profiles button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              side: BorderSide(
                color: _selectedButton == 'profiles' ? AppColors.defaultBlue500 : AppColors.defaultBlueGray700,
              ),
              backgroundColor: _selectedButton == 'profiles' ? AppColors.defaultBlue500 : Colors.transparent,
            ),
            child: Row(
              children: [
                Text(
                  'Profiles',
                  style: TextStyle(
                    color: _selectedButton == 'profiles' ? Colors.white : AppColors.defaultBlueGray500,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.person, // Add the icon here
                  color: _selectedButton == 'profiles' ? Colors.white : AppColors.defaultBlueGray500,
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _selectedButton = 'profiles';
              });
            },
          ),

          SizedBox(width: 10), // Add width          

          // Legal and Policies button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              side: BorderSide(
                color: _selectedButton == 'legalAndPolicies' ? AppColors.defaultBlue500 : AppColors.defaultBlueGray700,
              ),
              backgroundColor: _selectedButton == 'legalAndPolicies' ? AppColors.defaultBlue500 : Colors.transparent,
            ),
            child: Row(
              children: [
                Text(
                  'Legal & Policies',
                  style: TextStyle(
                    color: _selectedButton == 'legalAndPolicies' ? Colors.white : AppColors.defaultBlueGray500,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.policy, // Add the icon here
                  color: _selectedButton == 'legalAndPolicies' ? Colors.white : AppColors.defaultBlueGray500,
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _selectedButton = 'legalAndPolicies';
              });
            },
          ),
          
          SizedBox(width: 20), // Add width
        ],
      ),
    );
  }

// This is the settings section
  Padding _settings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20,0,20,20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                  const SizedBox(height: 25),

                  // Security Section with options to change email and password
                  const Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'john@email.com',
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

                  Column(
                    children: [
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              TextEditingController emailController = TextEditingController();

                              return Dialog(
                                backgroundColor: const Color.fromARGB(255, 37, 58, 86),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  height: 550,
                                  width: 1000,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 100),
                                      const Text(
                                        'ICON ART',
                                        style: TextStyle(
                                          fontSize: 40,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Titillium Web',
                                        ),
                                      ),
                                      const SizedBox(height: 80),
                                      const Text(
                                        'Enter New Email',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Titillium Web',
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Email',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: emailController,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontFamily: 'Titillium Web',
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Enter your email',
                                              hintStyle: const TextStyle(
                                                color: Color.fromARGB(255, 122, 122, 122),
                                                fontFamily: 'Titillium Web',
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(11),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(11),
                                                borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 25),
                                      GestureDetector(
                                        onTap: () async {
                                          try {
                                            // Get the new email from the controller
                                            String newEmail = emailController.text.trim();

                                            // Get the current user
                                            var user = FirebaseAuth.instance.currentUser;

                                            // Send email verification to the new email address
                                            await user!.updateEmail(newEmail);
                                            await user.sendEmailVerification();

                                            // Show a message to inform the user to check their email for verification.
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text('Email Change Requested'),
                                                  content: const Text(
                                                    'Please check your email for a verification link. You need to verify the new email address before it takes effect.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text('OK'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                          } catch (e) {
                                            // log the error for debugging
                                            log('Error updating email: $e');

                                            // Handle error, display a message, etc.
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text('Error'),
                                                  content: Text('Error updating email: $e'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text('OK'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        },

                                        child: Container(
                                          height: 55,
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(255, 30, 75, 137),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Continue',
                                              style: TextStyle(
                                                fontSize: 18,
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
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 55,
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
                                fontSize: 18,
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
                        onTap: () async {
                          try {
                            // Get the user's email
                            String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

                            // Check if the user has provided an email
                            if (userEmail.isNotEmpty) {
                              // Send a password reset email to the user's email address
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail);

                              // Show a success message or navigate to a success screen
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    backgroundColor: const Color.fromARGB(255, 37, 58, 86),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      height: 550,
                                      width: 1000,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 100),
                                          const Text(
                                            'ICON ART',
                                            style: TextStyle(
                                              fontSize: 40,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                          const SizedBox(height: 80),
                                          const Text(
                                            'Change Password',
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Center(
                                            child: Text(
                                              'You will receive an Email with a link to reset your password. Please check your inbox.',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontFamily: 'Titillium Web',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );

                              // Now you can navigate to another page or perform other actions
                            } else {
                              // Handle the case where the user's email is empty
                              log('User email is empty.');
                            }
                          } catch (e) {
                            // Handle errors, you can display them to the user or log them
                            log('Error sending password reset email: $e');
                          }
                        },
                        child: Container(
                          height: 55,
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
                                fontSize: 18,
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

                  // Haptics Section with options to change haptics
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          const Text(
                            'Haptics',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Enable haptics if you want to receive vibration feedback.',
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
                                value: switchValue,
                                activeColor: CupertinoColors.activeBlue,
                                onChanged: (bool? value) {
                                  // This is called when the user toggles the switch.
                                  setState(() {
                                    switchValue = value ?? false;
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
                                value: switchValue,
                                activeColor: CupertinoColors.activeBlue,
                                onChanged: (bool? value) {
                                  // This is called when the user toggles the switch.
                                  setState(() {
                                    switchValue = value ?? false;
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
                                value: switchValue,
                                activeColor: CupertinoColors.activeBlue,
                                onChanged: (bool? value) {
                                  // This is called when the user toggles the switch.
                                  setState(() {
                                    switchValue = value ?? false;
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
                        onTap: () => signUserOut(),
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 149, 28, 28),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Center(
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 18,
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
                  const SizedBox(height: 150),


        ],
              
      ),
      
    );
            
  }
  
// This is the function to display the selected page 
  Widget _buildSelectedPage() {
    switch (_selectedButton) {
      case 'settings':
        return _settings(); // replace with your actual Settings page widget
      case 'statementsAndDocuments':
        return _statementsAndDocuments(); // replace with your actual Statements and Documents page widget
      case 'helpCenter':
        return _helpCenter(); // replace with your actual Help Center page widget
      case 'profiles':
        return _profiles(); // replace with your actual Profiles page widget
      case 'legalAndPolicies':
        return _legalAndPolicies(); // replace with your actual Legal and Policies page widget
      default:
        return Container(); // return an empty container by default
    }
  }

// This is the app bar 
  SliverAppBar _buildAppBar(context) {
    return SliverAppBar(
    backgroundColor: const Color.fromARGB(255, 30, 41, 59),
    automaticallyImplyLeading: false,
    toolbarHeight: 80,
    expandedHeight: 0,
    snap: false,
    floating: true,
    pinned: true,
    flexibleSpace: SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
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
          
        ],
      ),
    ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/notification');
            },
            child: Image.asset(
              'assets/icons/notification_bell.png',
              color: Colors.white,
              height: 32,
              width: 32,
            ),
          ),
        ),
      ],
    );
  }

// This is the bottom navigation bar 
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 50, right: 20, left: 20),
      height: 80,
      padding: const EdgeInsets.only(right: 30, left: 30),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 41, 59),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 8,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            },
            child: Image.asset(
              'assets/icons/dashboard_hollowed.png',
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => AnalyticsPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            },
            child: Image.asset(
              'assets/icons/analytics_hollowed.png',
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ActivityPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );},
            child: Image.asset(
              'assets/icons/activity_hollowed.png',
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            },
            child: Image.asset(
              'assets/icons/profile_filled.png',
              height: 50,
            ),
          ),
        ],
      ),
    );
  }

// This is the Client Name and ID section
  Widget _buildClientNameAndID(String name, String clientId) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 30, 0, 20), // Add this line
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row containing Client ID and Name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Client ID: $clientId',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// This is the Statements and Documents section
  Container _statementsAndDocuments() {
  return Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statements and Documents',
          style: TextStyle(
            fontSize: 60,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Titillium Web',
          ),
        ),
      ],
    ),
  );

}

// This is the Help Center section
  Container _helpCenter() {
  return Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Advisors Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advisors',
              style: TextStyle(
                fontSize: 25,
                color: Color.fromRGBO(255, 255, 255, 1),
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),

            SizedBox(height: 20), 
            
            // Sonny Shaikh Info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10), 
                border: Border.all(color: Colors.white, width: 1), // Add this line
              ),
              
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // name and icon
                    Row(
                      children: [
                        Icon(Icons.square, color: Colors.white, size: 70),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ahsan \'Sonny\' Shaikh', 
                              style: TextStyle(
                                fontSize: 20,
                                color: Color.fromRGBO(255, 255, 255, 1),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),

                            Text(
                              'Investment Advisor', 
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  
                    const SizedBox(height: 20),

                  // contact info
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Info:', 
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        
                        const SizedBox(height: 15),

                        Text(
                          'Email: sonny@example.com', 
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Phone: (123) 456-7890', 
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),

                        const SizedBox(height: 10),

                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20), 

            // Kash Shaikh Info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10), 
                border: Border.all(color: Colors.white, width: 1), // Add this line
              ),
              
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // name and icon
                    Row(
                      children: [
                        Icon(Icons.square, color: Colors.white, size: 70),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ahsan \'Sonny\' Shaikh', 
                              style: TextStyle(
                                fontSize: 20,
                                color: Color.fromRGBO(255, 255, 255, 1),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),

                            Text(
                              'Investment Advisor', 
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  
                    const SizedBox(height: 20),

                  // contact info
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Info:', 
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        
                        const SizedBox(height: 15),

                        Text(
                          'Email: sonny@example.com', 
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Phone: (123) 456-7890', 
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),

                        const SizedBox(height: 10),

                      ],
                    ),
                  ],
                ),
              ),
            ),

          ],
       ),


        SizedBox(height: 40), 


        // FAQ Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FAQ',
              style: TextStyle(
                fontSize: 25,
                color: Color.fromRGBO(255, 255, 255, 1),
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
            
            SizedBox(height: 20), 

            Theme(
              data: ThemeData(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                title: Text(
                  'Question 1',
                  style: TextStyle(
                    fontFamily: 'Titillium Web',
                    color: Colors.white,
                  ),
                ),
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Answer 1',
                      style: TextStyle(
                        fontFamily: 'Titillium Web',
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            Theme(
              data: ThemeData(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                title: Text(
                  'Question 2',
                  style: TextStyle(
                    fontFamily: 'Titillium Web',
                    color: Colors.white,
                  ),
                ),
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Answer 2',
                      style: TextStyle(
                        fontFamily: 'Titillium Web',
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),

            Theme(
              data: ThemeData(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                title: Text(
                  'Question 3',
                  style: TextStyle(
                    fontFamily: 'Titillium Web',
                    color: Colors.white,
                  ),
                ),
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Answer 3',
                      style: TextStyle(
                        fontFamily: 'Titillium Web',
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          
          ],
        ),
        
        SizedBox(height: 150), 

      ],      
    ),
    
  );

}

// This is the Profiles section
  Container _profiles() {
  return Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profiles',
          style: TextStyle(
            fontSize: 60,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Titillium Web',
          ),
        ),
      ],
    ),
  );

}

// This is the Legal and Policies section
  Container _legalAndPolicies() {

  return Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Legal & Policies',
          style: TextStyle(
            fontSize: 60,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Titillium Web',
          ),
        ),
      ],
    ),
  );

}

  Scaffold buildProfilePage(BuildContext context, AsyncSnapshot<UserWithAssets> userSnapshot) {
        
    UserWithAssets user = userSnapshot.data!;
    String firstName = user.info['name']['first'] as String;
    String lastName = user.info['name']['last'] as String;
    String companyName = user.info['name']['company'] as String;
    Map<String, String> userName = {'first': firstName, 'last': lastName, 'company': companyName};
    String? cid = _databaseService.cid;


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
                        _buildClientNameAndID('$firstName $lastName', cid ?? ''),
                        _buildButtonRow(),
                        _buildSelectedPage(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNavigationBar(context), 
            ),
          ],
        ),
      );   
  }
}
