import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _hasNavigatedToFaceIDPage = false;
  bool _justAuthenticated = false;
  bool _initiallyAuthenticated = false;

  // Getter for _hasNavigatedToFaceIDPage
  bool get hasNavigatedToFaceIDPage => _hasNavigatedToFaceIDPage;

  // Getter for _justAuthenticated
  bool get justAuthenticated => _justAuthenticated;

  // Getter for _initiallyAuthenticated
  bool get initiallyAuthenticated => _initiallyAuthenticated;


  // Setter for _hasNavigatedToFaceIDPage
  void setHasNavigatedToFaceIDPage(bool value) {
    _hasNavigatedToFaceIDPage = value;
    notifyListeners();

  }

  // Setter for _justAuthenticated
  void setJustAuthenticated(bool value) {
    _justAuthenticated = value;
    notifyListeners();

  }

  // Setter for _initiallyAuthenticated
  void setInitiallyAuthenticated(bool value) {
    _initiallyAuthenticated = value;
    notifyListeners();
  }

}