import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MyAuthProvider extends ChangeNotifier {
  GoogleSignInAccount? _googleUser;
  User? _firebaseUser;
  bool _isAuthorized = false;
  String _errorMessage = '';

  final List<String> scopes = <String>['openid'];

  final _googleSignIn = GoogleSignIn.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  get googleUser => _googleUser;

  get firebaseUser => _firebaseUser;

  get isAuthorized => _isAuthorized;

  get errorMessage => _errorMessage;

  Future<void> initAuthState() async {
    await _googleSignIn.initialize();

    _googleSignIn.authenticationEvents
        .listen(_handleAuthEvent)
        .onError(_handleError);
  }

  Future<void> signIn() async {
    try {
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.authenticate(scopeHint: scopes);
      } else {
        // Handle web platform differently
        print('This platform requires platform-specific sign-in UI');
      }
    } catch (e) {
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
    _googleUser = null;
    _firebaseUser = null;
    _isAuthorized = false;
    _errorMessage = e is GoogleSignInException
        ? _errorMessageFromSignInException(e)
        : 'Unknown error: $e';

    notifyListeners();
  }

  Future<void> _handleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      _ => null,
    };

    if (user == null) {
      if (event is GoogleSignInAuthenticationEventSignOut) {
        print('Evento de sign Out');
        await _auth.signOut();
        _googleUser = null;
        _firebaseUser = null;
        _isAuthorized = false;
        _errorMessage = '';
        notifyListeners();
      }

      return;
    }

    final token = user.authentication.idToken;

    final credential = GoogleAuthProvider.credential(idToken: token);

    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user == null) {
      print('user credential is null');
      return;
    }

    _googleUser = user;
    _firebaseUser = userCredential.user;
    _isAuthorized = _firebaseUser != null;
    _errorMessage = '';

    print('chegou até aqui');

    notifyListeners();

    // await _sendTokenToBackend();
  }
}
