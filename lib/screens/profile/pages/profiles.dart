// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _ProfilesPageState createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  Client? client;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    client = Provider.of<Client?>(context);
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
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.all(0.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _profilesForUser(),
                      if (client!.connectedUsers != null &&
                          client!.connectedUsers!.isNotEmpty)
                        _profilesForConnectedUser()
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// This is the Profiless section
  Container _profilesForUser() => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
    child: Column(
      children: [
        const Row(
          children: [
            Text(
              'My Profiles', 
              style: TextStyle(
                fontSize: 22,
                color: Color.fromRGBO(255, 255, 255, 1),
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        clientCard(client!),

      ],
    ),
  
  );

// This is the Profiless section
  Container _profilesForConnectedUser() {
    if (client!.connectedUsers == null || client!.connectedUsers!.isEmpty) {
      return Container();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'Connected Users',
                style: TextStyle(
                  fontSize: 22,
                  color: Color.fromRGBO(255, 255, 255, 1),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
          ListView.builder(
            padding: const EdgeInsets.only(top: 20),
            itemCount: client!.connectedUsers!.length,
            itemBuilder: (context, index) {
              return 
              Column(
                children: [
                  clientCard(client!.connectedUsers![index]!),
                  const SizedBox(height: 20),
                ],
              );
            },
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ],
      ),
    );
  }

  Widget clientCard(Client c) => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10), 
            border: Border.all(color: Colors.white, width: 1), // Add this line
          ),
          
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.firstName} ${c.lastName}', 
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Client ID: ${c.cid}', 
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontFamily: 'Titillium Web',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'First Deposit Date: ${c.firstDepositDate.toString()}', // Assuming firstDepositDate is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Communication Email: ${c.initEmail}', // Assuming initEmail is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Phone Number: ${c.phoneNumber}', // Assuming phoneNumber is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Address: ${c.address}', // Assuming address is a String variable
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ],
            ),
          ),
        );

  // This is the app bar
  SliverAppBar _buildAppBar(context) => SliverAppBar(
        backgroundColor: const Color.fromARGB(255, 30, 41, 59),
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        expandedHeight: 0,
        snap: false,
        floating: true,
        pinned: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: const SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 60.0, right: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profiles',
                  style: TextStyle(
                    fontSize: 27,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
