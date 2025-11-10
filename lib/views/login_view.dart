import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:o_auth2/auth/auth_provider.dart';

/// A tela de Login exibida quando o usuário não está autenticado.
/// 
/// Esta é uma [StatelessWidget] pois não gerencia nenhum estado. 
/// Ela apenas exibe a UI e delega a ação de 'signIn' para o [MyAuthProvider].
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fundo com gradiente
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
              // Ícone do mapa
              const Icon(Icons.map_outlined, color: Colors.white, size: 100),
              const SizedBox(height: 24),

              // Título
              const Text(
                'Bem-vindo ao AriCrimes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10.0, color: Colors.black26)],
                ),
              ),
              const SizedBox(height: 12),

              // Subtítulo
              const Text(
                'Faça login com sua conta Google para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),

              // Botão de Login
              ElevatedButton.icon(
                // 2. LÓGICA SIMPLIFICADA
                // A ação é chamada diretamente no 'onPressed'.
                // Usei context.read() pois só precisamos chamar a função,
                // não precisamos "ouvir" mudanças de estado aqui.
                onPressed: () {
                  context.read<MyAuthProvider>().signIn();
                },
                icon: const Icon(Icons.person),
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