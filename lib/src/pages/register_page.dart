import 'dart:async';

import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/elements/selected_categories_widget.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:event_app/src/pages/manage_interests_register_page.dart';
import 'package:event_app/src/utility/custom_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

import '../utility/util_functions.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController passwordConfirmationController;
  late TextEditingController usernameController;
  late bool passwordVisibility;
  late bool confirmationPasswordVisibility;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String registerErrorText = "";
  late Categories categories;
  List<String> selectedCategories = [];
  bool inputPushNotificationEnabled = false;

  Future<void> _registerUser() async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      return Utils.showOfflineBanner();
    }

    if (categories.validateSelection() == false) {
      if (mounted) {
        setState(() {
          registerErrorText = 'Please select at least one category!';
        });
      }
      return;
    }

    RegExp regExp = RegExp(
      r"^[\s]*[a-zA-Z0-9]+[\s]?[a-zA-Z0-9]+$|^[a-zA-Z0-9]+[\s]*$",
      caseSensitive: false,
      multiLine: false,
    );

    if (!regExp.hasMatch(usernameController.value.text)) {
      if (mounted) {
        setState(() {
          registerErrorText =
              'Username can only contain letters, digits and one whitespace';
        });
      }
      return;
    }

    // Remove all whitespaces before and behind the e-mail and username
    String trimmedEMail = emailController.value.text.trim();
    String trimmedUsername = usernameController.value.text.trim();

    try {
      await network.registerEmailUser(
          trimmedEMail,
          passwordController.value.text,
          passwordConfirmationController.value.text,
          trimmedUsername);

      await network
          .createSession(trimmedEMail, passwordController.value.text)
          .then((http.Response loginState) async {
        if (loginState.statusCode == 200) {
          appState.secStorageCtrl
              .writeSecureData(Constants.LAST_LOGIN_EMAIL, trimmedEMail);

          appState.user.categories =
              Categories().withStartParameters(selectedCategories);

          await appState.sqliteDbUsers.updateUser(appState.user);
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/explorePage', (Route<dynamic> route) => false);

          network.updateSubscribedCategories(selectedCategories);
          if (inputPushNotificationEnabled) {
            pushNotificationController.enablePushNotifications();
          } else {
            pushNotificationController.disablePushNotifications();
          }
        }
      });
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      if (mounted) {
        setState(() {
          registerErrorText = 'Connection Timeout';
        });
      }
    } on CustomException catch (e) {
      if (mounted) {
        setState(() {
          registerErrorText = e.toString();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      if (mounted) {
        setState(() {
          registerErrorText = 'Error in register process';
        });
      }
    }
  }

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
    if (mounted) {
      setState(() {
        selectedCategories.clear();
        selectedCategories.addAll(result[0].toList());
        inputPushNotificationEnabled = result[1];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    passwordConfirmationController = TextEditingController();
    usernameController = TextEditingController();
    passwordVisibility = false;
    confirmationPasswordVisibility = false;
    categories = Categories();
    Categories().withStartParameters([]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const ScrollPhysics(),
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: const Color(0xFF262D34),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: Image.asset(
                    'assets/images/Party.jpg',
                  ).image,
                ),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  MediaQuery.of(context).size.width * 0.05,
                  MediaQuery.of(context).size.height * 0.12,
                  MediaQuery.of(context).size.width * 0.05,
                  MediaQuery.of(context).size.height * 0.25,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Constants.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 0),
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: const [
                              Expanded(
                                child: Text(
                                  'Hello my Friend!',
                                  style: MyTextStyle(
                                    cFontWeight: FontWeight.bold,
                                    cFontSize: 25,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(5, 0, 0, 5),
                                child: Text("Username", style: MyTextStyle()),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: usernameController,
                                      obscureText: false,
                                      decoration:
                                          const CustomFormFieldInputDecoration(
                                        hintText: 'Enter your username here...',
                                      ),
                                      style: const MyTextStyle(
                                        cColor: Colors.black,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(5, 0, 0, 5),
                                child: Text("E-Mail", style: MyTextStyle()),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: emailController,
                                      obscureText: false,
                                      decoration:
                                          const CustomFormFieldInputDecoration(
                                              hintText:
                                                  'Enter your email here...'),
                                      style: const MyTextStyle(
                                        cColor: Colors.black,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(5, 0, 0, 5),
                                child: Text("Password", style: MyTextStyle()),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: passwordController,
                                      obscureText: !passwordVisibility,
                                      decoration:
                                          CustomFormFieldInputDecoration(
                                        hintText: 'Enter your password here...',
                                        suffixIcon: InkWell(
                                          onTap: () {
                                            if (mounted) {
                                              setState(() {
                                                passwordVisibility =
                                                    !passwordVisibility;
                                              });
                                            }
                                          },
                                          child: Icon(
                                            passwordVisibility
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: Colors.grey,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      style: const MyTextStyle(
                                        cColor: Colors.black,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(5, 0, 0, 5),
                                child: Text("Confirm Password",
                                    style: MyTextStyle()),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller:
                                          passwordConfirmationController,
                                      obscureText:
                                          !confirmationPasswordVisibility,
                                      decoration:
                                          CustomFormFieldInputDecoration(
                                        hintText:
                                            'Confirm your password here ...',
                                        suffixIcon: InkWell(
                                          onTap: () {
                                            if (mounted) {
                                              setState(() {
                                                confirmationPasswordVisibility =
                                                    !confirmationPasswordVisibility;
                                              });
                                            }
                                          },
                                          child: Icon(
                                            confirmationPasswordVisibility
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: Colors.grey,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      style: const MyTextStyle(
                                        cColor: Colors.black,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
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
                        ),
                        registerErrorText.isEmpty
                            ? Container()
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                child: Text(registerErrorText,
                                    style:
                                        const MyTextStyle(cColor: Colors.red),
                                    overflow: TextOverflow.visible),
                              ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
                          child: CustomButton(
                            width: MediaQuery.of(context).size.width,
                            onPressed: _registerUser,
                            text: 'Register',
                            buttonTextStyle:
                                const ButtonTextStyle(cFontSize: 14),
                          ),
                        ),
                        const Divider(
                          height: 2,
                          thickness: 2,
                          color: Color(0xFFDBE2E7),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0, 12, 0, 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: CustomButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                        context, '/login');
                                  },
                                  text: "Sign In",
                                  width: 120,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
