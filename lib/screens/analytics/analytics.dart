// analytics_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:team_shaikh_app/components/alert_dialog.dart';
import 'package:team_shaikh_app/components/assets_structure_section.dart';
import 'package:team_shaikh_app/components/custom_bottom_navigation_bar.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/assets_model.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/database/models/graph_point_model.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/analytics/utils/timeline.dart';
import 'package:team_shaikh_app/screens/analytics/utils/analytics_utilities.dart';
import 'package:team_shaikh_app/screens/notifications/notifications.dart';

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

  // Variables for the line chart
  List<FlSpot> spots = [];
  double maxAmount = 0.0;
  String dropdownValue = 'last-year';

  @override
  Widget build(BuildContext context) {
    if (client == null) {
      return const CustomProgressIndicatorPage();
    }

    return buildAnalyticsPage(client!);
  }

  Scaffold buildAnalyticsPage(Client client) {

    // Prepare graph points
    _prepareGraphPoints();

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
                      // Line chart section
                      _buildLineChartSection(),
                      // Pie chart section
                      AssetsStructureSection(client: client),
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

  void _prepareGraphPoints() {
    spots.clear();
    maxAmount = 0.0;

    double yValue;

    if (client!.graphPoints != null && client!.graphPoints!.isNotEmpty) {
      // There are data points
      for (var point in client!.graphPoints!) {
        DateTime dateTime = point.time!;
        double amount = point.amount ?? 0;

        double xValue = calculateXValue(dateTime, dropdownValue);
        if (xValue >= 0) {
          spots.add(FlSpot(xValue, amount));
          if ((amount * 2) > maxAmount) {
            maxAmount = amount * 2;
          }
        }
      }

      // Ensure spots are sorted by x-value
      spots.sort((a, b) => a.x.compareTo(b.x));

      // Add a starting data point at x=0, y=0 if needed
      if (spots.isNotEmpty && spots.first.x > 0) {
        double firstXValue = spots.first.x;
        double startingY = 0;

        // Iterate through client.graphPoints in reverse order
        for (var point in client!.graphPoints!.reversed) {
          double xValue = calculateXValue(point.time!, dropdownValue);
          if (xValue < firstXValue) {
            startingY = point.amount ?? 0;
            break;
          }
        }

        FlSpot startingSpot = FlSpot(0, startingY);
        spots.insert(0, startingSpot);
      }

      // Add an extra data point at the end of the x-axis if needed
      double maxXValue = maxX(dropdownValue);
      if (spots.isNotEmpty && spots.last.x < maxXValue) {
        FlSpot lastSpot = spots.last;
        FlSpot extendedSpot = FlSpot(maxXValue, lastSpot.y);
        spots.add(extendedSpot);
      } else if (spots.isEmpty) {
        GraphPoint mostRecentSpot = client!.graphPoints!.last;
        spots.add(FlSpot(0, mostRecentSpot.amount ?? 0));
        spots.add(FlSpot(maxXValue, mostRecentSpot.amount ?? 0));
        maxAmount = mostRecentSpot.amount! * 1.5;
      }
    } else {
      // No data points
      // Use the user's total assets as the y-value
      yValue = client!.assets?.totalAssets ?? 0.0;

      // Handle case where yValue is 0
      if (yValue == 0.0) {
        maxAmount = 10.0; // Set a default max Y value
      } else {
        maxAmount = yValue * 1.5;
      }

      // Create two spots: from x=0 to x=maxX, at y=yValue
      spots.add(FlSpot(0, yValue));
      spots.add(FlSpot(maxX(dropdownValue), yValue));
    }
  }


  SliverAppBar _buildAppBar() => SliverAppBar(
        backgroundColor: const Color.fromARGB(255, 30, 41, 59),
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        expandedHeight: 0,
        snap: false,
        floating: true,
        pinned: true,
        flexibleSpace: const SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics',
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
                color: Colors.transparent,
                padding: const EdgeInsets.all(10.0),
                child: Stack(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/bell.svg',
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      height: 32,
                    ),
                    if ((client!.numNotifsUnread ?? 0) > 0)
                      Positioned(
                        right: 0,
                        top: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF267DB5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${client!.numNotifsUnread}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Titillium Web',
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildLineChartSection() => Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 30, 41, 59),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  children: [
                    const Text(
                      'Asset Timeline',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        // Implement time period selection if needed
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        child: Row(
                          children: [
                            const Text(
                              'Year-to-Date',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                            const SizedBox(width: 10),
                            SvgPicture.asset(
                              'assets/icons/YTD.svg',
                              color: Colors.green,
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(right: 20, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: LineChart(
                      LineChartData(
                        gridData: _buildGridData(),
                        titlesData: titlesData,
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: maxX(dropdownValue),
                        minY: 0,
                        maxY: calculateMaxY(maxAmount),
                        lineBarsData: [_buildLineChartBarData()],
                        lineTouchData: _buildLineTouchData(),
                      ),
                    ),
                  ),
                ),
              ),
              _buildChartFooter(),
              const SizedBox(height: 40),
              _buildDateRangeText(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

  FlGridData _buildGridData() => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: Color.fromARGB(255, 102, 102, 102),
          strokeWidth: 0.5,
        ),
        // horizontalInterval: calculateHorizontalInterval(maxAmount)
      );

  FlTitlesData get titlesData => FlTitlesData(
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 55,
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                return const Text('');
              }
              return Padding(
                padding: const EdgeInsets.only(right:5),
                child: Text(abbreviateNumber(value), textAlign: TextAlign.center,),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: getBottomTitleInterval(dropdownValue),
            getTitlesWidget: bottomTitlesWidget,
          ),
        ),
      );

  LineChartBarData _buildLineChartBarData() => LineChartBarData(
    spots: spots,
    isCurved: false,
    isStepLineChart: true,
    lineChartStepData: const LineChartStepData(stepDirection: 0),
    barWidth: 3,
    color: AppColors.defaultBlue300,
    isStrokeCapRound: true,
    dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (spot.x == 0 || spot.x == maxX(dropdownValue)) {
                  // Hide dots for starting and ending points
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  );
                }
                // Show dots only if there are actual data points
                if (client!.graphPoints != null &&
                    client!.graphPoints!.isNotEmpty) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.defaultBlue300,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                } else {
                  // Hide dots when there are no data points
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  );
                }
              },
            ),
    belowBarData: BarAreaData(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.defaultBlue300,
          AppColors.defaultBlue500,
          AppColors.defaultBlue500.withOpacity(0.2),
        ],
      ),
      show: true,
    ),
  );

  LineTouchData _buildLineTouchData() => LineTouchData(
    touchTooltipData: LineTouchTooltipData(
      tooltipBgColor: AppColors.defaultBlueGray100,
      tooltipRoundedRadius: 16.0,
      getTooltipItems: (List<LineBarSpot> touchedSpots) => touchedSpots.map((barSpot) {
          if (barSpot.x == 0 || barSpot.x == maxX(dropdownValue)) {
            // Exclude the starting and ending data points from showing tooltip
            return null;
          }
          final yValue = barSpot.y;
          final xValue = barSpot.x;
          final formattedYValue =
              NumberFormat.currency(symbol: '\$').format(yValue);

          DateTime dateTime =
              calculateDateTimeFromXValue(xValue, dropdownValue);
          final formattedDate = DateFormat('MMM dd').format(dateTime);

          return LineTooltipItem(
            '$formattedYValue\n$formattedDate',
            const TextStyle(
              color: AppColors.defaultBlue300,
              fontWeight: FontWeight.bold,
              fontFamily: 'Titillium Web',
              fontSize: 16,
            ),
          );
        }).toList(),
    ),
    getTouchedSpotIndicator:
        (LineChartBarData barData, List<int> spotIndexes) => spotIndexes.map((index) {
        final FlSpot spot = barData.spots[index];
        if (spot.x == 0 || spot.x == maxX(dropdownValue)) {
          // Exclude the starting and ending data points from touch indicators
          return null;
        }
        return const TouchedSpotIndicatorData(
          FlLine(color: Colors.white, strokeWidth: 2),
          FlDotData(show: false),
        );
      }).toList(),
    handleBuiltInTouches: true,
  );

  Widget bottomTitlesWidget(double value, TitleMeta meta) {
    DateTime dateTime = calculateDateTimeFromXValue(value, dropdownValue);
    String text = '';

    if (dropdownValue == 'last-year') {
      if (value == 0) {
        text = DateFormat('MMM yyyy').format(dateTime); // Start date
      } else if (value == maxX(dropdownValue) / 2) {
        text = DateFormat('MMM yyyy').format(calculateDateTimeFromXValue(
            maxX(dropdownValue) / 2, dropdownValue)); // Middle date
      } else if (value == maxX(dropdownValue)) {
        text = DateFormat('MMM yyyy').format(calculateDateTimeFromXValue(
            maxX(dropdownValue), dropdownValue)); // End date
      }
    } else {
      // Handle other cases similarly
      text = DateFormat('MMM dd').format(dateTime);
    }

    if (text.isEmpty) return const SizedBox();

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 3,
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildChartFooter() => Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 30.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.defaultBlue300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 20),
            const Text(
              'Total assets timeline',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Titillium Web',
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                CustomAlertDialog.showAlertDialog(
                  context,
                  'Important Note',
                  'The graph is still being developed and currently only shows your current balance. '
                      'It displays the asset balance for the selected time frame with markers indicating the balance at the start and end of the period.',
                  svgIconPath: 'assets/icons/warning.svg',
                  svgIconColor: AppColors.defaultYellow400,
                );
              },
              child: SvgPicture.asset(
                'assets/icons/warning.svg',
                color: AppColors.defaultYellow400,
                height: 25,
              ),
            ),
          ],
        ),
      );

  Widget _buildDateRangeText() {
    // String displayText = timeline.getDateRangeText(dropdownValue);
    String displayText = '';
    return Container(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Column(
            children: [
              Text(
                displayText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (spots.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 25),
                  child: Row(
                    children: [
                      SizedBox(width: 10),
                      Icon(
                        Icons.circle,
                        size: 20,
                        color: AppColors.defaultBlue500,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'No data available for this time period',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
