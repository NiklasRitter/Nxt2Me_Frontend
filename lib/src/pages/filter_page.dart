import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/elements/selected_categories_widget.dart';
import 'package:event_app/src/model/categories.dart';
import 'package:event_app/src/pages/select_categories_page.dart';
import 'package:event_app/src/utility/formatter.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({Key? key}) : super(key: key);

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late DateTimeRange calendarSelectedDay;
  double sliderValue = appState.user.exploreRadius;
  DateTime startSearchDate = appState.user.exploreStartDateTime;
  DateTime endSearchDate = appState.user.exploreEndDateTime;
  bool showOwnEvents = appState.shownOwnEventsOnExplorePage;
  Categories categories =
      Categories().copyFromExistingCategories(appState.user.categories);
  List<String> selectedCategories = [];
  String errorText = "";

  @override
  void initState() {
    super.initState();
    selectedCategories.addAll(categories.toList());
  }

  /// write new preferences to sqlite db
  void applyFilter() async {
    if (categories.toList().isEmpty) {
      if (mounted) {
        setState(() {
          errorText = "Please select at least one categorie";
        });
      }
      return;
    }

    appState.user.exploreRadius = sliderValue;
    appState.user.exploreStartDateTime = startSearchDate;
    appState.user.exploreEndDateTime = endSearchDate;
    appState.user.categories.copyFromExistingCategories(categories);
    appState.shownOwnEventsOnExplorePage = showOwnEvents;

    // update user profile in sqlite db
    await appState.sqliteDbUsers.updateUser(appState.user);

    Navigator.pop(context);
  }

  /// Catch the callback data of the opened child "filter categories page" with the users clicked categories
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

    categories = result;
    // catch the selected categories
    if (mounted) {
      setState(() {
        selectedCategories.clear();
        selectedCategories.addAll(categories.toList());
      });
    }
  }

  /// Decides if only one date is shown or a date range when selected a time period
  String _showDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.day == endDate.day &&
        startDate.month == endDate.month &&
        startDate.year == endDate.year) {
      return Formatter.getDateFormatted(
          startDate.millisecondsSinceEpoch, 'dd. MMMM yyyy');
    } else {
      return '${Formatter.getDateFormatted(startDate.millisecondsSinceEpoch, 'dd. MMMM yyyy')}  -  ${Formatter.getDateFormatted(endDate.millisecondsSinceEpoch, 'dd. MMMM yyyy')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Search Filter',
          style: MyTextStyle(cFontSize: Constants.pageHeadingFontSize),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Constants.backgroundColor,
        leading: IconButton(
          splashRadius: 25,
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () async {
            Navigator.pop(context);
          },
        ),
        centerTitle: false,
        elevation: 0,
      ),
      backgroundColor: Constants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: const [
                    Text(
                      'Distance',
                      style: MyTextStyle(),
                    )
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Slider(
                        activeColor: Constants.themeColor,
                        inactiveColor: Constants.backgroundColorSecondary,
                        min: Constants.DEFAULT_MIN_QUERY_DISTANCE,
                        max: Constants.DEFAULT_MAX_QUERY_DISTANCE,
                        value: sliderValue,
                        onChanged: (newValue) {
                          setState(() => sliderValue = newValue);
                        },
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          (sliderValue ~/ 1000).toInt().toString() + " km",
                          style: const MyTextStyle(),
                        )
                      ],
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
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
                                    selectedCategories: selectedCategories)),
                        const Icon(Icons.chevron_right_rounded)
                      ],
                    ),
                  ),
                ),
                CustomButton(
                    width: MediaQuery.of(context).size.width,
                    text: _showDateRange(startSearchDate, endSearchDate),
                    buttonTextStyle: const MyTextStyle(
                      cFontSize: 16,
                    ),
                    onPressed: () async {
                      var dateRangePicker = await showDateRangePicker(
                        context: context,
                        currentDate: DateTime.now(),
                        initialDateRange: DateTimeRange(
                            start: startSearchDate, end: endSearchDate),
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 60)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                        saveText: "Select",
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Constants.backgroundColor,
                                // header background color
                                onPrimary: Constants.themeColor,
                                // header text color
                                onSurface:
                                    Constants.themeColor, // body text color
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  primary:
                                      Constants.themeColor, // button text color
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (dateRangePicker != null) {
                        // Do further task
                        if (mounted) {
                          setState(() {
                            startSearchDate = dateRangePicker.start;
                            endSearchDate = dateRangePicker.end;
                          });
                        }
                      }
                    }),
                SwitchListTile.adaptive(
                  value: showOwnEvents,
                  onChanged: (newValue) => {
                    showOwnEvents = newValue,
                    if (mounted)
                      {
                        setState(() {
                          showOwnEvents = newValue;
                        })
                      },
                  },
                  title: const Text(
                    "Show own Events",
                    style: MyTextStyle(
                      cFontSize: 14,
                    ),
                  ),
                  activeColor: Colors.white,
                  activeTrackColor: Constants.themeColor,
                  dense: false,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding:
                      const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 0, 24),
                  child: CustomButton(
                    width: MediaQuery.of(context).size.width,
                    onPressed: applyFilter,
                    text: 'Apply Filter',
                    color: Constants.themeColor,
                    buttonTextStyle: const MyTextStyle(
                      cFontSize: 16,
                    ),
                    elevation: 2,
                  ),
                ),
                Text(
                  errorText,
                  style: MyTextStyle(cColor: Colors.red),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
