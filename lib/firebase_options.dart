// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAAzHGFJAMXNvdYfwbh8AA4lUY2F0sodIw',
    appId: '1:957281597606:web:c0ce35ed864d862118dc67',
    messagingSenderId: '957281597606',
    projectId: 'team-shaikh-app-52dc5',
    authDomain: 'team-shaikh-app-52dc5.firebaseapp.com',
    storageBucket: 'team-shaikh-app-52dc5.appspot.com',
    measurementId: 'G-S51WKX2KS3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDp7hVIVaZdrv2N_ig68lCMh17jp1uisA0',
    appId: '1:957281597606:android:c68e066ad43815b518dc67',
    messagingSenderId: '957281597606',
    projectId: 'team-shaikh-app-52dc5',
    storageBucket: 'team-shaikh-app-52dc5.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJTRrvHA_e7dKQTxIJ6XEv9PeVRXshjYE',
    appId: '1:957281597606:ios:3f79d3021f5018ec18dc67',
    messagingSenderId: '957281597606',
    projectId: 'team-shaikh-app-52dc5',
    storageBucket: 'team-shaikh-app-52dc5.appspot.com',
    iosBundleId: 'com.example.teamShaikhApp',
  );
}
