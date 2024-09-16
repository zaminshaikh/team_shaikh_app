import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/assets_model.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/screens/authenticate/app_state.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import 'package:intl/intl.dart';

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
    if (client == null) {
      return const CustomProgressIndicator();
    }

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
                      if (client!.connectedUsers != null &&
                          client!.connectedUsers!.isNotEmpty)
                        SlideTransition(
                          position: _offsetAnimation,
                          child: Row(
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
                        ),
                      if (client!.connectedUsers != null &&
                          client!.connectedUsers!.isNotEmpty)
                        const SizedBox(height: 20),
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

  String _currencyFormat(double amount) => NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 2,
        locale: 'en_US',
      ).format(amount);

  SliverAppBar _buildAppBar() => SliverAppBar(
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
                      'Welcome Back, ${client!.firstName} ${client!.lastName}!',
                      style: const TextStyle(
                        fontSize: 23,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Client ID: ${client!.cid}',
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
                                color: Colors.transparent,
                                width: 0.3,
                              ),
                              shape: BoxShape.rectangle,
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
                            // child: client!.unreadNotificationsCount > 0
                            child: 0 > 0
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF267DB5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    // ignore: prefer_const_constructors
                                    child: Text(
                                      '${0}',
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

  Widget _buildTotalAssetsSection() => Stack(
        children: [
          Container(
            width: 400,
            height: 160,
            padding: const EdgeInsets.only(left: 12, top: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3199DD),
                  Color.fromARGB(255, 13, 94, 175),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              image: const DecorationImage(
                image: AssetImage('assets/icons/total_assets_gradient.png'),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Total Assets',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat(client!.assets?.totalAssets ?? 0),
                      style: const TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/YTD.svg',
                          height: 13,
                          color: const Color.fromRGBO(74, 222, 128, 1),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _currencyFormat(client!.ytd ?? 0),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              icon: const Icon(Icons.info_outline_rounded,
                  color: Color.fromARGB(71, 255, 255, 255)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    backgroundColor: AppColors.defaultBlueGray800,
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: <Widget>[
                                Text('What is',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(width: 5),
                                SvgPicture.asset(
                                  'assets/icons/YTD.svg',
                                  height: 20,
                                ),
                                const SizedBox(width: 5),
                                Text('?',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                              ],
                            ),
                          ),
                          const Text(
                              'YTD stands for Year-To-Date. It is a financial term that describes the amount of income accumulated over the period of time from the beginning of the current year to the present date.'),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: <Widget>[
                                Text('What are my total assets?',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                              ],
                            ),
                          ),
                          const Text(
                              'Total assets are the sum of all assets in your account, including the assets of your connected users. This includes all IRAs, Nuview Cash, and assets in both AGQ and AK1.'),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 30, 75, 137),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Continue',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _buildUserBreakdownSection() {
    // Initialize empty lists for the tiles
    List<ListTile> assetTilesAGQ = [];
    List<ListTile> assetTilesAK1 = [];
    for (var fundEntry in client!.assets!.funds.entries) {
      String fundName = fundEntry.key;
      Fund fund = fundEntry.value;

      // Iterate through each field in the fund
      fund.toMap().forEach((fieldName, amount) {
        if (amount != 0) {
          switch (fundName) {
            case 'AGQ':
              assetTilesAGQ.add(_buildAssetTile(
                  fieldName, amount.toDouble(), 'AGQ',
                  companyName: client!.companyName));
              break;
            case 'AK1':
              assetTilesAK1.add(_buildAssetTile(
                  fieldName, amount.toDouble(), 'AK1',
                  companyName: client!.companyName,));
              break;
            default:
              break;
          }
        }
      });
    }

    // Sort tiles in order specified in _getAssetTileIndex
    assetTilesAGQ.sort((a, b) => _getAssetTileIndex((a.title as Text).data!,
            companyName: client!.companyName)
        .compareTo(_getAssetTileIndex((b.title as Text).data!,
            companyName: client!.companyName)));
    assetTilesAK1.sort((a, b) => _getAssetTileIndex((a.title as Text).data!,
            companyName: client!.companyName)
        .compareTo(_getAssetTileIndex((b.title as Text).data!,
            companyName: client!.companyName)));

    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent, // removes splash effect
      ),
      child: Container(
        color: const Color.fromARGB(255, 17, 24, 39),
        child: ExpansionTile(
          title: Row(
            children: [
              Text(
                '${client!.firstName} ${client!.lastName}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
              const SizedBox(width: 10),
              SvgPicture.asset(
                'assets/icons/YTD.svg',
                height: 13,
              ),
              const SizedBox(width: 5),
              Text(
                _currencyFormat(client!.ytd ?? 0),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
          subtitle: Text(
            _currencyFormat(client!.totalAssets ?? 0),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
          maintainState: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide.none,
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide.none,
          ),
          collapsedBackgroundColor: const Color.fromARGB(255, 30, 41, 59),
          backgroundColor: const Color.fromARGB(255, 30, 41, 59),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  left: 25.0, right: 25.0, bottom: 10.0, top: 10.0),
              child: Divider(color: Colors.grey[300]),
            ),
            Column(
              children: assetTilesAK1,
            ),
            Column(
              children: assetTilesAGQ,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedUsersSection() => Column(
        children: client!.connectedUsers!.map((connectedUser) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConnectedUserBreakdownSection(connectedUser!),
              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      );

  Widget _buildConnectedUserBreakdownSection(Client connectedUser) {
    // Initialize empty lists for the tiles
    List<ListTile> assetTilesAGQ = [];
    List<ListTile> assetTilesAK1 = [];

for (var fundEntry in connectedUser.assets!.funds.entries) {
      String fundName = fundEntry.key;
      Fund fund = fundEntry.value;

      // Iterate through each field in the fund
      fund.toMap().forEach((fieldName, amount) {
        if (amount != 0) {
          switch (fundName) {
            case 'AGQ':
              assetTilesAGQ.add(_buildAssetTile(
                  fieldName, amount.toDouble(), 'AGQ',
                  companyName: connectedUser.companyName));
              break;
            case 'AK1':
              assetTilesAK1.add(_buildAssetTile(
                  fieldName, amount.toDouble(), 'AK1',
                  companyName: connectedUser.companyName));
              break;
            default:
              break;
          }
        }
      });
    }

    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent, // removes splash effect
      ),
      child: Container(
        color: const Color.fromARGB(255, 17, 24, 39),
        child: ExpansionTile(
          title: Row(
            children: [
              Text(
                '${connectedUser.firstName} ${connectedUser.lastName}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
              const SizedBox(width: 10),
              SvgPicture.asset(
                'assets/icons/YTD.svg',
                height: 13,
              ),
              const SizedBox(width: 5),
              Text(
                _currencyFormat(connectedUser.ytd ?? 0),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
          subtitle: Text(
            _currencyFormat(connectedUser.totalAssets ?? 0),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
          maintainState: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.white),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.white),
          ),
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  left: 25.0, right: 25.0, bottom: 10.0, top: 10.0),
              child: Divider(color: Colors.grey[300]),
            ),
            Column(
              children: assetTilesAK1,
            ),
            Column(
              children: assetTilesAGQ,
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildAssetTile(String fieldName, double amount, String fund,
      {String? companyName}) {
    String sectionName = '';
    switch (fieldName) {
      case 'nuviewTrad':
        sectionName = 'Nuview Cash IRA';
        break;
      case 'nuviewRoth':
        sectionName = 'Nuview Cash Roth IRA';
        break;
      case 'nuviewSepIRA':
        sectionName = 'Nuview Cash SEP IRA';
        break;
      case 'roth':
        sectionName = 'Roth IRA';
        break;
      case 'trad':
        sectionName = 'Traditional IRA';
        break;
      case 'sep':
        sectionName = 'SEP IRA';
        break;
      case 'personal':
        sectionName = 'Personal';
        break;
      case 'company':
        try {
          sectionName = companyName!;
        } catch (e) {
          log('dashboard.dart: Error building asset tile for company: $e');
          sectionName = '';
        }
        break;
      default:
        sectionName = fieldName;
    }

    Widget leadingIcon;
    if (fund == 'AGQ') {
      leadingIcon = SvgPicture.asset('assets/icons/agq_logo.svg');
    } else if (fund == 'AK1') {
      leadingIcon = SvgPicture.asset('assets/icons/ak1_logo.svg');
    } else {
      leadingIcon = const Icon(Icons.account_balance, color: Colors.white);
    }

    return ListTile(
      leading: leadingIcon,
      title: Text(
        sectionName,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Titillium Web',
        ),
      ),
      trailing: Text(
        _currencyFormat(amount),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'Titillium Web',
        ),
      ),
    );
  }

  int _getAssetTileIndex(String name, {String? companyName}) {
    if (name == companyName) {
      return 1;
    }
    switch (name) {
      case 'Personal':
        return 0;
      case 'Traditional IRA':
        return 2;
      case 'Nuview Cash IRA':
        return 3;
      case 'Roth IRA':
        return 4;
      case 'Nuview Cash Roth IRA':
        return 5;
      case 'SEP IRA':
        return 6;
      case 'Nuview Cash SEP IRA':
        return 7;
      default:
        return -1;
    }
  }

  Widget _buildAssetsStructureSection() {
    // double totalAGQ = client!.totalAGQ;
    double totalAGQ = 0;

    // double totalAK1 = client!.totalAK1;
    double totalAK1 = 0;
    
    
    // double totalAssets = client!.totalAssets;
    double totalAssets = client!.assets?.totalAssets ?? 0;
    
    double percentageAGQ = totalAGQ / totalAssets * 100;
    double percentageAK1 = totalAK1 / totalAssets * 100;

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 41, 59),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Row(
            children: [
              SizedBox(width: 5),
              Text(
                'Assets Structure',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
              )
            ],
          ),
          const SizedBox(height: 60),
          Container(
            width: 250,
            height: 250,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 120,
                    centerSpaceRadius: 100,
                    sectionsSpace: 10,
                    sections: [
                      if (percentageAGQ > 0)
                        PieChartSectionData(
                          color: const Color.fromARGB(255, 12, 94, 175),
                          radius: 25,
                          value: percentageAGQ,
                          showTitle: false,
                        ),
                      if (percentageAK1 > 0)
                        PieChartSectionData(
                          color: const Color.fromARGB(255, 49, 153, 221),
                          radius: 25,
                          value: percentageAK1,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      Text(
                        _currencyFormat(client!.totalAssets ?? 0),
                        style: const TextStyle(
                          fontSize: 22,
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
          const SizedBox(height: 30),
          if (percentageAGQ > 0 || percentageAK1 > 0) ...[
            const Row(
              children: [
                SizedBox(width: 30),
                Text(
                  'Type',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 216, 216, 216),
                    fontFamily: 'Titillium Web',
                  ),
                ),
                Spacer(),
                Text(
                  '%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 216, 216, 216),
                    fontFamily: 'Titillium Web',
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 5),
            const Divider(
              thickness: 1.2,
              height: 1,
              color: Color.fromARGB(255, 102, 102, 102),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                if (percentageAGQ > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 20,
                        color: Color.fromARGB(255, 12, 94, 175),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AGQ Fund',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${percentageAGQ.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                if (percentageAGQ > 0 && percentageAK1 > 0)
                  const SizedBox(height: 20),
                if (percentageAK1 > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 20,
                        color: Color.fromARGB(255, 49, 153, 221),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AK1 Fund',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${percentageAK1.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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
