import 'package:flutter/material.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  void _reload(BuildContext context) {
    // Implement your reload logic here
    print('Reload button pressed');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 24, 39),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'No Internet Connection',
              style: TextStyle(
                color: Colors.white, 
                fontSize: 20,
                fontFamily: 'Titillium Web',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please connect to Wi-Fi first',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Titillium Web',
                ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _reload(context),
              child: const Text('Reload'),
            ),
          ],
        ),
      ),
    );
}
