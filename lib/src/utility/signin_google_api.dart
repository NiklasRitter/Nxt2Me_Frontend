import 'package:google_sign_in/google_sign_in.dart';

class SignInGoogleApi {
  static final _signInGoogle = GoogleSignIn(
      clientId:
          "103995926772-v6vasdtsgu0j8rsst9adjkg0nuoq7l7e.apps.googleusercontent.com",
      scopes: <String>[
        "https://www.googleapis.com/auth/userinfo.profile",
        "https://www.googleapis.com/auth/userinfo.email",
      ]);

  static Future<GoogleSignInAccount?> login() {
    return _signInGoogle.signIn();
  }

  static Future<GoogleSignInAccount?> logout() {
    return _signInGoogle.disconnect();
  }
}
