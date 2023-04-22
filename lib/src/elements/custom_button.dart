import 'package:event_app/src/constants.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final double? width;
  final double? height;
  final double elevation;
  final Color color;
  final Color overlayColor;
  final VoidCallback? onPressed;
  final TextStyle buttonTextStyle;
  final BorderRadius borderRadius = BorderRadius.circular(16);
  final ButtonStyle? buttonStyle;

  /// Customizable Button
  CustomButton({
    Key? key,
    required this.text,
    this.width,
    this.height,
    required this.onPressed,
    this.color = Constants.themeColor,
    this.buttonStyle,
    this.overlayColor = Constants.customButtonOverlayColor,
    this.buttonTextStyle = const ButtonTextStyle(),
    this.elevation = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: buttonTextStyle,
        ),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              return color;
            },
          ),
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              return elevation;
            },
          ),
          overlayColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              return overlayColor;
            },
          ),
        ),
      ),
    );
  }
}
