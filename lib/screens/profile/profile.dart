// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/authenticate/welcome.dart';
import 'package:team_shaikh_app/main.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'package:team_shaikh_app/utilities.dart';
import 'dart:developer';
import 'package:url_launcher/url_launcher.dart';
import 'PDFPreview.dart';
import 'downloadmethod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  // database service instance
  late DatabaseService _databaseService;


  Future<void> _initData() async {

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('User is not logged in');
      await Navigator.pushReplacementNamed(context, '/login');
    }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(user!.uid, 1);
    // If there is no matching CID, redirect to login page
    // ignore: duplicate_ignore
    if (service == null) {
      // ignore: use_build_context_synchronously
      await Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Otherwise set the database service instance
      _databaseService = service;
      log('Database Service has been initialized with CID: ${_databaseService.cid}');
    }
  }
  


  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _initData(), // Initialize the database service
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return StreamBuilder<UserWithAssets>(
          stream: _databaseService.getUserWithAssets,
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData || userSnapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            // Fetch connected users before building the profile page
            return StreamBuilder<List<UserWithAssets>>(
              stream: _databaseService.getConnectedUsersWithAssets, // Assuming this is the correct stream
              builder: (context, connectedUsersSnapshot) {

                if (!connectedUsersSnapshot.hasData || connectedUsersSnapshot.data!.isEmpty) {
                  // If there is no connected users, we build the dashboard for a single user
                  return buildProfilePage(context, userSnapshot, connectedUsersSnapshot);
                }
                // Once we have the connected users, proceed to fetch notifications
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _databaseService.getNotifications,
                  builder: (context, notificationsSnapshot) {
                    if (!notificationsSnapshot.hasData || notificationsSnapshot.data == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    unreadNotificationsCount = notificationsSnapshot.data!.where((notification) => !notification['isRead']).length;
                    // Now that we have all necessary data, build the profile page
                    return buildProfilePageWithConnectedUsers(context, userSnapshot, connectedUsersSnapshot);
                  }
                );
              }
            );
          }
        );
      }
    );  
    
    void signUserOut(BuildContext context) async {
    ('profile.dart: Signing out...');
    await FirebaseAuth.instance.signOut();
    assert(FirebaseAuth.instance.currentUser == null);

    emailController.clear();
    passwordController.clear();

    

    // Async gap mounted widget check
    if (!mounted){
      log('profile.dart: No longer mounted!');
      return;
    }

    // Pop the current page and go to login
    await Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => OnboardingPage(),
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


  void extractAndPrintUserInfo(AsyncSnapshot<UserWithAssets> userSnapshot, AsyncSnapshot<List<UserWithAssets>> connectedUsers) {

      if (!userSnapshot.hasData) {
        return;
      }

      UserWithAssets user = userSnapshot.data!;
      DateTime dob = (user.info['dob'] as Timestamp).toDate();
      userDob = DateFormat('MM/dd/yyyy').format(dob);

      email = user.info['email'] as String;
      userEmail = email;


      if (user.info['firstDepositDate'] != null) {
        DateTime firstDepositDateTime = (user.info['firstDepositDate'] as Timestamp).toDate();
        userFirstDepositDate = DateFormat('MM/dd/yyyy').format(firstDepositDateTime);
      } else {
        userFirstDepositDate = 'N/A'; 
      }
      
      initEmail = user.info['initEmail'] as String;
      phoneNumber = user.info['phoneNumber'] as String;
      address = user.info['address'] as String;
      beneficiaryFirstName = user.info['beneficiaryFirstName'] as String;
      beneficiaryLastName = user.info['beneficiaryLastName'] as String;
      beneficiary = '$beneficiaryFirstName $beneficiaryLastName';
      if (user.info['appEmail'] != '') {
        appEmail = user.info['appEmail'] as String;
      } else {
        appEmail = user.info['initEmail'] as String;
      }
      appEmail = user.info['appEmail'] as String;
      firstName = user.info['name']['first'] as String;
      lastName = user.info['name']['last'] as String;
      companyName = user.info['name']['company'] as String? ?? 'N/A';
      userName = '$firstName $lastName';
        double totalUserAssets = 0.00,
          totalAGQ = 0.00,
          totalAK1 = 0.00,
          totalAssets = 0.00;

      // This is a calculation of the total assets of the user only
      for (var asset in user.assets) {
        switch (asset['fund']) {
          case 'AGQ':
            totalAGQ += asset['total'];
            break;
          case 'AK1':
            totalAK1 += asset['total'];
            break;
          default:
            totalAssets += asset['total'];
            totalUserAssets += asset['total'];
        }
      }

      // This calculation is for the total assets of all connected users combined
    if (connectedUsers.data != null) {
      for (var user in connectedUsers.data!) {
          for (var asset in user.assets) {
            switch (asset['fund']) {
              case 'AGQ':
                totalAGQ += asset['total'];
                break;
              case 'AK1':
                totalAK1 += asset['total'];
                break;
              default:
                totalAssets += asset['total'];
            }
          }
        }
    }

      double percentageAGQ = totalAGQ / totalAssets * 100; // Percentage of AGQ
      double percentageAK1 = totalAK1 / totalAssets * 100; // Percentage of AK1
      log('dashboard.dart: Total AGQ: $totalAGQ, Total AK1: $totalAK1, Total Assets: $totalAssets, Total User Assets: $totalUserAssets, AGQ: $percentageAGQ, Percentage AK1: $percentageAK1');
      assets = NumberFormat('#,##0.00', 'en_US').format(totalAssets);

      if (connectedUsers.data != null) {
  for (var user in connectedUsers.data!) {
    DateTime? dob = user.info['dob'] != null ? (user.info['dob'] as Timestamp).toDate() : null;
    userDobs.add(dob != null ? DateFormat('MM/dd/yyyy').format(dob) : 'N/A');
    userEmails.add(user.info['email'] as String? ?? 'N/A'); // Adjusted
    DateTime? firstDepositDate = user.info['firstDepositDate'] != null ? (user.info['firstDepositDate'] as Timestamp).toDate() : null;
    userFirstDepositDates.add(firstDepositDate != null ? DateFormat('MM/dd/yyyy').format(firstDepositDate) : 'N/A');
    initEmails.add(user.info['initEmail'] as String? ?? 'N/A'); // Adjusted
    phoneNumbers.add(user.info['phoneNumber'] as String? ?? 'N/A'); // Adjusted
    addresses.add(user.info['address'] as String? ?? 'N/A'); // Adjusted
    String beneficiaryFirstName = user.info['beneficiaryFirstName'] as String? ?? 'N/A'; // Adjusted
    String beneficiaryLastName = user.info['beneficiaryLastName'] as String? ?? ''; // Adjusted
    beneficiaries.add('$beneficiaryFirstName $beneficiaryLastName');
    firstNames.add(user.info['name']['first'] as String? ?? 'N/A'); // Adjusted
    lastNames.add(user.info['name']['last'] as String? ?? 'N/A'); // Adjusted
    companyNames.add(user.info['name']['company'] as String? ?? 'N/A'); // Adjusted
    userNames.add('${user.info['name']['first'] ?? 'N/A'} ${user.info['name']['last'] ?? 'N/A'}'); // Adjusted
    double userTotalAssets = 0.0; // Ensure this is a double for calculations

    for (var asset in user.assets) {
      // Assuming asset['total'] is a double. If it's a string, parse it first.
      userTotalAssets += asset['total'];
    }

    // Format the total assets after summing them up
    String formattedTotalAssets = NumberFormat('#,##0.00', 'en_US').format(userTotalAssets);
    totalAssetsList.add(formattedTotalAssets);
    }}

    
  }
  
  bool hapticsSwitchValue = false;
  bool activitySwitchValue = false;
  bool statementsSwitchValue = false;

    List<String> connectedUserNames = [];



  @override
  void initState() {
    super.initState();
    _selectedButton = 'settings';
        _initData().then((_) {
      _databaseService.getConnectedUsersWithAssets.listen((connectedUsers) {
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
      });
    });

  }

// This is the selected button, initially set to an empty string
  String _selectedButton = '';

// This is the Profiles section
  Container _profileForUser() => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
    child: Column(
      children: [
        const Row(
          children: [
            Text(
              'My Profile', 
              style: TextStyle(
                fontSize: 22,
                color: Color.fromRGBO(255, 255, 255, 1),
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10), 
            border: Border.all(color: Colors.white, width: 1), // Add this line
          ),
          
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name and icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.toString(), 
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'DOB: $userDob', // Assuming dob is a DateTime or String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Beneficiary: $beneficiary', // Assuming beneficiary is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'First Deposit Date: $userFirstDepositDate', // Assuming firstDepositDate is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Initial Email: $initEmail', // Assuming initEmail is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Current Email: ${appEmail?.isEmpty ?? true ? initEmail : appEmail}', // Use initEmail if appEmail is null or empty
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Phone Number: $phoneNumber', // Assuming phoneNumber is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Address: $address', // Assuming address is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Assets:', 
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      '\$$assets', // Assuming totalAssets is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                ),

                const Spacer(),
        
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Change this to your desired color
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                )
              ],
            ),
          ),
        ),

      ],
    ),
  
  );


