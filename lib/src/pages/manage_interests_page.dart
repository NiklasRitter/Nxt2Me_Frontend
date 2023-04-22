import 'dart:convert';

import 'package:event_app/main.dart';
import 'package:event_app/src/elements/manage_interests_widget.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utility/util_functions.dart';

class ManageInterestsPage extends StatefulWidget {
  const ManageInterestsPage({Key? key}) : super(key: key);

  @override
  ManageInterestsPageState createState() => ManageInterestsPageState();
}

class ManageInterestsPageState extends State<ManageInterestsPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Categories categories = Categories();
  Map<String, bool> pushNotificationValue = {
    "pushNotificationValue": false,
  };

  Map<String, String> errorMap = {"error": ""};

  @override
  void initState() {
    super.initState();
    loadPushNotificationSettings();
  }

  /// loads whether the user has push notifications enabled
  Future<void> loadPushNotificationSettings() async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      if(mounted) {
        setState(() {
          errorMap["error"] =
          "Device in offline mode! Edit Push Notifications not possible.";
        });
      }
      return;
    }
    http.Response responseUser = await network.getUser();
    var user = json.decode(responseUser.body);

    if (user["pushNotificationToken"] != "") {
      if (mounted) {
        setState(() {
          pushNotificationValue["pushNotificationValue"] = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
         pushNotificationValue["pushNotificationValue"] = false;
       });
      }
    }
    if (mounted) {
      setState(() {
        categories.withStartParameters(user["subscribedCategories"]);
      });
    }
  }

  /// save the categories, the user is interested in and enable/disable notifications
  Future<void> saveInterestsSettings() async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      return Utils.showOfflineBanner();
    }
    if (pushNotificationValue["pushNotificationValue"]!) {
      await pushNotificationController.enablePushNotifications();
    } else {
      await pushNotificationController.disablePushNotifications();
    }

    var res = await network.updateSubscribedCategories(categories.toList());
    if (res.statusCode == 200) {
      Navigator.pop(context);
    } else {
      if (mounted) {
        setState(() {
          errorMap["error"] = res.body;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ManageInterestsWidget(
      pageName: 'Manage Interests',
      backToLastPage: () async {
        Navigator.pop(context);
      },
      saveChanges: saveInterestsSettings,
      categories: categories,
      pushNotificationValueMap: pushNotificationValue,
      showPushNotificationOption: true,
      errorMap: errorMap,
    );
  }
}
