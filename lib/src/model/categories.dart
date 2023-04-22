import 'package:event_app/src/constants.dart';

class Categories {
  Map<String, bool> _categoriesMap = {};

  Categories() {
    _categoriesMap.addAll(Constants.DEFAULT_CATEGORIES);
  }

  /// To copy an interests object
  Categories copyFromExistingCategories(Categories src) {
    for (String key in src.categoriesMap.keys) {
      if (_categoriesMap.containsKey(key)) {
        _categoriesMap[key] = src.categoriesMap[key] as bool;
      }
    }

    return this;
  }

  /// Generate new category object with categories from parameter list
  Categories withStartParameters(List categories) {
    // reset all cat´s
    for (String key in _categoriesMap.keys) {
      _categoriesMap[key] = false;
    }

    // set the flags in order to the list
    for (String key in categories) {
      if (_categoriesMap.containsKey(key)) {
        _categoriesMap[key] = true;
      }
    }
    return this;
  }

  /// Checks if at least one cat is selected
  bool validateSelection() {
    for (bool value in _categoriesMap.values) {
      if (value) {
        return true;
      }
    }
    return false;
  }

  /// Returns the selected categories as a list
  List<String> toList() {
    List<String> result = [];

    for (String category in categoriesMap.keys) {
      if (categoriesMap[category]!) {
        result.add(category);
      }
    }

    return result;
  }

  Map<String, bool> get categoriesMap => _categoriesMap;

  set categoriesMap(Map<String, bool> value) {
    _categoriesMap = value;
  }

  @override
  String toString() {
    String result = "";
    for (var category in categoriesMap.keys) {
      if (categoriesMap[category]!) {
        result = result + category + " ";
      }
    }
    return result;
  }
}
