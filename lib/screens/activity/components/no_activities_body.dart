import 'package:flutter/material.dart';

Widget buildNoActivityMessage() => const Padding(
      padding: EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 50,
            color: Colors.grey,
          ),
          Text(
            'No Activities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8), // Provides spacing between the text widgets
          Text(
            'Please adjust your filters to view activities.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
