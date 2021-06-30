import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// class to have functions related to notifications
class NotificationUtils {
  /// to create a single instance
  factory NotificationUtils() {
    _instance ??= NotificationUtils._();
    return _instance!;
  }

  NotificationUtils._();

  static NotificationUtils? _instance;

  // create a notification channel in Android
  AndroidNotificationChannel androidNotificationChannel =
      const AndroidNotificationChannel(
    'agenda_boa_notification_channel', // id
    'Agenda BOA notifications', // title
    'Channel to show the app notifications.', // description
    importance: Importance.max,
    playSound: true,
  );

  /// handle the new received notification.
  /// [fromBackground] = is this [message] is from background?
  Future<void> handleNewNotification(
      RemoteMessage message, bool fromBackground) async {
    debugPrint(
        'Handling a ${fromBackground ? "background" : "foreground"} message ${message.messageId}');
    if (fromBackground) {
      // If you're going to use other Firebase services in the background, such as Firestore,
      // make sure you call `initializeApp` before using other Firebase services.
      await Firebase.initializeApp();
    }

    // display the notification manually
    // 1. if the [fromBackground] is false i.e.the notification is when the app was foreground.
    // 2. if [RemoteNotification] is null in [message] i.e. [message.notification] is null.
    RemoteNotification? notification = message.notification;
    if (notification == null) {
      // there is no notification in the message.
      // probably this is silent push
      if (fromBackground && kIsWeb) {
        // the silent push is from background and in the web we can't display the local notification as the package flutter_local_notifications doesn't support that.
        return;
      }

      // TODO handle the silent push

      return; // silent push is handled
    }

    if (!fromBackground && notification != null) {
      // the push is from foreground
      // here we need to manually display the notification

      String? imageUrl = kIsWeb
          ? ''
          : (Platform.isAndroid
              ? notification.android?.imageUrl
              : notification.apple?.imageUrl);
      displayLocalNotification(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        imageUrl: imageUrl,
        data: message.data,
      );

      return; // foreground push is handled
    }
  }

  /// handle the notification [data] when the user taps on the notification.
  Future<void> handleNotificationData(Map<String, dynamic> data) async {
    // maybe here we need to open specific screen or link
    debugPrint("notification data is >>>> $data");
    // TODO handle the notification data
  }

  /// display a local notification
  void displayLocalNotification({
    required int id,
    required String? title,
    required String? body,
    String? imageUrl = "",
    Map<String, dynamic> data = const {},
  }) async {
    if (kIsWeb) {
      // TODO display the notification as toast in web
    } else {
      // display the local notification with flutter_local_notifications
      // currently this package doesn't work with web.
      bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
      StyleInformation notificationStyle = BigTextStyleInformation(body!);
      AndroidBitmap? largeIcon;
      if (hasImage) {
        // load the image
        File imageFile = await DefaultCacheManager().getSingleFile(imageUrl);
        notificationStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(imageFile.path),
          hideExpandedLargeIcon: true,
        );
        largeIcon = FilePathAndroidBitmap(imageFile.path);
      }
      FlutterLocalNotificationsPlugin().show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidNotificationChannel.id,
            androidNotificationChannel.name,
            androidNotificationChannel.description,
            color: const Color(0xFF242157),
            ticker: title,
            importance: Importance.high,
            // priority is required for heads up in android <= 7.1
            priority: Priority.high,
            largeIcon: largeIcon,
            styleInformation: notificationStyle,
          ),
        ),
        payload: data != null ? jsonEncode(data) : null,
      );
    }
  }
}
