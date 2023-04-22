import 'dart:convert';
import 'dart:typed_data';
import 'package:event_app/src/model/comment.dart';
import 'package:event_app/src/model/event.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class JsonUtility {
  String encodeEvent(Event event) {
    return jsonEncode(<String, Object>{
      "eventName": event.eventName,
      "startTimestamp": event.startTimestamp,
      "endTimestamp": event.endTimestamp,
      "description": event.description,
      "category": event.category.toList(),
      "organizerName": event.organizerName,
      "locationName": event.locationName,
      "location": {
        "type": "Point",
        "coordinates": [event.locationLongitude, event.locationLatitude]
      },
      "creationTimestamp": event.creationTimestamp,
      "image": event.image ?? "",
      "maxViews": event.maxViews,
    });
  }

  List<Event> decodeEvents(http.Response event) {
    var eventArrayJson = json.decode(event.body) as List;
    List<Event> events =
        eventArrayJson.map((eventJson) => Event.fromJson(eventJson)).toList();

    return events;
  }

  String encodeComment(String eventId, String author, int creationTimestamp,
      String commentText) {
    return jsonEncode(<String, Object>{
      "eventId": eventId,
      "author": author,
      "creationTimestamp": creationTimestamp,
      "commentText": commentText,
    });
  }

  List<Comment> decodeComments(http.Response commentArray) {
    var commentArrayJson = json.decode(commentArray.body) as List;
    List<Comment> comments = commentArrayJson
        .map((commentJson) => Comment.fromJson(commentJson))
        .toList();

    return comments;
  }

  String encodeCredentials(
      String oldPassword, String newPassword, String passwordConfirmation) {
    return jsonEncode(<String, Object>{
      "oldPassword": oldPassword,
      "newPassword": newPassword,
      "passwordConfirmation": passwordConfirmation,
    });
  }

  String encodeSubscribedCategories(List<String> subscribedCategories) {
    return jsonEncode(<String, Object>{
      "subscribedCategories": subscribedCategories,
    });
  }

  String encodePushNotificationToken(String pushNotificationToken) {
    return jsonEncode(<String, Object>{
      "pushNotificationToken": pushNotificationToken,
    });
  }

  static Future<Uint8List> compressImageUInt8List(Uint8List list) async {
    return await FlutterImageCompress.compressWithList(
      list,
      minHeight: 800,
      minWidth: 600,
      quality: 30,
    );
  }
}
