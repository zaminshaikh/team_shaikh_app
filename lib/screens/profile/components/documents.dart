
// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'dart:developer';
import 'package:team_shaikh_app/screens/profile/PDFPreview.dart';
import 'package:team_shaikh_app/screens/profile/downloadmethod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _DocumentsPageState createState() => _DocumentsPageState();
}

class PdfFileWithCid {
  final Reference file;
  final String cid;

  PdfFileWithCid(this.file, this.cid);
}

class _DocumentsPageState extends State<DocumentsPage> {
  final Future<void> _initializeWidgetFuture = Future.value();

  // database service instance
  DatabaseService? _databaseService;

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
            // Fetch connected users before building the Documents page
            return StreamBuilder<List<UserWithAssets>>(
              stream: _databaseService?.getConnectedUsersWithAssets, // Assuming this is the correct stream
              builder: (context, connectedUsersSnapshot) {

                if (!connectedUsersSnapshot.hasData || connectedUsersSnapshot.data!.isEmpty) {
                  // If there is no connected users, we build the dashboard for a single user
                  return buildDocumentsPage(context, userSnapshot, connectedUsersSnapshot);
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
                    // Now that we have all necessary data, build the Documents page
                    return buildDocumentsPage(context, userSnapshot, connectedUsersSnapshot);
                  }
                );
              }
            );
          }
        );
      }
    );  
    
  
  
  List<String> connectedUserNames = [];
  List<String> connectedUserCids = [];



  
  
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

  Future<void> _initData() async {

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('Documents.dart: User is not logged in');
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



  @override
  void initState() {
    super.initState();
    // Call the function to show the documents section during initialization
    showDocumentsSection();
    // Initialize other data
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

  Future<void> showDocumentsSection() async {
    // Update the state to indicate that the 'documents' button is selected
    setState(() {
      _selectedButton = 'documents';
    });
  
  
    // List the PDF files available
    await listPDFFiles();
  
    // Fetch the connected CIDs using the database service's CID or a fallback CID
    await fetchConnectedCids(_databaseService?.cid ?? '$cid');
  
    // List the PDF files for connected users
    await listPDFFilesConnectedUsers();
  }
  
  final FirebaseStorage storage = FirebaseStorage.instance;
  List<Reference> pdfFiles = [];

  Future<void> listPDFFiles() async {
    final String? userFolder = _databaseService?.cid;

    final ListResult result = await storage.ref('testUsersStatements/$userFolder').listAll();
    final List<Reference> allFiles = result.items.where((ref) => ref.name.endsWith('.pdf')).toList();

    if (mounted) {
      setState(() {
        pdfFiles = allFiles;
      });
    }
    for (int i = 0; i < pdfFiles.length; i++) {
    }
  }
  
  List<PdfFileWithCid> pdfFilesConnectedUsers = [];
 
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
  
  // This is the selected button, initially set to an empty string
  String _selectedButton = '';
  
  Scaffold buildDocumentsPage(
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
                      _buildButton(),
                      _documents(),
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
  
  // This is the row with buttons
  Widget _buildButton() => 

      // Statements and Documents button
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          side: BorderSide(
            color: _selectedButton == 'documents' ? AppColors.defaultBlue500 : AppColors.defaultBlueGray700,
          ),
          backgroundColor: _selectedButton == 'documents' ? AppColors.defaultBlue500 : Colors.transparent,
        ),
        child: Row(
          children: [
            Text(
              'Documents',
              style: TextStyle(
                color: _selectedButton == 'documents' ? Colors.white : AppColors.defaultBlueGray500,
                fontSize: 16,
                fontWeight: _selectedButton == 'documents' ? FontWeight.bold : FontWeight.w400,
                fontFamily: 'Titillium Web'
              ),
            ),
            const SizedBox(width: 10),
            SvgPicture.asset(
              'assets/icons/profile_statements_icon.svg',
              color: _selectedButton == 'documents' ? Colors.white : AppColors.defaultBlueGray500,
              height: 20,
            )
          ],
        ),
        onPressed: () async {
          await showDocumentsSection();
        },
      );
    
// This is the Statements and Documents section
  Padding _documents() => Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                itemCount: pdfFiles.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Column(
                            children: [
                              if (index != 0) // Only show the divider if it's not the first file
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                                  child: Divider(
                                    color: Colors.white,
                                    thickness: 0.2,
                                    height: 10,
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      splashColor: Colors.transparent,
                                      title: Text(
                                        pdfFiles[index].name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Titillium Web',
                                        ),
                                      ),
                                      onTap: () async {
                                        await downloadFile(context, _databaseService?.cid, pdfFiles[index].name);
                                        String filePath = await downloadFile(context, _databaseService?.cid, pdfFiles[index].name);
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PDFScreen(filePath),
                                          ),
                                        );
                                      },
                                      trailing: IconButton(
                                        icon: SvgPicture.asset(
                                          'assets/icons/download.svg',
                                          width: 24,
                                          height: 24,
                                          color: AppColors.defaultBlueGray300,
                                        ),
                                        onPressed: () {
                                          shareFile(context, _databaseService?.cid, pdfFiles[index].name);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                itemCount: pdfFilesConnectedUsers.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Column(
                            children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                                  child: Divider(
                                    color: Colors.white,
                                    thickness: 0.2,
                                    height: 10,
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      splashColor: Colors.transparent,
                                      title: Text(
                                        pdfFilesConnectedUsers[index].file.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Titillium Web',
                                        ),
                                      ),
                                      onTap: () async {
                                        String filePath = '';
                                        filePath = await downloadFile(context, pdfFilesConnectedUsers[index].cid, pdfFilesConnectedUsers[index].file.name);
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PDFScreen(filePath),
                                            ),
                                          );
                                      },
                                      trailing: IconButton(
                                        icon: SvgPicture.asset(
                                          'assets/icons/download.svg',
                                          width: 24,
                                          height: 24,
                                          color: AppColors.defaultBlueGray300,
                                        ),
                                        onPressed: () {
                                          shareFile(context, pdfFilesConnectedUsers[index].cid, pdfFilesConnectedUsers[index].file.name);
                                        },
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
        
        
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
                  'Documents',
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


  
}
