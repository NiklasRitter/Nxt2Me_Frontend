import 'package:event_app/src/elements/manage_interests_widget.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:flutter/material.dart';

class ManageInterestsRegisterPage extends StatefulWidget {
  const ManageInterestsRegisterPage(
      {Key? key,
      required this.inputCategories,
      required this.inputPushNotificationEnabled})
      : super(key: key);
  final Categories inputCategories;
  final bool inputPushNotificationEnabled;

  @override
  ManageInterestsRegisterPageState createState() =>
      ManageInterestsRegisterPageState();
}

class ManageInterestsRegisterPageState
    extends State<ManageInterestsRegisterPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  Categories currentCategories = Categories();
  late Categories inputCategories;
  late bool inputPushNotificationEnabled;
  Map<String, bool> pushNotificationValue = {
    "pushNotificationValue": false,
  };

  late Map<String, dynamic> result;

  @override
  void initState() {
    inputCategories = widget.inputCategories;
    pushNotificationValue["pushNotificationValue"] =
        widget.inputPushNotificationEnabled;
    // copy values to a new categories object for optionally dropping all changes on inputCategories
    inputPushNotificationEnabled = widget.inputPushNotificationEnabled;
    currentCategories.copyFromExistingCategories(inputCategories);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ManageInterestsWidget(
      pageName: 'Select Categories',
      backToLastPage: () async {
        //return unmodified values
        Navigator.pop(context, [inputCategories, inputPushNotificationEnabled]);
      },
      saveChanges: () {
        Navigator.pop(context, [
          currentCategories,
          pushNotificationValue["pushNotificationValue"]
        ]);
      },
      categories: currentCategories,
      pushNotificationValueMap: pushNotificationValue,
      showPushNotificationOption: true,
      errorMap: const {},
    );
  }
}
