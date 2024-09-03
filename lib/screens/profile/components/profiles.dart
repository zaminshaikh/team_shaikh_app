// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/authenticate/onboarding.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfilesPage extends StatefulWidget {
  const ProfilesPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _ProfilesPageState createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  final Future<void> _initializeWidgetFuture = Future.value();

  // database service instance
  DatabaseService? _databaseService;

  Future<void> _initData() async {

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('Profiles.dart: User is not logged in');
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

  Stream<List<String>> get getConnectedUsersWithCid => usersCollection.doc(_databaseService?.cid).snapshots().asyncMap((userSnapshot) async {
    final data = userSnapshot.data();
    if (data == null) {
      return [];
    }
    List<String> connectedUsers = [];
    // Safely add _databaseService.cid to the list of connected users if it's not null
    if (_databaseService?.cid != null) {
    }
    return connectedUsers;
  });

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
            // Fetch connected users before building the Profiles page
            return StreamBuilder<List<UserWithAssets>>(
              stream: _databaseService?.getConnectedUsersWithAssets, // Assuming this is the correct stream
              builder: (context, connectedUsersSnapshot) {

                if (!connectedUsersSnapshot.hasData || connectedUsersSnapshot.data!.isEmpty) {
                  // If there is no connected users, we build the dashboard for a single user
                  return buildProfilesPage(context, userSnapshot, connectedUsersSnapshot);
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
                    // Now that we have all necessary data, build the Profiles page
                    return buildProfilesPageWithConnectedUsers(context, userSnapshot, connectedUsersSnapshot);
                  }
                );
              }
            );
          }
        );
      }
    );  
    
    void signUserOut(BuildContext context) async {
    ('Profiles.dart: Signing out...');
    await FirebaseAuth.instance.signOut();
    assert(FirebaseAuth.instance.currentUser == null);


    

    // Async gap mounted widget check
    if (!mounted){
      log('Profiles.dart: No longer mounted!');
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


  void extractAndPrintUserInfo(AsyncSnapshot<UserWithAssets> userSnapshot, AsyncSnapshot<List<UserWithAssets>> connectedUsers) {

      if (!userSnapshot.hasData) {
        return;
      }

      UserWithAssets user = userSnapshot.data!;
      DateTime dob = user.info['dob'] != null ? (user.info['dob'] as Timestamp).toDate() : DateTime.now();
      userDob = DateFormat('MM/dd/yyyy').format(dob);

      email = (((user.info['appEmail'] ?? user.info['initEmail']) ?? user.info['email']) ?? 'N/A') as String;
      userEmail = email;


      if (user.info['firstDepositDate'] != null) {
        DateTime firstDepositDateTime = (user.info['firstDepositDate'] as Timestamp).toDate();
        userFirstDepositDate = DateFormat('MM/dd/yyyy').format(firstDepositDateTime);
      } else {
        userFirstDepositDate = 'N/A'; 
      }
      
      initEmail = user.info['initEmail'] != null ? user.info['initEmail'] as String: '';
      phoneNumber = user.info['phoneNumber'] != null ? user.info['phoneNumber'] as String : '';
      address = user.info['address'] as String? ?? '';
      beneficiaryFirstName = user.info['beneficiaryFirstName'] != null ? user.info['beneficiaryFirstName'] as String : '';
      beneficiaryLastName = user.info['beneficiaryLastName'] != null ? user.info['beneficiaryLastName'] as String : '';
      beneficiary = '$beneficiaryFirstName $beneficiaryLastName';
      if (user.info['appEmail'] != null && user.info['appEmail'] != '' ) {
        appEmail = user.info['appEmail'] as String;
      } else {
        appEmail = '';
      }
      // appEmail = user.info['appEmail'] as String;
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
            totalAssets += asset['total'] ?? 0;
            totalUserAssets += asset['total'] ?? 0;
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
                totalAssets += asset['total'] ?? 0;
            }
          }
        }
    }

      double percentageAGQ = totalAGQ / totalAssets * 100; // Percentage of AGQ
      double percentageAK1 = totalAK1 / totalAssets * 100; // Percentage of AK1
      log(' Total AGQ: $totalAGQ, Total AK1: $totalAK1, Total Assets: $totalAssets, Total User Assets: $totalUserAssets, AGQ: $percentageAGQ, Percentage AK1: $percentageAK1');
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
      userTotalAssets += asset['total'] ?? 0;
    }

    // Format the total assets after summing them up
    String formattedTotalAssets = NumberFormat('#,##0.00', 'en_US').format(userTotalAssets);
    totalAssetsList.add(formattedTotalAssets);
    }}

    
  }
  
  @override
  void initState() {
    super.initState();
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

// This is the Profiless section
  Container _profilesForUser() => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
    child: Column(
      children: [
        const Row(
          children: [
            Text(
              'My Profiles', 
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
                      'First Deposit Date: $userFirstDepositDate', // Assuming firstDepositDate is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Communication Email: $initEmail', // Assuming initEmail is a String variable
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

// This is the Profiless section
  Column _profilesForConnectedUser() => Column(
    children: [
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
      
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: ListView.builder(
          
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
                      'First Deposit Date: ${userFirstDepositDates[index]}', // Adjusted
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Communication Email: ${initEmails[index]}', // Adjusted
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
      ),
  
    ],
  );

Column _profilesForAllUsers() => Column(
    children: [
      _profilesForUser(),

      _profilesForConnectedUser(),
    ],
  );
  // Assuming these fields are part of the `user.info` map
  Scaffold buildProfilesPage(
    
    BuildContext context,
      AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {
    extractAndPrintUserInfo(userSnapshot, connectedUsers);

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
                        _profilesForUser(),
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

  Scaffold buildProfilesPageWithConnectedUsers(
    BuildContext context,
      AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {
    extractAndPrintUserInfo(userSnapshot, connectedUsers);
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
                        _profilesForAllUsers(),
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
              'Profiles',
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
