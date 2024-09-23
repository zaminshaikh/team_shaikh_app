// analytics_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:team_shaikh_app/components/alert_dialog.dart';
import 'package:team_shaikh_app/components/custom_bottom_navigation_bar.dart';
import 'package:team_shaikh_app/components/progress_indicator.dart';
import 'package:team_shaikh_app/database/models/assets_model.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/notifications/notifications.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class Timeline {
  late DateTime now;
  late DateTime firstDayOfCurrentMonth;
  late DateTime lastDayOfPreviousMonth;
  late int daysInLastMonth;
  late List<String> lastSixMonths;
  late List<String> lastYearMonths;
  late String lastWeekRange;
  late String lastMonthRange;
  late String lastSixMonthsRange;
  late String lastYearRange;
  late List<String> lastWeekDays;
  late List<String> lastMonthDays;

  Timeline() {
    now = DateTime.now();
    firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    lastDayOfPreviousMonth =
        firstDayOfCurrentMonth.subtract(const Duration(days: 1));
    daysInLastMonth = lastDayOfPreviousMonth.day;
    lastSixMonths = _calculateLastSixMonths();
    lastWeekRange = _calculateLastWeekRange();
    lastMonthRange = _calculateLastMonthRange();
    lastSixMonthsRange = _calculateLastSixMonthsRange();
    lastYearRange = _calculateLastYearRange();
    lastWeekDays = _calculateLastWeekDays();
    lastMonthDays = _calculateLastMonthDays();
    lastYearMonths = _calculateLastYearMonths();
  }

  List<String> _calculateLastSixMonths() {
    List<String> months = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('MMM').format(month));
    }
    return months.reversed.toList(); // Reverse to get the months in order
  }

  List<String> _calculateLastWeekDays() {
    DateTime now = DateTime.now();
    return List.generate(7, (index) {
      DateTime day = now.subtract(Duration(days: 6 - index));
      return DateFormat('EEE').format(day);
    });
  }

  String _calculateLastWeekRange() {
    DateTime now = DateTime.now();
    // Calculate the start of the range (7 days ago)
    DateTime startOfRange = now.subtract(const Duration(days: 6));
    // Calculate the end of the range (today)
    DateTime endOfRange = now;
    String formattedStart = DateFormat('MMMM dd, yyyy').format(startOfRange);
    String formattedEnd = DateFormat('MMMM dd, yyyy').format(endOfRange);
    return '$formattedStart - $formattedEnd';
  }

  String _calculateLastMonthRange() {
    DateTime now = DateTime.now();
    DateTime startOfLastMonth = DateTime(now.year, now.month - 1, now.day);
    DateTime endOfLastMonth = DateTime(now.year, now.month, now.day);
    String formattedStart = DateFormat('MMMM d, yyyy').format(startOfLastMonth);
    String formattedEnd = DateFormat('MMMM dd, yyyy').format(endOfLastMonth);
    return '$formattedStart - $formattedEnd';
  }

  List<String> _calculateLastMonthDays() {
    DateTime now = DateTime.now();
    DateTime startOfLastMonth = DateTime(now.year, now.month - 1, now.day);
    DateTime endOfLastMonth = DateTime(now.year, now.month, now.day);

    // Calculate the midpoint date
    DateTime midOfLastMonth = startOfLastMonth.add(Duration(
        days:
            (endOfLastMonth.difference(startOfLastMonth).inDays / 2).round()));

    String formattedStart = DateFormat('MMM d').format(startOfLastMonth);
    String formattedMid = DateFormat('MMM d').format(midOfLastMonth);
    String formattedEnd = DateFormat('MMM dd').format(endOfLastMonth);

    return [formattedStart, formattedMid, formattedEnd];
  }

  String _calculateLastSixMonthsRange() {
    DateTime now = DateTime.now();
    DateTime startOfSixMonthsAgo = DateTime(now.year, now.month - 5, now.day);
    DateTime endOfLastMonth = now;
    String formattedStart =
        DateFormat('MMMM dd, yyyy').format(startOfSixMonthsAgo);
    String formattedEnd = DateFormat('MMMM dd, yyyy').format(endOfLastMonth);
    return '$formattedStart - $formattedEnd';
  }

  String _calculateLastYearRange() {
    DateTime now = DateTime.now();
    DateTime startOfCurrentYear = DateTime(now.year, 1, 1);
    DateTime endOfCurrentYear = now;
    String formattedStart =
        DateFormat('MMMM dd, yyyy').format(startOfCurrentYear);
    String formattedEnd = DateFormat('MMMM dd, yyyy').format(endOfCurrentYear);
    return '$formattedStart - $formattedEnd';
  }

  List<String> _calculateLastYearMonths() {
    List<String> months = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 13; i++) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('MM').format(month));
    }
    return months.reversed.toList(); // Reverse to get the months in order
  }

  // Method to get labels for each month in the last year
  List<String> getLastYearMonthLabel() {
    List<String> labels = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      DateTime date = DateTime(now.year, now.month - i, 1);
      labels.add(DateFormat('MM/yy').format(date));
    }
    return labels.reversed.toList(); // Reverse to get chronological order
  }

  // Method to get labels for each day in the last week
  List<String> getLastWeekDayLabel() {
    List<String> labels = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: i));
      labels.add(DateFormat('EEE').format(date));
    }
    return labels.reversed.toList(); // Reverse to get chronological order
  }

  // Method to get labels for each month in the last six months
  List<String> getLastSixMonthsLabel() {
    List<String> labels = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      DateTime date = DateTime(now.year, now.month - i, 1);
      labels.add(DateFormat('MM/yy').format(date));
    }
    return labels.reversed.toList(); // Reverse to get chronological order
  }

  // Method to get labels for each day in the last month
  List<String> getLastMonthDayLabel() {
    List<String> labels = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      DateTime date = now.subtract(Duration(days: i));
      labels.add(DateFormat('MMM dd').format(date));
    }
    return labels.reversed.toList(); // Reverse to get chronological order
  }

}
class _AnalyticsPageState extends State<AnalyticsPage> {  
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
  Timeline timeline = Timeline();

