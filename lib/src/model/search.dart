import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'place.dart';

class SearchModel extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<Place> _suggestions = [];

  List<Place> get suggestions => _suggestions;

  String _query = '';

  String get query => _query;

  List<Place> history = [];
  static const historyLength = 5;

  /// reload search query suggestions
  void onQueryChanged(String query) async {
    if (query == _query) return;

    _query = query;
    _isLoading = true;

    notifyListeners();

    if (query.isEmpty) {
      _suggestions = history;
    } else {
      // query suggestions from komoot (OpenStreetMap)
      final response =
          await http.get(Uri.parse('https://photon.komoot.io/api/?q=$query'));
      final body = json.decode(utf8.decode(response.bodyBytes));
      final features = body['features'] as List;
      List<Place> featuresList =
          features.map((e) => Place.fromJson(e)).toSet().toList();

      List<Place> historyFeatures = [];
      List<Place> nonHistoryFeatures = [];

      for (Place p in featuresList) {
        if (history.contains(p)) {
          historyFeatures.add(p);
        } else {
          nonHistoryFeatures.add(p);
        }
      }
      _suggestions = historyFeatures;
      _suggestions.addAll(nonHistoryFeatures);
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _suggestions = history;
    notifyListeners();
  }

  /// adds a place item to search history
  void addPlaceToHistory(Place place) {
    if (history.contains(place)) {
      putPlaceFirst(place);
      return;
    }
    history = history.reversed.toList();
    history.add(place);
    if (history.length > historyLength) {
      history.removeRange(0, history.length - historyLength);
    }
    history = history.reversed.toList();
  }

  /// put the latest searched item at first position in history
  void putPlaceFirst(Place place) {
    deletePlaceFromHistory(place);
    addPlaceToHistory(place);
  }

  void deletePlaceFromHistory(Place place) {
    history.removeWhere((p) => p == place);
  }
}
