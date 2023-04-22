import 'package:event_app/main.dart';
import 'package:event_app/src/model/dto.dart';
import 'package:event_app/src/model/event.dart';
import 'package:event_app/src/utility/geofunctions.dart';

class FilterUtility {
  /// Apply Event Filter from filter page
  List<Event> filterEvents(List<Event> toFilter) {
    bool interestFlag = false;
    bool startsInDateRangeFlag = false;
    bool endsInDateRangeFlag = false;
    bool inRadiusFlag = false;
    bool showOwnEvent = true;

    List<Event> toFilteredEvents = [];

    for (Event event in toFilter) {
      // StartsInDateRange control
      if (event.startTimestamp >=
              appState.user.exploreStartDateTime.millisecondsSinceEpoch &&
          event.startTimestamp <=
              appState.user.exploreEndDateTime
                  .add(const Duration(hours: 23, minutes: 59))
                  .millisecondsSinceEpoch) {
        startsInDateRangeFlag = true;
      }

      // EndsInDateRange control
      if (event.endTimestamp >=
              appState.user.exploreStartDateTime.millisecondsSinceEpoch &&
          event.endTimestamp <=
              appState.user.exploreEndDateTime
                  .add(const Duration(hours: 23, minutes: 59))
                  .millisecondsSinceEpoch) {
        endsInDateRangeFlag = true;
      }

      if (!(startsInDateRangeFlag || endsInDateRangeFlag)) {
        // Reset flags
        startsInDateRangeFlag = false;
        endsInDateRangeFlag = false;
        interestFlag = false;
        inRadiusFlag = false;
        continue;
      }

      // Interest control
      for (String cat in appState.user.categories.categoriesMap.keys) {
        if (event.category.categoriesMap[cat] == true &&
            appState.user.categories.categoriesMap[cat] == true) {
          interestFlag = true;
          break;
        }
      }

      // Decides, whether event is in radius
      if (GeoFunctions.getDistanceBetween2Coordinates(
              appState.lastKnownLatitude,
              appState.lastKnownLongitude,
              event.locationLatitude,
              event.locationLongitude) <=
          appState.user.exploreRadius) {
        inRadiusFlag = true;
      }

      // Check if own Event filter
      if (event.organizerUserId == appState.user.id &&
          appState.shownOwnEventsOnExplorePage == false) {
        showOwnEvent = false;
      }

      // Add to shown events
      if (inRadiusFlag && interestFlag && showOwnEvent) {
        toFilteredEvents.add(event);
      }

      // Reset flags
      startsInDateRangeFlag = false;
      endsInDateRangeFlag = false;
      interestFlag = false;
      inRadiusFlag = false;
      showOwnEvent = true;
    }
    return toFilteredEvents;
  }

  /// Deletes Events from the Database that got deleted from the organizer
  Future<List<Event>> removeDeletedEvents(
      List<Event> queriedEvents, List<Event> filteredEvents) async {
    List<Event> toSave = [];
    for (Event aEvent in queriedEvents) {
      // Event should be removed
      if (!aEvent.valid!) {
        Event? toRemove;
        for (Event someEvent in filteredEvents) {
          if (someEvent.eventId == aEvent.eventId) {
            toRemove = someEvent;
            break;
          }
        }
        if (toRemove != null) {
          filteredEvents.remove(toRemove);
        }

        String? deleteId;
        for (String id in appState.user.favoriteEventIds) {
          if (id == aEvent.eventId) {
            deleteId = id;
            break;
          }
        }
        if (deleteId != null) {
          appState.user.favoriteEventIds.remove(deleteId);
        }

        await appState.sqliteDbEvents.deleteEvent(aEvent.eventId);
      } else {
        toSave.add(aEvent);
      }
    }
    return toSave;
  }

  List<int> getMinAndMaxCreationTimestamp(List<DTO> objects) {
    // find oldest and latest favourite
    int oldestTimestamp = 9223372036854775807; // max int value
    int latestTimestamp = 0;

    if (objects.isNotEmpty) {
      for (DTO object in objects) {
        if (object.creationTimestamp < oldestTimestamp) {
          oldestTimestamp = object.creationTimestamp;
        }
        if (object.creationTimestamp > latestTimestamp) {
          latestTimestamp = object.creationTimestamp;
        }
      }
    } else {
      // If favourite is empty
      oldestTimestamp = 0;
      latestTimestamp = 0;
    }

    return [oldestTimestamp, latestTimestamp];
  }
}
