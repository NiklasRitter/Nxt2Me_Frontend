import 'package:event_app/src/constants.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:flutter/material.dart';

class CustomSwitchListTile extends StatefulWidget {
  /// Switch interests in categories
  const CustomSwitchListTile(
      {Key? key, required this.text, required this.categories})
      : super(key: key);

  final String text;
  final Categories categories;

  @override
  State<CustomSwitchListTile> createState() => _CustomSwitchListTileState();
}

class _CustomSwitchListTileState extends State<CustomSwitchListTile> {
  late bool? switchListTileValue;
  late bool? old;

  @override
  void initState() {
    super.initState();
    switchListTileValue = widget.categories.categoriesMap[widget.text];
    old = widget.categories.categoriesMap[widget.text];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: SwitchListTile.adaptive(
            value: switchListTileValue!,
            onChanged: (newValue) => {
              widget.categories.categoriesMap[widget.text] = newValue,
              if (mounted)
                {
                  setState(() {
                    switchListTileValue = newValue;
                  })
                },
            },
            title: Text(
              widget.text,
              style: const MyTextStyle(
                cFontSize: 14,
              ),
            ),
            activeColor: Colors.white,
            activeTrackColor: Constants.themeColor,
            dense: false,
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
          ),
        )
      ],
    );
  }
}
