import 'package:flutter/material.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
      backgroundColor: Color.fromARGB(255, 17, 24, 39),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'No Internet Connection',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Please connect to Wi-Fi first',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
}
