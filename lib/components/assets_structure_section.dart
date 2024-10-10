import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/screens/utils/utilities.dart';

class AssetsStructureSection extends StatelessWidget {
  final Client client;

  const AssetsStructureSection({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalAGQ = client.assets?.funds['agq']?.total ?? 0;
    double totalAK1 = client.assets?.funds['ak1']?.total ?? 0;
    double totalAssets = client.assets?.totalAssets ?? 0;

    // Include connected users' total assets
    if (client.connectedUsers != null) {
      for (var user in client.connectedUsers!) {
        if (user != null) {
          totalAGQ += user.assets?.funds['agq']?.total ?? 0;
          totalAK1 += user.assets?.funds['ak1']?.total ?? 0;
          totalAssets += user.assets?.totalAssets ?? 0;
        }
      }
    }

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
                        currencyFormat(totalAssets),
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
}
