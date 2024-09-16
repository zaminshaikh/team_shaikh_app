import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/authenticate/app_state.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';

class DashboardPage extends StatefulWidget {
  final bool fromFaceIdPage;

  const DashboardPage({super.key, this.fromFaceIdPage = false});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  AuthState? authState;
  Client? client;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();
    // Initialize the transition state
    _initializeTransitionState();
    // Initialize the auth state and update the state
    _updateAuthState();
    // Validate whether the user is authenticated
    _validateAuth();
  }


  @override
  void dispose() {
    _controller.dispose(); // Dispose of the animation controller
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    client = Provider.of<Client?>(context);
  }

  void _updateAuthState() {
    // Initialize our  if it's null
    authState ??= AuthState();

    // Check if hasNavigatedToFaceIDPage is null and set it to false if it is
    if (authState?.hasNavigatedToFaceIDPage == null) {
      authState?.setHasNavigatedToFaceIDPage(false);
    }

    if (widget.fromFaceIdPage) {
      authState?.setHasNavigatedToFaceIDPage(false);
      authState?.setJustAuthenticated(true);
    } else {}
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

  Future<void> _validateAuth() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null && mounted) {
      log('dashboard.dart: User is not logged in');
      await Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the client is null, show a loading indicator
    if (client == null) {
      return const CustomProgressIndicator();
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
            Text('Welcome, ${client!.firstName} ${client!.lastName}'),
            Text('Company: ${client!.companyName}'),
            Text('Total Assets: \$${client!.totalAssets}'),
            const SizedBox(height: 20),
            // Add more client-related data and actions here
          ],
        ),
      ),
    );
  }

  // ignore: prefer_expression_function_bodies
  Scaffold _dashboard() {

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // Total assets section
                      SlideTransition(
                        position: _offsetAnimation,
                        child: _buildTotalAssetsSection(),
                      ),
                      const SizedBox(height: 32),
                      // User breakdown section
                      SlideTransition(
                        position: _offsetAnimation,
                        child: _buildUserBreakdownSection(),
                      ),
                      const SizedBox(height: 40),
                      SlideTransition(
                        position: _offsetAnimation,
                        child: Row(
                          children: [
                            Text(
                              'Connected Users',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                            Spacer(),
                            Text(
                              '(${client?.connectedUsers?.length})',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SlideTransition(
                        position: _offsetAnimation,
                        child:
                            _buildConnectedUsersSection(),
                      ),
                      const SizedBox(height: 32),
                      // Assets structure section
                      SlideTransition(
                        position: _offsetAnimation,
                        child: _buildAssetsStructureSection(),
                      ),
                      const SizedBox(height: 132),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(context),
          ),
        ],
      ),
    );
  
  }


  SliverAppBar _buildAppBar() =>
    SliverAppBar(
      backgroundColor: const Color.fromARGB(255, 30, 41, 59),
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      expandedHeight: 0,
      snap: false,
      floating: true,
      pinned: true,
      flexibleSpace: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back, ${client?.firstName} ${client?.lastName}!',
                    style: const TextStyle(
                      fontSize: 23,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Client ID: ${client?.cid}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
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
          padding: const EdgeInsets.only(right: 5.0, bottom: 5.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
            child: Container(
              color: const Color.fromRGBO(239, 232, 232, 0),
              padding: const EdgeInsets.all(10.0),
              child: ClipRect(
                child: Stack(
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors
                                  .transparent, // Change this color to the one you want
                              width: 0.3, // Adjust width to your need
                            ),
                            shape: BoxShape
                                .rectangle, // or BoxShape.rectangle if you want a rectangle
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/bell.svg',
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn),
                              height: 32,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 5,
                          child: unreadNotificationsCount > 0
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF267DB5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '$unreadNotificationsCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Titillium Web',
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Container(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

  Widget _buildBottomNavigationBar(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 30, right: 20, left: 20),
        height: 80,
        padding: const EdgeInsets.only(right: 10, left: 10),
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
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                color: const Color.fromRGBO(239, 232, 232, 0),
                padding: const EdgeInsets.all(20.0),
                child: SvgPicture.asset(
                  'assets/icons/dashboard_filled.svg',
                  height: 22,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const AnalyticsPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            child,
                  ),
                );
              },
              child: Container(
                color: const Color.fromRGBO(239, 232, 232, 0),
                padding: const EdgeInsets.all(20.0),
                child: SvgPicture.asset(
                  'assets/icons/analytics_hollowed.svg',
                  height: 25,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const ActivityPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            child,
                  ),
                );
              },
              child: Container(
                color: const Color.fromRGBO(239, 232, 232, 0),
                padding: const EdgeInsets.all(20.0),
                child: SvgPicture.asset(
                  'assets/icons/activity_hollowed.svg',
                  height: 22,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const ProfilePage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            child,
                  ),
                );
              },
              child: Container(
                color: const Color.fromRGBO(239, 232, 232, 0),
                padding: const EdgeInsets.all(20.0),
                child: SvgPicture.asset(
                  'assets/icons/profile_hollowed.svg',
                  height: 22,
                ),
              ),
            ),
          ],
        ),
      );

}
