import 'package:intl/intl.dart';

class Formatter {
  /// Creates the pretty print of the date
  static String getDateFormatted(int dateInMilliSecSinceEpoch, String format) {
    final DateFormat formatter = DateFormat(format);
    String formattedDate = formatter
        .format(DateTime.fromMillisecondsSinceEpoch(dateInMilliSecSinceEpoch));
    return formattedDate;
  }

  /// Creates the pretty print of the time input
  static String getTimeFormatted(int dateTime) {
    final DateFormat formatter = DateFormat().add_Hm();
    String formattedTime =
        formatter.format(DateTime.fromMillisecondsSinceEpoch(dateTime));
    return formattedTime;
  }
}
