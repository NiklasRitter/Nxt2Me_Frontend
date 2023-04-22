import 'dart:async';
import 'dart:io';

import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/pages/edit_profile_page.dart';
import 'package:event_app/src/pages/forgot_password_page.dart';
import 'package:event_app/src/utility/custom_exception.dart';
import 'package:event_app/src/utility/signin_google_api.dart';
import 'package:event_app/src/utility/util_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController emailAddressController;
  late TextEditingController passwordController;
  late bool passwordVisibility;
  String loginErrorText = '';

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Start sign in process with google oauth and register the user on the server
  Future _signInGoogle() async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      return Utils.showOfflineBanner();
    }

    try {
      final googleUser = await SignInGoogleApi.login();

      if (googleUser != null) {
        http.Response res =
            await network.registerGoogleUser(googleUser.serverAuthCode!);

        if (res.statusCode == 201 ||
            appState.user.username == appState.user.email) {
          appState.secStorageCtrl
              .writeSecureData(Constants.LAST_LOGIN_EMAIL, appState.user.email);
          Navigator.of(context).pushAndRemoveUntil(
              PageTransition(
                type: PageTransitionType.fade,
                duration: const Duration(milliseconds: 250),
                reverseDuration: const Duration(milliseconds: 250),
                child: EditProfilePage(
                  callback: () {},
                  forceChange: true,
                ),
                fullscreenDialog: true,
              ),
              (Route<dynamic> route) => false);
        } else if (res.statusCode == 200) {
          appState.secStorageCtrl
              .writeSecureData(Constants.LAST_LOGIN_EMAIL, appState.user.email);
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/explorePage', (Route<dynamic> route) => false);
        } else {
          SignInGoogleApi.logout();
          if (mounted) {
            setState(() {
              loginErrorText = res.body.toString();
            });
          }
        }
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      if (mounted) {
        setState(() {
          loginErrorText = 'Connection Timeout';
        });
      }
    } on CustomException catch (e) {
      if (mounted) {
        setState(() {
          loginErrorText = e.toString();
          passwordController.clear();
        });
        await SignInGoogleApi.logout();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      if (mounted) {
        setState(() {
          loginErrorText = 'Error in signInGoogle process';
        });
      }
    }
  }

  /// Start sign in process with the normal credentials
  Future<void> _signInNormal() async {
    RegExp regExpEMail = RegExp(
      r"^[\s]*[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}[\s]*$",
      caseSensitive: false,
      multiLine: false,
    );

    // Check E-Mail if it is valid
    if (!regExpEMail.hasMatch(emailAddressController.value.text)) {
      if (mounted) {
        setState(() {
          loginErrorText = 'E-Mail is not valid!';
        });
      }
      return;
    }

    String trimmedEMail = emailAddressController.value.text.trim();

    try {
      await network
          .createSession(trimmedEMail, passwordController.value.text)
          .then((http.Response loginResponse) {
        if (loginResponse.statusCode == 200) {
          appState.secStorageCtrl
              .writeSecureData(Constants.LAST_LOGIN_EMAIL, trimmedEMail);
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/explorePage', (Route<dynamic> route) => false);
        }
      });
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      if (mounted) {
        setState(() {
          loginErrorText = 'Server is unreachable!';
        });
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      if (mounted) {
        setState(() {
          loginErrorText = 'Network is unreachable!';
          passwordController.clear();
        });
      }
    } on CustomException catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      if (mounted) {
        setState(() {
          loginErrorText = e.toString();
          passwordController.clear();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      if (mounted) {
        setState(() {
          loginErrorText = 'Error in signIn process';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    emailAddressController = TextEditingController();
    passwordController = TextEditingController();
    passwordVisibility = false;
  }

  @override
  void dispose() {
    emailAddressController.dispose();
    passwordController.dispose();
    super.dispose();
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
                    MediaQuery.of(context).size.height * 0.25,
                    MediaQuery.of(context).size.width * 0.05,
                    MediaQuery.of(context).size.height * 0.25,
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Constants.backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  20, 16, 20, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: const [
                                  Expanded(
                                    child: Text(
                                      'Welcome Back',
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
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  20, 16, 20, 0),
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
                                          controller: emailAddressController,
                                          obscureText: false,
                                          decoration:
                                              const CustomFormFieldInputDecoration(
                                                  hintText:
                                                      'Enter your e-mail here...'),
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
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  20, 16, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(5, 0, 0, 5),
                                    child:
                                        Text("Password", style: MyTextStyle()),
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
                                            hintText:
                                                'Enter your password here...',
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
                                                    : Icons
                                                        .visibility_off_outlined,
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
                              padding: const EdgeInsets.fromLTRB(35, 20, 0, 0),
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(loginErrorText,
                                      style:
                                          const MyTextStyle(cColor: Colors.red),
                                      overflow: TextOverflow.visible)),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  20, 12, 20, 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            PageTransition(
                                              type: PageTransitionType.fade,
                                              duration: const Duration(
                                                  milliseconds: 250),
                                              reverseDuration: const Duration(
                                                  milliseconds: 250),
                                              child: const ForgotPasswordPage(),
                                              fullscreenDialog: true,
                                            ));
                                      },
                                      text: 'Forgot Password?',
                                      buttonTextStyle: const ButtonTextStyle(
                                        cColor: Colors.blueGrey,
                                        cFontSize: 12,
                                      ),
                                      color: Constants.backgroundColor,
                                      elevation: 0,
                                      overlayColor: Constants.transparent,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: CustomButton(
                                      onPressed: _signInNormal,
                                      text: "Login",
                                      height: 35,
                                      width: 120,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Divider(
                              height: 2,
                              thickness: 2,
                              indent: 20,
                              endIndent: 20,
                              color: Color(0xFFDBE2E7),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  20, 12, 20, 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: Image(
                                        image: Image.asset(
                                                'assets/images/google_icon.png')
                                            .image,
                                        height: 34,
                                      ),
                                      label: const Text(
                                        'Sign in with Google',
                                        style: ButtonTextStyle(
                                            cFontSize: 14,
                                            cColor: Color(0xff757575)),
                                      ),
                                      onPressed: () async {
                                        _signInGoogle();
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty
                                            .resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                            return const Color.fromRGBO(
                                                255, 255, 255, 1);
                                          },
                                        ),
                                        elevation: MaterialStateProperty
                                            .resolveWith<double>(
                                          (Set<MaterialState> states) {
                                            return 0;
                                          },
                                        ),
                                        overlayColor: MaterialStateProperty
                                            .resolveWith<Color>(
                                                (Set<MaterialState> states) {
                                          return Constants.transparent;
                                        }),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: CustomButton(
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(
                                            context, '/register');
                                      },
                                      text: 'Register',
                                      buttonTextStyle:
                                          const ButtonTextStyle(cFontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )),
        ));
  }
}
