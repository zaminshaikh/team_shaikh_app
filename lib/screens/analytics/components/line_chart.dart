// line_chart_section.dart

import 'dart:ui';

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
          if ((amount * 1.2) > maxAmount) {
            maxAmount = amount * 1.2;
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
                        _buildUnifiedDropdownButton(),
                      ],
                    ),
                    _buildClientAccountInfo(),
                    const SizedBox(height: 10),
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
              const SizedBox(height: 20),
              // Date range text
              _buildDateRangeText(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

  Widget _buildUnifiedDropdownButton() {
    // Pick a base blue color for icon/text:
    const baseBlue = Color.fromARGB(255, 0, 121, 220);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        // Make the background a semi‑transparent blue
        backgroundColor: baseBlue.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide.none,
        ),
        elevation: 0, // Keep it flat if you like
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      ),
      onPressed: () => _showBlurredDropdownModal(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/filter.svg',
            colorFilter: const ColorFilter.mode(baseBlue, BlendMode.srcIn),
            height: 18,
            width: 18,
          ),
          SizedBox(width: 8),
          Text(
            'Filters',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: baseBlue,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// When tapped, this function shows a modal with a blurred background.
  /// Inside, you'll see three sections: Time Period, By Client, By Account.
  /// There's also a floating X button at the bottom that closes the modal.
  void _showBlurredDropdownModal(BuildContext context) {
      showDialog(
        context: context,
        barrierDismissible: false,    // Disables closing by tapping outside
        builder: (BuildContext dialogContext) => Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: const Color.fromARGB(255, 93, 93, 93).withOpacity(0.6),
                  ),
                ),
              ),
              StatefulBuilder(
                builder: (ctx, setState) => Stack(
                  children: [
                    // 2) Actual content
                    Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              _buildModalTitle('Client'),
                              _buildClientOptions(setState),
                              const SizedBox(height: 30),
                              _buildModalTitle('Account'),
                              _buildAccountOptions(setState),
                              const SizedBox(height: 30),
                              _buildModalTitle('Time Period'),
                              _buildTimeOptions(setState),
                            ],
                          ),
                        ),
                      ),
                    ),
  
                    // 3) Floating X Button at bottom center
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                        child: Center(
                        child: FloatingActionButton(
                          shape: const CircleBorder(),
                          backgroundColor: AppColors.defaultBlueGray100,
                          child: const Icon(
                            Icons.close,
                            color: Color.fromARGB(255, 65, 65, 65),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }


Widget _buildModalTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 4.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );


Widget _buildTimeOptions(void Function(void Function()) modalSetState) {
  // Added 'year-to-date' and 'last-2-years'
  const timeOptions = [
    'last-week',
    'last-month',
    'last-year',
    'year-to-date',
    'last-2-years'
  ];

  return Column(
    children: timeOptions.map((option) {
      final displayText = _getTimeLabel(option); // e.g. 'Last Week', 'Year to Date', etc.
      final isSelected = (dropdownValue == option);

      return ListTile(
        title: isSelected 
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.defaultBlue500,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    displayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_rounded, color: Colors.white),
                ],
              ),
            )
          : Text(
              displayText,
              style: const TextStyle(color: Colors.white),
            ),
        splashColor: Colors.transparent,
        selectedTileColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () {
          modalSetState(() {
            setState(() {
              dropdownValue = option;
              // ...existing state changes...
              _prepareGraphPoints();
            });
          });
        },
      );
    }).toList(),
  );
}

// You’ll also need to update your _getTimeLabel method to include label strings for the new filters, for example:
String _getTimeLabel(String option) {
  switch (option) {
    case 'last-week': return 'Last Week';
    case 'last-month': return 'Last Month';
    case 'last-year': return 'Last Year';
    case 'year-to-date': return 'Year-to-Date';
    case 'last-2-years': return 'Last 2 Years';
    default: return 'Unknown';
  }
}

// Called when the user taps a client in the client list
Widget _buildClientOptions(void Function(void Function()) modalSetState) {
  if (allClients.isEmpty) {
    return const Text(
      'No clients available',
      style: TextStyle(color: Colors.white),
    );
  }

  return Column(
    children: allClients.map((clientItem) {
      final displayName = '${clientItem.firstName} ${clientItem.lastName}'.trim();
      final isSelected = (selectedClient == clientItem);

      return ListTile(
        title: isSelected 
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.defaultBlue500,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    displayName.length > 20 ? _getInitials(displayName) : displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_rounded, color: Colors.white),
                ],
              ),
            )
          : Text(
              displayName, 
              style: const TextStyle(color: Colors.white),
            ),
        onTap: () {
          modalSetState(() {
            setState(() {
              selectedClient = clientItem;  // Update selected client
              // Clear out any previously selected account or graph
              selectedAccount = null;
              selectedGraph = null;
              // Refresh the chart or data points as needed
              _prepareGraphPoints();
            });
          });
        },
      );
    }).toList(),
  );
}

