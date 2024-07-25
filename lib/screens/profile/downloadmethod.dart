import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:team_shaikh_app/database.dart';
import 'package:http/http.dart' as http;

DatabaseService _databaseService = DatabaseService(FirebaseAuth.instance.currentUser!.uid);

String clientId = _databaseService.cid ?? 'default'; // Replace 'default' with your actual default client ID
String documentName = 'TestPdf$clientId.pdf'; // Construct the document name

void downloadToFiles(String documentName) async {
  Directory downloadDir = await getApplicationDocumentsDirectory();
  var path = '${downloadDir.path}/$documentName';
  var file = File(path);
  var res = await http.get(Uri.parse('https://source.unsplash.com/random')); 
  await file.writeAsBytes(res.bodyBytes);
  print('File downloaded to: $path');

  // Open share options
}

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
    } else {
      print('Download failed: File data is null');
    }
  } catch (e) {
    print('Download error: $e');
  }

  return filePath;
}