import 'package:flutter/material.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {

  int selectedIndex = 0;
  List<String> data = [
    'assets/icons/dashboard_hollowed.png',
    'assets/icons/analytics_hollowed.png',
    'assets/icons/activity_hollowed.png',
    'assets/icons/profile_hollowed.png',
  ];


  @override
  Widget build(BuildContext context) => Scaffold(
      
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 37, 58, 86),
        toolbarHeight: 90,
        title:          
          const Row(
            children: [
              SizedBox(width: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Analytics',
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

      body: const Padding(
        padding: EdgeInsets.all(16.0),


      ),

      bottomNavigationBar: 
  Container(
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
      children: List.generate(
        data.length,
        (i) => GestureDetector(
          onTap: () {
            setState(() {
              selectedIndex = i;
            });

            if (data[i] == 'assets/icons/analytics_hollowed.png') {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const AnalyticsPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            }

            if (data[i] == 'assets/icons/dashboard_hollowed.png') {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            }

            if (data[i] == 'assets/icons/activity_hollowed.png') {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ActivityPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            }

            if (data[i] == 'assets/icons/profile_hollowed.png') {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            }

          },

          child: Image.asset(
            i == selectedIndex && data[i] == 'assets/icons/analytics_hollowed.png'
              ? 'assets/icons/analytics_filled.png'
              : data[i],
            height: 50,
          ),       
        ),
      ),
    ),    
  )
  

          
    );
}

