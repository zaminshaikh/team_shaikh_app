import 'package:flutter/material.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);
  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {

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
        title:          
          Row(
            children: [
              SizedBox(width: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ),
            ],
          ),
        automaticallyImplyLeading: false,
      ),

      body: const Padding(
        padding: EdgeInsets.all(16.0),


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

