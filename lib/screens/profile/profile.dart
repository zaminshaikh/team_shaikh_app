// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/authenticate/onboarding.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/notification.dart';
// import 'package:team_shaikh_app/screens/profile/components/authentication.dart';
import 'package:team_shaikh_app/screens/profile/components/disclaimer.dart';
import 'package:team_shaikh_app/screens/profile/components/documents.dart';
import 'package:team_shaikh_app/screens/profile/components/help.dart';
import 'package:team_shaikh_app/screens/profile/components/settings.dart';
import 'package:team_shaikh_app/screens/profile/components/profiles.dart';
import 'dart:developer';
import 'downloadmethod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class PdfFileWithCid {
  final Reference file;
  final String cid;

  PdfFileWithCid(this.file, this.cid);
}

class _ProfilePageState extends State<ProfilePage> {
  final Future<void> _initializeWidgetFuture = Future.value();

  // database service instance
  DatabaseService? _databaseService;

  Future<void> _initData() async {

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('profile.dart: User is not logged in');
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
            // Fetch connected users before building the profile page
            return StreamBuilder<List<UserWithAssets>>(
              stream: _databaseService?.getConnectedUsersWithAssets, // Assuming this is the correct stream
              builder: (context, connectedUsersSnapshot) {

                if (!connectedUsersSnapshot.hasData || connectedUsersSnapshot.data!.isEmpty) {
                  // If there is no connected users, we build the dashboard for a single user
                  return _buildProfilePage(context, userSnapshot, connectedUsersSnapshot);

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
                    // Now that we have all necessary data, build the profile page
                    return _buildProfilePageWithConnectedUsers(context, userSnapshot, connectedUsersSnapshot);
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


    

    // Async gap mounted widget check
    if (!mounted){
      log('profile.dart: No longer mounted!');
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
            totalAGQ += asset['total'] ?? 0;
            break;
          case 'AK1':
            totalAK1 += asset['total'] ?? 0;
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
                totalAGQ += asset['total'] ?? 0;
                break;
              case 'AK1':
                totalAK1 += asset['total'] ?? 0;
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
  
  Future<void> shareFile(context, clientId, documentName) async {
    try {
      // Call downloadFile to get the filePath
      String filePath = await downloadFile(context, clientId, documentName);

      // Debugging: Print the filePath

      // Check if the filePath is not empty
      if (filePath.isNotEmpty) {
        // Check if the filePath is a file
        File file = File(filePath);
        if (await file.exists()) {
          // Use Share.shareFiles to share the file
          await Share.shareFiles([filePath]);
        } else {
        }
      } else {
      }
    } catch (e) {
    }
  }


  final FirebaseStorage storage = FirebaseStorage.instance;
  List<Reference> pdfFiles = [];


  @override
  void initState() {
    super.initState();
    listPDFFiles();
    fetchConnectedCids(_databaseService?.cid ?? '$cid');
    listPDFFilesConnectedUsers();
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


  Future<void> listPDFFiles() async {
      final String? userFolder = _databaseService?.cid;
    
      final ListResult result = await storage.ref('testUsersStatements/$userFolder').listAll();
      final List<Reference> allFiles = result.items.where((ref) => ref.name.endsWith('.pdf')).toList();
    

        if (mounted) {
          setState(() {
            pdfFiles = allFiles;
          });
        }
  }

  List<PdfFileWithCid> pdfFilesConnectedUsers = [];

  Future<void> listPDFFilesConnectedUsers() async {
    final List<String> connectedUserFolders = connectedUserCids;
    List<PdfFileWithCid> allConnectedFiles = [];

    for (String folder in connectedUserFolders) {
      final ListResult result = await storage.ref('testUsersStatements/$folder').listAll();
      final List<Reference> pdfFilesInFolder = result.items.where((ref) => ref.name.endsWith('.pdf')).toList();
      
      // Convert List<Reference> to List<PdfFileWithCid>
      final List<PdfFileWithCid> pdfFilesWithCid = pdfFilesInFolder.map((file) => PdfFileWithCid(file, folder)).toList();
      allConnectedFiles.addAll(pdfFilesWithCid);
    }

    if (mounted) {
      setState(() {
        // Use a Set to keep track of already added files
        final existingFiles = pdfFilesConnectedUsers.map((pdfFileWithCid) => pdfFileWithCid.file.name).toSet();
        
        // Add only the new files that are not already in the list
        final newFiles = allConnectedFiles.where((pdfFileWithCid) => !existingFiles.contains(pdfFileWithCid.file.name)).toList();
        
        pdfFilesConnectedUsers.addAll(newFiles);
      });
    }
  }


  Scaffold _buildProfilePage(
    
    BuildContext context,
      AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {
    extractAndPrintUserInfo(userSnapshot, connectedUsers);
        String? cid = _databaseService?.cid;

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
                        _buildSampleCupertinoListSection(),
                        _buildLogoutButton(),
                        _buildDisclaimer(),
                        const SizedBox(height: 120),
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

  Scaffold _buildProfilePageWithConnectedUsers(
    BuildContext context,
      AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {
    extractAndPrintUserInfo(userSnapshot, connectedUsers);
        String? cid = _databaseService?.cid;
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
                        _buildSampleCupertinoListSection(),
                        _buildLogoutButton(),
                        _buildDisclaimer(),
                        const SizedBox(height: 120),
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


// This is the list of vertical buttons
Widget _buildSampleCupertinoListSection() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.defaultBlueGray800, // Gray background
        borderRadius: BorderRadius.circular(12.0), // Rounded borders
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          CupertinoListTile(
            leading: SvgPicture.asset(
              'assets/icons/profile_help_center_icon.svg',
              color: Colors.white,
              height: 20,
            ),
            title: const Text(
              'Help',
              style: TextStyle(
                fontFamily: 'Titillium Web',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const CupertinoListTileChevron(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpPage()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Divider(color: CupertinoColors.separator, thickness: 1.5),
          ),
          CupertinoListTile(
            leading: SvgPicture.asset(
              'assets/icons/profile_statements_icon.svg',
              color: Colors.white,
              height: 20,
            ),
            title: const Text(
              'Documents',
              style: TextStyle(
                fontFamily: 'Titillium Web',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const CupertinoListTileChevron(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DocumentsPage()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Divider(color: CupertinoColors.separator, thickness: 1.5),
          ),
          CupertinoListTile(
            leading: SvgPicture.asset(
              'assets/icons/profile_settings_icon.svg',
              color: Colors.white,
              height: 20,
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Titillium Web',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const CupertinoListTileChevron(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Divider(color: CupertinoColors.separator, thickness: 1.5 ),
          ),
          CupertinoListTile(
            leading: SvgPicture.asset(
              'assets/icons/profile_profiles_icon.svg',
              color: Colors.white,
              height: 20,
            ),
            title: const Text(
              'Profiles',
              style: TextStyle(
                fontFamily: 'Titillium Web',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const CupertinoListTileChevron(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilesPage()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Divider(color: CupertinoColors.separator, thickness: 1.5 ),
          ),
          CupertinoListTile(
            leading: SvgPicture.asset(
              'assets/icons/face_id.svg',
              color: Colors.white,
              height: 40,
            ),
            title: const Text(
              'Authentication',
              style: TextStyle(
                fontFamily: 'Titillium Web',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const CupertinoListTileChevron(),
            // onTap: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => AuthenticationPage()),
            //   );
            // },
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

  Widget _buildDisclaimer() {
    return  Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Divider(color: Color.fromARGB(46, 255, 255, 255), thickness: 1.5),
          const SizedBox(height: 15),
          const Text(
            'DISCLAIMER',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Titillium Web',
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Investment products and services are offered through AGQ Consulting LLC, a Florida limited liability company.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DisclaimerPage()),
              );
            },
            child: const Center(
              child: Row(
                children: [
                  Text(
                    'Read Full Disclaimer',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.blue,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
        
      )
    );
  }


  Widget _buildLogoutButton() => 
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
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
                borderRadius: BorderRadius.circular(12),
              ),
              child:  Center(
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
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
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
                    const DashboardPage(),
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


// Assuming _databaseService? is initialized and accessible in this context
Widget _buildClientNameAndID(String name, String clientId) {
  // Initialize cid here, before using it in the widget tree
  String? cid = _databaseService?.cid;

  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
      ],
    ),
  );
}

  
}
