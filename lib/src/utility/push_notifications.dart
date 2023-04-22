import 'dart:convert';

import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/model/event.dart';
import 'package:event_app/src/pages/event_detail_page.dart';
import 'package:event_app/src/pages/explore_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class PushNotificationController {
  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    "eventappks",
    "eventapp_ks_channel",
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// enable push notifications
  Future<void> enablePushNotifications() async {
    await _requestPushNotificationPermission();
    await _initialize();
    await _listenFCM();
    await _setDeviceToken();
  }

  /// disable push notifications
  Future<void> disablePushNotifications() async {
    await _deleteDeviceToken();
  }

  /// set device token to target device with push notification
  Future<void> _setDeviceToken() async {
    String token = await _getDeviceToken();
    if (token != "") {
      await network.updatePushNotificationToken(token);
    }
    await appState.secStorageCtrl
        .writeSecureData(Constants.PUSH_NOTIFICATION_TOKEN, token);
  }

  /// delete device specific token
  Future<void> _deleteDeviceToken() async {
    await network.updatePushNotificationToken("");
    await appState.secStorageCtrl
        .deleteSecureData(Constants.PUSH_NOTIFICATION_TOKEN);
  }

  /// get device token to target device with push notification
  Future<String> _getDeviceToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      return token;
    } else {
      return "";
    }
  }

  /// initialize and handle on tap when app in foreground
  Future<void> _initialize() async {
    // initializationSettings for Android
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
    );

    /// on push notification tap, app in foreground
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (String? eventId) async {
        if (eventId!.isNotEmpty) {
          _handleMessageOnTap(eventId);
        }
      },
    );
  }

  /// request permission to receive push notification
  Future<void> _requestPushNotificationPermission() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  /// listen for push notifications
  Future<void> _listenFCM() async {
    /// handle push notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (!kIsWeb) {
        try {
          NotificationDetails notificationDetails = NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              importance: Importance.max,
              priority: Priority.high,
              color: Constants.themeColor,
            ),
          );

          await flutterLocalNotificationsPlugin.show(
            message.hashCode,
            message.data['title'],
            message.data['body'],
            notificationDetails,
            payload: message.data['event'],
          );
        } on Exception catch (e) {
          if (kDebugMode) {
            print("error:" + e.toString());
          }
        }
      }
    });

    /// on push notification tap, app in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      String eventId = message.data['event'];
      _handleMessageOnTap(eventId);
    });

    /// on push notification tap, app terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      if (message != null) {
        String eventId = message.data['event'];
        _handleMessageOnTap(eventId);
      }
    });
  }

  Future<void> routeToExplorePage(String snackBarText) async {
    if (Navigator.canPop(navigatorKey.currentContext!)) {
      Navigator.pushReplacement(
          navigatorKey.currentContext!,
          MaterialPageRoute(
              builder: (context) => const ExplorePage(key: null)));
    } else {
      Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
              builder: (context) => const ExplorePage(key: null)));
    }

    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        snackBarText,
        style: const MyTextStyle(),
      ),
      duration: const Duration(milliseconds: 3000),
      backgroundColor: Colors.red,
    ));
  }

  /// handle push notification on tap
  Future<void> _handleMessageOnTap(String eventId) async {
    http.Response eventResponse = await network.getEvent(eventId);
    if (eventResponse.statusCode == 429) {
      routeToExplorePage("Event View limit is reached.");
    } else {
      Event event = Event.fromJson(json.decode(eventResponse.body));

      // Event should be removed
      if (!event.valid!) {
        await appState.sqliteDbEvents.deleteEvent(event.eventId);
        routeToExplorePage("Event was deleted by its owner");
      } else {
        // route to event page
        if (Navigator.canPop(navigatorKey.currentContext!)) {
          Navigator.pushReplacement(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                  builder: (context) =>
                      EventDetailsPage(key: null, event: event)));
        } else {
          Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                  builder: (context) =>
                      EventDetailsPage(key: null, event: event)));
        }
      }
    }
  }
}
