import 'package:flutter/material.dart';

class Styles {
  static TextStyle boldTextStyle(double fontSize, Color color) => TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.bold,
        fontFamily: 'Titillium Web',
      );

  static TextStyle regTextStyle(double fontSize, Color color) => TextStyle(
        fontSize: fontSize,
        color: color,
        fontFamily: 'Titillium Web',
      );
}