import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:o_auth2/auth/auth_provider.dart'; 
import 'package:o_auth2/views/login_view.dart';
import 'package:o_auth2/views/map_view.dart'; 
import 'package:o_auth2/models/user.dart'; 
import 'package:o_auth2/views/relato_list_view.dart'; // Lista de relatos do usuário
import 'package:o_auth2/views/relato_form_view.dart' show RelatoFormView; 
import 'package:o_auth2/views/latest_relatos_view.dart'; // 💡 NOVO: Importa a view de Últimos Relatos

/// [VIEW]
/// View principal (antiga 'HomePage').
/// Atua como um "Portão de Autenticação".
class HomeView extends StatelessWidget {
 const HomeView({super.key});

 // Método para lidar com a navegação para a lista de relatos (do USUÁRIO)
 void _goToRelatoList(BuildContext context) {
  Navigator.of(context).push(
   MaterialPageRoute(
    builder: (context) => const RelatoListView(),
   ),
  );
 }

 // Método para lidar com a navegação para o formulário de novo relato
 void _goToRelatoForm(BuildContext context) {
  Navigator.of(context).push(
   MaterialPageRoute(
    builder: (context) => const RelatoFormView(),
   ),
  );
 }
  
  // 💡 NOVO: Método para lidar com a navegação para a lista de ÚLTIMOS relatos (geral)
  void _goToLatestRelatos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LatestRelatosView(),
      ),
    );
  }

 @override
 Widget build(BuildContext context) {
  // Ouve o AuthProvider.
  final user = Provider.of<MyAuthProvider>(context, listen: true).user;

  // Se deslogado, mostra a tela de Login.
  if (user == null) {
   return const Scaffold(body: LoginView());
  }

  // Se logado, mostra a tela do Mapa com os botões flutuantes.
  return Scaffold(
   extendBodyBehindAppBar: true,
   body: MapView(user: user), 
   
   // Utiliza um Row para exibir os três Floating Action Buttons
   floatingActionButton: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column( // Usando Column para empilhar os FABs à direita
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Botão 3: Últimos Relatos (Últimos 7 dias)
            FloatingActionButton.extended(
              heroTag: 'latest_reports_fab', // Necessário para múltiplos FABs
              onPressed: () => _goToLatestRelatos(context),
              label: const Text('Novos Relatos'),
              icon: const Icon(Icons.access_time_filled),
              backgroundColor: Colors.orange.shade700, // Cor de destaque
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16), // Espaçamento
            // Botão 2: Lista de Relatos (do USUÁRIO - existente)
            FloatingActionButton.extended(
              heroTag: 'list_reports_fab', // Necessário para múltiplos FABs
              onPressed: () => _goToRelatoList(context),
              label: const Text('Meus Relatos'),
              icon: const Icon(Icons.list_alt),
              backgroundColor: Colors.red.shade700, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16), // Espaçamento
            // Botão 1: Novo Relato (vai para o Formulário)
            FloatingActionButton.extended(
              heroTag: 'new_report_fab', // Necessário para múltiplos FABs
              onPressed: () => _goToRelatoForm(context),
              label: const Text('Novo Relato'),
              icon: const Icon(Icons.add_location_alt),
              backgroundColor: Colors.blue.shade700, // Cor de destaque
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
   ),
   floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Alinha ao canto inferior direito
  );
 }
}