import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fl_chart/fl_chart.dart';


class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {  
    int selectedIndex = 0;
    List<IconData> data = [
      Icons.home_outlined,
      Icons.search,
      Icons.add_box_outlined,
      Icons.person_outline_sharp
    ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 37, 58, 86),
        toolbarHeight: 90,
        title: Row(
          children: [
            SizedBox(width: 10),
            Column( 
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  'Welcome Back, John Doe',
                  style: TextStyle(
                    fontSize: 23,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Client ID: 1649261',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontFamily: 'Titillium Web',
                  ),
                ),

              ]
            ),

            SizedBox(width: 105),

            Column(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 32
                ),

                SizedBox(height: 20)
              ],
            )

          ],
        ),
        automaticallyImplyLeading: false,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 400,
                height: 160,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Text(
                          'Total Assets',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '\$1,000,000.00',
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.abc),
                            SizedBox(width: 5),
                            Text(
                              '\$1,816',
                              style: TextStyle(
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
              
              const SizedBox(height: 32),

              Text('$selectedIndex',
                                style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontFamily: 'Titillium Web',
                  ),
),

              Container(
                width: 400,
                height: 90,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 37, 58, 86),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              'John Doe',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),

                            SizedBox(width: 10),

                            Icon(Icons.abc),

                            SizedBox(width: 5),

                            Text(
                              '\$1,816',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 7),

                        Text(
                          '\$500,000.00',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),

                      ],
                    ),
                    SizedBox(width: 170),
                    Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 25)
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              const Row(
                children: [

                  Text(
                    'Connected Users',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                  ),

                  SizedBox(width: 220),

                  Text(
                    '(3)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 20),

              CarouselSlider(
                options: CarouselOptions(
                  height: 90.0,
                  aspectRatio: 16 / 9,
                  viewportFraction: 1,
                  initialPage: 0,
                  enableInfiniteScroll: false,
                  reverse: true,
                  autoPlay: false,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.2,
                  onPageChanged: (index, reason) {
                    // Your callback function for page changes
                  },
                  scrollDirection: Axis.horizontal,
                ),
                items: ['Jane Doe', 'Kristin Watson', 'Floyd Miles'].map((i) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        padding: const EdgeInsets.all(15),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      '$i',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Titillium Web',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.abc),
                                    const SizedBox(width: 5),
                                    const Text(
                                      '\$1,816',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  '\$500,000.00',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 25,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 80),

              Container(
                width: 400,
                height: 520,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 37, 58, 86),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [

                    const SizedBox(height: 10),
                    
                    const Row(
                      children: [
                        SizedBox(width: 5,),
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
                                PieChartSectionData(
                                  color: const Color.fromARGB(255,12,94,175),
                                  radius: 25,
                                  value: 37.5,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  color: const Color.fromARGB(255,49,153,221),
                                  radius: 25,
                                  value: 62.5,
                                  showTitle: false,
                                ),
                              ],
                            ),
                          ),
                          const Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [ 
                                                  
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                              
                                Text(
                                  '\$500,000.00',
                                  style: TextStyle(
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

                        SizedBox(width: 280),

                        Text(
                          '%',
                        style: TextStyle(
                            fontSize: 16, 
                            color: Color.fromARGB(255, 216, 216, 216), 
                            fontFamily: 'Titillium Web', 
                          ),
                        ),
                      ],

                    ),

                    const SizedBox(height: 5),

                    const Divider(
                      thickness: 1.2,
                      height: 1,
                      color: Color.fromARGB(255, 102, 102, 102), 
                      
                    ),
                  
                    const SizedBox(height: 10),

                    const Column(
                      
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 20,
                              color: Color.fromARGB(255,12,94,175),
                            ),

                            SizedBox(width: 10),
                            
                            Text('AGQ Fixed Income',
                              style: TextStyle(
                                fontSize: 15, 
                                color: Colors.white, 
                                fontWeight: FontWeight.w600, 
                                fontFamily: 'Titillium Web', 
                              ),
                            ),

                            SizedBox(width: 50),

                            Text('62.5%',
                              style: TextStyle(
                                fontSize: 15, 
                                color: Colors.white, 
                                fontWeight: FontWeight.w600, 
                                fontFamily: 'Titillium Web', 
                              ),
                            ),


                          ],

                        ),

                        SizedBox(height: 20),

                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 20,
                              color: Color.fromARGB(255,49,153,221),
                            ),
                            SizedBox(width: 10),
                            
                            Text('AK1 Holdings LP',
                              style: TextStyle(
                                fontSize: 15, 
                                color: Colors.white, 
                                fontWeight: FontWeight.w600, 
                                fontFamily: 'Titillium Web', 
                              ),
                            ),

                            SizedBox(width: 50),

                            Text('62.5%',
                              style: TextStyle(
                                fontSize: 15, 
                                color: Colors.white, 
                                fontWeight: FontWeight.w600, 
                                fontFamily: 'Titillium Web', 
                              ),
                            ),


                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 30),

              

            ],
          ),
        ),
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 50, right: 20, left: 20),
        
        height: 80,
        padding: const EdgeInsets.only(right: 30, left: 30),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 37, 58, 86),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            data.length,
            (i) => GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = i;
                });

                // Check if the person outline icon is clicked
                if (data[i] == Icons.search) {
                  Navigator.pushNamed(context, '/analytics');
                }

                if (data[i] == Icons.home_outlined) {
                  Navigator.pushNamed(context, '/dashboard');
                }

                if (data[i] == Icons.add_box_outlined) {
                  Navigator.pushNamed(context, '/activity');
                }

                if (data[i] == Icons.person_outline_sharp) {
                  Navigator.pushNamed(context, '/profile');
                }

              },
              child: Icon(
                data[i],
                size: 35,
                color: i == selectedIndex ? Colors.white : Colors.blueGrey,
              ),
            ),
          ),
        ),
      ),
          
    );
  }
}