// Called when the user taps an account in the account list
Widget _buildAccountOptions(void Function(void Function()) modalSetState) {
  if (selectedClient == null || selectedClient!.graphs == null || selectedClient!.graphs!.isEmpty) {
    return const Text(
      'No accounts',
      style: TextStyle(color: Colors.white),
    );
  }

  final graphs = selectedClient!.graphs!;
  return Column(
    children: graphs.map((graph) {
      final isSelected = (selectedAccount == graph.account);

      return ListTile(
        title: isSelected 
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.defaultBlue500,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    graph.account.length > 20 ? _getInitials(graph.account) : graph.account,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_rounded, color: Colors.white),
                ],
              ),
            )
          : Text(
              graph.account, 
              style: const TextStyle(color: Colors.white),
            ),
        onTap: () {
          modalSetState(() {
            setState(() {
              selectedAccount = graph.account;  // Update selected account
              selectedGraph = graph;            // Update selected graph
              _prepareGraphPoints();
            });
          });
        },
      );
    }).toList(),
  );
}

// Use selectedClient and selectedGraph to display the current selection
Widget _buildClientAccountInfo() {
  final clientName = selectedClient?.firstName ?? 'Unknown Client';
  final accountName = selectedGraph?.account ?? 'No Account Selected';

  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$clientName – $accountName',
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontFamily: 'Titillium Web',
        ),
      ),
    ],
  );
}

// ...rest of your line_chart.dart file...



String _getInitials(String name) {
  List<String> names = name.split(' ');
  if (names.length == 1) {
    return names[0];
  }
  String firstName = names.first;
  String lastInitial = names.length > 1 ? '${names.last[0].toUpperCase()}.' : '';
  return '$firstName $lastInitial';
}


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
        text = DateFormat('MMM yyyy').format(dateTime);
      } else if (value == maxX(dropdownValue) / 2) {
        text = DateFormat('MMM yyyy')
            .format(calculateDateTimeFromXValue(maxX(dropdownValue) / 2, dropdownValue));
      } else if (value == maxX(dropdownValue)) {
        text = DateFormat('MMM yyyy')
            .format(calculateDateTimeFromXValue(maxX(dropdownValue), dropdownValue));
      }
    } else if (dropdownValue == 'year-to-date') {
      if (value == 0) {
        text = DateFormat('MMM dd').format(dateTime);
      } else if (value == maxX(dropdownValue)) {
        text = DateFormat('MMM dd').format(calculateDateTimeFromXValue(maxX(dropdownValue), dropdownValue));
      }
    } else if (dropdownValue == 'last-2-years') {
      if (value == 0) {
        text = DateFormat('MMM yyyy').format(dateTime);
      } else if (value == maxX(dropdownValue) / 2) {
        text = DateFormat('MMM yyyy')
            .format(calculateDateTimeFromXValue(maxX(dropdownValue) / 2, dropdownValue));
      } else if (value == maxX(dropdownValue)) {
        text = DateFormat('MMM yyyy')
            .format(calculateDateTimeFromXValue(maxX(dropdownValue), dropdownValue));
      }
    } else {
      // Default weekly/daily
      text = DateFormat('MMM dd').format(dateTime);
    }
  
    if (text.isEmpty) return const SizedBox();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 3,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  /// Builds the date range text displayed below the chart.
  ///
  /// This method shows the selected date range and handles the case where no data is available.
  Widget _buildDateRangeText() {
    String displayText = '';
    DateTime now = DateTime.now();
    DateFormat dateFormat = DateFormat('MMM. dd, yyyy');
  
    switch (dropdownValue) {
      case 'last-week':
        {
          DateTime startOfWeek = now.subtract(Duration(days: now.weekday));
          DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
          displayText = '${dateFormat.format(startOfWeek)} - ${dateFormat.format(endOfWeek)}';
        }
        break;
      case 'last-month':
        {
          DateTime startOfLast30Days = now.subtract(const Duration(days: 29));
          DateTime endOfLast30Days = now;
          displayText = '${dateFormat.format(startOfLast30Days)} - ${dateFormat.format(endOfLast30Days)}';
        }
        break;
      case 'last-year':
        {
          DateTime startOfLastYear = DateTime(now.year - 1, now.month, now.day);
          displayText = '${dateFormat.format(startOfLastYear)} - ${dateFormat.format(now)}';
        }
        break;
      case 'year-to-date':
        {
          DateTime startOfThisYear = DateTime(now.year, 1, 1);
          displayText = '${dateFormat.format(startOfThisYear)} - ${dateFormat.format(now)}';
        }
        break;
      case 'last-2-years':
        {
          DateTime startOfTwoYearsAgo = DateTime(now.year - 2, now.month, now.day);
          displayText = '${dateFormat.format(startOfTwoYearsAgo)} - ${dateFormat.format(now)}';
        }
        break;
      default:
        displayText = 'Unknown';
        break;
    }
  
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
                          fontWeight: FontWeight.w300,
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


