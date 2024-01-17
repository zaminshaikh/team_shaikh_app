import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 7, 26, 59),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 43, 93),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 40,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Titillium Web',
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      
      
    );
  }
}

