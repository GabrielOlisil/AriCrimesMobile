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

  get firebaseUser => _firebaseUser;

  get isAuthorized => _isAuthorized;

  get errorMessage => _errorMessage;

 void initAuthState()  {
    unawaited(
      _googleSignIn.initialize().then((_) {
        _googleSignIn.authenticationEvents
            .listen(_handleAuthEvent)
            .onError(_handleError);

        _googleSignIn.attemptLightweightAuthentication();
      }),
    );
  }


  Future<void> _sighInWeb() async{
    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    googleProvider.addScope('openid');
    googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

    final userCredential = await _auth.signInWithPopup(googleProvider);


    _firebaseUser = userCredential.user;
    notifyListeners();
  }


  Future<void> signIn() async {
    try {
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.authenticate(scopeHint: scopes);
      } else {

        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        googleProvider.addScope('openid');
        googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

        final userCredential = await _auth.signInWithPopup(googleProvider);


        _firebaseUser = userCredential.user;
        notifyListeners();

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
    print('authEvent');

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
