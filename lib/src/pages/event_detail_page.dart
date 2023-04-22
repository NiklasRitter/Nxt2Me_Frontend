import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_comment.dart';
import 'package:event_app/src/elements/selected_categories_widget.dart';
import 'package:event_app/src/model/comment.dart';
import 'package:event_app/src/model/event.dart';
import 'package:event_app/src/pages/add_event_page.dart';
import 'package:event_app/src/utility/filter.dart';
import 'package:event_app/src/utility/geofunctions.dart';
import 'package:event_app/src/utility/util_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class EventDetailsPage extends StatefulWidget {
  EventDetailsPage({
    required Key? key,
    required this.event,
  }) : super(key: key);

  Event event;

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String errorTextTop = "";
  String errorTextBottom = "";

  // GMaps
  late String _mapStyle;
  GoogleMapController? _googleMapsController;
  final Map<String, Marker> _markers = {};
  LatLng _eventPosition = const LatLng(0, 0);
  Marker eventMarker = const Marker(markerId: MarkerId('eventMarker'));

  List<Comment> comments = [];
  final _scrollController = ScrollController();
  final RefreshController refreshController = RefreshController();

  late TextEditingController textController;
  late bool toggleButtonFavourite;

  // Options in the drop down list when the upper right 3 points are touched
  List<String> choices = <String>[];

  List<String> selectedCategories = [];

  /// scroll to top on comment list
  void _scrollToTop() async {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(0.0,
          curve: Curves.easeOut, duration: const Duration(milliseconds: 300));
    });
  }

  /// gmaps create function
  void _onMapCreated(GoogleMapController _cntlr) {
    _googleMapsController = _cntlr;
    _googleMapsController!.setMapStyle(_mapStyle);

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers[widget.event.locationName] = eventMarker;
      });
    }

    _googleMapsController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _eventPosition, zoom: 15),
      ),
    );
  }

  /// gmaps center to event location
  void _centerOnLocation() {
    _googleMapsController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _eventPosition, zoom: 15),
      ),
    );
  }

  /// Formats the DateTime objects to user friendly strings for the widget
  String _getDateTimeFormatted() {
    final int startDateTimeSec = widget.event.startTimestamp;
    final int endDateTimeSec = widget.event.endTimestamp;
    final DateFormat formatterDate = DateFormat('dd. MMMM yyyy');
    final DateFormat formatterTime = DateFormat().add_Hm();

    final DateTime startDateTime =
        DateTime.fromMillisecondsSinceEpoch(startDateTimeSec);
    final DateTime endDateTime =
        DateTime.fromMillisecondsSinceEpoch(endDateTimeSec);

    String startDate = formatterDate
        .format(DateTime.fromMillisecondsSinceEpoch(startDateTimeSec));
    String endDate = formatterDate
        .format(DateTime.fromMillisecondsSinceEpoch(endDateTimeSec));

    String startTime = formatterTime
        .format(DateTime.fromMillisecondsSinceEpoch(startDateTimeSec));
    String endTime = formatterTime
        .format(DateTime.fromMillisecondsSinceEpoch(endDateTimeSec));

    if (startDateTime.day == endDateTime.day &&
        startDateTime.month == endDateTime.month &&
        startDateTime.year == endDateTime.year) {
      return '$startDate   $startTime - $endTime';
    } else {
      return '$startDate $startTime  -  $endDate $endTime';
    }
  }

  /// Reacts on the tap on the favourite star in the app bar
  void _toggleFavourite() async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      return Utils.showOfflineBanner();
    }

    int newValue = -1;

    try {
      newValue = await network.toggleFavoriteEvent(widget.event.eventId);
    } catch (e) {
      if (kDebugMode) {
        print(
            'Fav toggle not possible because of unreachable network or server!');
      }
      return;
    }
    if (newValue != -1) {
      if (mounted) {
        setState(() {
          toggleButtonFavourite = !toggleButtonFavourite;
        });
      }

      if (toggleButtonFavourite) {
        appState.user.favoriteEventIds.add(widget.event.eventId);
      } else {
        appState.user.favoriteEventIds.remove(widget.event.eventId);
      }

      widget.event.likeCount = newValue;

      await appState.sqliteDbUsers.updateUser(appState.user);
      await appState.sqliteDbEvents.updateEvent(widget.event);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _menuAction(String itemName) async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      return Utils.showOfflineBanner();
    }

    if (itemName == "Report Event") {
      var res = await network.reportEvent(widget.event.eventId);
      if (res.statusCode == 200) {
        await appState.sqliteDbEvents.deleteEvent(widget.event.eventId);
        appState.user.favoriteEventIds.remove(widget.event.eventId);
        await appState.sqliteDbUsers.updateUser(appState.user);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, "/explore");
        }
      }
    } else if (itemName == "Delete Event") {
      var res = await network.deleteEvent(widget.event);
      if (res.statusCode == 200) {
        var deleted =
            await appState.sqliteDbEvents.deleteEvent(widget.event.eventId);
        if (deleted == 0) {
          if (mounted) {
            setState(() {
              errorTextTop =
                  "Failed to delete Event locally please restart the application.";
            });
          }
        } else {
          Navigator.pop(context, widget.event);
        }
      } else {
        if (mounted) {
          setState(() {
            errorTextTop = res.body;
          });
        }
      }
    }
  }

  void _initMarker() async {
    await GeoFunctions.getPositionPlace(LatLng(
            widget.event.locationLatitude, widget.event.locationLongitude))
        .then((place) => {
              if (mounted)
                {
                  setState(() {
                    eventMarker = Marker(
                      markerId: MarkerId(widget.event.locationName),
                      position: LatLng(widget.event.locationLatitude,
                          widget.event.locationLongitude),
                      infoWindow: InfoWindow(
                        title:
                            place.name != '' ? place.name : place.level2Address,
                        snippet: place.name != '' ? place.level2Address : '',
                      ),
                    );
                  }),
                }
            });
  }

  /// Sends a new comment to the server
  void sendComment() async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      return Utils.showOfflineBanner();
    }

    var eventText = textController.value.text;
    if (eventText != "") {
      await network
          .createComment(widget.event.eventId, appState.user.username,
              DateTime.now().millisecondsSinceEpoch, eventText)
          .then((value) async {
        if (value.statusCode != 200) {
          if (mounted) {
            setState(() {
              errorTextBottom = value.body;
            });
          }
          return;
        }
        textController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
        await loadComments();
        _scrollToTop();
      });
    }
  }

  /// Called when the refresh indicator is pulled; Updates the comments
  Future<void> loadComments() async {
    if (appState.offlineMode == true || appState.serverAlive == false) {
      refreshController.loadComplete();
      refreshController.refreshCompleted();
      return Utils.showOfflineBanner();
    }

    List<int> result = FilterUtility().getMinAndMaxCreationTimestamp(comments);
    int oldestFavouriteTimestamp = result[0];
    int latestFavouriteTimestamp = result[1];

    try {
      List<Comment> newComments = await network.getCommentsOfEvent(
          widget.event.eventId,
          oldestFavouriteTimestamp,
          latestFavouriteTimestamp,
          Constants.LIMIT_COMMENTS_QUERY);

      if (mounted) {
        setState(() {
          comments.addAll(newComments);
          comments.sort((a, b) => a.compareTo(b));
          comments = comments.reversed.toList();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print('Query FavEvents failed!');
      }
      return;
    }

    refreshController.loadComplete();
    refreshController.refreshCompleted();
  }

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    toggleButtonFavourite = false;

    selectedCategories.addAll(widget.event.category.toList());

    GeoFunctions.getGeoLocationPermission();

    // refresh widget after asking for permission
    if (mounted) {
      setState(() {});
    }

    // load googlemap visual style out of the text file
    rootBundle.loadString('assets/gmap_style.txt').then((string) {
      _mapStyle = string;
    });

    // sets the initial camera on the event position
    _eventPosition =
        LatLng(widget.event.locationLatitude, widget.event.locationLongitude);

    // Find out the address of the event
    _initMarker();

    comments = widget.event.comments;

    toggleButtonFavourite =
        appState.user.favoriteEventIds.contains(widget.event.eventId);

    choices = widget.event.organizerUserId == appState.user.id
        ? <String>["Report Event", "Delete Event"]
        : <String>[
            "Report Event",
          ];

    loadComments();
  }

  @override
  void dispose() {
    if (_googleMapsController != null) {
      _googleMapsController!.dispose();
    }
    widget.event.comments = comments;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: true,
        backgroundColor: Constants.backgroundColor,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          reverse: false,
          primary: false,
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Image(
                        fit: BoxFit.contain,
                        image: widget.event.image == null
                            ? Image.asset('assets/images/Stand_By.jpg').image
                            : CachedNetworkImageProvider(
                                widget.event.image!,
                              ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  15, 44, 0, 0),
                              child: Card(
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                color: const Color(0xBE838383),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context, widget.event);
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 44, 15, 0),
                              child: Card(
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                color: const Color(0xBE838383),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    widget.event.organizerUserId ==
                                            appState.user.id
                                        ? Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                10, 0, 0, 0),
                                            child: InkResponse(
                                              radius: 25,
                                              onTap: () async {
                                                await Navigator.push(
                                                    context,
                                                    PageTransition(
                                                      type: PageTransitionType
                                                          .fade,
                                                      duration: const Duration(
                                                          milliseconds: 250),
                                                      reverseDuration:
                                                          const Duration(
                                                              milliseconds:
                                                                  250),
                                                      child: AddEventPage(
                                                        key: UniqueKey(),
                                                        event: widget.event,
                                                      ),
                                                      fullscreenDialog: true,
                                                    )).then((updatedEvent) {
                                                  if (mounted) {
                                                    if (updatedEvent != null) {
                                                      if (mounted) {
                                                        setState(() {
                                                          widget.event =
                                                              updatedEvent;
                                                        });
                                                      }
                                                    }
                                                    if (mounted) {
                                                      setState(() {
                                                        // look for selected categories to show it in view
                                                        selectedCategories
                                                            .clear();
                                                        selectedCategories
                                                            .addAll(widget
                                                                .event.category
                                                                .toList());
                                                      });
                                                    }
                                                  }
                                                });
                                              },
                                              child: const Icon(
                                                Icons.edit,
                                                color: Constants.iconColor,
                                                size: 22,
                                              ),
                                            ),
                                          )
                                        : Container(),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 0, 0, 0),
                                      child: InkResponse(
                                        radius: 25,
                                        onTap: _toggleFavourite,
                                        child: Icon(
                                          toggleButtonFavourite
                                              ? Icons.star_rate
                                              : Icons.star_outline,
                                          color: Constants.iconColor,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton(
                                      onSelected: _menuAction,
                                      color: Constants.backgroundColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      padding: EdgeInsets.zero,
                                      tooltip: "Support",
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Constants.iconColor,
                                        size: 20,
                                      ),
                                      itemBuilder: (BuildContext context) {
                                        return choices.map((String choice) {
                                          return PopupMenuItem<String>(
                                            value: choice,
                                            child: Text(choice,
                                                style: const MyTextStyle(
                                                    cColor: Colors.white)),
                                          );
                                        }).toList();
                                      },
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                (appState.offlineMode == true || appState.serverAlive == false)
                    ? Container(
                        width: MediaQuery.of(context).size.width,
                        height: 20.0,
                        color: const Color(0xFFEE4400),
                        child: const Center(
                          child: Text('OFFLINE'),
                        ),
                      )
                    : Container(),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.96,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(15, 0, 15, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 0, 0, 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  widget.event.organizerUserId ==
                                          appState.user.id
                                      ? Text(
                                          errorTextTop,
                                          style: const MyTextStyle(
                                            cFontSize: 25,
                                            cFontWeight: FontWeight.bold,
                                            cColor: Colors.red,
                                          ),
                                        )
                                      : const Text('',
                                          style: MyTextStyle(
                                            cFontSize: 25,
                                            cFontWeight: FontWeight.bold,
                                            cColor: Colors.red,
                                          )),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0, 0, 0, 10),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: 10,
                                        minWidth:
                                            MediaQuery.of(context).size.width,
                                        maxHeight: 170,
                                        maxWidth:
                                            MediaQuery.of(context).size.width,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: SingleChildScrollView(
                                              physics: const ScrollPhysics(),
                                              scrollDirection: Axis.vertical,
                                              child: Text(
                                                widget.event.eventName,
                                                overflow: TextOverflow.visible,
                                                style: const MyTextStyle(
                                                  cFontSize: 25,
                                                  cFontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(0, 0, 4, 0),
                                                child: Icon(
                                                    Icons.thumb_up_alt_rounded,
                                                    color:
                                                        Constants.themeColor),
                                              ),
                                              Text(
                                                widget.event.likeCount
                                                    .toString(),
                                                style: const MyTextStyle(
                                                  cColor: Colors.white,
                                                  cFontWeight: FontWeight.bold,
                                                ),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0, 0, 0, 30),
                                    child: SelectedCategoriesWidget(
                                        selectedCategories: selectedCategories),
                                  ),
                                  Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0, 0, 0, 5),
                                        child: Row(
                                          children: [
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(right: 10.0),
                                              child: Icon(
                                                Icons.calendar_today,
                                                color: Constants.themeColor,
                                                size: 24,
                                              ),
                                            ),
                                            Expanded(
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: SingleChildScrollView(
                                                  physics:
                                                      const ScrollPhysics(),
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Text(
                                                    _getDateTimeFormatted(),
                                                    style: const MyTextStyle(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(0, 0, 0, 5),
                              child: Text(
                                "Organizer",
                                style: MyTextStyle(
                                  cFontWeight: FontWeight.w600,
                                  cFontSize: 15,
                                  cColor: Constants.themeColor,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 0, 0, 5),
                              child: Text(
                                widget.event.organizerName,
                                style: const MyTextStyle(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(15, 16, 15, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(0, 0, 0, 5),
                              child: Text(
                                'Description',
                                style: MyTextStyle(
                                  cFontWeight: FontWeight.w600,
                                  cFontSize: 15,
                                  cColor: Constants.themeColor,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 0, 0, 20),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: 200,
                                  minWidth: MediaQuery.of(context).size.width,
                                  maxWidth: MediaQuery.of(context).size.width,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text(
                                    widget.event.description,
                                    style: const MyTextStyle(),
                                    maxLines: 2147483647, //max int
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(0, 0),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 10, 0, 0),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  height: 350,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: SizedBox(
                                    child: Stack(children: [
                                      GoogleMap(
                                        onMapCreated: _onMapCreated,
                                        markers: {eventMarker},
                                        // _markers.values.toSet(),
                                        initialCameraPosition: CameraPosition(
                                          target: _eventPosition,
                                          zoom: 15,
                                        ),
                                        gestureRecognizers: Set()
                                          ..add(Factory<PanGestureRecognizer>(
                                              () => PanGestureRecognizer()))
                                          ..add(Factory<ScaleGestureRecognizer>(
                                              () => ScaleGestureRecognizer()))
                                          ..add(Factory<TapGestureRecognizer>(
                                              () => TapGestureRecognizer()))
                                          ..add(Factory<
                                                  VerticalDragGestureRecognizer>(
                                              () =>
                                                  VerticalDragGestureRecognizer())),
                                        scrollGesturesEnabled: true,
                                        tiltGesturesEnabled: true,
                                        rotateGesturesEnabled: true,
                                        myLocationButtonEnabled: true,
                                        mapType: MapType.normal,
                                        zoomControlsEnabled: true,
                                        compassEnabled: true,
                                        mapToolbarEnabled: false,
                                        trafficEnabled: false,
                                        liteModeEnabled: false,
                                        myLocationEnabled: true,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(5),
                                                      topRight:
                                                          Radius.circular(5),
                                                      bottomLeft:
                                                          Radius.circular(5),
                                                      bottomRight:
                                                          Radius.circular(5)),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.2),
                                                  spreadRadius: 3,
                                                  blurRadius: 3,
                                                  offset: const Offset(0,
                                                      3), // changes position of shadow
                                                ),
                                              ]),
                                          width: 35,
                                          height: 35,
                                          child: Center(
                                            child: IconButton(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              onPressed: () {
                                                _centerOnLocation();
                                              },
                                              icon: const Icon(
                                                Icons.location_pin,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.96,
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 30),
                  decoration: const BoxDecoration(
                    color: Constants.backgroundColor,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(15, 16, 15, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        comments.isNotEmpty
                            ? const Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0, 0, 0, 20),
                                  child: Text(
                                    'Comments',
                                    style: MyTextStyle(
                                      cFontWeight: FontWeight.w600,
                                      cColor: Constants.themeColor,
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        comments.isNotEmpty
                            ? ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 50,
                                  minWidth:
                                      MediaQuery.of(context).size.width * 0.8,
                                  maxHeight: 250,
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.8,
                                ),
                                child: SmartRefresher(
                                  onRefresh: loadComments,
                                  onLoading: loadComments,
                                  enablePullUp: true,
                                  controller: refreshController,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    reverse: false,
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: comments.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return CustomComment(
                                        key: UniqueKey(),
                                        comment: comments[index],
                                        callback: (value) {
                                          setState(() {
                                            comments.remove(value);
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              )
                            : Container(),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(0, 25, 0, 10),
                              child: Text(
                                'Add a comment',
                                style: MyTextStyle(
                                  cFontWeight: FontWeight.w600,
                                  cFontSize: 15,
                                  cColor: Constants.themeColor,
                                ),
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: textController,
                                minLines: 1,
                                maxLines: 6,
                                keyboardType: TextInputType.multiline,
                                decoration:
                                    const CustomFormFieldInputDecoration(
                                        hintText: 'Type in a comment...'),
                                style: const MyTextStyle(
                                  cColor: Colors.black,
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(1, 0),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 10, 0, 0),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.send,
                                    color: Constants.themeColor,
                                    size: 20,
                                  ),
                                  onPressed: sendComment,
                                ),
                              ),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            errorTextBottom,
                            style: const MyTextStyle(
                              cColor: Colors.red,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
