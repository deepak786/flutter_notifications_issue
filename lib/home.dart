import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notifications_issue/utils_notification.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    // get the notification token
    FirebaseMessaging.instance.getToken().then(_savePushToken);

    // listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_savePushToken);

    // Get any messages which caused the application to open from
    // a terminated state.
    FirebaseMessaging.instance.getInitialMessage().then((initialMessage) async {
      if (initialMessage != null) {
        await NotificationUtils().handleNotificationData(initialMessage.data);
      }
    });

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await NotificationUtils().handleNotificationData(message.data);
    });

    // listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // received the message while the app was foreground
      // here the notification is not shown automatically.
      await NotificationUtils().handleNewNotification(message, false);
    });

    if (!kIsWeb) {
      // get the local notification details if the app is opened from that local notification
      FlutterLocalNotificationsPlugin()
          .getNotificationAppLaunchDetails()
          .then((localNotificationDetails) async {
        if (localNotificationDetails != null &&
            localNotificationDetails.didNotificationLaunchApp) {
          String? payload = localNotificationDetails.payload;
          if (payload != null) {
            Map<String, dynamic> data = jsonDecode(payload);
            await NotificationUtils().handleNotificationData(data);
          }
        }
      });
    }
  }

  /// save the push token to server
  Future<void> _savePushToken(String? fcmToken) async {
    debugPrint("FCM token is >>>>> $fcmToken");
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
