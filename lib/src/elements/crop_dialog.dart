import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:flutter/material.dart';

class CropDialog extends StatefulWidget {
  final Uint8List image;

  /// return cropped image
  final Function(Uint8List) callback;

  /// Dialog screen to crop selected image
  const CropDialog(this.image, this.callback);

  @override
  _CropDialogState createState() => _CropDialogState();
}

class _CropDialogState extends State<CropDialog> {
  final controller = CropController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Constants.backgroundColor,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.50,
            width: MediaQuery.of(context).size.width * 0.90,
            child: Crop(
              maskColor: const Color(0xAA1E2630),
              baseColor: Constants.backgroundColor,
              controller: controller,
              image: widget.image,
              aspectRatio: 4 / 3,
              onCropped: (value) {
                widget.callback(value);
                Navigator.pop(context);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CustomButton(
                  text: "select",
                  onPressed: () {
                    controller.crop();
                  }),
              CustomButton(
                  text: "back",
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
