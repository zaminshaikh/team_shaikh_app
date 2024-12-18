import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_shaikh_app/components/custom_bottom_navigation_bar.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/authenticate/utils/app_state.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAppLockState();
    // Initialize the animation controller and set its value to 1.0 by default
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..value = 1.0; // Animation is at the end by default

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5), // Start position (offset)
      end: Offset.zero, // End position (no offset)
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

  Future<void> _loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('isAppLockEnabled') ?? false;
    context.read<AuthState>().setAppLockEnabled(isEnabled);
    print('Loaded app lock state: $isEnabled');
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

  /// Initializes the transition state and handles the animation logic.
  Future<void> _initializeTransitionState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasTransitioned = prefs.getBool('hasTransitioned') ?? false;

    if (!hasTransitioned) {
      // Reset controller to start of animation
      _controller.value = 0.0;

      // Start the animation
      await _controller.forward().whenComplete(() async {
        // Set the flag to true after the animation completes
        await prefs.setBool('hasTransitioned', true);
      });
    } else {
      // Animation has already been shown; controller remains at end
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
                      // const SizedBox(height: 32),
                      // // Recent text
                      // SlideTransition(
                      //   position: _offsetAnimation,
                      //   child: _buildRecentText(),
                      // ),
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


  // Widget _buildRecentText() {
  //   print('Building Recent Text Section');
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         '3 Recent Transactions',
  //         style: TextStyle(
  //           fontSize: 20,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.white,
  //           fontFamily: 'Titillium Web',
  //         ),
  //       ),
  //       SizedBox(height: 20.0),
  //       _buildActivityCard(),
  //       SizedBox(height: 20.0),
  //       Row(
  //         children: [
  //           Text(
  //             'View all transactions',
  //             style: TextStyle(
  //               fontSize: 18,
  //               color: Colors.blue,
  //               fontFamily: 'Titillium Web',
  //             ),
  //           ),
  //           SizedBox(width: 8.0),
  //           Icon(
  //             Icons.arrow_forward_ios,
  //             color: Colors.blue,
  //             size: 18.0,
  //           ),
  //         ],
  //       ),
        


  //     ],
  //   );
  // }
  



  // Widget _buildActivityCard() {
  //   return FractionallySizedBox(
  //     widthFactor: 3/5,
  //     child: Container(
  //       padding: EdgeInsets.all(16.0),
  //       decoration: BoxDecoration(
  //         color: Colors.transparent,
  //         borderRadius: BorderRadius.circular(12.0),
  //         border: Border.all(color: Colors.white, width: 2.0),
  //       ),
  //       child: Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Title',
  //                   style: TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.white,
  //                     fontFamily: 'Titillium Web',
  //                   ),
  //                 ),
  //                 SizedBox(height: 4.0),
  //                 Text(
  //                   'Subtitle',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     color: Colors.white70,
  //                     fontFamily: 'Titillium Web',
  //                   ),
  //                 ),
  //                 SizedBox(height: 16.0),
  //                 Text(
  //                   '\$123.45',
  //                   style: TextStyle(
  //                     fontSize: 24,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.white,
  //                     fontFamily: 'Titillium Web',
  //                   ),
  //                 ),
  //                 SizedBox(height: 16.0),
  //                 Text(
  //                   'Date: January 1, 2023',
  //                   style: TextStyle(
  //                     fontSize: 12,
  //                     color: Colors.white70,
  //                     fontFamily: 'Titillium Web',
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           CircleAvatar(
  //             radius: 24.0,
  //             backgroundColor: Colors.white,
  //             child: Icon(
  //               Icons.attach_money,
  //               color: Colors.blue,
  //               size: 24.0,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }


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