// This is the Profiles section
  Container _profilesForConnectedUser() => Container(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Column(
      children: [


        ListView.builder(
          
          itemCount: connectedUserNames.length,
          itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10), 
            border: Border.all(color: Colors.white, width: 1), // Add this line
          ),
          
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name and icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectedUserNames[index], 
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'DOB: ${userDobs[index]}', 
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Beneficiary: ${beneficiaries[index]}', // Adjusted
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'First Deposit Date: ${userFirstDepositDates[index]}', // Adjusted
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Initial Email: ${initEmails[index]}', // Adjusted
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Current Email: ${userEmails[index]}', // Adjusted
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Phone Number: ${phoneNumbers[index]}', // Adjusted
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Address: ${addresses[index]}', // Adjusted
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Assets:', 
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      '\$${totalAssetsList[index]}', // Adjusted
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),                  ],
                ),

                const Spacer(),
        
              ],
            ),
          ),
        ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),

      ],
    ),
  
  );

Column _profileForAllUsers() => Column(
    children: [
      _profileForUser(),
              const Row(
          children: [
            SizedBox(width: 20),

            Text(
              'Connected Users', 
              style: TextStyle(
                fontSize: 22,
                color: Color.fromRGBO(255, 255, 255, 1),
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
          ],
        ),

      _profilesForConnectedUser(),
        const SizedBox(height: 80),
    ],
  );
  // Assuming these fields are part of the `user.info` map
  Scaffold buildProfilePage(
    
    BuildContext context,
      AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {
    extractAndPrintUserInfo(userSnapshot, connectedUsers);
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

  Scaffold buildProfilePageWithConnectedUsers(
    BuildContext context,
      AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {
    extractAndPrintUserInfo(userSnapshot, connectedUsers);
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
                        _buildSelectedPageWithConnectedUsers(),
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


// This is the row with buttons
  Widget _buildButtonRow() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 20), // Add initial width

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
                    fontSize: 16,
                    fontWeight: _selectedButton == 'settings' ? FontWeight.bold : FontWeight.w400,
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/icons/profile_settings_icon.svg',
                  color: _selectedButton == 'settings' ? Colors.white : AppColors.defaultBlueGray500,
                  height: 20,
                )
              ],
            ),
            onPressed: () {
              setState(() {
                _selectedButton = 'settings';
              });
            },
          ),
          
          const SizedBox(width: 10), // Add width
          
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
                    fontSize: 16,
                    fontWeight: _selectedButton == 'statementsAndDocuments' ? FontWeight.bold : FontWeight.w400,
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/icons/profile_statements_icon.svg',
                  color: _selectedButton == 'statementsAndDocuments' ? Colors.white : AppColors.defaultBlueGray500,
                  height: 20,
                )
              ],
            ),
            onPressed: () {
              setState(() {
                _selectedButton = 'statementsAndDocuments';
              });
            },
          ),
          
          const SizedBox(width: 10), // Add width
          
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
                    fontSize: 16,
                    fontWeight: _selectedButton == 'helpCenter' ? FontWeight.bold : FontWeight.w400,
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/icons/profile_help_center_icon.svg',
                  color: _selectedButton == 'helpCenter' ? Colors.white : AppColors.defaultBlueGray500,
                  height: 20,
                )
              ],
            ),
            onPressed: () {
              setState(() {
                _selectedButton = 'helpCenter';
              });
            },
          ),

          const SizedBox(width: 10), // Add width

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
                    fontSize: 16,
                    fontWeight: _selectedButton == 'profiles' ? FontWeight.bold : FontWeight.w400,
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/icons/profile_profiles_icon.svg',
                  // ignore: deprecated_member_use
                  color: _selectedButton == 'profiles' ? Colors.white : AppColors.defaultBlueGray500,
                  height: 20,
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _selectedButton = 'profiles';
              });
            },
          ),

          const SizedBox(width: 10), // Add width          

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
                    fontSize: 16,
                    fontWeight: _selectedButton == 'legalAndPolicies' ? FontWeight.bold : FontWeight.w400,
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/icons/profile_legal_policies_icon.svg',
                  // ignore: deprecated_member_use
                  color: _selectedButton == 'legalAndPolicies' ? Colors.white : AppColors.defaultBlueGray500,
                  height: 20,
                ),],
            ),
            onPressed: () {
              setState(() {
                _selectedButton = 'legalAndPolicies';
              });
            },
          ),
          
          const SizedBox(width: 20), // Add width
        ],
      ),
    );


