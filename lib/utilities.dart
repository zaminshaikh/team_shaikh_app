import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/resources.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Config {
  static late Map<String, dynamic> _config;

  static Future<void> loadConfig() async {
    String jsonString = await rootBundle.loadString('assets/config.json');
    _config = jsonDecode(jsonString);
  }

  static dynamic get(String key) => _config[key];
}

/// A class that provides a custom alert dialog.
///   
/// Displays an alert dialog with the specified [title] and [message].
///
/// The [context] parameter is required to show the dialog.
/// The [title] parameter specifies the title of the dialog.
/// The [message] parameter specifies the message content of the dialog.
///
/// Example usage:
///
/// ```dart
/// CustomAlertDialog.showAlertDialog(context, 'Alert', 'This is an alert message');
/// ```
class CustomAlertDialog {
  static Future<void> showAlertDialog(BuildContext context, String title, String message, {Icon? icon}) async => showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.defaultBlueGray800,
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(width: 10),
                    icon ?? const Icon(Icons.square, color: Colors.transparent),
                  ],
                  ),
                ),
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity, // This will make the container take up the full width of the AlertDialog
                padding: const EdgeInsets.symmetric(vertical: 10), // Add some vertical padding
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 30, 75, 137), // Change this to the color you want
                  borderRadius: BorderRadius.circular(20), // This will make the corners rounded
                ),
                child: const Text(
                  'Continue',
                  textAlign: TextAlign.center, // This will center the text
                ),
              ),
            )
          ],
        ),
    );
}
/// Formats the given amount as a currency string.
String currencyFormat(double amount) => NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
    locale: 'en_US',
  ).format(amount);
