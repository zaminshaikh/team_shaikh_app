// line_chart_section.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/components/alert_dialog.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/database/models/graph_point_model.dart';
import 'package:team_shaikh_app/database/models/graph_model.dart'; // Import Graph class
import 'package:team_shaikh_app/screens/utils/resources.dart';
import 'package:team_shaikh_app/screens/analytics/utils/analytics_utilities.dart';

/// A widget that displays the line chart section in the Analytics page.
///
/// This widget is responsible for preparing the data points and rendering the
/// line chart that shows the asset timeline for the client.
class LineChartSection extends StatefulWidget {
  /// The client data containing the graph points.
  final Client client;

  /// Creates a new instance of [LineChartSection].
  const LineChartSection({Key? key, required this.client}) : super(key: key);

  @override
  _LineChartSectionState createState() => _LineChartSectionState();
}

class _LineChartSectionState extends State<LineChartSection> {
  // Variables for the line chart data
  List<FlSpot> spots = [];
  double maxAmount = 0.0;
  String dropdownValue = 'last-week';

  // New state variables for account selection
  String? selectedAccount;
  Graph? selectedGraph;

  // New state variables for client selection
  late final List<Client> allClients;
  Client? selectedClient;

  @override
  void initState() {
    super.initState();
    allClients = [widget.client, ...(widget.client.connectedUsers?.whereType<Client>() ?? [])];
    selectedClient = allClients.isNotEmpty ? allClients.first : null;
    // Default to the cumulative graph if available
    if (selectedClient != null && (selectedClient!.graphs?.isNotEmpty ?? false)) {
      selectedGraph = selectedClient!.graphs!.firstWhere(
        (g) => g.account.toLowerCase() == 'cumulative',
        orElse: () => selectedClient!.graphs!.first,
      );
      selectedAccount = selectedGraph?.account;
    }
    _prepareGraphPoints();
  }

