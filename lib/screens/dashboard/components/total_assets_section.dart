import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/utils/resources.dart';
import 'package:team_shaikh_app/utils/utilities.dart';

class TotalAssetsSection extends StatelessWidget {

  final Client client;

  const TotalAssetsSection({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) => Stack(
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
                      currencyFormat(client.assets?.totalAssets ?? 0),
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
                          currencyFormat(client.assets?.totalYTD ?? 0),
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
}