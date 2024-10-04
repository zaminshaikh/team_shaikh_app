// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart'; // Added for CupertinoSearchTextField
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';
import 'package:team_shaikh_app/screens/profile/utils/PDFPreview.dart';
import 'package:team_shaikh_app/screens/profile/utils/downloadmethod.dart';
import 'package:team_shaikh_app/screens/utils/utilities.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _DocumentsPageState createState() => _DocumentsPageState();
}

class PDF {
  final Reference file;
  final String cid;

  PDF(this.file, this.cid);
}

class _DocumentsPageState extends State<DocumentsPage> {
  Client? client;
  final FirebaseStorage storage = FirebaseStorage.instance;
  List<Reference> pdfFiles = [];
  List<Reference> filteredPdfFiles = [];
  List<PDF> pdfFilesConnectedUsers = [];
  List<PDF> filteredPdfFilesConnectedUsers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    client = Provider.of<Client?>(context);
    _initializeDocuments();
  }

  @override
  Widget build(BuildContext context) {
    if (client == null) {
      return const CustomProgressIndicator();
    }

    return buildDocumentsPage();
  }

  Future<void> shareFile(context, clientId, documentName) async {
    try {
      // Call downloadFile to get the filePath
      String filePath = await downloadFile(context, clientId, documentName);

      // Check if the filePath is not empty
      if (filePath.isNotEmpty) {
        // Check if the filePath is a file
        File file = File(filePath);
        if (await file.exists()) {
          // Use Share.shareFiles to share the file
          await Share.shareXFiles([XFile(filePath)]);
        } else {}
      } else {}
    } catch (e) {}
  }

  Future<void> _initializeDocuments() async {
    await showDocumentsSection();
  }

  Future<void> showDocumentsSection() async {
    // Update the state to indicate that the 'documents' button is selected
    setState(() {});

    // List the PDF files available
    await listPDFFiles();

    // List the PDF files for connected users
    await listPDFFilesConnectedUsers();
  }

  Future<void> listPDFFiles() async {
    final String userFolder = client!.cid;
    final ListResult result =
        await storage.ref('${Config.get('DOCUMENTS_PATH')}/$userFolder').listAll();
    final List<Reference> allFiles =
        result.items.where((ref) => ref.name.endsWith('.pdf')).toList();

    if (mounted) {
      setState(() {
        pdfFiles = allFiles;
        filteredPdfFiles = allFiles;
      });
    }

    print(pdfFiles.map((file) => file.name).toList());
  }

  Future<void> listPDFFilesConnectedUsers() async {
    List<PDF> allConnectedFiles = [];

    for (String folder in client!.connectedUsers!.whereType<Client>().map((client) => client.cid)) {
      final ListResult result =
          await storage.ref('${Config.get('DOCUMENTS_PATH')}/$folder').listAll();
      final List<Reference> pdfFilesInFolder =
          result.items.where((ref) => ref.name.endsWith('.pdf')).toList();

      // Convert List<Reference> to List<PDF>
      final List<PDF> pdfFilesWithCid =
          pdfFilesInFolder.map((file) => PDF(file, folder)).toList();
      allConnectedFiles.addAll(pdfFilesWithCid);
    }

    if (mounted) {
      setState(() {
        // Use a Set to keep track of already added files
        final existingFiles = pdfFilesConnectedUsers
            .map((pdfFileWithCid) => pdfFileWithCid.file.name)
            .toSet();

        // Add only the new files that are not already in the list
        final newFiles = allConnectedFiles
            .where((pdfFileWithCid) =>
                !existingFiles.contains(pdfFileWithCid.file.name))
            .toList();

        pdfFilesConnectedUsers.addAll(newFiles);
        filteredPdfFilesConnectedUsers = pdfFilesConnectedUsers;
      });
    }
  }

  void _filterPdfFiles(String query) {
    setState(() {
      filteredPdfFiles = pdfFiles
          .where((file) =>
              file.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      filteredPdfFilesConnectedUsers = pdfFilesConnectedUsers
          .where((file) =>
              file.file.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Scaffold buildDocumentsPage() {
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
          _filterPdfFiles(query);
        },
        onSubmitted: (query) {
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

  // This is the Statements and Documents section
  Padding _documents() => Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (filteredPdfFiles.isEmpty && filteredPdfFilesConnectedUsers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Text(
                    'There are no documents available.',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                      fontSize: 20,
                    ),
                  ),
                ),
              )
            else ...[
              if (filteredPdfFiles.isNotEmpty)
                Flexible(
                  fit: FlexFit.loose,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredPdfFiles.length,
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
                                            await downloadFile(context, client!.cid, filteredPdfFiles[index].name);
                                            String filePath = await downloadFile(context, client!.cid, filteredPdfFiles[index].name);
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
                                              shareFile(context, client!.cid, filteredPdfFiles[index].name);
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
              if (filteredPdfFilesConnectedUsers.isNotEmpty)
                Flexible(
                  fit: FlexFit.loose,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredPdfFilesConnectedUsers.length,
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
                                            filteredPdfFilesConnectedUsers[index].file.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                          onTap: () async {
                                            String filePath = '';
                                            filePath = await downloadFile(context, filteredPdfFilesConnectedUsers[index].cid, filteredPdfFilesConnectedUsers[index].file.name);
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
                                              shareFile(context, filteredPdfFilesConnectedUsers[index].cid, filteredPdfFilesConnectedUsers[index].file.name);
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
                ),
            ],
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
