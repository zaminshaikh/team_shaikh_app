import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void signUserOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Navigate to the login screen and clear the existing routes
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  int selectedIndex = 0;
  List<IconData> data = [
    Icons.home_outlined,
    Icons.search,
    Icons.add_box_outlined,
    Icons.person_outline_sharp
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 37, 58, 86),
        toolbarHeight: 90,
        title: const Row(
          children: [
            SizedBox(width: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                children: [
                  GestureDetector(
                    onTap: () => signUserOut(context),
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color:  const Color.fromARGB(255, 149, 28, 28),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Center(
                        child: Text(
                          "Logout",
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 50, right: 20, left: 20),
        height: 80,
        padding: const EdgeInsets.only(right: 30, left: 30),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 37, 58, 86),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            data.length,
            (i) => GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = i;
                });

                if (data[i] == Icons.search) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const AnalyticsPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return child;
                      },
                    ),
                  );
                }

                if (data[i] == Icons.home_outlined) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return child;
                      },
                    ),
                  );
                }

                if (data[i] == Icons.add_box_outlined) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const ActivityPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return child;
                      },
                    ),
                  );
                }

                if (data[i] == Icons.person_outline_sharp) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return child;
                      },
                    ),
                  );
                }
              },
              child: Icon(
                data[i],
                size: 35,
                color: data[i] == Icons.person_outline_sharp ? Colors.white : Colors.blueGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
