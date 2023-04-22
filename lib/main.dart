import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:event_app/src/application_state.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/model/search.dart';
import 'package:event_app/src/pages/account_settings_page.dart';
import 'package:event_app/src/pages/explore_page.dart';
import 'package:event_app/src/pages/first_page.dart';
import 'package:event_app/src/pages/login_page.dart';
import 'package:event_app/src/pages/my_events_page.dart';
import 'package:event_app/src/pages/register_page.dart';
import 'package:event_app/src/utility/network.dart';
import 'package:event_app/src/utility/push_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

ApplicationState appState = ApplicationState();
Network network = Network();
PushNotificationController pushNotificationController =
    PushNotificationController();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final Connectivity _connectivity = Connectivity();
late StreamSubscription<ConnectivityResult> _connectivitySubscription;

// Health Check Timer
bool _isRunning = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase services
  await Firebase.initializeApp();

  // Start listener on Connectivity Changed events
  await initConnectivity();
  _connectivitySubscription =
      _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

  // Health Check Timer
  Timer.periodic(
      const Duration(seconds: Constants.SERVER_HEALTH_CHECK_INTERVAL),
      (Timer timer) async {
    if (!_isRunning) {
      timer.cancel();
    }
    try {
      await network.healthCheck();
    } catch (e) {
      if (kDebugMode) {
        print('Server unavailable!\n' + e.toString());
      }
    }
  });

  // Lock display rotation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Start App Widget
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ChangeNotifierProvider(
        create: (_) => SearchModel(),
        child: const MyApp(),
      ),
    ),
  );
}

Future<void> initConnectivity() async {
  late ConnectivityResult result;
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    result = await _connectivity.checkConnectivity();
  } on PlatformException catch (e) {
    if (kDebugMode) {
      print('Could not check connectivity status\n' + e.toString());
    }
    return;
  }
  return _updateConnectionStatus(result);
}

Future<void> _updateConnectionStatus(ConnectivityResult result) async {
  appState.connectionStatus = result;
  if ((result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) &&
      appState.offlineMode == true) {
    appState.offlineMode = false;
  } else if (result == ConnectivityResult.none &&
      appState.offlineMode == false) {
    appState.offlineMode = true;
  }
}

@override
void dispose() {
  _isRunning = false; // Stop Health Check Timer
  _connectivitySubscription.cancel();
  appState.dispose();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Nxt2Me',
      theme: ThemeData(
        primaryColor: Constants.themeColor,
        timePickerTheme: TimePickerTheme.of(context).copyWith(
          hourMinuteColor: Colors.white10,
          entryModeIconColor: Colors.white,
          dialTextColor: Colors.white,
          backgroundColor: Constants.backgroundColor,
          dayPeriodColor: Colors.white,
          dayPeriodTextColor: Colors.white,
          dialHandColor: Constants.themeColor,
          hourMinuteTextColor: Colors.white,
          helpTextStyle: const MyTextStyle(cColor: Colors.white),
        ),
        buttonTheme:
            ButtonTheme.of(context).copyWith(textTheme: ButtonTextTheme.accent),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: Constants.glowingScrollColor),
        textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Constants.themeColor,
            selectionHandleColor: Constants.themeColor),
      ),
      initialRoute: '/first',
      routes: {
        '/explorePage': (context) => const ExplorePage(),
        '/myEvents': (context) => const MyEventsPage(),
        '/settings': (context) => const AccountSettingsPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/first': (context) => FirstPage(),
      },
    );
  }
}
