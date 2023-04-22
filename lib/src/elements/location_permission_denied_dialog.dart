import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionDenyDialog extends StatefulWidget {
  const LocationPermissionDenyDialog({Key? key}) : super(key: key);

  @override
  _LocationPermissionDenyDialogState createState() =>
      _LocationPermissionDenyDialogState();
}

class _LocationPermissionDenyDialogState
    extends State<LocationPermissionDenyDialog> {
  String errorText = '';

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
              "This app needs the location permission to work correctly!\nAre you sure to deny the permission?",
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
                        text: "Request again",
                        onPressed: () async {
                          var status = PermissionStatus.denied;
                          if (await Permission.location.isGranted) {
                            Navigator.pop(context);
                          } else if (await Permission.location.isDenied) {
                            await Geolocator.openAppSettings();
                            status = await Permission.location.request();
                          } else {
                            status = await Permission.location.request();
                          }
                          if (status == PermissionStatus.granted) {
                            Navigator.pop(context);
                          }
                        }),
                  ),
                  Container(width: 5.0),
                  Expanded(
                    child: CustomButton(
                        text: "Close App",
                        onPressed: () {
                          // if user does not want to give
                          // permission for location access
                          SystemNavigator.pop();
                        }),
                  )
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
