import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:o_auth2/models/user.dart';
import 'dart:convert';

class MyAuthProvider extends ChangeNotifier {
  String? _errorMessage;
  bool _isAuthenticated = false;

  AuthUser? _user;

  final appAuth = FlutterAppAuth();

  static const scopes = ['openid'];

  String? _idToken;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _isAuthenticated;

  AuthUser? get user => _user;

  MyAuthProvider() {
    print('inicializando auth provider');
    if (!isAuthenticated) {
      signIn();
    }
  }

  void initAuthState() {}

  Future<void> _sighInWeb() async {}

  Future<void> signIn() async {
    try {
      final AuthorizationTokenResponse
      result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          'flutter-app',
          'com.example.oauth2://auth',
          discoveryUrl:
              'https://kc.gabiruka.duckdns.org/realms/aricrimes/.well-known/openid-configuration',
          scopes: scopes,
        ),
      );

      var tokenRaw = result.idToken;

      if (tokenRaw != null) {
        var token = Jwt.parseJwt(tokenRaw);

        var name = token['name'];
        var preferredUsername = token['preferred_username'];
        var givenName = token['given_name'];
        var familyName = token['family_name'];
        var email = token['email'];
        var picture = token['picture'];

        _user = AuthUser.init(
          name,
          preferredUsername,
          givenName,
          familyName,
          email,
          picture,
        );
        _idToken = tokenRaw;
        _isAuthenticated = true;
        _errorMessage = null;

        notifyListeners();
      }
    } on FlutterAppAuthUserCancelledException catch (e) {
      _user = null;
      _idToken = null;
      _isAuthenticated = false;
      _errorMessage = 'user cancelou: $e';
      notifyListeners();
    }
  }

  Future<void> signOut() async {

    await appAuth.endSession(
      EndSessionRequest(
        idTokenHint: _idToken,
        postLogoutRedirectUrl: 'com.example.oauth2://logout',
        discoveryUrl: 'https://kc.gabiruka.duckdns.org/realms/aricrimes/.well-known/openid-configuration'
      ),
    );


    _user = null;
    _idToken = null;
    _isAuthenticated = false;
    notifyListeners();


  }
}
