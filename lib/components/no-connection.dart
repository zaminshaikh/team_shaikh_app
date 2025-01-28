import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';
import 'package:team_shaikh_app/screens/authenticate/utils/app_state.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  Future<void> _reload(BuildContext context) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      print('Reload button pressed');
      final authState = Provider.of<AuthState>(context, listen: false);
      authState.setForceDashboard(true);
      Phoenix.rebirth(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text('Please check your internet connection and try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
