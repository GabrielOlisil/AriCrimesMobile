import 'dart:async';
import 'package:flutter/material.dart';
import 'package:o_auth2/auth/auth_provider.dart';
import 'package:o_auth2/components/authenticated_body.dart';
import 'package:o_auth2/components/unauthenticated_body.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<MyAuthProvider>(context, listen: true).user;

    if (user == null) {
      return Scaffold(body: UnauthenticatedBody());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AuthenticatedBody(user: user),
    );
  }
}
