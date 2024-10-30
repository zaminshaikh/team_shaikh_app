// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final notifications.FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = notifications.FlutterLocalNotificationsPlugin();

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(provisional: true);

      log('User granted permission: ${settings.authorizationStatus}');

      // Initialize local notifications
      const notifications.AndroidInitializationSettings initializationSettingsAndroid = notifications.AndroidInitializationSettings('@mipmap/team_shaikh_app_icon');
      const notifications.DarwinInitializationSettings initializationSettingsIOS = notifications.DarwinInitializationSettings();
      const notifications.InitializationSettings initializationSettings = notifications.InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // For apple platforms, ensure the APNS token is available before making any FCM plugin API calls
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (Platform.isIOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          // APNs token is available, proceed to get FCM token
          String? token = await FirebaseMessaging.instance.getToken();
          log('FCM Token: $token');

          // Handle background messages
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

          // Handle foreground messages
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            log('Received a message while in the foreground: ${message.messageId}');
            // Your message handling logic
          });

        } else {
          log('Failed to get APNs token');
        }
      } else {
        // For Android, directly get the FCM token
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          log('FCM Token: $token');

          // Handle background messages
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

          // Handle foreground messages
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            log('Received a message while in the foreground: ${message.messageId}');
            // Your message handling logic
          });

        } else {
          log('Failed to get FCM token');
        }
      } 
    } catch (e) {
      log('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> _showNotification(RemoteNotification notification) async {
    log('Showing notification with title: ${notification.title} and body: ${notification.body}');
    
    const notifications.AndroidNotificationDetails androidPlatformChannelSpecifics = notifications.AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: notifications.Importance.max,
      priority: notifications.Priority.high,
      showWhen: false,
    );

    const notifications.NotificationDetails platformChannelSpecifics = notifications.NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await _flutterLocalNotificationsPlugin.show(
        0,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: 'item x',
      );
      log('Notification shown successfully');
    } catch (e) {
      log('Error showing notification: $e');
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Handling a background message: ${message.messageId}');
}