import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  AuthUser? _user;

  final appAuth = FlutterAppAuth();
  final discoveryUrl =
      'https://kc.gabiruka.duckdns.org/realms/aricrimes/.well-known/openid-configuration';

  // No Web, usamos a URL base atual como URI de redirecionamento
  final redirectUriWeb = kIsWeb
      ? html.window.location.origin
      : 'com.example.oauth2://auth';

  static const scopes = ['openid', 'email', 'profile'];
  static const clientId = 'flutter-app';

  String? _idToken;
  String?
  _codeVerifier; // Armazena o verifier (carregado do localStorage na Web)

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _isAuthenticated;

  String? get accessToken => _accessToken;


  AuthUser? get user => _user;

  MyAuthProvider() {
    print('Inicializando Auth Provider. kIsWeb: $kIsWeb');
    if (_isAuthenticated) return;

    // 1. CARREGA O CODE VERIFIER (SÓ NA WEB)
    if (kIsWeb) {
      _codeVerifier = html.window.localStorage[_kCodeVerifierKey];
      print(
        'PKCE Verifier carregado do storage: ${_codeVerifier != null ? "Sim" : "Não"}',
      );
      _handleWebAuthFlow();
    } else {
      _signInMobile();
    }
  }

  // =========================================================================
  // FLUXO DE AUTENTICAÇÃO WEB (PKCE)
  // =========================================================================

  Future<void> _handleWebAuthFlow() async {
    print("web auth flow");
    try {
      final uri = html.window.location.href;
      final urlParams = Uri.parse(uri).queryParameters;

      if (urlParams.containsKey('code')) {
        print(
          "Código de autorização encontrado na URL. Trocando por tokens...",
        );
        await _exchangeCodeForTokens(urlParams['code']!);
      } else if (urlParams.containsKey('error')) {
        // 2. Erro do Keycloak (ex: usuário negou)
        _errorMessage = 'Erro de autorização: ${urlParams['error']}';
        _resetAuth();
      } else {
        // 3. Nenhum código encontrado. Redirecionar para o Keycloak.
        print("Nenhum código encontrado. Redirecionando para o Keycloak...");
        await _redirectToKeycloakLogin();
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
    _handleWebAuthFlow();
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
          'client_id': clientId,
          'redirect_uri': redirectUriWeb,
          'response_type': 'code',
          'scope': scopes.join(' '),
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
          'Erro de segurança: Code Verifier NÃO PODE SER CARREGADO. O fluxo PKCE falhou.';
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
          'client_id': clientId,
          'redirect_uri': redirectUriWeb,
          'code': code,
          'code_verifier': _codeVerifier!,
        },
      );

      final Map<String, dynamic> tokenData = json.decode(response.body);

      if (response.statusCode == 200 &&
          tokenData.containsKey('id_token') &&
          tokenData.containsKey('access_token'))
      {

        _processToken(tokenData['id_token'], tokenData['access_token']);

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
      print('ERRO na troca de código: $e'); // Adicionado log de erro
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
      final AuthorizationTokenResponse? result = await appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              clientId,
              'com.example.oauth2://auth', // URI de redirecionamento Mobile
              discoveryUrl: discoveryUrl,
              scopes: scopes,
            ),
          );

      if (result == null || result.idToken == null) {
        throw Exception("Falha ao obter tokens.");
      }

      _processToken(result.idToken!, result.accessToken!);
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
    final response = await http.get(Uri.parse(discoveryUrl));
    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível obter a configuração OIDC do Keycloak. Status: ${response.statusCode}',
      );
    }
    return json.decode(response.body);
  }

  void _processToken(String tokenRaw, String access) {
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
    _accessToken = access;
    print('access token: $access');
    log('access token: $access');

    notifyListeners();
  }

  void _resetAuth() {
    _user = null;
    _idToken = null;
    _isAuthenticated = false;
    _accessToken = null;
    if (kIsWeb) {
      html.window.localStorage.remove(_kCodeVerifierKey);
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
      await appAuth.endSession(
        EndSessionRequest(
          idTokenHint: _idToken,
          postLogoutRedirectUrl: 'com.example.oauth2://logout',
          discoveryUrl: discoveryUrl,
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
          'post_logout_redirect_uri': redirectUriWeb,
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
