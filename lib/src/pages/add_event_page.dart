import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/crop_dialog.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/elements/quantity_input.dart';
import 'package:event_app/src/elements/selected_categories_widget.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:event_app/src/model/event.dart';
import 'package:event_app/src/model/place.dart';
import 'package:event_app/src/pages/map_page.dart';
import 'package:event_app/src/pages/select_categories_page.dart';
import 'package:event_app/src/utility/formatter.dart';
import 'package:event_app/src/utility/geofunctions.dart';
import 'package:event_app/src/utility/json_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({Key? key, this.event}) : super(key: key);

  final Event? event;

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late TextEditingController textControllerDescription;
  late TextEditingController textControllerEventName;
  late TextEditingController quantityInputController;
  late final String _userId;
  late final String _username;
  late DateTime date;
  Categories categories = Categories();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(hours: 1));
  late String formattedStartTime;
  late String formattedEndTime;
  String uploadedFileUrl = '';
  Uint8List? image;
  String fileExtensionImage = "";
  bool progressing = false;

  List<String> selectedCategories = [];

  String errorText = "";

  Place eventLocation = Place.getDummyPlace();

  @override
  void initState() {
    super.initState();
    textControllerEventName = TextEditingController();
    textControllerDescription = TextEditingController();
    quantityInputController = TextEditingController(text: "unlimited");
    _userId = appState.user.id;
    _username = appState.user.username;

    if (widget.event != null) {
      selectedCategories.addAll(widget.event!.category.toList());
      textControllerEventName.text = widget.event!.eventName;
      textControllerDescription.text = widget.event!.description;
      quantityInputController.text = widget.event!.maxViews == -1
          ? "unlimited"
          : widget.event!.maxViews.toString();

      startDate =
          DateTime.fromMillisecondsSinceEpoch(widget.event!.startTimestamp);
      endDate = DateTime.fromMillisecondsSinceEpoch(widget.event!.endTimestamp);

      categories = widget.event!.category;
      setInitLocation();
    }
    formattedStartTime =
        Formatter.getTimeFormatted(startDate.millisecondsSinceEpoch);
    formattedEndTime =
        Formatter.getTimeFormatted(endDate.millisecondsSinceEpoch);
  }

  Future<void> setInitLocation() async {
    Place place = await GeoFunctions.getPositionPlace(LatLng(
        widget.event!.locationLatitude, widget.event!.locationLongitude));
    if (mounted) {
      setState(() {
        eventLocation = place;
      });
    }
  }

  Future<Place> initYourLocation() async {
    Place place = const Place(
        name: 'Your Location',
        city: '',
        street: '',
        housenumber: '',
        state: '',
        country: '',
        type: '',
        lat: 0,
        lng: 0);

    await GeoFunctions.getGeoLocationPermissionAndPosition()
        .then((position) async {
      // reverse geocoding
      double latitude = position.latitude;
      double longitude = position.longitude;

      place = await GeoFunctions.getPositionPlace(LatLng(latitude, longitude));
    });
    return place;
  }

  bool eventChanged(Event oldEvent, Event newEvent) {
    if (oldEvent.eventName != newEvent.eventName ||
        oldEvent.description != newEvent.description ||
        oldEvent.category != newEvent.category ||
        oldEvent.locationLongitude != newEvent.locationLongitude ||
        oldEvent.locationLatitude != newEvent.locationLatitude ||
        oldEvent.locationName != newEvent.locationName ||
        oldEvent.startTimestamp != newEvent.startTimestamp ||
        oldEvent.endTimestamp != newEvent.endTimestamp ||
        oldEvent.maxViews != newEvent.maxViews ||
        image != null) {
      return true;
    }
    return false;
  }

  /// Creates an event after clicking the "Add Event" button on the widget.
  Future<void> _createEvent() async {
    // eventId is empty because it is set by the server
    final eventDetailsDTO = Event(
        eventId: widget.event == null ? '' : widget.event!.eventId,
        eventName: textControllerEventName.value.text.trim(),
        startTimestamp: startDate.millisecondsSinceEpoch,
        endTimestamp: endDate.millisecondsSinceEpoch,
        description: textControllerDescription.value.text.trim(),
        organizerUserId: _userId,
        organizerName: _username,
        locationName: eventLocation.address,
        category: categories,
        locationLatitude: eventLocation.lat,
        locationLongitude: eventLocation.lng,
        likeCount: 0,
        creationTimestamp: DateTime.now().millisecondsSinceEpoch,
        maxViews: 0);

    if (!_validateAllInputs(eventDetailsDTO)) return;

    if (image != null) {
      // compress image
      Uint8List compressedFile =
          await JsonUtility.compressImageUInt8List(image!);

      // upload image to googleDrive
      var res = await network.uploadImage(fileExtensionImage, compressedFile);

      if (res.statusCode != 200) {
        if (mounted) {
          setState(() {
            errorText = res.body;
          });
        }
        return;
      }
      eventDetailsDTO.image = res.body;
    } else {
      eventDetailsDTO.image = widget.event!.image;
      if (!eventChanged(widget.event!, eventDetailsDTO)) {
        Navigator.pop(context, eventDetailsDTO);
        return;
      }
    }

    Response response;
    if (widget.event == null) {
      response = await network.createEvent(eventDetailsDTO);
      Event event = Event.fromJson(json.decode(response.body));
      // Add new event in local DB
      appState.sqliteDbEvents.insertEvent(event);
    } else {
      // update event if it already existed
      response = await network.updateEvent(eventDetailsDTO);
      appState.sqliteDbEvents.updateEvent(eventDetailsDTO);
    }

    if (response.statusCode == 200) {
      Navigator.pop(context, eventDetailsDTO);
    } else {
      if (mounted) {
        setState(() {
          errorText = response.body;
        });
      }
    }
  }

  /// Validates all input to not be not empty
  bool _validateAllInputs(Event eventDetailsDTO) {
    int inputValue;
    try {
      inputValue = int.parse(quantityInputController.value.text);
      if (inputValue < 10) {
        if (mounted) {
          setState(() {
            errorText = "Please allow at least 10 views!";
          });
        }
        return false;
      }
    } catch (e) {
      if (quantityInputController.value.text == "unlimited") {
        inputValue = -1;
      } else {
        setState(() {
          errorText = "Please enter a maximum views value!";
        });
        return false;
      }
    }

    eventDetailsDTO.maxViews = inputValue;

    // only allow letters in event name
    RegExp regExpEventName = RegExp(
      r"^[\s]*[\w\S]+([\s][\w\S]+)*[\s]*$",
      caseSensitive: false,
      multiLine: false,
    );

    if ((appState.offlineMode == true || appState.serverAlive == false)) {
      setState(() {
        errorText = "Adding events not possible in offline mode!";
      });
      return false;
    } else if (image == null && widget.event == null) {
      setState(() {
        errorText = "Please select an image!";
      });
      return false;
    } else if (textControllerEventName.value.text.trim().isEmpty) {
      setState(() {
        errorText = "Please type in an event name!";
      });
      return false;
    } else if (!regExpEventName.hasMatch(textControllerEventName.value.text)) {
      setState(() {
        errorText =
            'Event name can only contain letters, digits and one whitespace between words!';
      });
      return false;
    } else if (eventLocation.name == 'Select Location') {
      setState(() {
        errorText = "Please select a location!";
      });
      return false;
    } else if (textControllerDescription.value.text.isEmpty) {
      setState(() {
        errorText = "Please type in a description!";
      });
      return false;
    } else if (categories.validateSelection() == false) {
      setState(() {
        errorText = "Please select at least one category!";
      });
      return false;
    }

    return true;
  }

  /// Validates the new start date time of its correctness
  void _validateAndFormatStartDate() {
    // check for logical times
    if (endDate.millisecondsSinceEpoch < startDate.millisecondsSinceEpoch) {
      endDate = startDate.add(const Duration(hours: 1));
    }

    _refreshTimeDateLabels();
  }

  /// Validates the new end date time of its correctness
  void _validateAndFormatEndDate() {
    // check for logical times
    if (endDate.millisecondsSinceEpoch < startDate.millisecondsSinceEpoch) {
      endDate = startDate.add(const Duration(hours: 1));
      _showAlertDialog(context);
    }

    _refreshTimeDateLabels();
  }

  /// Replaces the old text strings of the time with the new time values
  void _refreshTimeDateLabels() {
    // update text output
    setState(() {
      formattedStartTime =
          Formatter.getTimeFormatted(startDate.millisecondsSinceEpoch);
      formattedEndTime =
          Formatter.getTimeFormatted(endDate.millisecondsSinceEpoch);
    });
  }

  /// Decides if only one date is shown or a date range when selected a time period
  String? _showSelectedDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.day == endDate.day &&
        startDate.month == endDate.month &&
        startDate.year == endDate.year) {
      _validateAndFormatStartDate();
      return Formatter.getDateFormatted(
          startDate.millisecondsSinceEpoch, 'dd. MMMM yyyy');
    } else {
      return '${Formatter.getDateFormatted(startDate.millisecondsSinceEpoch, 'dd. MMMM yyyy')}  -  ${Formatter.getDateFormatted(endDate.millisecondsSinceEpoch, 'dd. MMMM yyyy')}';
    }
  }

  /// Opens an alert dialog which shows a hint
  Future<void> _showAlertDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invalid End Time'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'Please select an end time greater than or equal to the start time!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('I understand'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// Opens an alert dialog which shows a hint
  Future<void> _showStorageDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Storage permission is needed!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'Please turn on the storage permission in the phone settings!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Settings'),
              onPressed: () {
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Catch the callback data of the opened child "select categories page" with the users clicked interests
  void _awaitReturnValueFromSelectCategories(BuildContext context) async {
    final result = await Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 250),
          reverseDuration: const Duration(milliseconds: 250),
          child: SelectCategoryPage(inputCategories: categories),
          fullscreenDialog: true,
        ));

    // catch the selected categories
    setState(() {
      categories = result;
      selectedCategories.clear();
      selectedCategories.addAll(categories.toList());
    });
  }

  /// picks image from library and gives option to crop it
  Future pickImage() async {
    // Request storage permissions
    if (await Permission.storage.isPermanentlyDenied) {
      _showStorageDialog(context);
    } else {
      await Permission.storage.request();
    }

    try {
      // pick image from gallery
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemporary = File(image.path);
      Uint8List? callback;

      // show image cropper to crop to 4:3 format
      await showDialog<AlertDialog>(
          context: context,
          builder: (BuildContext context) {
            return CropDialog(imageTemporary.readAsBytesSync(), (value) {
              callback = value;
            });
          });

      setState(() {
        if (callback != null) {
          fileExtensionImage = path.extension(imageTemporary.path);
          this.image = callback;
        }
      });
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to pick image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Constants.backgroundColor,
        automaticallyImplyLeading: false,
        leading: IconButton(
          splashRadius: 25,
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () async {
            Navigator.pop(context, widget.event);
          },
        ),
        title: Text(
          widget.event == null ? 'Add Event' : 'Update Event',
          style: const MyTextStyle(cFontSize: Constants.pageHeadingFontSize),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      backgroundColor: Constants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
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
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                      color: Constants.backgroundColor,
                    ),
                    child: InkWell(
                      onTap: () async {
                        pickImage();
                      },
                      child: image != null
                          ? Image.memory(image!)
                          : widget.event != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.event!.image!,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(
                                    color: Constants.themeColor,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                )
                              : Image(
                                  image: Image.asset(
                                  'assets/images/no_photo_selected.png',
                                ).image),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(15, 16, 15, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 15),
                      child: TextFormField(
                        controller: textControllerEventName,
                        obscureText: false,
                        decoration: const CustomFormFieldInputDecoration(
                            hintText: 'Event Name'),
                        style: const MyTextStyle(
                            cColor: Colors.black,
                            cFontSize: Constants.flowingTextFontSize),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 15),
                      child: TextFormField(
                        controller: textControllerDescription,
                        obscureText: false,
                        decoration: const CustomFormFieldInputDecoration(
                            hintText: 'Description'),
                        style: const MyTextStyle(
                            cColor: Colors.black,
                            cFontSize: Constants.flowingTextFontSize),
                        textAlign: TextAlign.start,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 5),
                      child: TextButton(
                        onPressed: () {
                          _awaitReturnValueFromSelectCategories(context);
                        },
                        style: TextButton.styleFrom(
                          primary: Colors.white,
                          side: const BorderSide(
                              color: Constants.themeColor, width: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            selectedCategories.isEmpty
                                ? const Text("Select Categories")
                                : Expanded(
                                    child: SelectedCategoriesWidget(
                                        selectedCategories:
                                            selectedCategories)),
                            const Icon(Icons.chevron_right_rounded)
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CustomButton(
                            width: 100,
                            onPressed: () async {
                              if (appState.offlineMode == true ||
                                  appState.serverAlive == false) {
                                setState(() {
                                  errorText =
                                      'Location not settable because of offline mode!';
                                });
                                return;
                              }

                              // init your location and pass it to the map page
                              Place currentLocation = await initYourLocation();
                              var results = await Navigator.of(context).push(
                                  PageTransition(
                                      type: PageTransitionType.fade,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      reverseDuration:
                                          const Duration(milliseconds: 250),
                                      child: MapPage(
                                          key: null,
                                          initPlace: currentLocation)));
                              // if a location is selected, set eventLocation
                              if (results is Map) {
                                if (results.containsKey('place')) {
                                  setState(() {
                                    eventLocation = results['place'];
                                  });
                                }
                              }
                            },
                            text: 'Location',
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                10, 0, 0, 0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  eventLocation.address,
                                  style: const MyTextStyle(),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CustomButton(
                              width: 100,
                              text: 'Date',
                              onPressed: () async {
                                var datePicker = await showDateRangePicker(
                                  context: context,
                                  initialEntryMode:
                                      DatePickerEntryMode.calendarOnly,
                                  confirmText: "SELECT",
                                  currentDate: DateTime.now(),
                                  initialDateRange: DateTimeRange(
                                      start: startDate, end: endDate),
                                  firstDate: widget.event == null
                                      ? DateTime.now()
                                      : (startDate.millisecondsSinceEpoch <
                                              DateTime.now()
                                                  .millisecondsSinceEpoch
                                          ? startDate
                                          : DateTime.now()),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 730)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Constants.backgroundColor,
                                          // header background color
                                          onPrimary: Constants.themeColor,
                                          // header text color
                                          onSurface: Constants
                                              .themeColor, // body text color
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            primary: Constants
                                                .themeColor, // button text color
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (datePicker != null) {
                                  // Do further task
                                  setState(() {
                                    startDate = DateTime(
                                        datePicker.start.year,
                                        datePicker.start.month,
                                        datePicker.start.day,
                                        startDate.hour,
                                        startDate.minute);
                                    endDate = DateTime(
                                        datePicker.end.year,
                                        datePicker.end.month,
                                        datePicker.end.day,
                                        endDate.hour,
                                        endDate.minute);
                                  });
                                  _refreshTimeDateLabels();
                                }
                              }),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                10, 0, 0, 0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  _showSelectedDateRange(startDate, endDate)!,
                                  style: const MyTextStyle(),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CustomButton(
                            width: 100,
                            text: 'Start Time',
                            onPressed: () async {
                              final selectedTime = await showTimePicker(
                                context: context,
                                confirmText: "SELECT",
                                initialTime: widget.event == null
                                    ? TimeOfDay.now()
                                    : TimeOfDay(
                                        hour: startDate.hour,
                                        minute: startDate.minute),
                                builder: (BuildContext context, Widget? child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      textTheme: const TextTheme(
                                          caption:
                                              TextStyle(color: Colors.white)),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          primary: Constants
                                              .themeColor, // button text color
                                        ),
                                      ),
                                    ),
                                    child: MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                          alwaysUse24HourFormat: true),
                                      child: child!,
                                    ),
                                  );
                                },
                              );

                              if (selectedTime != null) {
                                // Do further task
                                setState(() {
                                  startDate = DateTime(
                                      startDate.year,
                                      startDate.month,
                                      startDate.day,
                                      selectedTime.hour,
                                      selectedTime.minute);
                                });
                                _validateAndFormatStartDate();
                              }
                            },
                          ),
                        ),
                        Text(
                          formattedStartTime,
                          style: const MyTextStyle(),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CustomButton(
                            width: 100,
                            text: 'End Time',
                            onPressed: () async {
                              final selectedTime = await showTimePicker(
                                context: context,
                                confirmText: "SELECT",
                                initialTime: widget.event == null
                                    ? TimeOfDay.now()
                                    : TimeOfDay(
                                        hour: endDate.hour,
                                        minute: endDate.minute),
                                builder: (BuildContext context, Widget? child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      textTheme: const TextTheme(
                                          caption:
                                              TextStyle(color: Colors.white)),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          primary: Constants
                                              .themeColor, // button text color
                                        ),
                                      ),
                                    ),
                                    child: MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                          alwaysUse24HourFormat: true),
                                      child: child!,
                                    ),
                                  );
                                },
                              );

                              if (selectedTime != null) {
                                // Do further task
                                setState(() {
                                  endDate = DateTime(
                                      endDate.year,
                                      endDate.month,
                                      endDate.day,
                                      selectedTime.hour,
                                      selectedTime.minute);
                                });
                                _validateAndFormatEndDate();
                              }
                            },
                          ),
                        ),
                        Text(
                          formattedEndTime,
                          style: const MyTextStyle(),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Container(
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(6.0)),
                                color: Constants.themeColor,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Text(
                                  "Maximum Views",
                                  style: MyTextStyle(),
                                ),
                              )),
                        ),
                        QuantityInput(
                          controller: quantityInputController,
                        ),
                      ],
                    ),
                    progressing
                        ? const Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                color: Constants.themeColor,
                              ),
                            ),
                          )
                        : Container(),
                    CustomButton(
                      text: widget.event == null ? 'Add Event' : 'Update Event',
                      width: MediaQuery.of(context).size.width,
                      onPressed: () async {
                        setState(() {
                          progressing = true;
                        });
                        try {
                          await _createEvent();
                        } finally {
                          setState(() {
                            progressing = false;
                          });
                        }
                      },
                    ),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 10, 0, 10),
                      child: Text(
                        errorText,
                        overflow: TextOverflow.visible,
                        style: const MyTextStyle(cColor: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
