
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/authenticate/app_state.dart';
import 'package:team_shaikh_app/database/newdb.dart'; 

int unreadNotificationsCount = 0;

class DashboardPage extends StatefulWidget {
  final bool fromFaceIdPage;

  const DashboardPage({super.key, this.fromFaceIdPage = false});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  // database service instance
  DatabaseService? _databaseService;
  AppState? appState;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();

    // Initialize the transition state
    _initializeTransitionState();

    // Initialize appState if it's null
    appState ??= AppState();

    // Check if hasNavigatedToFaceIDPage is null and set it to false if it is
    if (appState?.hasNavigatedToFaceIDPage == null) {
      appState?.setHasNavigatedToFaceIDPage(false);
    }

    if (widget.fromFaceIdPage) {
      appState?.setHasNavigatedToFaceIDPage(false);
      appState?.setJustAuthenticated(true);
    } else {}
    _initData();
  }
  void dispose() {
    _controller.dispose(); // Dispose of the animation controller
    super.dispose();
  }

  Future<void> _initializeTransitionState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _hasTransitioned = prefs.getBool('hasTransitioned') ?? false;
  
    if (!_hasTransitioned) {
      _controller = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..forward();
      _offsetAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
  
      // Set the flag to true after the animation completes
      _controller.addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          _hasTransitioned = true;
          await prefs.setBool('hasTransitioned', true);
        }
      });
    } else {
      _controller = AnimationController(
        duration: Duration.zero,
        vsync: this,
      );
      _offsetAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset.zero,
      ).animate(_controller);
    }
  }

  Future<void> _initData() async {
    await Future.delayed(const Duration(seconds: 1));

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null && mounted) {
      log('dashboard.dart: User is not logged in');
      await Navigator.pushReplacementNamed(context, '/login');
    }

    DatabaseService? service = await DatabaseService.fetchCID(context, user!.uid, 1);
    if (service == null && mounted) {
      await Navigator.pushReplacementNamed(context, '/login');
    } else {
      _databaseService = service!;
    }
  }



  @override
  Widget build(BuildContext context) {
    print('DASHBOARD');
    // Access the Client data from the StreamProvider
    Client? client = Provider.of<Client?>(context) ;

    client?.graphPoints?.forEach((element) {print(element.toMap());});

    // If the client is null, show a loading indicator
    if (client == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If the client is not null, display the data
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${client.firstName} ${client.lastName}'),
            Text('Company: ${client.companyName}'),
            Text('Total Assets: \$${client.totalAssets}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleButtonPress, // Example action handler
              child: const Text('Refresh Data'),
            ),
            // Add more client-related data and actions here
          ],
        ),
      ),
    );
  }

  // Example action method to demonstrate state changes
  void _handleButtonPress() {
    setState(() {
      // You can modify the state or trigger actions here that will re-render the widget
      // For example, you might want to fetch some additional data or update a UI element
      // The state will be updated and the UI will refresh when setState is called
    });
  }
}