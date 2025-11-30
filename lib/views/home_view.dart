import 'package:flutter/material.dart';
import 'package:o_auth2/controllers/category_controller.dart';
import 'package:o_auth2/views/relato_search_view.dart';
import 'package:provider/provider.dart';
import 'package:o_auth2/auth/auth_provider.dart';
import 'package:o_auth2/views/login_view.dart';
import 'package:o_auth2/views/map_view.dart';
import 'package:o_auth2/models/user.dart';
import 'package:o_auth2/models/categoria.dart'; // Importe o modelo
import 'package:o_auth2/services/relato_service.dart'; // Importe o service
import 'package:o_auth2/controllers/latest_relatos_controller.dart'; // Importe o controller
import 'package:o_auth2/views/relato_list_view.dart';
import 'package:o_auth2/views/relato_form_view.dart' show RelatoFormView;
import 'package:o_auth2/views/latest_relatos_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  // Navegação para Meus Relatos
  void _goToRelatoList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RelatoListView()),
    );
  }

  // Navegação para Novo Relato
  void _goToRelatoForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RelatoFormView()),
    );
  }

  // Lógica para mostrar categorias e navegar
  void _showCategorySelectionAndNavigate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Usamos Consumer para ler o estado atual do CategoryController
        return Consumer<CategoryController>(
          builder: (context, controller, child) {

            // Se ainda estiver carregando (ex: internet muito lenta na abertura)
            if (controller.isLoading) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Se deu erro, damos opção de tentar de novo
            if (controller.error != null) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(controller.error!),
                      TextButton(
                        onPressed: () => controller.loadCategorias(),
                        child: const Text("Tentar Novamente"),
                      )
                    ],
                  ),
                ),
              );
            }

            // Lista Pronta (instantânea)
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filtrar Relatos",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.access_time, color: Colors.blue),
                          title: const Text("Recentes"),
                          onTap: () {
                            Navigator.pop(ctx);
                            _navigateToFeed(context, null, null);
                          },
                        ),
                        const Divider(),
                        // Mapeia a lista que já está na memória
                        ...controller.categorias.map((cat) => ListTile(
                          leading: const Icon(Icons.label_important_outline, color: Colors.orange),
                          title: Text(cat.nome),
                          onTap: () {
                            Navigator.pop(ctx);
                            _navigateToFeed(context, cat.id, cat.nome);
                          },
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToFeed(BuildContext context, int? catId, String? catName) {
    // 1. Atualiza o estado do Controller ANTES de navegar ou no Init da próxima tela.
    // Como o Controller é Singleton no main (Provider), podemos acessá-lo aqui,
    // mas a View reseta no initState com fetchLatestRelatos().
    // Vamos passar os argumentos para o Controller na construção da View ou via chamada direta.

    // Uma abordagem limpa é resetar o controller aqui:
    final controller = context.read<LatestRelatosController>();
    controller.loadRelatos(categoryId: catId, categoryName: catName);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LatestRelatosView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyAuthProvider>(context, listen: true).user;

    if (user == null) {
      return const Scaffold(body: LoginView());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: MapView(user: user),

      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [

            FloatingActionButton( // Mini ou normal, usei normal para destaque
              heroTag: 'search_fab',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const RelatoSearchView()),
                );
              },
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              tooltip: 'Pesquisar Relatos',
              child: const Icon(Icons.search),
            ),

            const SizedBox(height: 16),
            // Botão MODIFICADO: Abre seleção de categoria
            FloatingActionButton.extended(
              heroTag: 'category_reports_fab',
              onPressed: () => _showCategorySelectionAndNavigate(context),
              label: const Text('Explorar Relatos'), // Texto alterado para refletir a nova ação
              icon: const Icon(Icons.search),
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 16),

            FloatingActionButton.extended(
              heroTag: 'list_reports_fab',
              onPressed: () => _goToRelatoList(context),
              label: const Text('Meus Relatos'),
              icon: const Icon(Icons.list_alt),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 16),

            FloatingActionButton.extended(
              heroTag: 'new_report_fab',
              onPressed: () => _goToRelatoForm(context),
              label: const Text('Novo Relato'),
              icon: const Icon(Icons.add_location_alt),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}