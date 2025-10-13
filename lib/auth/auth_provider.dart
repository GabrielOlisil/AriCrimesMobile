import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
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

  static const scopes = ['openid', 'email', 'profile'];

  String? _idToken;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _isAuthenticated;

  AuthUser? get user => _user;

  MyAuthProvider() {
    print('inicializando auth provider');
    if (isAuthenticated) {
      return;
    }

    if(!kIsWeb){
      signIn();
    }

    //será aqui
  }

  void initAuthState() {}

  Future<void> _handleWebAuthFlow() async {
    final uri = html.window.location.href;
    final urlParams = Uri.parse(uri).queryParameters;

    if (urlParams.containsKey('code')) {
      // 1. O Keycloak REDIRECIONOU de volta com o 'code' de autorização
      log("Código de autorização encontrado na URL. Trocando por tokens...");
      await _exchangeCodeForTokens(urlParams['code']!);
    } else if (urlParams.containsKey('error')) {
      // 2. Erro do Keycloak (ex: acesso negado)
      _errorMessage = 'Erro de autorização: ${urlParams['error']}';
      _resetAuth();
    } else {
      // 3. Nenhum código encontrado. Redirecionar para o Keycloak.
      log("Nenhum código encontrado. Redirecionando para o Keycloak...");
      await _redirectToKeycloakLogin();
    }
  }

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

      log("ACCESS TOKEN: ${result.accessToken}");
      log("ID TOKEN: ${result.idToken}");


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
