import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_bottom_navigation_bar.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/elements/delete_account_dialog.dart';
import 'package:event_app/src/elements/options_container.dart';
import 'package:event_app/src/pages/change_password_page.dart';
import 'package:event_app/src/pages/edit_profile_page.dart';
import 'package:event_app/src/pages/manage_interests_page.dart';
import 'package:event_app/src/pages/acknowledgement.dart';
import 'package:event_app/src/utility/signin_google_api.dart';
import 'package:event_app/src/utility/util_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:page_transition/page_transition.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late final String authMethod;

  String errorText = '';

  Future<void> logout() async {
    // allow logout only in online mode
    if (appState.offlineMode == true || appState.serverAlive == false) {
      return Utils.showOfflineBanner();
    }

    // remove notification
    await FlutterLocalNotificationsPlugin().cancelAll();
    await pushNotificationController.disablePushNotifications();

    if (authMethod == "google" && appState.offlineMode == false) {
      await SignInGoogleApi.logout();
    }

    // invalidate session
    bool status = await network.deleteSession();
    if (status) {
      await appState.sqliteDbUsers.updateUser(appState.user);
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    } else {
      if (kDebugMode) {
        print("An error during logout occurred!");
      }
    }

    await appState.secStorageCtrl.deleteSecureData(Constants.LAST_LOGIN_EMAIL);
    await appState.secStorageCtrl
        .deleteSecureData(Constants.CURRENT_LOC_LONGITUDE);
    await appState.secStorageCtrl
        .deleteSecureData(Constants.CURRENT_LOC_LATITUDE);

    appState.sqliteDbEvents.isInitialized = false;
  }

  /// Triggered when offlineMode changed
  void _onOfflineModeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    appState.addListener(_onOfflineModeChanged, ['offlineMode', 'serverAlive']);
    authMethod = appState.user.authMethod;
  }

  @override
  void dispose() {
    appState
        .removeListener(_onOfflineModeChanged, ['offlineMode', 'serverAlive']);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.backgroundColor,
        automaticallyImplyLeading: false,
        title: const Text(
          'Account Settings',
          style: MyTextStyle(
            cFontSize: Constants.pageHeadingFontSize,
            cFontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      key: scaffoldKey,
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 2,
      ),
      backgroundColor: Constants.backgroundColor,
      body: SingleChildScrollView(
        reverse: false,
        primary: false,
        child: Column(mainAxisSize: MainAxisSize.max, children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
            child: (appState.offlineMode || appState.serverAlive == false)
                ? Container(
                    width: MediaQuery.of(context).size.width,
                    height: 20.0,
                    color: const Color(0xFFEE4400),
                    child: const Center(
                      child: Text('OFFLINE'),
                    ),
                  )
                : Container(),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 5, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 5, 0, 0),
                          child: Text(
                            appState.user.username,
                            overflow: TextOverflow.fade,
                            maxLines: 3,
                            style: const MyTextStyle(
                              cFontWeight: FontWeight.bold,
                              cColor: Constants.themeColor,
                              cFontSize: 25,
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 5, 0, 0),
                          child: Text(
                            appState.user.email,
                            overflow: TextOverflow.fade,
                            maxLines: 5,
                            style: const MyTextStyle(
                              cFontSize: 16,
                              cFontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]),
                ),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () {
                      // edit user info
                      Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            duration: const Duration(milliseconds: 250),
                            reverseDuration: const Duration(milliseconds: 250),
                            child: EditProfilePage(
                              callback: () {
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              forceChange: false,
                            ),
                            fullscreenDialog: true,
                          ));
                    },
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Constants.iconColor,
                      size: 24,
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          return Constants.backgroundColor;
                        },
                      ),
                      elevation: MaterialStateProperty.resolveWith<double>(
                        (Set<MaterialState> states) {
                          return 0;
                        },
                      ),
                      overlayColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        return Constants.transparent;
                      }),
                    ),
                  ),
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(24, 15, 24, 15),
            child: Divider(
              color: Colors.white,
              thickness: 2,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              OptionsContainer(
                text: 'Manage Interests',
                onPressed: () {
                  Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 250),
                        reverseDuration: const Duration(milliseconds: 250),
                        child: const ManageInterestsPage(),
                        fullscreenDialog: true,
                      ));
                },
              ),
              appState.user.authMethod != 'google' ?
              OptionsContainer(
                text: 'Change Password',
                onPressed: () {
                  Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 250),
                        reverseDuration: const Duration(milliseconds: 250),
                        child: const ChangePasswordPage(),
                        fullscreenDialog: true,
                      ));
                },
              ): Container(),
              OptionsContainer(
                text: 'Acknowledgements',
                onPressed: () {
                  Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 250),
                        reverseDuration: const Duration(milliseconds: 250),
                        child: const AcknowledgementPage(),
                        fullscreenDialog: true,
                      ));
                },
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 30, 0, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      onPressed: logout,
                      width: MediaQuery.of(context).size.width - 50,
                      height: 40,
                      text: 'Logout',
                      buttonTextStyle: const ButtonTextStyle(
                        cColor: Constants.mainTextColorLight,
                        cFontSize: 16,
                      ),
                      color: Constants.themeColor,
                      elevation: 3,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 15, 0, 15),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      onPressed: () async {
                        await showDialog<AlertDialog>(
                            context: context,
                            builder: (BuildContext context) {
                              return const DeleteAccountDialog();
                            });
                      },
                      text: 'Delete Account',
                      buttonTextStyle: const ButtonTextStyle(
                        cColor: Colors.red,
                        cFontSize: 12,
                      ),
                      color: Constants.backgroundColor,
                      elevation: 0,
                      overlayColor: Constants.transparent,
                    ),
                  ],
                ),
              ),
            ],
          )
        ]),
      ),
    );
  }
}
