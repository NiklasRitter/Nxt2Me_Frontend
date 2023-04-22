import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/model/event.dart';
import 'package:event_app/src/model/user.dart';
import 'package:event_app/src/utility/secure_storage_controller.dart';
import 'package:event_app/src/utility/sqlite_db_events.dart';
import 'package:event_app/src/utility/sqlite_db_user.dart';
import 'package:flutter/foundation.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class ApplicationState extends PropertyChangeNotifier<String> {
  ApplicationState() {
    _secStorageCtrl = SecureStorageCtrl();
    _sqliteDbEvents = SQLiteDbEvents();
    _sqliteDbUsers = SQLiteDbUser();

    addListener(_onOfflineModeChanged, ['offlineMode', 'serverAlive']);
  }

  @override
  void dispose() {
    super.dispose();
    removeListener(_onOfflineModeChanged, ['offlineMode', 'serverAlive']);
  }

  late User user;
  bool _offlineMode = false;
  bool _serverAlive = true;
  List<Event> _eventList = [];
  double lastKnownLatitude = 0.0;
  double lastKnownLongitude = 0.0;
  ConnectivityResult connectionStatus = ConnectivityResult.none;
  bool shownOwnEventsOnExplorePage = false;

  late SecureStorageCtrl _secStorageCtrl;
  late SQLiteDbEvents _sqliteDbEvents;
  late SQLiteDbUser _sqliteDbUsers;

  Future<void> initUser(data) async {
    user = User.fromJson(data);
    await User.getOrCreateUser(user);

    // enable push notifications on start
    if (data['pushNotificationToken'] != null) {
      await pushNotificationController.enablePushNotifications();
    }

    String? latitude = await appState.secStorageCtrl
        .readSecureData(Constants.CURRENT_LOC_LATITUDE);
    String? longitude = await appState.secStorageCtrl
        .readSecureData(Constants.CURRENT_LOC_LONGITUDE);

    if (latitude != null && longitude != null) {
      try {
        appState.lastKnownLatitude = double.parse(latitude);
        appState.lastKnownLongitude = double.parse(longitude);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing coordinates to double');
        }
      }
    }
  }

  void _onOfflineModeChanged() {
    if (offlineMode == false && serverAlive == true) {
      network.offlineModeAutoLogin();
    }
  }

  bool get offlineMode => _offlineMode;

  bool get serverAlive => _serverAlive;

  List<Event> get eventList => _eventList;

  SecureStorageCtrl get secStorageCtrl => _secStorageCtrl;

  SQLiteDbEvents get sqliteDbEvents => _sqliteDbEvents;

  SQLiteDbUser get sqliteDbUsers => _sqliteDbUsers;

  set eventList(List<Event> newEvents) {
    _eventList = newEvents;
  }

  set offlineMode(bool value) {
    _offlineMode = value;
    notifyListeners('offlineMode');
  }

  set serverAlive(bool value) {
    _serverAlive = value;
    notifyListeners('serverAlive');
  }
}
