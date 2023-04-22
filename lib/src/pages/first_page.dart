import 'dart:async';
import 'dart:convert';

import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/location_permission_denied_dialog.dart';
import 'package:event_app/src/model/user.dart';
import 'package:event_app/src/pages/edit_profile_page.dart';
import 'package:event_app/src/pages/explore_page.dart';
import 'package:event_app/src/pages/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class FirstPage extends StatefulWidget {
  FirstPage({Key? key}) : super(key: key);

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  /// decide whether to autologin the user and show the ExplorePage
  /// based on the availability of valid tokens
  Future<Widget> autoLogin() async {
    try {
      await network.healthCheck();
    } catch (e) {
      if (kDebugMode) {
        print('Server unavailable!\n' + e.toString());
      }
    }

    if (appState.serverAlive == false || appState.offlineMode == true) {
      return _tryOfflineModeSignIn();
    }

    try {
      bool tokensAvailable = await network.checkTokenAvailability();

      if (tokensAvailable) {
        http.Response userResponse = await network.getUser();
        if (userResponse.statusCode == 200) {
          await appState.initUser(json.decode(userResponse.body));

          if (appState.user.username == appState.user.email) {
            return EditProfilePage(
              callback: () {},
              forceChange: true,
            );
          }

          return const ExplorePage();
        } else {
          return const LoginPage();
        }
      } else {
        return const LoginPage();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return const LoginPage();
    }
  }

  Future<Widget> _tryOfflineModeSignIn() async {
    String? lastEmail = await appState.secStorageCtrl
        .readSecureData(Constants.LAST_LOGIN_EMAIL);

    if (lastEmail == null) return const LoginPage();

    User? queriedUser =
        await appState.sqliteDbUsers.getUserFromEmail(lastEmail);

    if (queriedUser == null) return const LoginPage();

    // Load DB User in appState
    await User.getOrCreateUser(queriedUser);
    return const ExplorePage();
  }

  void _getLocPermissionDialog(BuildContext context) async {
    if (!await Permission.location.isGranted) {
      showDialog<AlertDialog>(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return WillPopScope(
                onWillPop: () async => false,
                child: LocationPermissionDenyDialog(key: UniqueKey()));
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () => _getLocPermissionDialog(context));
    return FutureBuilder<Widget>(
        future: autoLogin(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text('Error: ${snapshot.error}'),
                    )
                  ])),
            );
          } else {
            return Scaffold(
              body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Loading ...'),
                      )
                    ]),
              ),
            );
          }
        });
  }
}
