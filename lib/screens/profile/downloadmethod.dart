import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:team_shaikh_app/database.dart';

  late DatabaseService _databaseService;

String clientId = {_databaseService.cid} as String; // Replace with the actual client ID
String documentName = 'TestPdf$clientId.pdf'; // Construct the document name


Future<String> downloadFile(context, clientId, documentName) async {
  String filePath = '';

  try {
    // Get the directory for the app's temporary files.
    final directory = await getTemporaryDirectory();

    // Construct the file path where the file should be saved.
    filePath = '${directory.path}/$documentName';

    // Create a reference to the file on Firebase Storage.
    final ref = FirebaseStorage.instance.ref().child('testUsersStatements').child(clientId).child(documentName);

    // Start the download and save the file to local storage.
    final bytes = await ref.getData();
    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Download completed!'),
            content: Text('File saved at $filePath'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      print('Download failed: File data is null');
    }
  } catch (e) {
    print('Download error: $e');
  }

  return filePath;
}