// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class DisclaimerPage extends StatefulWidget {
  const DisclaimerPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _DisclaimerPageState createState() => _DisclaimerPageState();
}

class PdfFileWithCid {
  final Reference file;
  final String cid;

  PdfFileWithCid(this.file, this.cid);
}

class _DisclaimerPageState extends State<DisclaimerPage> {
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
        return StreamBuilder<UserWithAssets>(
          stream: _databaseService?.getUserWithAssets,
          builder: (context, userSnapshot) {
            return StreamBuilder<List<UserWithAssets>>(
              stream: _databaseService?.getConnectedUsersWithAssets, // Assuming this is the correct stream
              builder: (context, connectedUsersSnapshot) {

                  return buildDisclaimerPage(context, userSnapshot, connectedUsersSnapshot);
                // Once we have the connected users, proceed to fetch notifications
              }
            );
          }
        );
      }
    );  
    

  @override
  void initState() {
    super.initState();
  }

  // Assuming these fields are part of the `user.info` map
  Scaffold buildDisclaimerPage(
    
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
                        _disclaimer(),
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
              'Disclaimer',
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

// This is the Disclaimer Center section
  Container _disclaimer() => Container(
    padding: const EdgeInsets.all(20),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'AGQ Consulting LLC',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
            SizedBox(height: 10),
            Text(
              'AGQ Consulting LLC is a Florida limited liability company exempt from the registration '
              'requirements of the Investment Company Act of 1940 pursuant to Section 3(c)(1) thereof. '
              'Our private offerings are available for up to one hundred (100) accredited investors of '
              'which no more than thirty-five (35) may be non-accredited investors and rely on the '
              'registration exemption under Rule 506 of Regulation D under the Securities Act of 1933. '
              'A Form D claiming such exemption as a safe harbor is on file with the SEC and applicable '
              'states. AGQ is domiciled at 195 International Parkway, Suite 103, Lake Mary, Florida 32746 '
              'and is under the purview of the State of Florida and United States laws. '
              'Please contact AGQ at management@agqconsulting.com. Thank you.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontFamily: 'Titillium Web',
              ),
            ),
            SizedBox(height: 50),
            Text(
              'AK1 Holdings L.P.',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
            SizedBox(height: 10),
            Text(
              'AK1 Holdings L.P. is a limited partnership that is exempt from the registration requirements '
              'of the Investment Company Act of 1940 pursuant to Section 3(c)(1) thereof. Our private offerings '
              'are available to accredited investors only and rely on the registration exemptions under Regulation '
              'D under the Securities Act of 1933. A Form D claiming such exemption is on file with the SEC. '
              'AK1 Holdings L.P. is domiciled at 195 International Parkway, Suite 103, Lake Mary, Florida 32746 and '
              'is under the purview of the State of Florida and United States laws. A copy of the subscription agreement, '
              'risk factors and fees is available upon request. Thank you.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontFamily: 'Titillium Web',
              ),
            ),
            SizedBox(height: 40),
          ],
        )
      ],
    ),
  );

}
