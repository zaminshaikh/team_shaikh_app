import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _hasNavigatedToFaceIDPage = false;
  bool _justAuthenticated = false;

  // Getter for _hasNavigatedToFaceIDPage
  bool get hasNavigatedToFaceIDPage => _hasNavigatedToFaceIDPage;

  // Getter for _justAuthenticated
  bool get justAuthenticated => _justAuthenticated;

  // Setter for _hasNavigatedToFaceIDPage
  void setHasNavigatedToFaceIDPage(bool value) {
    _hasNavigatedToFaceIDPage = value;
    notifyListeners();

    // Print statement to indicate that _hasNavigatedToFaceIDPage has been updated
  }

  // Setter for _justAuthenticated
  void setJustAuthenticated(bool value) {
    _justAuthenticated = value;
    notifyListeners();

    // Print statement to indicate that _justAuthenticated has been updated
  }
}