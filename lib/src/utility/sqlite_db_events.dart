import 'dart:async';
import 'dart:convert';

import 'package:event_app/main.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:event_app/src/model/event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteDbEvents {
  late Future<Database> database;
  bool isInitialized = false;

  Future<void> connectDB() async {
    if (!isInitialized) {
      WidgetsFlutterBinding.ensureInitialized();
      // Open the database and store the reference.
      database = openDatabase(
        join(await getDatabasesPath(),
            'eventapp_events_database_' + appState.user.id.toString() + '.db'),
        onCreate: (db, version) {
          // Run the CREATE TABLE statement on the database.
          db.execute(
            '''CREATE TABLE IF NOT EXISTS events(
              id INTEGER PRIMARY KEY,
              eventId TEXT,
              eventName TEXT,
              category TEXT,
              startTimestamp INTEGER,
              endTimestamp INTEGER,
              description TEXT,
              organizerUserId TEXT,
              organizerName TEXT,
              locationName TEXT,
              locationLatitude REAL,
              locationLongitude REAL,
              creationTimestamp INTEGER,
              image TEXT,
              likeCount INTEGER,
              maxViews INTEGER)''',
          );

          // create unique index to avoid double event entries
          return db.execute(
            '''CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_eventId 
               ON events(eventId)''',
          );
        },
        // Set the version. This executes the onCreate function and provides a
        // path to perform database upgrades and downgrades.
        version: 1,
      );
      isInitialized = true;
    }
  }

  Future<void> insertEvent(Event newEvent) async {
    await connectDB();

    Database db = await database;

    await db.insert(
      'events',
      newEvent.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAllEvents(List<Event> newEventsList) async {
    await connectDB();

    Database db = await database;

    for (Event aEvent in newEventsList) {
      await db.insert(
        'events',
        aEvent.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  List<Event> generateEvents(List<Map<String, dynamic>> eventMap) {
    return List.generate(eventMap.length, (i) {
      return Event(
        eventId: eventMap[i]['eventId'],
        eventName: eventMap[i]['eventName'],
        category: Categories()
            .withStartParameters(jsonDecode(eventMap[i]['category']) as List),
        startTimestamp: eventMap[i]['startTimestamp'],
        endTimestamp: eventMap[i]['endTimestamp'],
        description: eventMap[i]['description'],
        organizerUserId: eventMap[i]['organizerUserId'],
        organizerName: eventMap[i]['organizerName'],
        locationName: eventMap[i]['locationName'],
        locationLatitude: eventMap[i]['locationLatitude'],
        locationLongitude: eventMap[i]['locationLongitude'],
        creationTimestamp: eventMap[i]['creationTimestamp'],
        image: eventMap[i]['image'],
        likeCount: eventMap[i]['likeCount'],
        maxViews: eventMap[i]['maxViews'],
      );
    });
  }

  Future<List<Event>> allEvents() async {
    await connectDB();
    Database db = await database;

    // Query the table for all events.
    final List<Map<String, dynamic>> maps = await db.query('events');

    // Convert the List<Map<String, dynamic> into a List<Event>.
    return generateEvents(maps);
  }

  Future<List<Event>> allFavouriteEvents() async {
    await connectDB();
    Database db = await database;

    if (appState.user.favoriteEventIds.isNotEmpty) {
      final List<Map<String, dynamic>> maps = await db.query('events');

      List<Event> allEvents = generateEvents(maps);
      List<Event> favourites = [];
      for (var event in allEvents) {
        if (appState.user.favoriteEventIds.contains(event.eventId)) {
          favourites.add(event);
        }
      }
      return favourites;
    } else {
      return [];
    }
  }

  Future<List<Event>> allMyEvents() async {
    await connectDB();
    Database db = await database;

    // Query the table for all events.
    final List<Map<String, dynamic>> maps = await db.query('events',
        where: 'organizerUserId = (?)',
        whereArgs: [appState.user.id],
        orderBy: 'creationTimestamp DESC');

    // Convert the List<Map<String, dynamic> into a List<Event>.
    return generateEvents(maps);
  }

  Future<void> updateEvent(Event updatedEvent) async {
    await connectDB();

    Database db = await database;

    // Update the given Event.
    await db.update(
      'events',
      updatedEvent.toMap(),
      where: 'eventId = ?',
      whereArgs: [updatedEvent.eventId],
    );
  }

  Future<int> deleteEvent(String eventId) async {
    await connectDB();

    Database db = await database;

    // Remove the Event from the database.
    return await db.delete(
      'events',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
  }

  Future<void> deleteOldEvents() async {
    await connectDB();

    Database db = await database;

    // get current favorite events from server
    var res = await network.getUser();
    appState.user.favoriteEventIds = json.decode(res.body)["favoriteEventIds"];
    await appState.sqliteDbUsers.updateUser(appState.user);

    // Remove likes from events to delete
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'endTimestamp < ? AND organizerUserId != ?',
      whereArgs: [
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .millisecondsSinceEpoch,
        appState.user.id
      ],
    );

    List<Event> events = generateEvents(maps);
    for (Event event in events) {
      if (appState.user.favoriteEventIds.contains(event.eventId)) {
        await network.toggleFavoriteEvent(event.eventId);
      }
    }

    // get current favorite events from server
    res = await network.getUser();
    appState.user.favoriteEventIds = json.decode(res.body)["favoriteEventIds"];
    await appState.sqliteDbUsers.updateUser(appState.user);

    // Remove the Event from the database.
    await db.delete(
      'events',
      where: 'endTimestamp < ? AND organizerUserId != ?',
      whereArgs: [
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .millisecondsSinceEpoch,
        appState.user.id
      ],
    );
    if (kDebugMode) {
      print('Old Events in sqliteDB are deleted!');
    }
  }

  Future<void> deleteAllEvents() async {
    await connectDB();

    Database db = await database;

    // Remove the Event from the database.
    await db.delete('events');
  }

  Future<void> deleteUserEventDatabase() async {
    await deleteDatabase(join(await getDatabasesPath(),
        'eventapp_events_database_' + appState.user.id.toString() + '.db'));
    isInitialized = false;
  }
}
