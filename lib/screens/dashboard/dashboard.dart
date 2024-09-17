import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_shaikh_app/components/custom_bottom_navigation_bar.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/authenticate/app_state.dart';
import 'package:team_shaikh_app/components/assets_structure_section.dart';
import 'package:team_shaikh_app/screens/dashboard/components/dashboard_app_bar.dart';
import 'package:team_shaikh_app/screens/dashboard/components/total_assets_section.dart';
import 'package:team_shaikh_app/screens/dashboard/components/user_breakdown_section.dart';

class DashboardPage extends StatefulWidget {
  final bool fromFaceIdPage;

  const DashboardPage({super.key, this.fromFaceIdPage = false});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  AuthState? authState;
  Client? client;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller and offset animation synchronously
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

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
    // Initialize our authState if it's null
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
      // Start the animation
      _controller.forward();

      // Set the flag to true after the animation completes
      _controller.addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          _hasTransitioned = true;
          await prefs.setBool('hasTransitioned', true);
        }
      });
    } else {
      // If already transitioned, jump to the end of the animation
      _controller.value = 1.0;
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
    if (client == null) {
      return const CustomProgressIndicatorPage();
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              DashboardAppBar(client: client!),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // Total assets section
                      SlideTransition(
                        position: _offsetAnimation,
                        child: TotalAssetsSection(client: client!),
                      ),
                      const SizedBox(height: 32),
                      // User breakdown section
                      SlideTransition(
                        position: _offsetAnimation,
                        child: UserBreakdownSection(client: client!),
                      ),
                      if (client!.connectedUsers != null &&
                          client!.connectedUsers!.isNotEmpty)
                        SlideTransition(
                          position: _offsetAnimation,
                          child: _buildConnectedUsersSection(),
                        ),
                      const SizedBox(height: 32),
                      // Assets structure section
                      SlideTransition(
                        position: _offsetAnimation,
                        child: AssetsStructureSection(client: client!),
                      ),
                      const SizedBox(height: 132),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigationBar(
                currentItem: NavigationItem.dashboard),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedUsersSection() => Column(
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              const Text(
                'Connected Users',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
              ),
              const Spacer(),
              Text(
                '(${client!.connectedUsers?.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: client!.connectedUsers!
                .map(
                  (connectedUser) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserBreakdownSection(
                        client: connectedUser!,
                        isConnectedUser: true,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      );
}
