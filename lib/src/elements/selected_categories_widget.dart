import 'package:event_app/src/constants.dart';
import 'package:flutter/material.dart';

class SelectedCategoriesWidget extends StatefulWidget {
  /// widget to show selected categories
  SelectedCategoriesWidget({Key? key, required this.selectedCategories})
      : super(key: key);

  List<String> selectedCategories;

  @override
  _SelectedCategoriesWidgetState createState() =>
      _SelectedCategoriesWidgetState();
}

class _SelectedCategoriesWidgetState extends State<SelectedCategoriesWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: const ScrollPhysics(),
        itemCount: widget.selectedCategories.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
            child: Container(
              decoration: const BoxDecoration(
                color: Constants.themeColor,
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(
                  widget.selectedCategories[index],
                  style: const MyTextStyle(
                    cFontSize: 12,
                    cColor: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
