import 'package:event_app/src/elements/manage_interests_widget.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:flutter/material.dart';

class SelectCategoryPage extends StatefulWidget {
  const SelectCategoryPage({Key? key, required this.inputCategories})
      : super(key: key);

  final Categories inputCategories;

  @override
  _SelectCategoryPageState createState() => _SelectCategoryPageState();
}

class _SelectCategoryPageState extends State<SelectCategoryPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  Categories currentCategories = Categories();
  late Categories inputCategories;
  bool switchListTileValue = false;

  @override
  void initState() {
    inputCategories = widget.inputCategories;
    // copy values to a new categories object for optionally dropping all changes on inputCategories
    currentCategories.copyFromExistingCategories(inputCategories);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ManageInterestsWidget(
      pageName: 'Select Categories',
      backToLastPage: () async {
        Navigator.pop(context, inputCategories);
      },
      saveChanges: () {
        Navigator.pop(context, currentCategories);
      },
      categories: currentCategories,
      pushNotificationValueMap: const {},
      showPushNotificationOption: false,
      errorMap: const {},
    );
  }
}