  /// Prepares the data points for the line chart based on the selected graph's graph points.
  ///
  /// This method processes the selected graph's graph points, calculates the appropriate
  /// x and y values, and populates the [spots] list with [FlSpot] instances.
  /// It also calculates the maximum amount for setting the y-axis limit.
  void _prepareGraphPoints() {
    spots.clear();
    maxAmount = 0.0;

    double yValue;

    if (selectedGraph != null && selectedGraph!.graphPoints.isNotEmpty) {
      // There are data points available
      for (var point in selectedGraph!.graphPoints) {
        DateTime dateTime = point.time;
        double amount = point.amount;

        // Calculate the x-value based on the date and selected time frame
        double xValue = calculateXValue(dateTime, dropdownValue);
        if (xValue >= 0) {
          spots.add(FlSpot(xValue, amount));
          if ((amount * 2) > maxAmount) {
            maxAmount = amount * 2;
          }
        }
      }

      // Ensure the spots are sorted by x-value
      spots.sort((a, b) => a.x.compareTo(b.x));

      // Add a starting data point at x=0 if needed
      if (spots.isNotEmpty && spots.first.x > 0) {
        double firstXValue = spots.first.x;
        double startingY = 0;

        // Find the starting y-value from previous data points
        for (var point in selectedGraph!.graphPoints.reversed) {
          double xValue = calculateXValue(point.time, dropdownValue);
          if (xValue < firstXValue) {
            startingY = point.amount;
            break;
          }
        }

        // Insert the starting spot at the beginning
        FlSpot startingSpot = FlSpot(0, startingY);
        spots.insert(0, startingSpot);
      }

      // Add an ending data point at the max x-axis value if needed
      double maxXValue = maxX(dropdownValue);
      if (spots.isNotEmpty && spots.last.x < maxXValue) {
        FlSpot lastSpot = spots.last;
        FlSpot extendedSpot = FlSpot(maxXValue, lastSpot.y);
        spots.add(extendedSpot);
      } else if (spots.isEmpty) {
        // No data points, add default spots
        GraphPoint mostRecentSpot = selectedGraph!.graphPoints.last;
        spots.add(FlSpot(0, mostRecentSpot.amount));
        spots.add(FlSpot(maxXValue, mostRecentSpot.amount));
        maxAmount = (mostRecentSpot.amount) * 1.5;
      }
    } else {
      // No data points available
      yValue = 0.0;

      // Set a default maximum amount for the y-axis
      if (yValue == 0.0) {
        maxAmount = 100000.0; // Default max Y value
      } else {
        maxAmount = yValue * 1.5;
      }

      // Create default spots with y-value set to 0
      spots.add(FlSpot(0, yValue));
      spots.add(FlSpot(maxX(dropdownValue), yValue));
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 30, 41, 59),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align to start
            children: [
              const SizedBox(height: 10),
              // Header section with title and dropdowns
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        DropdownButton<String>(
                          value: dropdownValue,
                          // icon: const Icon(Icons.arrow_downward,
                          //     color: Colors.white),
                          // iconSize: 24,
                          elevation: 16,
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white),
                          // underline: Container(
                          //   height: 2,
                          //   color: Colors.white,
                          // ),
                          onChanged: (String? newValue) {
                            setState(() {
                              dropdownValue = newValue!;
                              _prepareGraphPoints();
                            });
                          },
                          items: <String>[
                            'last-week',
                            'last-month',
                            'last-year'
                          ].map<DropdownMenuItem<String>>((String value) {
                            String displayText;
                            switch (value) {
                              case 'last-week':
                                displayText = 'Last Week';
                                break;
                              case 'last-month':
                                displayText = 'Last Month';
                                break;
                              case 'last-year':
                                displayText = 'Last Year';
                                break;
                              default:
                                displayText = value;
                            }
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                displayText,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // New dropdown for clients
                        DropdownButton<Client>(
                          value: selectedClient,
                          dropdownColor: Colors.black,
                          onChanged: (newClient) {
                            setState(() {
                              selectedClient = newClient;
                              final graphs = selectedClient?.graphs ?? [];
                              selectedGraph = graphs.firstWhere(
                                (g) => g.account.toLowerCase() == 'cumulative',
                                orElse: () => graphs.first,
                              );
                              selectedAccount = selectedGraph?.account;
                              _prepareGraphPoints();
                            });
                          },
                          items: allClients.map((clientItem) {
                            final displayName = '${clientItem.firstName} ${clientItem.lastName}'.trim();
                            return DropdownMenuItem<Client>(
                              value: clientItem,
                              child: Text(displayName.isEmpty ? 'Unnamed Client' : displayName),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 10),
                        // Update the account dropdown section
                        if (selectedClient?.graphs != null && selectedClient!.graphs!.isNotEmpty)
                          DropdownButton<String>(
                            value: selectedAccount,
                            elevation: 16,
                            dropdownColor: Colors.black,
                            style: const TextStyle(color: Colors.white),
                            // underline: Container(
                            //   height: 2,
                            //   color: Colors.white,
                            // ),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedAccount = newValue!;
                                selectedGraph = selectedClient!.graphs!
                                    .firstWhere((graph) =>
                                        graph.account == selectedAccount);
                                _prepareGraphPoints();
                              });
                            },
                            items: selectedClient!.graphs!
                                .map<DropdownMenuItem<String>>((Graph graph) {
                              return DropdownMenuItem<String>(
                                value: graph.account,
                                child: Text(
                                  graph.account,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                          )
                        else
                          const Text(
                            'No accounts',
                            style: TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Line chart container
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
              // Footer with legend and alert icon
              _buildChartFooter(),
              const SizedBox(height: 40),
              // Date range text
              _buildDateRangeText(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

  /// Builds the grid data for the line chart.
  ///
  /// Configures the appearance of the horizontal grid lines on the chart.
  FlGridData _buildGridData() => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: Color.fromARGB(255, 102, 102, 102),
          strokeWidth: 0.5,
        ),
      );

  /// Configures the titles data for the line chart axes.
  ///
  /// This includes settings for the left, right, top, and bottom titles (labels).
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
                padding: const EdgeInsets.only(right: 5),
                child: Text(
                  abbreviateNumber(value),
                  textAlign: TextAlign.center,
                ),
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

  /// Builds the line chart bar data, which defines the appearance and behavior of the line.
  ///
  /// This includes settings for the line's color, width, dot appearance, and the area below the line.
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
              // Hide dots for the starting and ending points
              return FlDotCirclePainter(
                radius: 0,
                color: Colors.transparent,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              );
            }
            // Show dots only if there are actual data points
            if (selectedGraph != null &&
                selectedGraph!.graphPoints.isNotEmpty) {
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

  /// Configures the touch behavior and tooltips for the line chart.
  ///
  /// This includes settings for how tooltips appear when the user interacts with the chart.
  LineTouchData _buildLineTouchData() => LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 16.0,
          getTooltipItems: (List<LineBarSpot> touchedSpots) =>
              touchedSpots.map((barSpot) {
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
            (LineChartBarData barData, List<int> spotIndexes) =>
                spotIndexes.map((index) {
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

  /// Widget for displaying the bottom axis titles.
  ///
  /// This method formats and returns the appropriate labels for the x-axis based on the time frame.
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

  /// Builds the footer for the line chart section, including the legend and alert icon.
  ///
  /// This method creates a row containing a colored indicator, a description, and an alert icon.
  Widget _buildChartFooter() => Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 30.0),
        child: Row(
          children: [
            // Colored indicator for the line chart
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.defaultBlue300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 20),
            // Description text
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
            // Alert icon that shows an important note when tapped
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

  /// Builds the date range text displayed below the chart.
  ///
  /// This method shows the selected date range and handles the case where no data is available.
  Widget _buildDateRangeText() {
    // TODO: Implement logic to display the correct date range based on dropdownValue
    String displayText = ''; // Placeholder for date range text

    return Container(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Column(
            children: [
              // Display the date range text
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
              // Show a message if no data is available
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