  @override
  Widget build(BuildContext context) {
    if (client == null) {
      return const CustomProgressIndicatorPage();
    }

    return buildAnalyticsPage(client!);
  }

  Scaffold buildAnalyticsPage(Client client) {
    // Calculate total assets of the user
    double totalAGQ = 0.0;
    double totalAK1 = 0.0;

    // Calculate user's total assets
    if (client.assets != null) {
      for (var fundEntry in client.assets!.funds.entries) {
        String fundName = fundEntry.key;
        Fund fund = fundEntry.value;

        switch (fundName.toUpperCase()) {
          case 'AGQ':
            totalAGQ += fund.total;
            break;
          case 'AK1':
            totalAK1 += fund.total;
            break;
        }
        
      }
    }


    // Calculate percentages
    double percentageAGQ = client.assets!.totalAssets! > 0 ? (totalAGQ / client!.assets!.totalAssets!.toDouble()) * 100 : 0;
    double percentageAK1 = client.assets!.totalAssets! > 0 ? (totalAK1 / client!.assets!.totalAssets!.toDouble()) * 100 : 0;

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
            child: CustomBottomNavigationBar(currentItem: NavigationItem.analytics),
          ),
        ],
      ),
    );
  }

  void _prepareGraphPoints() {
    spots.clear();
    maxAmount = 0.0;

    if (client!.graphPoints != null && client!.graphPoints!.isNotEmpty) {
      for (var point in client!.graphPoints!) {
        DateTime dateTime = point.time!;
        double amount = point.amount ?? 0;

        double xValue = _calculateXValue(dateTime);
        if (xValue >= 0) {
          spots.add(FlSpot(xValue, amount));
          if (amount > maxAmount) {
            maxAmount = amount;
          }
        }
      }

      // Ensure spots are sorted by x-value
      spots.sort((a, b) => a.x.compareTo(b.x));
    }
  }

  double _calculateXValue(DateTime dateTime) {
    DateTime now = DateTime.now();
    DateTime startDate;
    double totalPeriod;
    double maxXValue = maxX(dropdownValue);

    switch (dropdownValue) {
      case 'last-week':
        startDate = now.subtract(const Duration(days: 6));
        totalPeriod = 7;
        break;
      case 'last-month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        totalPeriod = 30;
        break;
      case 'last-6-months':
        startDate = DateTime(now.year, now.month - 5, now.day);
        totalPeriod = 180;
        break;
      case 'last-year':
        startDate = DateTime(now.year, 1, 1);
        totalPeriod = 365;
        break;
      default:
        return -1.0;
    }

    if (dateTime.isBefore(startDate) || dateTime.isAfter(now)) {
      return -1.0;
    }

    double dayDifference = dateTime.difference(startDate).inDays.toDouble();
    return (dayDifference / totalPeriod) * maxXValue;
  }

  DateTime _calculateDateTimeFromXValue(double xValue) {
    DateTime now = DateTime.now();
    DateTime startDate;
    double totalPeriod;
    double maxXValue = maxX(dropdownValue);

    switch (dropdownValue) {
      case 'last-week':
        startDate = now.subtract(const Duration(days: 6));
        totalPeriod = 7;
        break;
      case 'last-month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        totalPeriod = 30;
        break;
      case 'last-6-months':
        startDate = DateTime(now.year, now.month - 5, now.day);
        totalPeriod = 180;
        break;
      case 'last-year':
        startDate = DateTime(now.year, 1, 1);
        totalPeriod = 365;
        break;
      default:
        return DateTime.now(); // Return current date for default case
    }

    double dayDifference = (xValue / maxXValue) * totalPeriod;
    DateTime dateTime = startDate.add(Duration(days: dayDifference.round()));

    return dateTime;
  }


  double maxX(String dropdownValue) {
    switch (dropdownValue) {
      case 'last-week':
        return 6;
      case 'last-month':
        return 2;
      case 'last-6-months':
        return 5;
      case 'last-year':
        return 12;
      case 'custom-time-period':
        // Handle custom time period
        return 2; // Adjust as necessary
      default:
        return 6;
    }
  }

  String _abbreviateNumber(double value) {
    if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  double calculateMaxY(double value) {
    double increment = 1.0;
    if (value >= 100000000) {
      increment = 10000000;
    } else if (value >= 10000000) {
      increment = 1000000;
    } else if (value >= 1000000) {
      increment = 100000;
    } else if (value >= 100000) {
      increment = 10000;
    } else if (value >= 10000) {
      increment = 1000;
    } else if (value >= 1000) {
      increment = 100;
    } else if (value >= 500) {
      increment = 50;
    }
    return ((value / increment).ceil() * increment).toDouble();
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
              const SizedBox(height: 20),
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
      );

  FlTitlesData get titlesData => FlTitlesData(
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                return const Text('');
              }
              return Text(_abbreviateNumber(value));
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: dropdownValue == 'last-week'
                ? 1
                : dropdownValue == 'last-month'
                    ? 5
                    : dropdownValue == 'last-6-months'
                        ? 30
                        : 60,
            getTitlesWidget: bottomTitlesWidget,
          ),
        ),
      );

  LineChartBarData _buildLineChartBarData() => LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.15,
        color: AppColors.defaultBlue300,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 4,
            color: AppColors.defaultBlue300,
            strokeWidth: 2,
            strokeColor: Colors.white,
          ),
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

  LineTouchData _buildLineTouchData() =>  LineTouchData(
      touchTooltipData: LineTouchTooltipData(
      tooltipBgColor: AppColors.defaultBlueGray100,
      tooltipRoundedRadius: 16.0,
      getTooltipItems: (List<LineBarSpot> touchedSpots) => touchedSpots.map((barSpot) {
          final yValue = barSpot.y;
          final xValue = barSpot.x;
          final formattedYValue = NumberFormat.currency(symbol: '\$').format(yValue);

          DateTime dateTime = _calculateDateTimeFromXValue(xValue);
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
  );


  Widget bottomTitlesWidget(double value, TitleMeta meta) {
    DateTime dateTime = _calculateDateTimeFromXValue(value);
    String text;

    switch (dropdownValue) {
      case 'last-week':
        text = DateFormat('EEE').format(dateTime); // e.g., Mon, Tue
        break;
      case 'last-month':
        text = DateFormat('MMM dd').format(dateTime); // e.g., Sep 01
        break;
      case 'last-6-months':
        text = DateFormat('MMM').format(dateTime); // e.g., Apr
        break;
      case 'last-year':
        text = DateFormat('MMM').format(dateTime); // e.g., Jan, Feb
        break;
      default:
        text = '';
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 3,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
    String displayText = 'TEST';
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

