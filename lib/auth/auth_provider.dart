import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MyAuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  String _errorMessage = '';

  final List<String> scopes = <String>['openid'];

  final _googleSignIn = GoogleSignIn.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  get firebaseUser => _firebaseUser;

  get errorMessage => _errorMessage;

  void initAuthState() {
    _listenToAuthChanges();
    _firebaseUser = _auth.currentUser;

    print("aaaaaaa");
    unawaited(
      _googleSignIn.initialize().then((_) {
        _googleSignIn.authenticationEvents
            .listen(_handleAuthEvent)
            .onError(_handleError);
        if (_firebaseUser == null) {
          _googleSignIn.attemptLightweightAuthentication();
        }
      }),
    );
  }

  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      _errorMessage = '';
      notifyListeners();
    });
  }

  Future<void> _sighInWeb() async {
    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    googleProvider.addScope('openid');
    googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

    final userCred = await _auth.signInWithPopup(googleProvider);

    if (userCred.user == null) return;

    _firebaseUser = userCred.user;
    notifyListeners();
  }

  Future<void> signIn() async {
    try {
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.authenticate(scopeHint: scopes);
      } else {
        await _sighInWeb();
      }
    } catch (e) {
      await _googleSignIn.disconnect();
      print('Sign-in error: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
  }

  String _errorMessageFromSignInException(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in canceled',
      _ => 'GoogleSignInException ${e.code}: ${e.description}',
    };
  }

  void _handleError(Object e) {
    _errorMessage = e is GoogleSignInException
        ? _errorMessageFromSignInException(e)
        : 'Unknown error: $e';

    notifyListeners();
  }

  Future<void> _handleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    print('authEvent');

    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      _ => null,
    };

    if (event is GoogleSignInAuthenticationEventSignOut) {
      print('Evento de sign Out');
      await _auth.signOut();
      return;
    }

    final token = user!.authentication.idToken;

    final credential = GoogleAuthProvider.credential(idToken: token);

    await _auth.signInWithCredential(credential);
  }
}
