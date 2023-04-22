import 'dart:convert';

import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_bottom_navigation_bar.dart';
import 'package:event_app/src/elements/explore_element.dart';
import 'package:event_app/src/elements/favourites_element.dart';
import 'package:event_app/src/model/event.dart';
import 'package:event_app/src/pages/filter_page.dart';
import 'package:event_app/src/utility/filter.dart';
import 'package:event_app/src/utility/geofunctions.dart';
import 'package:event_app/src/utility/util_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<Event> filteredEvents = [];
  List<Event> favEvents = [];

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final RefreshController favoritesRefresher = RefreshController(initialRefresh: false);

  void _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await onRefresh();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await onRefresh();
    _refreshController.loadComplete();
  }

  /// Load the last known events from sqlite DB for fav and explore events list
  Future<void> loadEventsFromSQLiteDB() async {
    await appState.sqliteDbEvents.allEvents().then((loadedEvents) async {
      // Apply explore filter on loaded events
      List<Event> toFilteredEvents = FilterUtility().filterEvents(loadedEvents);

      if (mounted) {
        setState(() {
          filteredEvents.clear();
          filteredEvents.addAll(toFilteredEvents);
          filteredEvents.sort((a, b) => a.compareTo(b));
        });
      }
    });

    if (kDebugMode) {
      print('Local DB Explore Events loaded!');
    }
  }

  /// Query for new events from current position in a specific radius
  Future<void> loadEventsFromServer(double lng, double lat) async {
    // In offlineMode not possible
    if (appState.offlineMode == true || appState.serverAlive == false) return;

    List<Event> queriedEvents = [];

    DateTime lastQuery = DateTime.fromMillisecondsSinceEpoch(0);

    // Look for older query timestamp
    await appState.secStorageCtrl
        .readSecureData(Constants.LAST_EVENT_QUERY_TIMESTAMP)
        .then((value) {
      if (value != null) {
        lastQuery = DateTime.fromMillisecondsSinceEpoch(int.parse(value));
      }
    });

    try {
      queriedEvents = await network.getEventsSinceTimestamp(
          lng,
          lat,
          Constants.DEFAULT_MAX_QUERY_DISTANCE,
          lastQuery.millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print('Query Events failed!');
      }
      return;
    }

    if (queriedEvents.isNotEmpty) {
      // set query timestamp from last queried event
      appState.secStorageCtrl.writeSecureData(
          Constants.LAST_EVENT_QUERY_TIMESTAMP,
          queriedEvents.last.creationTimestamp.toString());

      List<Event> toSave = await FilterUtility()
          .removeDeletedEvents(queriedEvents, filteredEvents);

      // add all events in the radius in the devices sqlite DB and filter it to show only the matching ones
      await appState.sqliteDbEvents.insertAllEvents(toSave);

      await loadEventsFromSQLiteDB();
    }
    if (kDebugMode) {
      print('Server events loaded!');
    }
  }

  /// Updates the current position in appState and Secure Storage
  Future<void> updateLocation() async {
    // in offline mode is getGeoLocationPermissionAndPosition very slow,
    // use old location to enhance speed of application
    if (appState.offlineMode == true || appState.serverAlive == false) {
      var latitude = await appState.secStorageCtrl
          .readSecureData(Constants.CURRENT_LOC_LATITUDE);
      var longitude = await appState.secStorageCtrl
          .readSecureData(Constants.CURRENT_LOC_LONGITUDE);

      if (latitude != null && longitude != null) {
        appState.lastKnownLatitude = double.parse(latitude);
        appState.lastKnownLongitude = double.parse(longitude);
      }
      return;
    }

    await GeoFunctions.getGeoLocationPermissionAndPosition()
        .then((position) async {
      appState.lastKnownLatitude = position.latitude;
      appState.lastKnownLongitude = position.longitude;

      // Save the current location in the persistent secure storage
      await appState.secStorageCtrl.writeSecureData(
          Constants.CURRENT_LOC_LATITUDE, position.latitude.toString());
      await appState.secStorageCtrl.writeSecureData(
          Constants.CURRENT_LOC_LONGITUDE, position.longitude.toString());
    });
  }

  /// Waits for callback of the Filter Page and reloads events because of the applied new filter
  void _awaitFilterPageCall(BuildContext context) async {
    await Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 250),
          reverseDuration: const Duration(milliseconds: 250),
          child: FilterPage(key: UniqueKey()),
          fullscreenDialog: true,
        ));

    await loadEventsFromSQLiteDB();
  }

  /// Looks in DB Events for fav events and adds them in the fav bar
  Future<void> refreshFavBar() async {
    await appState.sqliteDbEvents.allFavouriteEvents().then((loadedEvents) {
      if (mounted) {
        setState(() {
          favEvents.clear();
          favEvents.addAll(loadedEvents);
          favEvents.sort((a, b) => a.compareTo(b));
        });
      }
    });

    if (kDebugMode) {
      print('Local DB Fav Events loaded!');
    }
  }

  /// Loads FavEvents from server and updates the sqlite DB
  Future<void> reloadFavEventsFromServer() async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      return Utils.showOfflineBanner();
    }

    FilterUtility filter = FilterUtility();
    List<int> result = filter.getMinAndMaxCreationTimestamp(favEvents);
    int oldestFavouriteTimestamp = result[0];
    int latestFavouriteTimestamp = result[1];

    try {
      await network
          .getFavEvents(oldestFavouriteTimestamp, latestFavouriteTimestamp)
          .then((queriedFavEvents) async {
        if (queriedFavEvents.isNotEmpty) {
          List<Event> toSave =
          await filter.removeDeletedEvents(queriedFavEvents, favEvents);
          await appState.sqliteDbEvents.insertAllEvents(toSave);

          var res = await network.getUser();
          appState.user.favoriteEventIds = json.decode(res.body)["favoriteEventIds"];
          await appState.sqliteDbUsers.updateUser(appState.user);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print('Query FavEvents failed!');
      }
      return;
    }
  }

  /// Reloads and optional refreshes the events; Either only toggled favourite event or edited event
  Future<void> refresh() async {
    await refreshFavBar();
    await loadEventsFromSQLiteDB();
  }

  /// Called after using the refresh indicator; update loc and query new all events
  Future<void> onRefresh() async {
    await updateLocation();
    await loadEventsFromSQLiteDB();

    // In offlineMode or server error not possible
    if (!(appState.offlineMode == true || appState.serverAlive == false)) {
      await loadEventsFromServer(appState.lastKnownLongitude, appState.lastKnownLatitude);
      await reloadFavEventsFromServer();
    } else {
      Utils.showOfflineBanner();
    }
    await refreshFavBar();
  }

  /// load favorite Events from server
  Future<void> loadFavorites() async {
    await reloadFavEventsFromServer();
    await refreshFavBar();
    favoritesRefresher.loadComplete();
  }

  /// Triggered when offlineMode changed
  void _onOfflineModeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    appState.addListener(_onOfflineModeChanged, ['offlineMode', 'serverAlive']);

    // Deletes older events
    appState.sqliteDbEvents.deleteOldEvents();

    // load events initially
    onRefresh();
  }

  @override
  void dispose() {
    appState
        .removeListener(_onOfflineModeChanged, ['offlineMode', 'serverAlive']);
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 0,
      ),
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Constants.backgroundColor,
        automaticallyImplyLeading: false,
        title: const Text(
          'Explore',
          style: MyTextStyle(
            cFontSize: Constants.pageHeadingFontSize,
            cFontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ElevatedButton(
            child: const Icon(
              Icons.filter_alt,
              color: Constants.iconColor,
              size: 24,
            ),
            onPressed: () {
              _awaitFilterPageCall(context);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  return Constants.backgroundColor;
                },
              ),
              elevation: MaterialStateProperty.resolveWith<double>(
                (Set<MaterialState> states) {
                  return 0;
                },
              ),
              overlayColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                return Constants.transparent;
              }),
            ),
          ),
        ],
        centerTitle: false,
        elevation: 2,
      ),
      backgroundColor: Constants.backgroundColor,
      body: SmartRefresher(
        scrollDirection: Axis.vertical,
        enablePullDown: true,
        enablePullUp: true,
        footer: CustomFooter(
          builder: (BuildContext context, LoadStatus? mode) {
            Widget body;
            if (mode == LoadStatus.idle) {
              body = const Text("Pull Up To Load More Events",
                  style: MyTextStyle(cColor: Colors.white));
            } else if (mode == LoadStatus.loading) {
              body = const CupertinoActivityIndicator(color: Colors.white);
            } else if (mode == LoadStatus.failed) {
              body = const Text("Load Failed!Click retry!",
                  style: MyTextStyle(cColor: Colors.white));
            } else if (mode == LoadStatus.canLoading) {
              body = const Text("Release to load more",
                  style: MyTextStyle(cColor: Colors.white));
            } else {
              body = const Text("No more Data",
                  style: MyTextStyle(cColor: Colors.white));
            }
            return SizedBox(
              height: 55.0,
              child: Center(child: body),
            );
          },
        ),
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: CustomScrollView(slivers: [
          if (appState.user.favoriteEventIds.isNotEmpty)
            SliverAppBar(
              backgroundColor: Constants.backgroundColor,
              toolbarHeight: kToolbarHeight +
                  MediaQuery.of(context).size.width * 2 / 5 +
                  ((appState.offlineMode == true ||
                          appState.serverAlive == false)
                      ? 20
                      : 0),
              flexibleSpace: Column(children: [
                Container(
                    child: (appState.offlineMode == true ||
                            appState.serverAlive == false)
                        ? Container(
                            width: MediaQuery.of(context).size.width,
                            height: 20.0,
                            color: const Color(0xFFEE4400),
                            child: const Center(
                              child: Text('OFFLINE'),
                            ))
                        : Container()),
                appState.user.favoriteEventIds.isNotEmpty
                    ? const Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(8, 5, 0, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Favourites',
                            style: MyTextStyle(
                              cFontSize: Constants.subheadingFontSize,
                              cFontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Container(),
                appState.user.favoriteEventIds.isNotEmpty
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.width * 2 / 5 * 1.11,
                        ),
                        child: Container(
                          height: 200,
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                8, 0, 0, 0),
                            child: SmartRefresher(
                              scrollDirection: Axis.horizontal,
                              controller: favoritesRefresher,
                              footer: CustomFooter(
                                builder: (BuildContext context, LoadStatus? mode) {
                                  Widget  body = const Text("",
                                      style: MyTextStyle(cColor: Colors.white));
                                  return SizedBox(
                                    height: 55.0,
                                    child: Center(child: body),
                                  );
                                },
                              ),
                              enablePullUp: true,
                              enablePullDown: false,
                              onLoading: loadFavorites,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: favEvents.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return FavouritesElement(
                                    key: UniqueKey(),
                                    event: favEvents[index],
                                    callback: () async {
                                      await refresh();
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(),
              ]),
            ),
          appState.user.favoriteEventIds.isNotEmpty
              ? const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 20,
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
                      child: Text(
                        'Explore',
                        style: MyTextStyle(
                          cFontSize: Constants.subheadingFontSize,
                          cFontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: SizedBox(
                    height: 20,
                    child: Container(
                        child: (appState.offlineMode == true ||
                                appState.serverAlive == false)
                            ? Container(
                                width: MediaQuery.of(context).size.width,
                                height: 20.0,
                                color: const Color(0xFFEE4400),
                                child: const Center(
                                  child: Text('OFFLINE'),
                                ))
                            : Container()),
                  ),
                ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ExploreElement(
                  key: UniqueKey(),
                  event: filteredEvents[index],
                  callback: () async {
                    await refresh();
                  },
                );
              },
              childCount: filteredEvents.length,
            ),
          ),
        ]),
      ),
    );
  }
}
