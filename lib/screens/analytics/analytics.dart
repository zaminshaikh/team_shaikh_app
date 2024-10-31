// analytics_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:team_shaikh_app/components/assets_structure_section.dart';
import 'package:team_shaikh_app/components/custom_bottom_navigation_bar.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/analytics/components/analytics_app_bar.dart';
import 'package:team_shaikh_app/screens/analytics/components/line_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);
  @override
  AnalyticsPageState createState() => AnalyticsPageState();
}

class AnalyticsPageState extends State<AnalyticsPage> {
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
              AnalyticsAppBar(
                client: client!,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // Line chart section
                      LineChartSection(client: client!),
                      // Pie chart section
                      AssetsStructureSection(client: client!),
                      const SizedBox(height: 120),

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
                currentItem: NavigationItem.analytics),
          ),
        ],
      ),
    );
  }
}
