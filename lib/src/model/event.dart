import 'dart:convert';
import 'dart:core';

import 'package:event_app/src/model/categories.dart';
import 'package:event_app/src/model/comment.dart';

import 'dto.dart';

class Event implements DTO {
  Event({
    required this.eventId,
    required this.eventName,
    required this.category,
    required this.startTimestamp,
    required this.endTimestamp,
    required this.description,
    required this.organizerUserId,
    required this.organizerName,
    required this.locationName,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.creationTimestamp,
    required this.likeCount,
    required this.maxViews,
    this.valid,
    this.image,
  });

  /// Generate event object from json document
  factory Event.fromJson(dynamic json) {
    return Event(
        eventId: json["_id"] as String,
        eventName: json["eventName"],
        category: Categories().withStartParameters(json["category"] as List),
        startTimestamp: json["startTimestamp"] as int,
        endTimestamp: json["endTimestamp"] as int,
        description: json["description"],
        organizerUserId: json["user"],
        organizerName: json["organizerName"],
        locationName: json["locationName"],
        likeCount: json["likeCount"] as int,
        locationLatitude: json["location"]["coordinates"][1],
        locationLongitude: json["location"]["coordinates"][0],
        creationTimestamp: json["creationTimestamp"] as int,
        maxViews: json["maxViews"] ?? -1,
        valid: json["valid"] ?? true,
        image: json["image"] ?? "");
  }

  String eventId;
  String eventName;
  Categories category;
  int startTimestamp;
  int endTimestamp;
  String description;
  String organizerUserId;
  String organizerName;
  String locationName;
  double locationLatitude;
  double locationLongitude;
  int creationTimestamp;
  bool? valid = true;
  String? image = "";
  int likeCount = 0;
  int maxViews = 0;
  List<Comment> comments = [];

  /// generate json document from event object
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'category': jsonEncode(category.toList()),
      'startTimestamp': startTimestamp,
      'endTimestamp': endTimestamp,
      'description': description,
      'organizerUserId': organizerUserId,
      'organizerName': organizerName,
      'locationName': locationName,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'creationTimestamp': creationTimestamp,
      'image': image,
      'likeCount': likeCount,
      'maxViews': maxViews,
    };
  }

  int compareTo(Event eventB) {
    if (startTimestamp < eventB.startTimestamp) {
      return -1;
    } else if (startTimestamp > eventB.startTimestamp) {
      return 1;
    } else {
      return eventName.compareTo(eventB.eventName);
    }
  }
}
