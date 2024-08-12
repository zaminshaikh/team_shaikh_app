import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/scheduler.dart' as scheduler;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final notifications.FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = notifications.FlutterLocalNotificationsPlugin();

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(provisional: true);

    log('User granted permission: ${settings.authorizationStatus}');

    // Initialize local notifications
    const notifications.AndroidInitializationSettings initializationSettingsAndroid = notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    const notifications.DarwinInitializationSettings initializationSettingsIOS = notifications.DarwinInitializationSettings();
    const notifications.InitializationSettings initializationSettings = notifications.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // For apple platforms, ensure the APNS token is available before making any FCM plugin API calls
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken != null) {
      // APNS token is available, make FCM plugin API requests...
      // Get the FCM token
      String? token = await _firebaseMessaging.getToken();
      log('database_messaging.dart: FCM Token: $token');

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Received a message while in the foreground: ${message.messageId}');
        if (message.notification != null) {
          log('Notification Title: ${message.notification!.title}');
          log('Notification Body: ${message.notification!.body}');
          _showNotification(message.notification!);
        }
      });

      // Handle when the app is launched from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('Message clicked!');
      });
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