import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import 'package:intl/intl.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);
  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  int selectedIndex = 0;
  List<String> data = [
    'assets/icons/dashboard_hollowed.png',
    'assets/icons/analytics_hollowed.png',
    'assets/icons/activity_filled.png',
    'assets/icons/profile_hollowed.png',
  ];


  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(
      slivers: <Widget>[
        const SliverAppBar(
          backgroundColor: Color.fromARGB(255, 30, 41, 59),
          automaticallyImplyLeading: false,
          expandedHeight: 80,
          floating: true,
          snap: true,
          pinned: true,
          flexibleSpace: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 20.0, right: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity',
                        style: TextStyle(
                          fontSize: 23,
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
              padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 10.0),
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              Column(
                children: [

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search by title',
                                hintStyle: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Titillium Web',
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.filter_list, color: Colors.white),
                            onPressed: () {
                              // Implement your filter functionality here
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.sort, color: Colors.white),
                            onPressed: () {
                              // Implement your sort functionality here
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Container(
                    height: 40.0, // Make the buttons a little shorter
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        const SizedBox(width: 20.0), // Add some space before the first button
                        ElevatedButton(
                          child: const Text(
                            'All',
                            style: TextStyle(
                              fontFamily: 'Titillium Web',
                              color: Colors.white, // Make the text white
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.transparent,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          onPressed: () {
                            // Implement your button functionality here
                          },
                        ),
                        const SizedBox(width: 10.0), // Add some space between the buttons
                        ElevatedButton(
                          child: const Text(
                            'John Doe',
                            style: TextStyle(
                              fontFamily: 'Titillium Web',
                              color: Colors.white, // Make the text white
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.transparent,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          onPressed: () {
                            // Implement your button functionality here
                          },
                        ),
                        const SizedBox(width: 10.0), // Add some space between the buttons
                        ElevatedButton(
                          child: const Text(
                            'Jane Doe',
                            style: TextStyle(
                              fontFamily: 'Titillium Web',
                              color: Colors.white, // Make the text white
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.transparent,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          onPressed: () {
                            // Implement your button functionality here
                          },
                        ),
                        const SizedBox(width: 10.0), // Add some space between the buttons
                        ElevatedButton(
                          child: const Text(
                            'Kristen Watson',
                            style: TextStyle(
                              fontFamily: 'Titillium Web',
                              color: Colors.white, // Make the text white
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.transparent,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          onPressed: () {
                            // Implement your button functionality here
                          },
                        ),
                        const SizedBox(width: 10.0), // Add some space between the buttons
                        ElevatedButton(
                          child: const Text(
                            'Floyd Miles',
                            style: TextStyle(
                              fontFamily: 'Titillium Web',
                              color: Colors.white, // Make the text white
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.transparent,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          onPressed: () {
                            // Implement your button functionality here
                          },
                        ),
                        const SizedBox(width: 20.0), // Add some space after the last button
                        // Add more buttons as needed
                      ],
                    ),                  
                  ),
                
                const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Aligns the children to the left
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'November 11',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container( // Container for the list of activities
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: Color.fromARGB(255, 19, 66, 105),
                                        size: 50,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AGQ Consulting LLC',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Fixed Income',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '\$1,000.00',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Titillium Web',
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Text(
                                                '2:27 PM',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Container(
                                                height: 15, // You can adjust the height as needed
                                                child: VerticalDivider(
                                                  color: Colors.white,
                                                  width: 1,
                                                  thickness: 1,
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Text(
                                                'John Doe',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Divider(
                                    color: const Color.fromARGB(255, 132, 132, 132),
                                    thickness: 1,
                                  ), // Add a divider between the activities

                                  const SizedBox(height: 20),
                                  
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: Color.fromARGB(255, 19, 66, 105),
                                        size: 50,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AGQ Consulting LLC',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Fixed Income',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '\$1,000.00',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Titillium Web',
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Text(
                                                '2:27 PM',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Container(
                                                height: 15, // You can adjust the height as needed
                                                child: VerticalDivider(
                                                  color: Colors.white,
                                                  width: 1,
                                                  thickness: 1,
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Text(
                                                'John Doe',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Divider(
                                    color: const Color.fromARGB(255, 132, 132, 132),
                                    thickness: 1,
                                  ), // Add a divider between the activities

                                  const SizedBox(height: 20),
                                  
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: Color.fromARGB(255, 19, 66, 105),
                                        size: 50,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AGQ Consulting LLC',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Fixed Income',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '\$1,000.00',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Titillium Web',
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Text(
                                                '2:27 PM',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Container(
                                                height: 15, // You can adjust the height as needed
                                                child: VerticalDivider(
                                                  color: Colors.white,
                                                  width: 1,
                                                  thickness: 1,
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Text(
                                                'John Doe',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Divider(
                                    color: const Color.fromARGB(255, 132, 132, 132),
                                    thickness: 1,
                                  ), // Add a divider between the activities

                                  const SizedBox(height: 20),
                                  
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: Color.fromARGB(255, 19, 66, 105),
                                        size: 50,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AGQ Consulting LLC',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Fixed Income',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '\$1,000.00',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Titillium Web',
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Text(
                                                '2:27 PM',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Container(
                                                height: 15, // You can adjust the height as needed
                                                child: VerticalDivider(
                                                  color: Colors.white,
                                                  width: 1,
                                                  thickness: 1,
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Text(
                                                'John Doe',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Divider(
                                    color: const Color.fromARGB(255, 132, 132, 132),
                                    thickness: 1,
                                  ), // Add a divider between the activities

                                  const SizedBox(height: 20),
                                  
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: Color.fromARGB(255, 19, 66, 105),
                                        size: 50,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AGQ Consulting LLC',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Fixed Income',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '\$1,000.00',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Titillium Web',
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Text(
                                                '2:27 PM',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Container(
                                                height: 15, // You can adjust the height as needed
                                                child: VerticalDivider(
                                                  color: Colors.white,
                                                  width: 1,
                                                  thickness: 1,
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Text(
                                                'John Doe',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Divider(
                                    color: const Color.fromARGB(255, 132, 132, 132),
                                    thickness: 1,
                                  ), // Add a divider between the activities

                                  const SizedBox(height: 20),
                                  
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: Color.fromARGB(255, 19, 66, 105),
                                        size: 50,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AGQ Consulting LLC',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Fixed Income',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '\$1,000.00',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Titillium Web',
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Text(
                                                '2:27 PM',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Container(
                                                height: 15, // You can adjust the height as needed
                                                child: VerticalDivider(
                                                  color: Colors.white,
                                                  width: 1,
                                                  thickness: 1,
                                                ),
                                              ),
                                              SizedBox(width: 7), // Add width
                                              Text(
                                                'John Doe',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Titillium Web',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Divider(
                                    color: const Color.fromARGB(255, 132, 132, 132),
                                    thickness: 1,
                                  ), // Add a divider between the activities

                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),

    bottomNavigationBar: Container(
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
              i == selectedIndex && data[i] == 'assets/icons/dashboard_hollowed.png'
                ? 'assets/icons/dashboard_hollowed.png'
                : data[i],
              height: 50,
            ),       
          ),
        ),
      ),    
    ),
        
  );
  
}

