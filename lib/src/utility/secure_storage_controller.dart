import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageCtrl {
  final _flutterSecStorage = const FlutterSecureStorage();

  Future<bool> containsKey(String key) async {
    return await _flutterSecStorage.containsKey(key: key);
  }

  Future writeSecureData(String key, String value) async {
    try {
      await _flutterSecStorage.write(key: key, value: value);
    } catch (e) {
      throw Exception("Error while adding value " +
          key +
          ": " +
          value +
          " to SecureStorage: " +
          e.toString());
    }
  }

  Future readSecureData(String key) async {
    try {
      var readData = await _flutterSecStorage.read(key: key);
      return readData;
    } catch (e) {
      if (kDebugMode) {
        print('Error while reading value ' +
            key +
            ' out of the persistent SecureStorage!');
      }
      return null;
    }
  }

  Future deleteSecureData(String key) async {
    if (await _flutterSecStorage.containsKey(key: key)) {
      var deleteData = await _flutterSecStorage.delete(key: key);
      return deleteData;
    }
  }
}
