import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:flutter/material.dart';

class Utils {
  static void showOfflineBanner() {
    ScaffoldMessenger.of(navigatorKey.currentContext!)
        .showSnackBar(const SnackBar(
      content: Text(
        Constants.OFFLINE_UNAVAILABLE,
        style: MyTextStyle(),
      ),
      duration: Duration(milliseconds: 1000),
      backgroundColor: Colors.red,
    ));
  }
}
