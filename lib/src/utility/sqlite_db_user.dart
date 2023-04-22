import 'dart:async';
import 'dart:convert';

import 'package:event_app/src/constants.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:event_app/src/model/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteDbUser {
  late Future<Database> database;
  bool isInitialized = false;

  Future<void> connectDB() async {
    if (!isInitialized) {
      WidgetsFlutterBinding.ensureInitialized();
      // Open the database and store the reference.
      database = openDatabase(
        join(await getDatabasesPath(), Constants.SQLITE_USERS_DB_NAME),
        onCreate: (db, version) {
          // Run the CREATE TABLE statement on the database.
          db.execute(
            '''CREATE TABLE IF NOT EXISTS users(
               id INTEGER PRIMARY KEY,
               userId TEXT,
               userName TEXT,
               userEmail TEXT,
               userAuthMethod TEXT,
               favouriteIds TEXT,
               categories TEXT,
               exploreRadius REAL,
               exploreStartDateTime TEXT,
               exploreEndDateTime TEXT)''',
          );
          // create unique index to avoid double user entries
          return db.execute(
            '''CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_userId 
               ON users(userId)''',
          );
        },
        // Set the version. This executes the onCreate function and provides a
        // path to perform database upgrades and downgrades.
        version: 1,
      );
      isInitialized = true;
    }
  }

  Future<void> insertUser(User newUser) async {
    await connectDB();

    Database db = await database;

    await db.insert(
      'users',
      newUser.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User> getUserFromUserId(String userId) async {
    await connectDB();

    Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    // Convert the List<Map<String, dynamic> into a List<User>.
    return List.generate(maps.length, (i) {
      return User(
        id: maps[i]['userId'],
        username: maps[i]['userName'],
        email: maps[i]['userEmail'],
        authMethod: maps[i]['userAuthMethod'],
        favoriteEventIds: jsonDecode(maps[i]['favouriteIds']) as List,
        categories: Categories()
            .withStartParameters(jsonDecode(maps[i]['categories']) as List),
        exploreRadius: maps[i]['exploreRadius'],
        exploreStartDateTime: DateTime.fromMillisecondsSinceEpoch(
            int.parse(maps[i]['exploreStartDateTime'])),
        exploreEndDateTime: DateTime.fromMillisecondsSinceEpoch(
            int.parse(maps[i]['exploreEndDateTime'])),
      );
    }).first;
  }

  Future<User?> getUserFromEmail(String userEmail) async {
    await connectDB();

    Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
    );

    try {
      // Convert the List<Map<String, dynamic> into a List<User>.
      return List.generate(maps.length, (i) {
        return User(
          id: maps[i]['userId'],
          username: maps[i]['userName'],
          email: maps[i]['userEmail'],
          authMethod: maps[i]['userAuthMethod'],
          favoriteEventIds: jsonDecode(maps[i]['favouriteIds']) as List,
          categories: Categories()
              .withStartParameters(jsonDecode(maps[i]['categories']) as List),
          exploreRadius: maps[i]['exploreRadius'],
          exploreStartDateTime: DateTime.fromMillisecondsSinceEpoch(
              int.parse(maps[i]['exploreStartDateTime'])),
          exploreEndDateTime: DateTime.fromMillisecondsSinceEpoch(
              int.parse(maps[i]['exploreEndDateTime'])),
        );
      }).first;
    } on StateError catch (e) {
      if (kDebugMode) {
        print('Error in getUserFromEmail\n' + e.toString());
      }
      return null;
    }
  }

  Future<List<User>> allUsers() async {
    await connectDB();

    Database db = await database;

    // Query the table for all users.
    final List<Map<String, dynamic>> maps = await db.query('users');

    // Convert the List<Map<String, dynamic> into a List<User>.
    return List.generate(maps.length, (i) {
      return User(
        id: maps[i]['userId'],
        username: maps[i]['userName'],
        email: maps[i]['userEmail'],
        authMethod: maps[i]['userAuthMethod'],
        favoriteEventIds: jsonDecode(maps[i]['favouriteIds']) as List,
        categories: Categories()
            .withStartParameters(jsonDecode(maps[i]['categories']) as List),
        exploreRadius: maps[i]['exploreRadius'],
        exploreStartDateTime: DateTime.fromMillisecondsSinceEpoch(
            int.parse(maps[i]['exploreStartDateTime'])),
        exploreEndDateTime: DateTime.fromMillisecondsSinceEpoch(
            int.parse(maps[i]['exploreEndDateTime'])),
      );
    });
  }

  Future<void> updateUser(User updatedUser) async {
    await connectDB();

    Database db = await database;

    // Update the given User.
    await db.update(
      'users',
      updatedUser.toMap(),
      where: 'userId = ?',
      whereArgs: [updatedUser.id],
    );
  }

  Future<void> deleteUser(String userId) async {
    await connectDB();

    Database db = await database;

    // Remove the User from the database.
    await db.delete(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteAllUsers() async {
    await connectDB();

    Database db = await database;

    // Remove the User from the database.
    await db.delete('users');
  }
}
