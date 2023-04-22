import 'dart:async';

import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/utility/util_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late TextEditingController emailController;

  String afterButtonActionText = "";
  String errorText = "";

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.backgroundColor,
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
          onPressed: () async {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Forgot Password',
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
      body: SafeArea(
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
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                        child: TextFormField(
                          controller: emailController,
                          decoration: const CustomFormFieldInputDecoration(
                            hintText: 'E-Mail',
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
                padding: const EdgeInsetsDirectional.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      width: 200,
                      onPressed: () async {
                        if (appState.offlineMode == true ||
                            appState.serverAlive == false) {
                          return Utils.showOfflineBanner();
                        }

                        if (emailController.value.text.trim() == "") {
                          if (mounted) {
                            setState(() {
                              afterButtonActionText = "";
                              errorText = "Type in your email address";
                            });
                          }
                        } else {
                          try {
                            var res = await network.forgotPassword(
                                emailController.value.text.trim());

                            if (res.statusCode == 200) {
                              if (mounted) {
                                setState(() {
                                  afterButtonActionText =
                                      "We sent you an email to reset your password. Please take a look into your inbox and follow the link.";
                                  errorText = "";
                                });
                              }
                            } else {
                              if (mounted) {
                                setState(() {
                                  afterButtonActionText = "";
                                  errorText = res.body;
                                });
                              }
                            }
                          } on TimeoutException catch (e) {
                            if (kDebugMode) {
                              print(e.toString());
                            }
                            if (mounted) {
                              setState(() {
                                errorText = 'Connection Timeout';
                              });
                            }
                          } catch (e) {
                            if (kDebugMode) {
                              print(e.toString());
                            }
                            if (mounted) {
                              setState(() {
                                errorText = 'Error in signIn process';
                              });
                            }
                          }
                        }
                      },
                      text: 'Reset Password',
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                child: Text(
                  afterButtonActionText,
                  style: const MyTextStyle(),
                  overflow: TextOverflow.clip,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                child: Text(
                  errorText,
                  style: const MyTextStyle(cColor: Colors.red),
                  overflow: TextOverflow.clip,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
