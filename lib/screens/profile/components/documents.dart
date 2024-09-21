

// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'dart:developer';
import 'package:team_shaikh_app/screens/profile/PDFPreview.dart';
import 'package:team_shaikh_app/screens/profile/downloadmethod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);
  @override
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

    final FirebaseStorage storage = FirebaseStorage.instance;
    List<String> connectedUserNames = [];
    List<String> connectedUserCids = [];
    List<Reference> pdfFiles = [];
    List<Reference> filteredPdfFiles = [];
    List<PdfFileWithCid> pdfFilesConnectedUsers = [];
    List<PdfFileWithCid> filteredPdfFilesConnectedUsers = [];
  
    @override
    void initState() {
      super.initState();
      _initData().then((_) {
        _initializeDocuments();
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
  
    Future<void> _initData() async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log('Documents.dart: User is not logged in');
        await Navigator.pushReplacementNamed(context, '/login');
      }
      DatabaseService? service = await DatabaseService.fetchCID(context, user!.uid, 1);
      if (service == null) {
        await Navigator.pushReplacementNamed(context, '/login');
      } else {
        _databaseService = service;
        log('Database Service has been initialized with CID: ${_databaseService?.cid}');
      }
    }
  
    Future<void> _initializeDocuments() async {
      await showDocumentsSection();
    }
  
    Future<void> showDocumentsSection() async {
      setState(() {});
      await listPDFFiles();
      await fetchConnectedCids(_databaseService?.cid ?? '$cid');
      await listPDFFilesConnectedUsers();
    }
  
    Future<void> listPDFFiles() async {
      print('listPDFFiles: Starting to list PDF files');
      final String? userFolder = _databaseService?.cid;
      print('listPDFFiles: User folder = $userFolder');
      final ListResult result = await storage.ref('testUsersStatements/$userFolder').listAll();
      print('listPDFFiles: Retrieved ${result.items.length} items from storage');
      final List<Reference> allFiles = result.items.where((ref) => ref.name.endsWith('.pdf')).toList();
      print('listPDFFiles: Filtered ${allFiles.length} PDF files');
    
      if (mounted) {
        setState(() {
          pdfFiles = allFiles;
          filteredPdfFiles = allFiles;
          print('listPDFFiles: Updated state with ${pdfFiles.length} PDF files');
        });
      }
    }
    
    Future<List<String>> fetchConnectedCids(String cid) async {
      print('fetchConnectedCids: Fetching connected CIDs for user $cid');
      DocumentSnapshot userSnapshot = await usersCollection.doc(cid).get();
      if (userSnapshot.exists) {
        Map<String, dynamic> info = userSnapshot.data() as Map<String, dynamic>;
        List<String> connectedUsers = info['connectedUsers'].cast<String>();
        connectedUserCids = connectedUsers;
        print('fetchConnectedCids: Found ${connectedUsers.length} connected users');
        return connectedUsers;
      } else {
        print('fetchConnectedCids: No connected users found');
        return [];
      }
    }
    
    Future<void> listPDFFilesConnectedUsers() async {
      print('listPDFFilesConnectedUsers: Starting to list PDF files for connected users');
      final List<String> connectedUserFolders = connectedUserCids;
      print('listPDFFilesConnectedUsers: Connected user folders = $connectedUserFolders');
      List<PdfFileWithCid> allConnectedFiles = [];
    
      for (String folder in connectedUserFolders) {
        print('listPDFFilesConnectedUsers: Listing files for folder $folder');
        final ListResult result = await storage.ref('testUsersStatements/$folder').listAll();
        print('listPDFFilesConnectedUsers: Retrieved ${result.items.length} items from storage for folder $folder');
        final List<Reference> pdfFilesInFolder = result.items.where((ref) => ref.name.endsWith('.pdf')).toList();
        print('listPDFFilesConnectedUsers: Filtered ${pdfFilesInFolder.length} PDF files in folder $folder');
        final List<PdfFileWithCid> pdfFilesWithCid = pdfFilesInFolder.map((file) => PdfFileWithCid(file, folder)).toList();
        allConnectedFiles.addAll(pdfFilesWithCid);
      }
    
      if (mounted) {
        setState(() {
          final existingFiles = pdfFilesConnectedUsers.map((pdfFileWithCid) => pdfFileWithCid.file.name).toSet();
          final newFiles = allConnectedFiles.where((pdfFileWithCid) => !existingFiles.contains(pdfFileWithCid.file.name)).toList();
          pdfFilesConnectedUsers.addAll(newFiles);
          filteredPdfFilesConnectedUsers = pdfFilesConnectedUsers;
          print('listPDFFilesConnectedUsers: Updated state with ${pdfFilesConnectedUsers.length} PDF files from connected users');
        });
      }
    }
    
    void _filterPdfFiles(String query) {
      print('_filterPdfFiles: Filtering PDF files with query "$query"');
      setState(() {
        filteredPdfFiles = pdfFiles.where((file) => file.name.toLowerCase().contains(query.toLowerCase())).toList();
        print('_filterPdfFiles: Found ${filteredPdfFiles.length} matching PDF files for user');
        filteredPdfFilesConnectedUsers = pdfFilesConnectedUsers.where((file) => file.file.name.toLowerCase().contains(query.toLowerCase())).toList();
        print('_filterPdfFiles: Found ${filteredPdfFilesConnectedUsers.length} matching PDF files for connected users');
      });
    }
  
    Future<void> shareFile(context, clientId, documentName) async {
      try {
        String filePath = await downloadFile(context, clientId, documentName);
        if (filePath.isNotEmpty) {
          File file = File(filePath);
          if (await file.exists()) {
            await Share.shareFiles([filePath]);
          }
        }
      } catch (e) {
        // Handle error
      }
    }
  
    @override
    Widget build(BuildContext context) => FutureBuilder(
        future: _initializeWidgetFuture,
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
              return StreamBuilder<List<UserWithAssets>>(
                stream: _databaseService?.getConnectedUsersWithAssets,
                builder: (context, connectedUsersSnapshot) {
                  if (!connectedUsersSnapshot.hasData || connectedUsersSnapshot.data!.isEmpty) {
                    return buildDocumentsPage(context, userSnapshot, connectedUsersSnapshot);
                  }
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
                      return buildDocumentsPage(context, userSnapshot, connectedUsersSnapshot);
                    }
                  );
                }
              );
            }
          );
        }
      );
  
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
                        _buildSearchBar(),
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
  
    Widget _buildSearchBar() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: CupertinoSearchTextField(
          onChanged: (query) {
            print('_buildSearchBar: onChanged called with query "$query"');
            _filterPdfFiles(query);
          },
          onSubmitted: (query) {
            print('_buildSearchBar: onSubmitted called with query "$query"');
            _filterPdfFiles(query);
          },
          placeholder: 'Search PDF files',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Titillium Web',
          ),
        ),
      );
    }
  
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
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredPdfFiles.length,
                  itemBuilder: (BuildContext context, int index) {
                    print('_documents: Building ListTile for user PDF file "${filteredPdfFiles[index].name}"');
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
                                if (index != 0)
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
                                          filteredPdfFiles[index].name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Titillium Web',
                                          ),
                                        ),
                                        onTap: () async {
                                          await downloadFile(context, _databaseService?.cid, filteredPdfFiles[index].name);
                                          String filePath = await downloadFile(context, _databaseService?.cid, filteredPdfFiles[index].name);
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
                                            shareFile(context, _databaseService?.cid, filteredPdfFiles[index].name);
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
                  itemCount: filteredPdfFilesConnectedUsers.length,
                  itemBuilder: (BuildContext context, int index) {
                    print('_documents: Building ListTile for connected user PDF file "${filteredPdfFilesConnectedUsers[index].file.name}"');
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
                                          filteredPdfFilesConnectedUsers[index].file.name,
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
      ),
    );
  }