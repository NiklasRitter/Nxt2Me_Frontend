import 'package:flutter/material.dart';

class Constants {
  // Used Font Sizes
  static const double flowingTextFontSize = 14;
  static const double pageHeadingFontSize = 20;
  static const double subheadingFontSize = 16;

  // Color Themes
  static const Color backgroundColor = Color(0xFF1E2630);
  static const Color backgroundColorSecondary = Colors.white;
  static const Color themeColor = Color(0xFF8250CA);
  static const Color mainTextColorLight = Color(0xFFFFFFFF);
  static const Color mainTextColorDark = Color(0xFF151B1E);
  static const Color secondaryTextColorDark = Color(0xFF8B97A2);
  static const Color hintTextColor = Color(0xFF95A1AC);
  static const Color iconColor = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00FFFFFF);
  static const Color formFieldFillColor = Colors.white;
  static const Color formFieldEnabledBorderColor = Colors.white;
  static const Color formFieldFocusedBorderColor = Colors.white;
  static const Color customButtonOverlayColor = Color(0x2FFFFFFF);
  static const Color glowingScrollColor = Color(0xFF95A1AC);

  // Default Filter Settings
  static const double DEFAULT_EXPLORE_DISTANCE_VALUE =
      DEFAULT_MAX_QUERY_DISTANCE / 2.0;

  static const double DEFAULT_MIN_QUERY_DISTANCE = 1000.0;
  static const double DEFAULT_MAX_QUERY_DISTANCE = 100000.0;
  static const int LIMIT_COMMENTS_QUERY = 5;

  // Categories (all have to be false by default!)
  static const Map<String, bool> DEFAULT_CATEGORIES = {
    'Culture': false,
    'Food': false,
    'Party': false,
    'Sport': false,
    'Miscellaneous': false
  };

  /// Standard texts
  static const String OFFLINE_UNAVAILABLE = "You are offline!";

  /// Timeouts / Timer / Intervals etc.
  static const int SERVER_CONNECTION_TIMEOUT_SECONDS = 10;
  static const int SERVER_HEALTH_CHECK_INTERVAL = 10; // in seconds

  /// Secure Storage Key Names
  static const SERVER_IP = 'https://event-app-server1.herokuapp.com';
  static const String ACCESS_TOKEN = 'ACCESS_TOKEN';
  static const String REFRESH_TOKEN = 'REFRESH_TOKEN';
  static const String LAST_EVENT_QUERY_TIMESTAMP = 'LAST_EVENT_QUERY_TIMESTAMP';
  static const String LAST_LOGIN_EMAIL = 'LAST_LOGIN_EMAIL';
  static const String CURRENT_LOC_LATITUDE = 'CURRENT_LOC_LATITUDE';
  static const String CURRENT_LOC_LONGITUDE = 'CURRENT_LOC_LONGITUDE';
  static const String PUSH_NOTIFICATION_TOKEN = 'PUSH_NOTIFICATION_TOKEN';

  /// SQLite Database
  static String SQLITE_USERS_DB_NAME = 'eventapp_user_database.db';

  static ButtonStyle buttonStyle = ButtonStyle(
      foregroundColor: MaterialStateProperty.all<Color>(themeColor),
      shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
}

//****************************************************************************
//                              Custom Styles
//****************************************************************************

class MyTextStyle extends TextStyle {
  final Color cColor;
  final FontWeight cFontWeight;
  final double cFontSize;
  final String cFontFamily;
  final Color? cBackgroundColor;

  const MyTextStyle(
      {this.cColor = Constants.mainTextColorLight,
      this.cFontWeight = FontWeight.normal,
      this.cFontSize = 14,
      this.cFontFamily = 'Overpass',
      this.cBackgroundColor})
      : super(
          color: cColor,
          fontWeight: cFontWeight,
          fontSize: cFontSize,
          fontFamily: cFontFamily,
          backgroundColor: cBackgroundColor,
          overflow: TextOverflow.ellipsis,
        );
}

class ButtonTextStyle extends TextStyle {
  final Color cColor;
  final FontWeight cFontWeight;
  final double cFontSize;
  final String cFontFamily;
  final Color? cBackgroundColor;

  const ButtonTextStyle(
      {this.cColor = Constants.mainTextColorLight,
      this.cFontWeight = FontWeight.normal,
      this.cFontSize = 14,
      this.cFontFamily = 'Overpass',
      this.cBackgroundColor})
      : super(
          color: cColor,
          fontWeight: cFontWeight,
          fontSize: cFontSize,
          fontFamily: cFontFamily,
          backgroundColor: cBackgroundColor,
        );
}

class CustomFormFieldInputDecoration extends InputDecoration {
  final String? labelText;
  final TextStyle? labelStyle;
  final String hintText;
  final TextStyle? hintStyle;
  final String? errorText;
  final TextStyle? errorStyle;
  final OutlineInputBorder? focusedBorder;
  final OutlineInputBorder? enabledBorder;
  final bool? filled;
  final Color? fillColor;
  final EdgeInsets? contentPadding;
  final InkWell? suffixIcon;

  const CustomFormFieldInputDecoration({
    required this.hintText,
    this.labelText,
    this.labelStyle = const MyTextStyle(cColor: Colors.white),
    this.hintStyle = const MyTextStyle(
      cColor: Constants.hintTextColor,
    ),
    this.errorText,
    this.errorStyle = const MyTextStyle(
      cColor: Colors.red,
    ),
    this.focusedBorder = const OutlineInputBorder(
      borderSide: BorderSide(
        color: Constants.formFieldFocusedBorderColor,
        width: 1,
      ),
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    this.enabledBorder = const OutlineInputBorder(
      borderSide: BorderSide(
        color: Constants.formFieldEnabledBorderColor,
        width: 1,
      ),
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    this.filled = true,
    this.fillColor = Constants.formFieldFillColor,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.suffixIcon,
  }) : super(
          labelText: labelText,
          labelStyle: labelStyle,
          hintText: hintText,
          hintStyle: hintStyle,
          errorText: errorText,
          errorStyle: errorStyle,
          focusedBorder: focusedBorder,
          enabledBorder: enabledBorder,
          filled: filled,
          fillColor: fillColor,
          contentPadding: contentPadding,
          suffixIcon: suffixIcon,
        );
}
