import 'package:event_app/src/constants.dart';
import 'package:event_app/src/elements/custom_button.dart';
import 'package:event_app/src/model/place.dart';
import 'package:event_app/src/model/search.dart';
import 'package:event_app/src/utility/geofunctions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    required Key? key,
    required this.initPlace,
  }) : super(key: key);

  final Place initPlace;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _floatingSearchBarController = FloatingSearchBarController();
  String _selectedTerm = '';

  final GlobalKey<FloatingSearchBarState> _floatingSearchBarKey =
      GlobalKey<FloatingSearchBarState>();

  late final GoogleMapController _googleMapsController;
  Marker _eventMarker = const Marker(markerId: MarkerId('eventMarker'));

  late String _mapStyle;

  @override
  void initState() {
    super.initState();

    // load google map visual style out of the text file
    rootBundle.loadString('assets/gmap_style.txt').then((string) {
      _mapStyle = string;
    });
  }

  @override
  void dispose() {
    _floatingSearchBarController.dispose();
    _googleMapsController.dispose();
    super.dispose();
  }

  /// add a marker at given position
  void _addMarker(LatLng pos) {
    _eventMarker = const Marker(markerId: MarkerId('Loading'));

    /// get address etc. of the event
    GeoFunctions.getPositionPlace(pos).then((place) => {
          if (mounted)
            {
              setState(() {
                _eventMarker = Marker(
                  markerId: const MarkerId('eventMarker'),
                  position: LatLng(pos.latitude, pos.longitude),
                  infoWindow: InfoWindow(
                    title: place.name != '' ? place.name : place.level2Address,
                    snippet: place.name != '' ? place.level2Address : '',
                    onTap: () {},
                  ),
                );
                _selectedTerm = place.address;
              }),
            }
        });
  }

  /// gmaps create function
  void _onMapCreated(GoogleMapController _cntlr) {
    _googleMapsController = _cntlr;
    _googleMapsController.setMapStyle(_mapStyle);

    _googleMapsController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(widget.initPlace.lat, widget.initPlace.lng),
            zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: buildFloatingSearchBar(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Constants.themeColor,
          foregroundColor: Constants.iconColor,
          onPressed: () async {
            GeoFunctions.getGeoLocationPermissionAndPosition()
                .then((currentLocation) {
              if (mounted) {
                setState(() {
                  _googleMapsController.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                          target: LatLng(currentLocation.latitude,
                              currentLocation.longitude),
                          zoom: 15),
                    ),
                  );
                });
              }
            });
          },
          child: const Icon(Icons.my_location),
        ));
  }

  Widget buildFloatingSearchBar() {
    final actions = [
      FloatingSearchBarAction(
        showIfOpened: false,
        child: _selectedTerm.isNotEmpty
            ? CustomButton(
                onPressed: () async {
                  Place place = Place.getDummyPlace();
                  if (_eventMarker.infoWindow != InfoWindow.noText) {
                    place = await GeoFunctions.getPositionPlace(
                        _eventMarker.position);
                  }
                  Navigator.pop(context, {'place': place});
                },
                text: 'Select',
              )
            : Container(),
      ),
      // delete searchterm if X clicked
      FloatingSearchBarAction.searchToClear(
        showIfClosed: false,
      ),
    ];

    // whether screen is upright or horizontal
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Consumer<SearchModel>(
      builder: (context, model, _) => FloatingSearchBar(
        key: _floatingSearchBarKey,
        controller: _floatingSearchBarController,
        body: buildMap(),
        title: Text(
          _selectedTerm.isEmpty ? 'Search...' : _selectedTerm,
          style: const MyTextStyle(
              cColor: Constants.mainTextColorDark, cFontSize: 16),
        ),
        physics: const BouncingScrollPhysics(),
        transition: CircularFloatingSearchBarTransition(),
        actions: actions,
        builder: (context, _) => buildExpandableBody(model),
        onQueryChanged: model.onQueryChanged,
        progress: model.isLoading,
        // maximizes fsb when horizontal
        axisAlignment: isPortrait ? 0.0 : -1.0,
        openAxisAlignment: 0.0,
        debounceDelay: const Duration(milliseconds: 500),
        // padding of search results to fsb
        scrollPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget buildMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      markers: {
        _eventMarker,
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.initPlace.lat, widget.initPlace.lng),
        zoom: 15,
      ),
      gestureRecognizers: Set()
        ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
        ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()))
        ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
        ..add(Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer())),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      myLocationEnabled: true,
      onTap: _addMarker,
    );
  }

  /// builds the body for SearchResultItems
  Widget buildExpandableBody(SearchModel model) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ImplicitlyAnimatedList<Place>(
          shrinkWrap: true,
          // makes it possible to scroll through suggestions
          physics: const NeverScrollableScrollPhysics(),
          items: model.suggestions,
          insertDuration: const Duration(milliseconds: 700),
          itemBuilder: (context, animation, item, i) {
            return SizeFadeTransition(
              animation: animation,
              child: buildSearchResultItem(context, item),
            );
          },
          updateItemBuilder: (context, animation, item) {
            return FadeTransition(
              opacity: animation,
              child: buildSearchResultItem(
                  _floatingSearchBarKey.currentContext!, item),
            );
          },
          areItemsTheSame: (a, b) => a == b,
        ),
      ),
    );
  }

  Widget buildSearchResultItem(BuildContext context, Place place) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final model = Provider.of<SearchModel>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
            if (mounted) {
              setState(() {
                _googleMapsController.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                        target: LatLng(place.lat, place.lng), zoom: 15),
                  ),
                );
              });
            }

            _floatingSearchBarController.close();

            model.addPlaceToHistory(place);
            _addMarker(LatLng(place.lat, place.lng));
            setState(() {
              _selectedTerm = place.address;
            });

            Future.delayed(
              const Duration(milliseconds: 1500),
              () => model.clear(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: model.history.contains(place)
                        ? const Icon(Icons.history, key: Key('history'))
                        : const Icon(Icons.place, key: Key('place')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: textTheme.subtitle1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.level2Address,
                        style: textTheme.bodyText2
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (model.suggestions.isNotEmpty && place != model.suggestions.last)
          const Divider(height: 0),
      ],
    );
  }
}
