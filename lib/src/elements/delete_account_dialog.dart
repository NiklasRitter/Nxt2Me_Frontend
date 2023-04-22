import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/utility/signin_google_api.dart';
import 'package:flutter/material.dart';

import '../utility/util_functions.dart';

class DeleteAccountDialog extends StatefulWidget {
  /// Safe delete account dialog
  const DeleteAccountDialog({Key? key}) : super(key: key);

  @override
  _DeleteAccountDialogState createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  String errorText = '';

  Future<void> _deleteAccount() async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      Navigator.pop(context);
      return Utils.showOfflineBanner();
    }

    var res = await network.deleteUser();

    if (res.statusCode == 200) {
      var userId = res.body;

      // google sign out if authMethod is google
      if (appState.user.authMethod == "google") {
        SignInGoogleApi.logout();
      }

      // delete account from user sqlite
      await appState.sqliteDbUsers.deleteUser(userId);

      // delete whole user event sqlite db
      await appState.sqliteDbEvents.deleteUserEventDatabase();

      // delete everything from secure storage
      await appState.secStorageCtrl
          .writeSecureData(Constants.LAST_EVENT_QUERY_TIMESTAMP, "0");
      await appState.secStorageCtrl
          .deleteSecureData(Constants.CURRENT_LOC_LONGITUDE);
      await appState.secStorageCtrl
          .deleteSecureData(Constants.CURRENT_LOC_LATITUDE);

      // redirect to login page
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    } else {
      if (mounted) {
        setState(() {
          errorText = res.body.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Container(
      color: Constants.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure that you want to delete your Account?\nRemember that all of your data inclusive events and comments get deleted.",
              overflow: TextOverflow.visible,
              style: MyTextStyle(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomButton(
                        text: "Delete Account",
                        color: Colors.red,
                        onPressed: () async {
                          await _deleteAccount();
                        }),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: CustomButton(
                        text: "Back",
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                  ),
                ],
              ),
            ),
            Text(
              errorText,
              overflow: TextOverflow.visible,
              style: const MyTextStyle(cColor: Colors.red),
            )
          ],
        ),
      ),
    ));
  }
}
