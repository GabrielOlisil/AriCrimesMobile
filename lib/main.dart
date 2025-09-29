import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:o_auth2/Auth/auth_provider.dart';
import 'package:o_auth2/components/authenticated_body.dart';
import 'package:o_auth2/components/unauthenticated_body.dart';
import 'package:o_auth2/firebase_options.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => MyAuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  initState() {
    super.initState();
    Provider.of<MyAuthProvider>(context, listen: false).initAuthState();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<MyAuthProvider>(
      context,
      listen: true,
    ).firebaseUser;

    if (firebaseUser != null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        body: AuthenticatedBody(user: firebaseUser),
      );
    }

    return Scaffold(body: UnauthenticatedBody());
  }
}
