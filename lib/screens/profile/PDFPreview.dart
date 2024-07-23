import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:team_shaikh_app/resources.dart';

class PDFScreen extends StatelessWidget {
  final String path;

  PDFScreen(this.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.defaultBlueGray700,
        title: Text(
          'PDF Preview',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Titillium Web',
          ),
        ),
      ),
      body: PDFView(
        filePath: path,
      ),
    );
  }
}