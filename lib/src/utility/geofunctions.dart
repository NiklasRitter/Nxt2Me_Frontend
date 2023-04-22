import 'dart:convert';
import 'package:event_app/main.dart';
import 'package:event_app/src/model/place.dart';
import 'package:geolocator/geolocator.dart' as geoloc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GeoFunctions {
  static double getDistanceBetween2Coordinates(
      double lat1, double lng1, double lat2, double lng2) {
    return geoloc.Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  static Future<geoloc.Position> getGeoLocationPermissionAndPosition() async {
    await getGeoLocationPermission();
    return getGeoLocationPosition();
  }

  static Future<bool> getGeoLocationPermission() async {
    bool serviceEnabled;
    geoloc.LocationPermission permission;

    serviceEnabled = await geoloc.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await geoloc.Geolocator.openLocationSettings();
      Future.error('Location services are disabled.');
      return false;
    }
    permission = await geoloc.Geolocator.checkPermission();
    if (permission == geoloc.LocationPermission.denied) {
      permission = await geoloc.Geolocator.requestPermission();
      if (permission == geoloc.LocationPermission.denied) {
        Future.error('Location permissions are denied');
        return false;
      }
    }
    if (permission == geoloc.LocationPermission.deniedForever) {
      Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }

    return true;
  }

  /// gets the current position - !Use getGeoLocationPermissionAndPosition
  static Future<geoloc.Position> getGeoLocationPosition() async {
    return await geoloc.Geolocator.getCurrentPosition(
        desiredAccuracy: geoloc.LocationAccuracy.high);
  }

  /// get the Place of the given LatLng position
  static Future<Place> getPositionPlace(LatLng pos) async {
    double lat = pos.latitude;
    double lon = pos.longitude;

    if (appState.offlineMode == true || appState.serverAlive == false) {
      return Place(
          city: '',
          street: '',
          housenumber: '',
          name: '',
          state: '',
          country: '',
          type: '',
          lat: pos.latitude,
          lng: pos.longitude);
    }

    final response = await http
        .get(Uri.parse('https://photon.komoot.io/reverse?lon=$lon&lat=$lat'));
    final body = json.decode(utf8.decode(response.bodyBytes));
    final features = body['features'] as List;
    List<Place> _positions =
        features.map((e) => Place.fromJson(e)).toSet().toList();

    String name = '';
    String state = '';
    String country = '';
    String city = '';
    String street = '';
    String housenumber = '';
    String type = '';

    if (_positions.isNotEmpty) {
      try {
        name = _positions[0].name;
      } catch (e) {
        name = "No specific place";
      }
      state = _positions[0].state;
      country = _positions[0].country;
      city = _positions[0].city;
      street = _positions[0].street;
      housenumber = _positions[0].housenumber;
      type = _positions[0].type;
    }

    Place place = Place(
        city: city,
        street: street,
        housenumber: housenumber,
        name: name,
        state: state,
        country: country,
        type: type,
        lat: pos.latitude,
        lng: pos.longitude);

    return place;
  }
}
