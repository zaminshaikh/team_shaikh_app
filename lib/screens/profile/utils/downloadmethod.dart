// ignore_for_file: empty_catches

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:team_shaikh_app/database.dart';
import 'package:http/http.dart' as http;


void downloadToFiles(String documentName) async {
  Directory downloadDir = await getApplicationDocumentsDirectory();
  var path = '${downloadDir.path}/$documentName';
  var file = File(path);
  var res = await http.get(Uri.parse('https://source.unsplash.com/random')); 
  await file.writeAsBytes(res.bodyBytes);

  // Open share options
}

Future<String> downloadFile(context, clientId, documentName) async {
  String filePath = '';

  try {
    final directory = await getTemporaryDirectory();

    filePath = '${directory.path}/$documentName';

    final ref = FirebaseStorage.instance.ref().child('testUsersStatements').child(clientId).child(documentName);

    final bytes = await ref.getData();
    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    } else {
    }
  } catch (e) {
  }

  return filePath;
}