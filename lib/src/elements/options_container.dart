import 'package:event_app/src/constants.dart';
import 'package:flutter/material.dart';

class OptionsContainer extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const OptionsContainer({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          onPressed();
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 50,
          child: Row(mainAxisSize: MainAxisSize.max, children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 0, 0),
              child: Text(
                text,
                style: const MyTextStyle(
                  cFontSize: 16,
                ),
              ),
            ),
            const Expanded(
              child: Align(
                alignment: AlignmentDirectional(0.85, 0),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Constants.hintTextColor,
                  size: 18,
                ),
              ),
            )
          ]),
        ));
  }
}
