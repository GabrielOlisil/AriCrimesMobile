import 'package:flutter/material.dart';
import 'package:o_auth2/auth/auth_provider.dart';
import 'package:provider/provider.dart';





class UnauthenticatedBody extends StatefulWidget {
  const UnauthenticatedBody({super.key});

  @override
  State<UnauthenticatedBody> createState() => _UnauthenticatedBodyState();
}

class _UnauthenticatedBodyState extends State<UnauthenticatedBody> {
  Future<void> _handleSignIn() async {
    await Provider.of<MyAuthProvider>(context, listen: false).signIn();
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _handleSignIn,
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
}
