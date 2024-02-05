import 'package:flutter/material.dart';

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
  static Future<void> showAlertDialog(BuildContext context, String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}