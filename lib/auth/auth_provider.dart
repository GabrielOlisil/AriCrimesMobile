import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:o_auth2/models/user.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

// =========================================================================
// FUNÇÕES AUXILIARES PKCE
// =========================================================================

// Chave usada no localStorage do navegador
const String _kCodeVerifierKey = 'pkce_code_verifier';
const String _kAccessTokenKey = 'auth_access_token';
const String _kIdTokenKey = 'auth_id_token';
const String _kRefreshTokenKey = 'auth_refresh_token';

// Gera uma string aleatória (code verifier)
String _generateCodeVerifier() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  // Codifica em Base64 Url-Safe e remove padding
  return base64UrlEncode(bytes).replaceAll('=', '');
}

// Gera o hash SHA256 do verifier (code challenge)
String _generateCodeChallenge(String codeVerifier) {
  final bytes = utf8.encode(codeVerifier);
  final sha256Hash = sha256.convert(bytes);
  return base64UrlEncode(sha256Hash.bytes).replaceAll('=', '');
}

class MyAuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _refreshToken;
  AuthUser? _user;

  final _appAuth = FlutterAppAuth();

  final _discoveryUrl =
      'https://kc.gabiruka.duckdns.org/realms/aricrimes/.well-known/openid-configuration';

  final _redirectUriWeb = kIsWeb
      ? html.window.location.origin
      : 'com.example.oauth2://auth';

  static const _scopes = ['openid', 'email', 'profile'];
  static const _clientId = 'flutter-app';

  String? _idToken;
  String? _codeVerifier;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _isAuthenticated;

  String? get accessToken => _accessToken;

  AuthUser? get user => _user;

  MyAuthProvider() {
    if (kIsWeb) {
      tryLoadFromLocalStorage();
    }
  }

  void tryLoadFromLocalStorage() async {
    try {
      _codeVerifier = html.window.localStorage[_kCodeVerifierKey];
      final storedAccess = html.window.localStorage[_kAccessTokenKey];
      final storedRefresh = html.window.localStorage[_kRefreshTokenKey];
      final storedId = html.window.localStorage[_kIdTokenKey];

      if (storedAccess == null || storedRefresh == null || storedId == null) {
        await _handleWebAuthFlow();
        return;
      }

      _processToken(storedId, storedAccess, storedRefresh);
    } catch (e, stack) {
      _errorMessage = "Erro ao iniciar: $e";
      _resetAuth();
    }
  }

  // =========================================================================
  // FLUXO DE AUTENTICAÇÃO WEB (PKCE)
  // =========================================================================

  Future<void> _handleWebAuthFlow() async {
    try {
      final uri = html.window.location.href;
      final urlParams = Uri.parse(uri).queryParameters;

      if (urlParams.containsKey('code')) {
        print(
          "Código de autorização encontrado na URL. Trocando por tokens...",
        );
        await _exchangeCodeForTokens(urlParams['code']!);
      } else if (urlParams.containsKey('error')) {
        _errorMessage = 'Erro de autorização: ${urlParams['error']}';
        _resetAuth();
      }
    } catch (e, stack) {
      log(
        'ERRO CRÍTICO no _handleWebAuthFlow: $e',
        error: e,
        stackTrace: stack,
      );
      _errorMessage = 'Falha crítica ao iniciar o login: $e';
      _resetAuth();
    }
  }

  Future<void> signIn() async {
    if (!kIsWeb) {
      _signInMobile();
      return;
    }
    await _redirectToKeycloakLogin();
  }

  Future<void> _redirectToKeycloakLogin() async {
    try {
      // 1. Gerar NOVO PKCE e SALVAR no localStorage
      _codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(_codeVerifier!);
      html.window.localStorage[_kCodeVerifierKey] = _codeVerifier!;
      print("PKCE gerado e SALVO. Verifier: $_codeVerifier");

      // 2. Buscar URLs de autorização
      print("Buscando configuração OIDC...");
      final config = await _fetchOidcConfig();
      final authorizationEndpoint = config['authorization_endpoint'];
      print("Endpoint de autorização encontrado: $authorizationEndpoint");

      // 3. Construir e redirecionar
      final loginUri = Uri.parse(authorizationEndpoint).replace(
        queryParameters: {
          'client_id': _clientId,
          'redirect_uri': _redirectUriWeb,
          'response_type': 'code',
          'scope': _scopes.join(' '),
          // PKCE
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
        },
      );

      print("Redirecionando para: ${loginUri.toString()}");
      // Redireciona o navegador para o Keycloak
      html.window.location.href = loginUri.toString();
    } catch (e, stack) {
      log(
        'ERRO FATAL no redirecionamento Keycloak: $e',
        error: e,
        stackTrace: stack,
      );
      _errorMessage =
          'Não foi possível se conectar ao servidor Keycloak. Verifique a URL: $e';
      _resetAuth();
    }
  }

  Future<void> _exchangeCodeForTokens(String code) async {
    // A variável _codeVerifier agora deve ter sido carregada do localStorage
    if (_codeVerifier == null) {
      // Se não houver verifier, o fluxo é inseguro/quebrado
      _errorMessage =
          'Erro de segurança: Code Verifier NÃO PODE SER CARREGADO.';
      _resetAuth();
      return;
    }

    try {
      final config = await _fetchOidcConfig();
      final tokenEndpoint = config['token_endpoint'];

      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'redirect_uri': _redirectUriWeb,
          'code': code,
          'code_verifier': _codeVerifier!,
        },
      );

      final Map<String, dynamic> tokenData = json.decode(response.body);

      if (response.statusCode == 200 &&
          tokenData.containsKey('id_token') &&
          tokenData.containsKey('access_token') &&
          tokenData.containsKey('refresh_token')) {
        _processToken(
          tokenData['id_token'],
          tokenData['access_token'],
          tokenData['refresh_token'],
        );

        // LIMPEZA: Remove o verifier após o uso bem-sucedido
        html.window.localStorage.remove(_kCodeVerifierKey);
        _codeVerifier = null;

        // Limpa os parâmetros de code/state da URL
        html.window.history.replaceState(null, '', html.window.location.origin);
      } else {
        throw Exception(
          'Falha na troca de código: ${tokenData['error_description'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      log('ERRO na troca de código: $e'); // Adicionado log de erro
      _errorMessage = 'Erro ao trocar código por tokens: $e';
      _resetAuth();
    }
  }

  // =========================================================================
  // FLUXO DE AUTENTICAÇÃO MOBILE (AppAuth)
  // =========================================================================

  Future<void> _signInMobile() async {
    print('Executando fluxo de autenticação Mobile/Desktop...');
    try {
      final AuthorizationTokenResponse result = await _appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              _clientId,
              'com.example.oauth2://auth', // URI de redirecionamento Mobile
              discoveryUrl: _discoveryUrl,
              scopes: _scopes,
            ),
          );

      if (result.idToken == null) {
        throw Exception("Falha ao obter tokens.");
      }

      _processToken(result.idToken!, result.accessToken!, result.refreshToken);
    } on FlutterAppAuthUserCancelledException {
      _errorMessage = 'Usuário cancelou a autenticação.';
      _resetAuth();
    } catch (e) {
      _errorMessage = 'Erro de autenticação: $e';
      _resetAuth();
    }
  }

  // =========================================================================
  // LÓGICA COMPARTILHADA
  // =========================================================================

  Future<Map<String, dynamic>> _fetchOidcConfig() async {
    final response = await http.get(Uri.parse(_discoveryUrl));
    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível obter a configuração OIDC do Keycloak. Status: ${response.statusCode}',
      );
    }
    return json.decode(response.body);
  }

  void _processToken(String tokenRaw, String access, String? refresh) {
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

    _refreshToken = refresh;
    _idToken = tokenRaw;
    _isAuthenticated = true;
    _errorMessage = null;
    _accessToken = access;

    if (kIsWeb) {
      html.window.localStorage[_kIdTokenKey] = _idToken!;
      html.window.localStorage[_kAccessTokenKey] = _accessToken!;
      html.window.localStorage[_kRefreshTokenKey] = _refreshToken!;
    }

    _realizeRegister(access);

    notifyListeners();
  }

  Future<void> _realizeRegister(String token) async {
    final url = Uri.parse('https://aricrimes-api.gabiruka.duckdns.org/auth/login');

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        _errorMessage = "Erro no login";
      }
    } catch (e) {
      print('Erro na requisição: $e');
      _errorMessage = "Erro na requisição: $e";
    }
  }

  Future<bool> refreshToken() async {


    if (_refreshToken == null) {
      log('Não há refresh token disponível. Forçando logout.');
      _resetAuth();
      return false;
    }

    try {
      log('Tentando atualizar token usando o refresh token...');
      final config = await _fetchOidcConfig();
      final tokenEndpoint = config['token_endpoint'];

      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': _clientId,
          'refresh_token': _refreshToken!,
          // 'scope': scopes.join(' '), // Alguns provedores exigem o escopo, verifique o Keycloak
        },
      );

      final Map<String, dynamic> tokenData = json.decode(response.body);

      if (response.statusCode == 200) {
        log('Token atualizado com sucesso.');
        // Re-processa e salva os novos tokens
        _processToken(
          tokenData['id_token'],
          tokenData['access_token'],
          tokenData['refresh_token'],
        );
        return true;
      } else {
        // Ex: "invalid_grant" - o refresh token expirou ou foi revogado
        log(
          'Falha ao atualizar o token: ${tokenData['error_description'] ?? 'Erro desconhecido'}',
        );
        // O refresh token é inválido. Desloga o usuário.
        await signOut();
        return false;
      }
    } catch (e) {
      log('Erro crítico durante o refresh token: $e. Deslogando.');
      await signOut();
      return false;
    }
  }

  void _resetAuth() {
    _user = null;
    _idToken = null;
    _isAuthenticated = false;
    _accessToken = null;
    _refreshToken = null;
    if (kIsWeb) {
      html.window.localStorage.remove(_kCodeVerifierKey);
      html.window.localStorage.remove(_kRefreshTokenKey);
      html.window.localStorage.remove(_kAccessTokenKey);
      html.window.localStorage.remove(_kIdTokenKey);

    }
    _codeVerifier = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    final tokenToHint = _idToken;

    _resetAuth();

    if (tokenToHint == null) {
      return;
    }

    if (!kIsWeb) {
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: _idToken,
          postLogoutRedirectUrl: 'com.example.oauth2://logout',
          discoveryUrl: _discoveryUrl,
        ),
      );
      return;
    }

    try {
      final config = await _fetchOidcConfig();
      final endSessionEndpoint = config['end_session_endpoint'];

      final logoutUri = Uri.parse(endSessionEndpoint).replace(
        queryParameters: {
          'id_token_hint': tokenToHint,
          'post_logout_redirect_uri': _redirectUriWeb,
          // Redireciona para a URL base do app
        },
      );

      log("Redirecionando para Logout Web: ${logoutUri.toString()}");
      // Isso fará o navegador sair do seu aplicativo Flutter
      html.window.location.href = logoutUri.toString();
    } catch (e) {
      log(
        'Erro ao fazer logout via Web Redirect (a sessão local foi limpa): $e',
      );
    }
  }
}