// This is the settings section
  Padding _settings() => Padding(
      padding: const EdgeInsets.fromLTRB(20,0,20,20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                  const SizedBox(height: 25),

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
                                      log('Error updating email: $e');

                                      // Handle error, display a message, etc.
                                      await CustomAlertDialog.showAlertDialog(
                                        context,
                                        'Error',
                                        'Error updating email: $e',
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    primary: const Color.fromARGB(255, 30, 75, 137), // Background color
                                    onPrimary: Colors.white, // Text color
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

                              AlertDialog buildProfileDialog(BuildContext context, TextEditingController emailController) {
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
                              
                              return buildProfileDialog(context, emailController);
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
                                          'Password Change Successful',
                                          'Your password has been updated successfully.',
                                        );
                                      }

                                    } catch (e) {
                                      // log the error for debugging
                                      log('Error updating password: $e');

                                      // Handle error, display a message, etc.
                                      await CustomAlertDialog.showAlertDialog(
                                        context,
                                        'Error',
                                        'Error updating password: $e',
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    primary: const Color.fromARGB(255, 30, 75, 137), // Background color
                                    onPrimary: Colors.white, // Text color
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

                              AlertDialog buildProfileDialog(BuildContext context, TextEditingController passwordController) {
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

                              return buildProfileDialog(context, passwordController);
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
                        value: hapticsSwitchValue,
                        activeColor: CupertinoColors.activeBlue,
                        onChanged: (bool? value) {
                          // This is called when the user toggles the switch.
                          setState(() {
                            hapticsSwitchValue = value ?? false;
                          });
                        },
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
                                  // This is called when the user toggles the switch.
                                    statementsSwitchValue = value ?? false;
                                    print('$statementsSwitchValue');
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
                        onTap: () => signUserOut(context),
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
       return _profileForUser(); // replace with your actual Profiles page widget
      case 'legalAndPolicies':
       return _legalAndPolicies(); // replace with your actual Legal and Policies page widget
      default:
        return Container(); // return an empty container by default
    }
  }

// This is the function to display the selected page 
  Widget _buildSelectedPageWithConnectedUsers() {
    switch (_selectedButton) {
      case 'settings':
        return _settings(); // replace with your actual Settings page widget
      case 'statementsAndDocuments':
        return _statementsAndDocuments(); // replace with your actual Statements and Documents page widget
      case 'helpCenter':
       return _helpCenter(); // replace with your actual Help Center page widget
      case 'profiles':
       return _profileForAllUsers(); // replace with your actual Profiles page widget   
      case 'legalAndPolicies':
       return _legalAndPolicies(); // replace with your actual Legal and Policies page widget
      default:
        return Container(); // return an empty container by default
    }
  }

// This is the app bar 
  SliverAppBar _buildAppBar(context) => SliverAppBar(
    backgroundColor: const Color.fromARGB(255, 30, 41, 59),
    automaticallyImplyLeading: false,
    toolbarHeight: 80,
    expandedHeight: 0,
    snap: false,
    floating: true,
    pinned: true,
    flexibleSpace: const SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
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
            padding: const EdgeInsets.only(right: 5.0, bottom: 5.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 450),
                    pageBuilder: (_, __, ___) => const NotificationPage(),
                    transitionsBuilder: (_, animation, __, child) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: const Offset(0.0, 0.0),
                        ).animate(animation),
                        child: child,
                      ),
                  ),
                );
              },
              child: Container(
                color: const Color.fromRGBO(239, 232, 232, 0),
                padding: const EdgeInsets.all(10.0),
                child: ClipRect(
                  child: Stack(
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.transparent, // Change this color to the one you want
                                width: 0.3, // Adjust width to your need
                              ),
                              shape: BoxShape.rectangle, // or BoxShape.rectangle if you want a rectangle
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/bell.svg',
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                height: 32,
                              ),
                            ),
                          ),
                      Positioned(
                        right: 0,
                        top: 5,
                        child: unreadNotificationsCount > 0
                            ? Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF267DB5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '$unreadNotificationsCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Titillium Web',
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Container(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
    );

// This is the bottom navigation bar 
  Widget _buildBottomNavigationBar(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 30, right: 20, left: 20),
    height: 80,
    padding: const EdgeInsets.only(right: 10, left: 10),
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
                pageBuilder: (context, animation, secondaryAnimation) =>
                    DashboardPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: const Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/dashboard_hollowed.svg',
              height: 22,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const AnalyticsPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: const Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/analytics_hollowed.svg',
              height: 25,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ActivityPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: const Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/activity_hollowed.svg',
              height: 22,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ProfilePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: const Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/profile_filled.svg',
              height: 22,
            ),
          ),
        ),
      ],
    ),
  );


