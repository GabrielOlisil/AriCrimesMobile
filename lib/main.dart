import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // NOVO: Garante que o Flutter está inicializado
  WidgetsFlutterBinding.ensureInitialized();
  // NOVO: Inicializa o Firebase antes de rodar o app
  await Firebase.initializeApp();
  runApp(MaterialApp(home: MapScreen(), debugShowCheckedModeBanner: false));
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

const List<String> scopes = <String>['openid'];

class _MapScreenState extends State<MapScreen> {
  User? _firebaseUser;
  GoogleSignInAccount? _googleUser;

  final _googlesignin = GoogleSignIn.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAuthorized = false;
  String _contactText = '';
  String _errorMessage = '';
  String _serverAuthCode = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeGoogleSignIn();

    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        print("AUTH STATE CHANGED");

        // Garante que o widget ainda está na tela
        setState(() {
          _firebaseUser = user;
        });
      }
    });
  }

  Future<void> _handleSignOut() async {
    // Disconnect instead of just signing out, to reset the example state as
    // much as possible.
    await _auth.signOut();
    await GoogleSignIn.instance.disconnect();
  }

  Future<void> _takesInformation() async {
    var token = await _firebaseUser?.getIdToken();

    print(token);

    final response = await http.get(Uri.parse('http://10.0.2.2:8000/users/me'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

      print(response.body);

  }

  Future<void> _handleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    print("EXECUTANDO AUTH EVENT");
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      _ => null,
    };

    var token = user?.authentication.idToken;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: token,
    );

    await _auth.signInWithCredential(credential);

    final GoogleSignInClientAuthorization? authorization = await user
        ?.authorizationClient
        .authorizationForScopes(scopes);

    setState(() {
      _googleUser = user;
      _isAuthorized = authorization != null;
      _errorMessage = '';
    });


    await _sendTokenToBackend();
  }

  void _initializeGoogleSignIn() {
    // Initialize and listen to authentication events

    unawaited(
      _googlesignin.initialize().then((_) {
        _googlesignin.authenticationEvents
            .listen(_handleAuthEvent)
            .onError(_handleError);
        _googlesignin.attemptLightweightAuthentication();
      }),
    );
  }

  Future<void> _sendTokenToBackend() async {
    // Certifique-se de que o _user não é nulo
    if (_firebaseUser == null) {
      print("Usuário não está logado.");
      return;
    }

    try {
      final idToken = await _firebaseUser!.getIdToken();


      if (idToken == null) {
        print("Erro: Não foi possível obter o ID Token.");
        return;
      }

      print("Google ID Token: $idToken");

      // 3. Envie o token para o seu backend FastAPI
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/auth/login'),
        // Use o endpoint correto
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          // Envie no cabeçalho Authorization
        },
      );

      if (response.statusCode == 200) {
        print("Token verificado com sucesso pelo backend!");
        print("Resposta do backend: ${response.body}");
        // Navegue para a tela principal, salve o token da SUA API, etc.
      } else {
        print("Falha na verificação do token.");
        print("Status code: ${response.statusCode}");
        print("Erro: ${response.body}");
      }
    } catch (error) {
      print("Ocorreu um erro ao enviar o token: $error");
    }
  }

  Future<void> _handleError(Object e) async {
    setState(() {
      _googleUser = null;
      _isAuthorized = false;
      _errorMessage = e is GoogleSignInException
          ? _errorMessageFromSignInException(e)
          : 'Unknown error: $e';
    });
  }

  Future<void> _signIn() async {
    try {
      // Check if platform supports authenticate
      if (_googlesignin.supportsAuthenticate()) {
        await _googlesignin.authenticate(scopeHint: ['email']);
      } else {
        // Handle web platform differently
        print('This platform requires platform-specific sign-in UI');
      }
    } catch (e) {
      print('Sign-in error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _firebaseUser != null
          ? _buildAuthenticatedBody(_firebaseUser!)
          : _buildUnauthenticatedBody(),
    );
  }

  Widget _buildAuthenticatedBody(User user) {
    const LatLng initialPosition = LatLng(-9.91375, -63.044);

    return Stack(
      children: [
        // O mapa ocupa toda a tela
        const GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14,
          ),
          zoomControlsEnabled:
              false, // Controles de zoom desabilitados para um visual mais limpo
        ),

        // NOVO: Card de informações do usuário na parte superior
        Positioned(
          top: 50.0,
          left: 15.0,
          right: 15.0,
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Foto de perfil do usuário
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(user.photoURL ?? ''),
                        onBackgroundImageError:
                            (_, __) {}, // Lida com caso de foto nula
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'Nome não disponível',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.email ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Ícone de logout
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        onPressed: _handleSignOut,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _takesInformation,
                      child: const Text('Verificar Token com Backend'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnauthenticatedBody() {
    return Container(
      // NOVO: Fundo com gradiente para um visual mais moderno.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.lightBlue.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // NOVO: Um ícone mais temático para o mapa
              const Icon(Icons.map_outlined, color: Colors.white, size: 100),
              const SizedBox(height: 24),
              const Text(
                'Bem-vindo ao App Mapa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10.0, color: Colors.black26)],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Faça login com sua conta Google para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _signIn,
                icon: Icon(Icons.person),
                // Adicione um logo do Google nos seus assets
                label: const Text('Entrar com Google'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue.shade800,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 5,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const LatLng _initialPosition = LatLng(
    -9.91375,
    -63.044,
  ); // Posição inicial (exemplo: São Francisco)

  String _errorMessageFromSignInException(GoogleSignInException e) {
    // In practice, an application should likely have specific handling for most
    // or all of the, but for simplicity this just handles cancel, and reports
    // the rest as generic errors.
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in canceled',
      _ => 'GoogleSignInException ${e.code}: ${e.description}',
    };
  }
}
