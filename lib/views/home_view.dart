import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:o_auth2/auth/auth_provider.dart'; 
import 'package:o_auth2/views/login_view.dart';
import 'package:o_auth2/views/map_view.dart'; 
import 'package:o_auth2/models/user.dart'; 

/// [VIEW]
/// View principal (antiga 'HomePage').
/// Atua como um "Portão de Autenticação".
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ouve o AuthProvider.
    final user = Provider.of<MyAuthProvider>(context, listen: true).user;

    // Se deslogado, mostra a tela de Login.
    if (user == null) {
      return const Scaffold(body: LoginView());
    }

    // Se logado, mostra a tela do Mapa.
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: MapView(user: user), 
    );
  }
}