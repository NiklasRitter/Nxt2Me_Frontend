import 'dart:convert';

import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/model/categories.dart';

class User {
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.authMethod,
    required this.favoriteEventIds,
    required this.categories,
    required this.exploreRadius,
    required this.exploreStartDateTime,
    required this.exploreEndDateTime,
  });

  String id;
  String username;
  String email;
  String authMethod;
  List favoriteEventIds = [];
  List<int> location = [];
  Categories categories = Categories();
  double exploreRadius = Constants.DEFAULT_EXPLORE_DISTANCE_VALUE;
  DateTime exploreStartDateTime = DateTime.now();
  DateTime exploreEndDateTime = DateTime.now().add(const Duration(days: 14));

  factory User.fromJson(dynamic json) {
    return User(
        id: json["_id"] as String,
        username: json["name"],
        email: json["email"],
        authMethod: json["authMethod"],
        favoriteEventIds: json["favoriteEventIds"],
        categories: Categories(),
        exploreRadius: Constants.DEFAULT_EXPLORE_DISTANCE_VALUE,
        exploreStartDateTime: DateTime.now(),
        exploreEndDateTime: DateTime.now().add(const Duration(days: 14)));
  }

  /// Queries existent user or creates a new one in DB
  static Future<void> getOrCreateUser(User user) async {
    await appState.sqliteDbUsers.getUserFromUserId(user.id).then((queriedUser) {
      appState.user.exploreRadius = queriedUser.exploreRadius;
      appState.user.exploreStartDateTime = queriedUser.exploreStartDateTime;
      appState.user.exploreEndDateTime = queriedUser.exploreEndDateTime;
      appState.user.categories
          .copyFromExistingCategories(queriedUser.categories);
    }).catchError((onNonExistingUser) async {
      await appState.sqliteDbUsers.insertUser(user);
      appState.user = user;
    });
  }

  /// generate json document from user object
  Map<String, dynamic> toMap() {
    return {
      'userId': id,
      'userName': username,
      'userEmail': email,
      'userAuthMethod': authMethod,
      'favouriteIds': jsonEncode(favoriteEventIds),
      'categories': jsonEncode(categories.toList()),
      'exploreRadius': exploreRadius.toString(),
      'exploreStartDateTime':
          exploreStartDateTime.millisecondsSinceEpoch.toString(),
      'exploreEndDateTime':
          exploreEndDateTime.millisecondsSinceEpoch.toString(),
    };
  }
}
