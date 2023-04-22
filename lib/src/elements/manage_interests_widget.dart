import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/elements/switch_list_tile.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:flutter/material.dart';

class ManageInterestsWidget extends StatefulWidget {
  /// generalized widget for Interests management
  const ManageInterestsWidget({
    Key? key,
    required this.pageName,
    required this.backToLastPage,
    required this.saveChanges,
    required this.categories,
    required this.pushNotificationValueMap,
    required this.showPushNotificationOption,
    required this.errorMap,
  }) : super(key: key);
  final String pageName;
  final void Function()? backToLastPage;
  final void Function()? saveChanges;
  final Categories categories;
  final Map<String, bool> pushNotificationValueMap;
  final bool showPushNotificationOption;
  final Map<String, String> errorMap;

  @override
  ManageInterestsWidgetState createState() => ManageInterestsWidgetState();
}

class ManageInterestsWidgetState extends State<ManageInterestsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late String pageName;
  late void Function()? backToLastPage;
  late void Function()? saveChanges;
  late Categories categories;
  late Map<String, bool> pushNotificationValueMap;
  late bool showPushNotificationOption;
  late Map<String, String> errorMap;

  @override
  void initState() {
    super.initState();
    pageName = widget.pageName;
    backToLastPage = widget.backToLastPage;
    saveChanges = widget.saveChanges;
    categories = widget.categories;
    pushNotificationValueMap = widget.pushNotificationValueMap;
    showPushNotificationOption = widget.showPushNotificationOption;
    errorMap = widget.errorMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Constants.backgroundColor,
        title: Text(
          pageName,
          style: const MyTextStyle(
            cFontSize: Constants.pageHeadingFontSize,
            cFontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          iconSize: 22,
          padding: const EdgeInsets.all(5.0),
          splashRadius: 25,
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 30,
          ),
          onPressed: backToLastPage,
        ),
        centerTitle: false,
        elevation: 0,
      ),
      backgroundColor: Constants.backgroundColor,
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            showPushNotificationOption
                ? Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                          child: SwitchListTile.adaptive(
                            value: pushNotificationValueMap[
                                "pushNotificationValue"]!,
                            onChanged: (newValue) => setState(() {
                              pushNotificationValueMap[
                                  "pushNotificationValue"] = newValue;
                            }),
                            title: const Text(
                              'Push Notifications',
                              style: MyTextStyle(
                                cFontSize: 16,
                                cFontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              'Stay updated on new events',
                              style: MyTextStyle(
                                cFontSize: 12,
                              ),
                            ),
                            activeColor: Colors.white,
                            activeTrackColor: Constants.themeColor,
                            dense: false,
                            controlAffinity: ListTileControlAffinity.trailing,
                            contentPadding:
                                const EdgeInsetsDirectional.fromSTEB(
                                    24, 12, 24, 12),
                          ),
                        ),
                      )
                    ],
                  )
                : Container(),
            for (var category in categories.categoriesMap.keys)
              CustomSwitchListTile(
                key: UniqueKey(),
                categories: categories,
                text: category,
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 0),
              child: Row(
                children: [
                  Expanded(child: Container()),
                  Expanded(
                    child: CustomButton(
                      onPressed: saveChanges,
                      text: 'Save',
                      color: Constants.themeColor,
                      buttonTextStyle: const MyTextStyle(
                        cFontWeight: FontWeight.w500,
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              errorMap["error"] != null ? errorMap["error"]! : "",
              style: const MyTextStyle(cColor: Colors.red),
            )
          ],
        ),
      ),
    );
  }
}
