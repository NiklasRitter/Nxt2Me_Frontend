import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/model/comment.dart';
import 'package:event_app/src/model/event.dart';
import 'package:event_app/src/pages/login_page.dart';
import 'package:event_app/src/utility/custom_exception.dart';
import 'package:event_app/src/utility/json_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

class Network {
  JsonUtility jsonUtility = JsonUtility();

  Future<void> checkRefreshToken(http.Response response) async {
    if (response.statusCode == 511) {
      await appState.secStorageCtrl.deleteSecureData(Constants.ACCESS_TOKEN);
      await appState.secStorageCtrl.deleteSecureData(Constants.REFRESH_TOKEN);
      await appState.secStorageCtrl
          .deleteSecureData(Constants.PUSH_NOTIFICATION_TOKEN);
      Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 250),
            reverseDuration: const Duration(milliseconds: 250),
            child: const LoginPage(),
            fullscreenDialog: true,
          ),
          (Route<dynamic> route) => false);
    }
  }

  Future<bool> checkTokenAvailability() async {
    bool tokensAvailable = false;

    var refreshToken =
        await appState.secStorageCtrl.readSecureData(Constants.REFRESH_TOKEN);
    var accessToken =
        await appState.secStorageCtrl.readSecureData(Constants.ACCESS_TOKEN);

    if (refreshToken != null && accessToken != null) {
      tokensAvailable = true;
    }
    return tokensAvailable;
  }

  /// This needs to be invoked with the response of every server request except createSession, registerUser and deleteSession
  Future<void> checkForNewAccessToken(http.Response res) async {
    String? newAccessToken;
    try {
      newAccessToken = res.headers['x-access-token'];
    } catch (e) {
      newAccessToken = null;
    }

    if (newAccessToken != null) {
      appState.secStorageCtrl
          .writeSecureData(Constants.ACCESS_TOKEN, newAccessToken);
    }
  }

  Future<void> offlineModeAutoLogin() async {
    try {
      bool tokensAvailable = await checkTokenAvailability();

      if (tokensAvailable) {
        http.Response userResponse = await network.getUser();

        await checkRefreshToken(userResponse);

        if (userResponse.statusCode == 200) {
          await appState.initUser(json.decode(userResponse.body));
          return;
        } else {
          return;
        }
      } else {
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return;
    }
  }

  Future<Map<String, String>> addRequiredHeaders(
      Map<String, String> headers) async {
    var refreshToken =
        await appState.secStorageCtrl.readSecureData(Constants.REFRESH_TOKEN);
    var accessToken =
        await appState.secStorageCtrl.readSecureData(Constants.ACCESS_TOKEN);

    if (refreshToken == null) {
      throw Exception("No refreshToken available");
    }

    if (accessToken == null) {
      throw Exception("No accessToken available");
    }

    headers.addAll(<String, String>{
      'x-refresh': refreshToken,
      'authorization': accessToken,
    });
    return headers;
  }

  //****************************************************************************
  //                              POST
  //****************************************************************************

  Future<http.Response> registerEmailUser(String email, String password,
      String passwordConfirmation, String name) async {
    http.Response res;

    try {
      res = await http
          .post(
        Uri.parse(Constants.SERVER_IP + '/api/users'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
          'passwordConfirmation': passwordConfirmation,
          'name': name,
          'authMethod': "email",
        }),
      )
          .timeout(
              const Duration(
                  seconds: Constants.SERVER_CONNECTION_TIMEOUT_SECONDS),
              onTimeout: () {
        throw TimeoutException('Timeout in registerEmailUser!');
      });

      await appState.secStorageCtrl
          .writeSecureData(Constants.LAST_EVENT_QUERY_TIMESTAMP, '0');

      if (res.statusCode == 200) {
        return res;
      } else if (res.statusCode == 400) {
        // broke specifications (e.g. no valid email, password)
        var jsonBody = json.decode(res.body);
        String errorMessage = jsonBody[0]['message'];
        throw CustomException(errorMessage);
      } else if (res.statusCode == 409) {
        // username or email already in use
        String errorMessage = res.body.toString();
        throw CustomException(errorMessage);
      } else {
        throw CustomException('Error in registerEmailUser');
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      rethrow;
    }
  }

  Future<http.Response> registerGoogleUser(String serverAuthCode) async {
    http.Response res;
    try {
      res = await http
          .post(
        Uri.parse(Constants.SERVER_IP + '/api/users/oauth/google'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'serverAuthCode': serverAuthCode,
        }),
      )
          .timeout(
              const Duration(
                  seconds: Constants.SERVER_CONNECTION_TIMEOUT_SECONDS),
              onTimeout: () {
        throw TimeoutException('Timeout in registerGoogleUser!');
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        var data = json.decode(res.body);
        await appState.secStorageCtrl
            .writeSecureData(Constants.LAST_EVENT_QUERY_TIMESTAMP, '0');

        await appState.secStorageCtrl
            .writeSecureData(Constants.ACCESS_TOKEN, data['accessToken']);

        await appState.secStorageCtrl
            .writeSecureData(Constants.REFRESH_TOKEN, data['refreshToken']);

        await appState.initUser(data['user']);
        return res;
      } else {
        String errorMessage = res.body.toString();
        throw CustomException(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      rethrow;
    }
  }

  Future<http.Response> forgotPassword(String email) async {
    try {
      var res = await http
          .post(
        Uri.parse(Constants.SERVER_IP + "/api/users/forgotPassword"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
        }),
      )
          .timeout(
              const Duration(
                  seconds: Constants.SERVER_CONNECTION_TIMEOUT_SECONDS),
              onTimeout: () {
        throw TimeoutException('Timeout in forgotPassword!');
      });

      return res;
    } catch (e) {
      if (kDebugMode) {
        print('Error in forgotPassword!');
      }
      rethrow;
    }
  }

  Future<http.Response> createSession(String email, String password) async {
    http.Response res;
    try {
      res = await http
          .post(
        Uri.parse(Constants.SERVER_IP + '/api/sessions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      )
          .timeout(
              const Duration(
                  seconds: Constants.SERVER_CONNECTION_TIMEOUT_SECONDS),
              onTimeout: () {
        throw TimeoutException('Timeout in create Session!');
      });

      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        await appState.secStorageCtrl
            .writeSecureData(Constants.LAST_EVENT_QUERY_TIMESTAMP, '0');
        await appState.secStorageCtrl
            .writeSecureData(Constants.ACCESS_TOKEN, data['accessToken']);
        await appState.secStorageCtrl
            .writeSecureData(Constants.REFRESH_TOKEN, data['refreshToken']);
        await appState.initUser(data['user']);
        return res;
      } else if (res.statusCode == 401) {
        throw CustomException(res.body);
      } else {
        throw CustomException('Error in createSession');
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      rethrow;
    }
  }

  Future<http.Response> createEvent(Event event) async {
    var res = await http.post(
      Uri.parse(Constants.SERVER_IP + '/api/events'),
      headers: await addRequiredHeaders(
        <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
      body: jsonUtility.encodeEvent(event),
    );
    await checkRefreshToken(res);
    return res;
  }

  Future<http.Response> reportEvent(String eventId) async {
    var res = await http.post(
        Uri.parse(Constants.SERVER_IP + "/api/events/" + eventId + "/report/"),
        headers: await addRequiredHeaders(
          <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ));
    await checkRefreshToken(res);
    await checkForNewAccessToken(res);
    return res;
  }

  Future<http.Response> createComment(String eventId, String author,
      int creationTimestamp, String commentText) async {
    var res = await http.post(
      Uri.parse(Constants.SERVER_IP + '/api/events/' + eventId + '/comments'),
      headers: await addRequiredHeaders(
        <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
      body: jsonUtility.encodeComment(
          eventId, author, creationTimestamp, commentText),
    );
    await checkRefreshToken(res);
    return res;
  }

  Future<http.Response> reportComment(String eventId, String commentId) async {
    var res = await http.post(
        Uri.parse(Constants.SERVER_IP +
            "/api/events/" +
            eventId +
            "/comments/" +
            commentId +
            "/report"),
        headers: await addRequiredHeaders(
          <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ));
    await checkRefreshToken(res);
    await checkForNewAccessToken(res);
    return res;
  }

  Future<http.Response> uploadImage(String extension, Uint8List image) async {
    var request = http.MultipartRequest(
        "POST", Uri.parse(Constants.SERVER_IP + "/api/image"));

    request.files.add(http.MultipartFile.fromBytes('upload', image,
        filename:
            DateTime.now().millisecondsSinceEpoch.toString() + extension));

    request.headers.addAll(await addRequiredHeaders(
      <String, String>{
        'Content-Type': 'multipart/form-data',
      },
    ));

    var resStream = await request.send();
    final res = await http.Response.fromStream(resStream);

    await checkRefreshToken(res);

    return res;
  }

  //****************************************************************************
  //                              GET
  //****************************************************************************

  Future<void> healthCheck() async {
    try {
      await http.get(Uri.parse(Constants.SERVER_IP + '/healthcheck')).then(
          (res) {
        if (res.statusCode == 200 && !appState.serverAlive) {
          appState.serverAlive = true;
        } else if (res.statusCode != 200 && appState.serverAlive) {
          appState.serverAlive = false;
        }
      }).timeout(
          const Duration(seconds: Constants.SERVER_CONNECTION_TIMEOUT_SECONDS),
          onTimeout: () {
        if (appState.serverAlive) {
          appState.serverAlive = false;
        }
        throw TimeoutException('Timeout in Health Check!');
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> getUser() async {
    try {
      var res = await http
          .get(Uri.parse(Constants.SERVER_IP + '/api/users'),
              headers: await addRequiredHeaders(
                <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                },
              ))
          .timeout(
              const Duration(
                  seconds: Constants.SERVER_CONNECTION_TIMEOUT_SECONDS),
              onTimeout: () {
        throw TimeoutException('Timeout in getUser!');
      });

      await checkRefreshToken(res);
      checkForNewAccessToken(res);

      return res;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUser');
      }
      rethrow;
    }
  }

  Future<http.Response> getEvent(String eventId) async {
    var res = await http.get(
        Uri.parse(Constants.SERVER_IP + '/api/events/' + eventId),
        headers: await addRequiredHeaders(
          <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ));

    checkForNewAccessToken(res);
    return res;
  }

  Future<List<Event>> getEventsSinceTimestamp(
      num longitude, num latitude, num radius, int milliSecSinceEpoch) async {
    var res = await http.get(
        Uri.parse(Constants.SERVER_IP +
            '/api/events/explore/' +
            longitude.toString() +
            '/' +
            latitude.toString() +
            '/' +
            radius.toString() +
            '/' +
            milliSecSinceEpoch.toString()),
        headers: await addRequiredHeaders(
          <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ));

    await checkRefreshToken(res);
    await checkForNewAccessToken(res);
    List<Event> events = jsonUtility.decodeEvents(res);
    return events;
  }

  Future<List<Event>> getMyEvents(
      int oldEventTimestamp, int latestEventTimestamp) async {
    var res = await http.get(
        Uri.parse(Constants.SERVER_IP +
            '/api/events/myEvents/' +
            oldEventTimestamp.toString() +
            '/' +
            latestEventTimestamp.toString()),
        headers: await addRequiredHeaders(
          <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ));

    await checkRefreshToken(res);
    checkForNewAccessToken(res);

    List<Event> events = jsonUtility.decodeEvents(res);
    return events;
  }

  Future<List<Event>> getFavEvents(
      int oldFavouriteTimestamp, int latestFavouriteTimestamp) async {
    var res = await http.get(
        Uri.parse(Constants.SERVER_IP +
            '/api/events/favEvents/' +
            oldFavouriteTimestamp.toString() +
            '/' +
            latestFavouriteTimestamp.toString()),
        headers: await addRequiredHeaders(
          <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ));

    await checkRefreshToken(res);
    checkForNewAccessToken(res);

    List<Event> events = jsonUtility.decodeEvents(res);
    return events;
  }

  Future<List<Comment>> getCommentsOfEvent(String eventId,
      int oldEventsTimestamp, int newEventsTimestamp, int maxComments) async {
    var res = await http.get(
        Uri.parse(Constants.SERVER_IP +
            '/api/events/' +
            eventId +
            '/comments/' +
            oldEventsTimestamp.toString() +
            '/' +
            newEventsTimestamp.toString() +
            '/' +
            maxComments.toString()),
        headers: await addRequiredHeaders(
          <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ));
    await checkRefreshToken(res);
    checkForNewAccessToken(res);

    List<Comment> comments = jsonUtility.decodeComments(res);
    return comments;
  }

  //****************************************************************************
  //                              PUT
  //****************************************************************************

  Future<http.Response> changeUsername(String newUsername) async {
    var res = await http.put(
      Uri.parse(Constants.SERVER_IP + '/api/users/changeUsername'),
      headers: await addRequiredHeaders(
        <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
      body: jsonEncode(<String, Object>{
        "newUsername": newUsername,
      }),
    );
    await checkRefreshToken(res);
    return res;
  }

  Future<http.Response> changePassword(String oldPassword, String newPassword,
      String passwordConfirmation) async {
    var res = await http.put(
      Uri.parse(Constants.SERVER_IP + '/api/users/credentials'),
      headers: await addRequiredHeaders(
        <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
      body: jsonUtility.encodeCredentials(
          oldPassword, newPassword, passwordConfirmation),
    );
    await checkRefreshToken(res);
    return res;
  }

  Future<http.Response> updateSubscribedCategories(
      List<String> subscribedCategories) async {
    var res = await http.put(
      Uri.parse(Constants.SERVER_IP + '/api/users/subscribedCategories'),
      headers: await addRequiredHeaders(
        <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
      body: jsonUtility.encodeSubscribedCategories(subscribedCategories),
    );

    await checkRefreshToken(res);
    return res;
  }

  Future<http.Response> updatePushNotificationToken(
      String pushNotificationToken) async {
    var res = await http.put(
      Uri.parse(Constants.SERVER_IP + '/api/users/pushNotificationToken'),
      headers: await addRequiredHeaders(
        <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
      body: jsonUtility.encodePushNotificationToken(pushNotificationToken),
    );
    await checkRefreshToken(res);
    return res;
  }

  Future<http.Response> updateEvent(Event event) async {
    var res = await http.put(
      Uri.parse(Constants.SERVER_IP + '/api/events/' + event.eventId),
      headers: await addRequiredHeaders(
        <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
      body: jsonUtility.encodeEvent(event),
    );
    await checkRefreshToken(res);
    return res;
  }

  Future<int> toggleFavoriteEvent(String eventId) async {
    try {
      var res = await http
          .put(
        Uri.parse(Constants.SERVER_IP + '/api/users/events/' + eventId),
        headers: await addRequiredHeaders(
          <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      )
          .timeout(
              const Duration(
                  seconds: Constants.SERVER_CONNECTION_TIMEOUT_SECONDS),
              onTimeout: () {
        throw TimeoutException('Timeout in toggleFavoriteEvent!');
      });
      await checkRefreshToken(res);
      if (res.statusCode != 200) {
        return -1;
      } else {
        return jsonDecode(res.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  //****************************************************************************
  //                              DELETE
  //****************************************************************************

  Future<http.Response> deleteUser() async {
    var res = await http.delete(Uri.parse(Constants.SERVER_IP + '/api/users'),
        headers: await addRequiredHeaders(
          <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ));

    await appState.secStorageCtrl.deleteSecureData(Constants.ACCESS_TOKEN);
    await appState.secStorageCtrl.deleteSecureData(Constants.REFRESH_TOKEN);
    await appState.secStorageCtrl
        .deleteSecureData(Constants.PUSH_NOTIFICATION_TOKEN);

    return res;
  }

  Future<bool> deleteSession() async {
    try {
      await http.delete(
        Uri.parse(Constants.SERVER_IP + '/api/sessions'),
        headers: await addRequiredHeaders(<String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        }),
      );

      await appState.secStorageCtrl
          .writeSecureData(Constants.LAST_EVENT_QUERY_TIMESTAMP, '0');
      await appState.secStorageCtrl.deleteSecureData(Constants.ACCESS_TOKEN);
      await appState.secStorageCtrl.deleteSecureData(Constants.REFRESH_TOKEN);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<http.Response> deleteEvent(Event event) async {
    var res = await http.delete(
      Uri.parse(Constants.SERVER_IP + '/api/events/' + event.eventId),
      headers: await addRequiredHeaders(<String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      }),
    );
    await checkRefreshToken(res);
    return res;
  }
}
