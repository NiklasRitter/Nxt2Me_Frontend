import 'dart:convert';

import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/pages/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late TextEditingController oldPasswordController;
  late bool oldPasswordVisibility;
  late TextEditingController newPasswordController;
  late bool newPasswordVisibility;
  late TextEditingController newConfirmPasswordController;
  late bool newConfirmPasswordVisibility;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String errorText = '';
  String successText = '';

  @override
  void initState() {
    super.initState();
    oldPasswordController = TextEditingController();
    oldPasswordVisibility = false;
    newPasswordController = TextEditingController();
    newPasswordVisibility = false;
    newConfirmPasswordController = TextEditingController();
    newConfirmPasswordVisibility = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Constants.backgroundColor,
        leading: IconButton(
          iconSize: 22,
          padding: const EdgeInsets.all(5.0),
          splashRadius: 25,
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () async {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Change Password',
          style: MyTextStyle(
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 8, 16, 8),
                          child: TextFormField(
                            controller: oldPasswordController,
                            obscureText: !oldPasswordVisibility,
                            decoration: CustomFormFieldInputDecoration(
                              hintText: 'Old Password',
                              suffixIcon: InkWell(
                                onTap: () => setState(
                                  () => oldPasswordVisibility =
                                      !oldPasswordVisibility,
                                ),
                                child: Icon(
                                  oldPasswordVisibility
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Constants.hintTextColor,
                                  size: 22,
                                ),
                              ),
                            ),
                            style: const MyTextStyle(
                              cColor: Colors.black,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 8, 16, 8),
                          child: TextFormField(
                            controller: newPasswordController,
                            obscureText: !newPasswordVisibility,
                            decoration: CustomFormFieldInputDecoration(
                              hintText: 'New Password',
                              suffixIcon: InkWell(
                                onTap: () => setState(
                                  () => newPasswordVisibility =
                                      !newPasswordVisibility,
                                ),
                                child: Icon(
                                  newPasswordVisibility
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Constants.hintTextColor,
                                  size: 22,
                                ),
                              ),
                            ),
                            style: const MyTextStyle(
                              cColor: Colors.black,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 8, 16, 8),
                          child: TextFormField(
                            controller: newConfirmPasswordController,
                            obscureText: !newConfirmPasswordVisibility,
                            decoration: CustomFormFieldInputDecoration(
                              hintText: 'Confirm New Password',
                              suffixIcon: InkWell(
                                onTap: () => setState(
                                  () => newConfirmPasswordVisibility =
                                      !newConfirmPasswordVisibility,
                                ),
                                child: Icon(
                                  newConfirmPasswordVisibility
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Constants.hintTextColor,
                                  size: 22,
                                ),
                              ),
                            ),
                            style: const MyTextStyle(
                              cColor: Colors.black,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Text(
                  errorText,
                  overflow: TextOverflow.visible,
                  style: const MyTextStyle(cColor: Colors.red),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: CustomButton(
                          color: Constants.backgroundColor,
                          elevation: 0,
                          overlayColor: Constants.transparent,
                          onPressed: () async {
                            // navigate to forgot password page
                            await Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.fade,
                                duration: const Duration(milliseconds: 250),
                                reverseDuration:
                                    const Duration(milliseconds: 250),
                                child: const ForgotPasswordPage(),
                              ),
                            );
                          },
                          text: 'Forgot Password?',
                        ),
                      ),
                      Expanded(
                        child: CustomButton(
                          onPressed: () async {
                            if ((appState.offlineMode == true ||
                                appState.serverAlive == false)) {
                              if (mounted) {
                                setState(() {
                                  errorText =
                                      "Changing password not possible in offline mode!";
                                  successText = '';
                                  oldPasswordController.clear();
                                  newPasswordController.clear();
                                });
                              }
                              return;
                            }

                            var res = await network.changePassword(
                                oldPasswordController.value.text,
                                newPasswordController.value.text,
                                newConfirmPasswordController.value.text);
                            if (res.statusCode == 200) {
                              setState(() {
                                successText = "Password change was successful";
                                errorText = '';
                              });
                            } else {
                              var jsonString = json.decode(res.body);
                              setState(() {
                                errorText = jsonString[0]['message'].toString();
                              });
                            }
                          },
                          text: 'Change',
                        ),
                      )
                    ],
                  ),
                ),
                Text(
                  successText,
                  overflow: TextOverflow.visible,
                  style: const MyTextStyle(cColor: Colors.green),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
