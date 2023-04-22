import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/elements/selected_categories_widget.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:event_app/src/pages/manage_interests_register_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage(
      {Key? key, required this.callback, required this.forceChange})
      : super(key: key);

  // refresh ancestor widget
  final Function() callback;

  // determine if a userName has to be set
  final bool forceChange;

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController usernameController;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String errorText = '';
  String successText = '';

  List<String> selectedCategories = [];
  bool inputPushNotificationEnabled = false;

  /// Catch the callback data of the opened child "filter categories page" with the users clicked categories
  void _awaitReturnValueFromSelectCategories(BuildContext context) async {
    final result = await Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 250),
          reverseDuration: const Duration(milliseconds: 250),
          child: ManageInterestsRegisterPage(
              key: UniqueKey(),
              inputCategories: categories,
              inputPushNotificationEnabled: inputPushNotificationEnabled),
          fullscreenDialog: true,
        ));

    // catch the selected categories
    categories = result[0];
    setState(() {
      selectedCategories.clear();
      selectedCategories.addAll(result[0].toList());
      inputPushNotificationEnabled = result[1];

      if (selectedCategories.isNotEmpty) {
        errorText = '';
      }
    });
  }

  /// Save Categories if user is registering with google
  Future<bool> _saveCategories() async {
    if (categories.validateSelection() == false) {
      setState(() {
        errorText = 'Please select at least one category!';
      });
      return false;
    }

    appState.user.categories =
        Categories().withStartParameters(selectedCategories);
    await appState.sqliteDbUsers.updateUser(appState.user);

    await network.updateSubscribedCategories(selectedCategories);
    if (inputPushNotificationEnabled) {
      await pushNotificationController.enablePushNotifications();
    } else {
      await pushNotificationController.disablePushNotifications();
    }
    return true;
  }

  /// Save username and potential category changes
  void _saveChanges() async {
    // if google register - save categories
    if (widget.forceChange) {
      if (!await _saveCategories()) return;
    }

    if (appState.offlineMode == true || appState.serverAlive == false) {
      if (mounted) {
        setState(() {
          errorText = 'Change username isn´t possible in offline mode!';
          successText = '';
        });
      }
      return;
    }

    if (usernameController.text.isEmpty) {
      if (mounted) {
        setState(() {
          errorText = 'Please type in a username!';
          successText = '';
        });
      }
      return;
    }

    // only strings that contain letters, digits and one whitespace
    RegExp regExp = RegExp(
      r"^[a-zA-Z0-9]+[\s]?[a-zA-Z0-9]+$|^[a-zA-Z0-9]+$",
      caseSensitive: false,
      multiLine: false,
    );

    if (!regExp.hasMatch(usernameController.text)) {
      if (mounted) {
        setState(() {
          errorText =
              'Username can only contain letters, digits and one whitespace';
        });
      }
      return;
    }

    http.Response res = await network.changeUsername(usernameController.text);

    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          appState.user.username = usernameController.text;
          appState.sqliteDbUsers.updateUser(appState.user);
          usernameController.clear();
          errorText = '';
          successText = 'Changing username successful!';
        });
      }
      // in case of register
      if (widget.forceChange) {
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/explorePage', (Route<dynamic> route) => false);
      }
    } else {
      if (mounted) {
        setState(() {
          errorText = res.body.toString();
          successText = '';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();

    categories = Categories();
    Categories().withStartParameters([]);
  }

  late Categories categories;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Constants.backgroundColor,
          automaticallyImplyLeading: false,
          leading: !widget.forceChange
              ? IconButton(
                  iconSize: 22,
                  padding: const EdgeInsets.all(5.0),
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () async {
                    widget.callback();
                    if (!widget.forceChange) {
                      Navigator.pop(context);
                    }
                  },
                )
              : Container(),
          title: Text(
            widget.forceChange ? 'Set Username' : 'Edit Username',
            style: const MyTextStyle(
              cFontSize: Constants.pageHeadingFontSize,
              cFontWeight: FontWeight.bold,
            ),
          ),
          actions: const [],
          centerTitle: false,
          elevation: 0,
        ),
        backgroundColor: Constants.backgroundColor,
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 40, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 0, 5),
                      child: Text(
                          widget.forceChange ? 'Set Username' : 'New Username',
                          style: const MyTextStyle()),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: usernameController,
                            obscureText: false,
                            decoration: CustomFormFieldInputDecoration(
                              hintText: widget.forceChange
                                  ? 'Type in your username'
                                  : 'Type in new username',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 10),
              successText.isNotEmpty
                  ? Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
                      child: Text(
                        successText,
                        overflow: TextOverflow.visible,
                        style: const MyTextStyle(cColor: Colors.green),
                      ),
                    )
                  : errorText.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              20, 0, 20, 0),
                          child: Text(
                            errorText,
                            overflow: TextOverflow.visible,
                            style: const MyTextStyle(cColor: Colors.red),
                          ),
                        )
                      : Container(),
              Container(height: 10),
              widget.forceChange
                  ? Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          MediaQuery.of(context).size.width * 0.05,
                          0,
                          MediaQuery.of(context).size.width * 0.05,
                          12),
                      child: TextButton(
                        onPressed: () {
                          _awaitReturnValueFromSelectCategories(context);
                        },
                        style: TextButton.styleFrom(
                          primary: Colors.white,
                          side: const BorderSide(
                              color: Constants.themeColor, width: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            selectedCategories.isEmpty
                                ? const Text("Select Categories")
                                : Expanded(
                                    child: SelectedCategoriesWidget(
                                        selectedCategories:
                                            selectedCategories)),
                            const Icon(Icons.chevron_right_rounded)
                          ],
                        ),
                      ),
                    )
                  : Container(),
              Container(height: 10),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 20, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomButton(
                      width: MediaQuery.of(context).size.width * 0.35,
                      onPressed: _saveChanges,
                      text: 'Save',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
