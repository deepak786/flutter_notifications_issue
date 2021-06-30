import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notifications_issue/home.dart';
import 'package:notifications_issue/utils_notification.dart';

/// top level function to listen for messages in the background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // received the message when the app was in background
  await NotificationUtils().handleNewNotification(message, true);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize the firebase
  await Firebase.initializeApp();

  // listen for background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // firebase messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  // request for notification permission
  // only applicable for iOS, Mac, Web. For the Android the result is always authorized.
  // ignore: unused_local_variable
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // initialize the notifications
  if (!kIsWeb) {
    // ic_notification is a drawable source added in the Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();

    // initialise the plugin
    await plugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
      // notification tapped
      if (payload != null) {
        Map<String, dynamic> data = jsonDecode(payload);
        await NotificationUtils().handleNotificationData(data);
      }
    });

    // create the channel
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
            NotificationUtils().androidNotificationChannel);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