// Assuming _databaseService is initialized and accessible in this context
Widget _buildClientNameAndID(String name, String clientId) {
  // Initialize cid here, before using it in the widget tree
  String? cid = _databaseService.cid;

  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 30, 0, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row containing Client ID and Name
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Client ID: $cid',
              style: const TextStyle(
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
  Container _statementsAndDocuments() => Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // statements
        ListTile(
          contentPadding: const EdgeInsets.all(8.0),
          title: const Text(
            'Statement Title',
            style: TextStyle(
              fontSize: 20.0,
              fontFamily: 'Titillium Web',
              color: Colors.white,
            ),
          ),
          onTap: () async {
            await downloadFile(context, _databaseService.cid, 'TestPdf${_databaseService.cid}.pdf');
            String filePath = await downloadFile(context, {_databaseService.cid}, 'TestPdf${_databaseService.cid}.pdf');
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFScreen(filePath),
              ),
            );
                    },
          trailing: IconButton(
            icon: const Icon(
              Icons.download_rounded,
              color: Colors.white, 
            ),
            onPressed: () {
              downloadToFiles(documentName);
            },
          ),
          ),
      ],
    ),
  );

// This is the Help Center section
  Container _helpCenter() => Container(
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


            const SizedBox(height: 20), 
            
            // Sonny Shaikh Info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: AppColors.defaultBlueGray600, width: 2), // Add this line
              ),
              
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // name and icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/icons/sonny_headshot.png',
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
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
                        const Text(
                          'Contact Info:', 
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        
                        const SizedBox(height: 15),

                        GestureDetector(
                          onTap: () async {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: 'sonny@agqconsulting.com',
                              query: 'subject=${Uri.encodeComponent("Your Subject Here")}',
                            );
                            if (await canLaunch(emailLaunchUri.toString())) {
                              await launch(emailLaunchUri.toString());
                            } else {
                            }
                          },

                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/email.svg',
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Email: sonny@agqconsulting.com', 
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Titillium Web',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        GestureDetector(
                          onTap: () async {
                            const url = 'tel:+1 (631) 487-9818';
                            try {
                              bool launched = await launch(url);
                              if (!launched) {
                              }
                            } on PlatformException catch (e) {
                            } catch (e) {
                            }
                          },
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/phone.svg',
                                color: Colors.white,
                                height: 16,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Phone: +1 (631) 487-9818', 
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Titillium Web',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20), 

            // Kash Shaikh Info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: AppColors.defaultBlueGray600, width: 2), // Add this line
              ),
              
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // name and icon
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/kash_headshot.png',
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kashif Shaikh', 
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
                        const Text(
                          'Contact Info:', 
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        
                        const SizedBox(height: 15),


                        GestureDetector(
                          onTap: () async {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: 'kash@agqconsulting.com',
                              query: 'subject=${Uri.encodeComponent("Your Subject Here")}',
                            );
                            if (await canLaunch(emailLaunchUri.toString())) {
                              await launch(emailLaunchUri.toString());
                            } else {
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/email.svg',
                                  color: Colors.white,
                                  height: 16,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Email: kash@agqconsulting.com', 
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        GestureDetector(
                          onTap: () async {
                            const url = 'tel:+1 (973) 610 4916';
                            try {
                              bool launched = await launch(url);
                              if (!launched) {
                              }
                            } on PlatformException catch (e) {
                            } catch (e) {
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/phone.svg',
                                  color: Colors.white,
                                  height: 16,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Phone: +1 (973) 610 4916',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                              ],
                            ),
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


        const SizedBox(height: 40), 


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
            
            const SizedBox(height: 10), 

            Theme(
              data: ThemeData(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: const ExpansionTile(
                title: Text(
                  'How do I reset my password?',
                  style: TextStyle(
                    fontFamily: 'Titillium Web',
                    color: Colors.white,
                  ),
                ),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'To reset your password, go to the settings page and click on "Change Password". Follow the instructions provided.',
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
              child: const ExpansionTile(
                title: Text(
                  'Where can I find the user manual?',
                  style: TextStyle(
                    fontFamily: 'Titillium Web',
                    color: Colors.white,
                  ),
                ),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'The user manual is available in the Help section of our app. You can also access it directly from our website.',
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
              child: const ExpansionTile(
                title: Text(
                  'How to contact customer support?',
                  style: TextStyle(
                    fontFamily: 'Titillium Web',
                    color: Colors.white,
                  ),
                ),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Customer support can be reached via email at support@example.com, or you can call us at +123456789. Our team is available 24/7 to assist you.',
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
        
        const SizedBox(height: 150), 

      ],      
    ),
    
  );


// This is the Legal and Policies section
  Container _legalAndPolicies() => Container(
    padding: const EdgeInsets.all(20),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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
