import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:developer';
import 'package:team_shaikh_app/database.dart';
import 'package:http/http.dart' as http;

DatabaseService _databaseService = DatabaseService(FirebaseAuth.instance.currentUser!.uid);

String clientId = _databaseService.cid ?? 'default'; // Replace 'default' with your actual default client ID
String documentName = 'TestPdf$clientId.pdf'; // Construct the document name

void downloadToFiles(String documentName) async {
  Directory downloadDir = await getApplicationDocumentsDirectory();
  var path = "${downloadDir.path}/$documentName";
  var file = File(path);
  var res = await http.get(Uri.parse('https://source.unsplash.com/random')); 
  await file.writeAsBytes(res.bodyBytes);
  log('downloadmethod.dart: File downloaded to: $path');

  // Open share options
}

Future<String> downloadFile(context, clientId, documentName) async {
  String filePath = '';

  try {
    log('downloadmethod.dart: Attempting to get the directory for the app\'s temporary files.');
    final directory = await getTemporaryDirectory();
    log('downloadmethod.dart: Temporary directory obtained: ${directory.path}');

    filePath = '${directory.path}/$documentName';
    log('downloadmethod.dart: Constructed file path: $filePath');

    log('downloadmethod.dart: Creating a reference to the file on Firebase Storage.');
    final ref = FirebaseStorage.instance.ref().child('testUsersStatements').child(clientId).child(documentName);
    log('downloadmethod.dart: Firebase Storage reference created: ${ref.fullPath}');

    log('downloadmethod.dart: Starting the download...');
    final bytes = await ref.getData();
    if (bytes != null) {
      log('downloadmethod.dart: Download successful. File size: ${bytes.length} bytes.');
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      log('downloadmethod.dart: File saved to local storage at $filePath');
    } else {
      log('downloadmethod.dart: Download failed: File data is null');
    }
  } catch (e) {
    log('downloadmethod.dart: Download error: $e');
  }

  return filePath;
}