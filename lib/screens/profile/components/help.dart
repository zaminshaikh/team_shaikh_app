// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final String content;

  const CustomExpansionTile({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  _CustomExpansionTileState createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Titillium Web',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        trailing: Icon(
          _isExpanded ? Icons.remove : Icons.add,
          color: _isExpanded ? Colors.blue : Colors.white,
        ),
        children: <Widget>[
          ListTile(
            title: Text(
              widget.content,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Titillium Web',
                color: Colors.white,
              ),
            ),
          ),
        ],
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
      ),
    );
  }
}

class HelpPage extends StatefulWidget {
  const HelpPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
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

                  return buildHelpPage(context, userSnapshot, connectedUsersSnapshot);
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
  Scaffold buildHelpPage(
    
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
                        _helpCenter(),
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
              'Help',
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 10),
                Text(
                  'FAQ',
                  style: TextStyle(
                    fontSize: 22,
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ],
            ),
            SizedBox(height: 10), 

            CustomExpansionTile(
              title: 'Is the app secure?',
              content: 'Yes, the Team Shaikh App is designed with strong security measures to protect your data and ensure your privacy.',
            ),
            CustomExpansionTile(
              title: 'How do I contact customer support?',
              content: 'If you have any questions or issues, please feel free to reach out to melindafromflorida@gmail.com. If it is urgent or of high priority, please contact Kashif or Sonny Shaikh. Their numbers are listed higher on the page.',
            ),
            CustomExpansionTile(
              title: 'How do I update my personal information?',
              content: 'To update your personal information, including changing your email and password, go to the settings page, under the "Security" section. If there is anything that seems incorrect about your personal information, please reach out to melindafromflorida@gmail.com.',
            ),
            CustomExpansionTile(
              title: 'What happens if my phone is lost or stolen?',
              content: 'The app requires a PIN or Face ID for access, so it should be secure. However, if you believe that the app may still be accessible, we can temporarily disable your account for your safety.',
            ),
            CustomExpansionTile(
              title: 'Can I export my financial data?',
              content: 'Yes, you can export your financial data. Go to the settings page and look for the "Export Data" option. Follow the instructions to export your data in a suitable format.',
            ),

            SizedBox(height: 20),
          
          ],
        ),
      ],      
    ),
    
  );

}
