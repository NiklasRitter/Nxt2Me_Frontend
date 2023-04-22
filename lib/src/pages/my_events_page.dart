import 'dart:convert';

import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_bottom_navigation_bar.dart';
import 'package:event_app/src/elements/explore_element.dart';
import 'package:event_app/src/model/event.dart';
import 'package:event_app/src/pages/add_event_page.dart';
import 'package:event_app/src/utility/filter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as ptr;

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({Key? key}) : super(key: key);

  @override
  _MyEventsPageState createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<Event> myEvents = [];
  List<Event> favEvents = [];

  late TabController _controller;
  int _selectedIndex = 0;

  final ptr.RefreshController _refreshControllerMyEvents =
      ptr.RefreshController(initialRefresh: false);
  final ptr.RefreshController _refreshControllerFavourites =
      ptr.RefreshController(initialRefresh: false);

  void _onLoadingMyEvents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await reloadMyEventsFromServer().then((value) => null);
    _refreshControllerMyEvents.loadComplete();
  }

  void _onLoadingFavourites() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await reloadFavEventsFromServer();
    _refreshControllerFavourites.loadComplete();
  }

  /// Loads MyEvents from server and updates the sqlite DB
  Future<void> reloadMyEventsFromServer() async {
    if (appState.offlineMode == true || appState.serverAlive == false) return;

    FilterUtility filter = FilterUtility();
    List<int> result = filter.getMinAndMaxCreationTimestamp(myEvents);
    int oldestMyEventTimestamp = result[0];
    int latestMyEventTimestamp = result[1];

    try {
      await network
          .getMyEvents(oldestMyEventTimestamp, latestMyEventTimestamp)
          .then((queriedMyEvents) async {
        if (queriedMyEvents.isNotEmpty) {
          List<Event> toSave =
              await filter.removeDeletedEvents(queriedMyEvents, myEvents);

          appState.sqliteDbEvents.insertAllEvents(toSave);

          if (mounted) {
            setState(() {
              myEvents.addAll(toSave);
              myEvents.sort((a, b) {
                if (a.creationTimestamp < b.creationTimestamp) {
                  return 1;
                } else if (a.creationTimestamp > b.creationTimestamp) {
                  return -1;
                } else {
                  return (-1) * a.eventName.compareTo(b.eventName);
                }
              });
            });
          }
        }

        if (kDebugMode) {
          print('Server MyEvents loaded!');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print('Query My Events failed!');
      }
      return;
    }
  }

  /// Load MyEvents from SQLiteDB
  Future<void> reloadMyEventsFromSQLiteDB() async {
    try {
      appState.sqliteDbEvents.allMyEvents().then((loadedEvents) async {
        if (mounted) {
          setState(() {
            myEvents.clear();
            myEvents.addAll(loadedEvents);
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print('Local My Events failed!');
      }
      return;
    }
    if (kDebugMode) {
      print('Local MyEvents loaded!');
    }
  }

  /// Loads FavEvents from server and updates the sqlite DB
  Future<void> reloadFavEventsFromServer() async {
    if (appState.offlineMode == true || appState.serverAlive == false) return;

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
          await reloadFavEventsFromSQLiteDB();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print('Query FavEvents failed!');
      }
      return;
    }

    // Update fav id list in user
    try {
      await network.getUser().then((res) {
        appState.user.favoriteEventIds =
            json.decode(res.body)["favoriteEventIds"];
        appState.sqliteDbUsers.updateUser(appState.user);
        if (kDebugMode) {
          print('User FavIds loaded from Server!');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print('User FavIds loaded from Server failed!');
      }
      return;
    }

    if (kDebugMode) {
      print('Server FavEvents loaded!');
    }
  }

  /// Loads FavEvents from sqlite DB
  Future<void> reloadFavEventsFromSQLiteDB() async {
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

  /// Triggered when offlineMode changed
  void _onOfflineModeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> listenerFunction() async {
    if (_selectedIndex == _controller.index) return;
    if (mounted) {
      setState(() {
        _selectedIndex = _controller.index;
      });
    }
    if (_selectedIndex == 0) {
      await reloadFavEventsFromServer();
    }
    if (_selectedIndex == 1) {
      await reloadMyEventsFromServer();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(listenerFunction);
    _controller.dispose();
    appState
        .removeListener(_onOfflineModeChanged, ['offlineMode', 'serverAlive']);
    _refreshControllerMyEvents.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    appState.addListener(_onOfflineModeChanged, ['offlineMode', 'serverAlive']);

    _controller = TabController(vsync: this, length: 2);
    _controller.addListener(listenerFunction);

    reloadMyEventsFromSQLiteDB();
    reloadFavEventsFromSQLiteDB();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 1,
      ),
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Constants.backgroundColor,
        automaticallyImplyLeading: false,
        title: const Text(
          'Events',
          style: MyTextStyle(
            cFontSize: Constants.pageHeadingFontSize,
            cFontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 10, 0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.fade,
                      duration: const Duration(milliseconds: 250),
                      reverseDuration: const Duration(milliseconds: 250),
                      child: const AddEventPage(),
                      fullscreenDialog: true,
                    )).then((value) async {
                  await reloadMyEventsFromSQLiteDB();
                });
              },
              splashRadius: 25,
              icon: const Icon(
                CupertinoIcons.add,
                size: 30,
              ),
            ),
          )
        ],
      ),
      backgroundColor: Constants.backgroundColor,
      body: DefaultTabController(
        length: 2,
        initialIndex: 0,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
              child: (appState.offlineMode || appState.serverAlive == false)
                  ? Container(
                      width: MediaQuery.of(context).size.width,
                      height: 20.0,
                      color: const Color(0xFFEE4400),
                      child: const Center(
                        child: Text('OFFLINE'),
                      ),
                    )
                  : Container(),
            ),
            TabBar(
              controller: _controller,
              labelColor: Colors.white,
              labelStyle: const MyTextStyle(
                cFontSize: Constants.flowingTextFontSize,
              ),
              indicatorColor: Constants.themeColor,
              tabs: const [
                Tab(
                  text: 'Favourites',
                ),
                Tab(
                  text: 'My Events',
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 16, 0, 0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            height: double.infinity,
                            child: ptr.SmartRefresher(
                              enablePullDown: false,
                              enablePullUp: true,
                              footer: ptr.CustomFooter(
                                builder: (BuildContext context,
                                    ptr.LoadStatus? mode) {
                                  Widget body;
                                  if (mode == ptr.LoadStatus.idle) {
                                    body = const Text(
                                        "Pull Up To Load More Favourites",
                                        style:
                                            MyTextStyle(cColor: Colors.white));
                                  } else if (mode == ptr.LoadStatus.loading) {
                                    body = const CupertinoActivityIndicator(
                                        color: Colors.white);
                                  } else if (mode == ptr.LoadStatus.failed) {
                                    body = const Text(
                                        "Load Failed! Click retry!",
                                        style:
                                            MyTextStyle(cColor: Colors.white));
                                  } else if (mode ==
                                      ptr.LoadStatus.canLoading) {
                                    body = const Text("Release to load more",
                                        style:
                                            MyTextStyle(cColor: Colors.white));
                                  } else {
                                    body = const Text("No more Data",
                                        style:
                                            MyTextStyle(cColor: Colors.white));
                                  }
                                  return SizedBox(
                                    height: 55.0,
                                    child: Center(child: body),
                                  );
                                },
                              ),
                              controller: _refreshControllerFavourites,
                              onLoading: _onLoadingFavourites,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ScrollPhysics(),
                                itemCount: favEvents.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return ExploreElement(
                                    key: UniqueKey(),
                                    event: favEvents[index],
                                    callback: () async {
                                      await reloadMyEventsFromSQLiteDB();
                                      await reloadFavEventsFromSQLiteDB();
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 16, 0, 0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            height: double.infinity,
                            child: ptr.SmartRefresher(
                              enablePullDown: false,
                              enablePullUp: true,
                              footer: ptr.CustomFooter(
                                builder: (BuildContext context,
                                    ptr.LoadStatus? mode) {
                                  Widget body;
                                  if (mode == ptr.LoadStatus.idle) {
                                    body = const Text(
                                        "Pull Up To Load More Events",
                                        style:
                                            MyTextStyle(cColor: Colors.white));
                                  } else if (mode == ptr.LoadStatus.loading) {
                                    body = const CupertinoActivityIndicator(
                                        color: Colors.white);
                                  } else if (mode == ptr.LoadStatus.failed) {
                                    body = const Text(
                                        "Load Failed! Click retry!",
                                        style:
                                            MyTextStyle(cColor: Colors.white));
                                  } else if (mode ==
                                      ptr.LoadStatus.canLoading) {
                                    body = const Text("Release to load more",
                                        style:
                                            MyTextStyle(cColor: Colors.white));
                                  } else {
                                    body = const Text("No more Data",
                                        style:
                                            MyTextStyle(cColor: Colors.white));
                                  }
                                  return SizedBox(
                                    height: 55.0,
                                    child: Center(child: body),
                                  );
                                },
                              ),
                              controller: _refreshControllerMyEvents,
                              onLoading: _onLoadingMyEvents,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ScrollPhysics(),
                                itemCount: myEvents.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return ExploreElement(
                                    key: UniqueKey(),
                                    event: myEvents[index],
                                    callback: () async {
                                      await reloadMyEventsFromSQLiteDB();
                                      await reloadFavEventsFromSQLiteDB();
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
