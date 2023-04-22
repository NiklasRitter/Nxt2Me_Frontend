import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/model/comment.dart';
import 'package:event_app/src/utility/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomComment extends StatefulWidget {
  /// Widget to shoe comment in comment list
  const CustomComment({Key? key, required this.comment, required this.callback})
      : super(key: key);

  final Comment comment;
  final Function(Comment comment) callback;

  @override
  State<CustomComment> createState() => _CustomCommentState();
}

class _CustomCommentState extends State<CustomComment> {
  static const List<String> choices = <String>[
    "Report Comment",
  ];

  void _reportCommentAction() async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      return Utils.showOfflineBanner();
    }

    var res =
        await network.reportComment(widget.comment.eventId, widget.comment.id);

    if (res.statusCode == 200) {
      widget.callback(widget.comment);
    }
  }

  String _getCommentTimestampFormatted() {
    final creationDateTime =
        DateTime.fromMillisecondsSinceEpoch(widget.comment.creationTimestamp);
    final DateFormat formatterDate = DateFormat('dd/MM/yyyy');
    final DateFormat formatterTime = DateFormat().add_Hm();

    String result = formatterDate.format(creationDateTime) +
        ' ' +
        formatterTime.format(creationDateTime);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 20),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 5),
                  child: Text(
                    widget.comment.author,
                    overflow: TextOverflow.clip,
                    style: const MyTextStyle(
                      cFontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 5),
                  child: Text(
                    _getCommentTimestampFormatted(),
                    overflow: TextOverflow.clip,
                    style: const MyTextStyle(
                      cFontWeight: FontWeight.normal,
                      cFontSize: 13,
                    ),
                  ),
                ),
              ),
              PopupMenuButton(
                onSelected: (value) async {
                  _reportCommentAction();
                },
                padding: EdgeInsets.zero,
                color: Constants.backgroundColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                icon: const Icon(
                  Icons.report,
                  color: Colors.white,
                  size: 20,
                ),
                itemBuilder: (BuildContext context) {
                  return choices.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice,
                          style: const MyTextStyle(cColor: Colors.white)),
                    );
                  }).toList();
                },
              )
            ],
          ),
          Text(
            widget.comment.commentText,
            maxLines: 10,
            style: const MyTextStyle(
              cFontSize: 12,
            ),
          )
        ],
      ),
    );
  }
}
