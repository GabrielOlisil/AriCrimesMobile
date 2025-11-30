import 'package:flutter/material.dart';
import 'package:o_auth2/controllers/category_controller.dart';
import 'package:o_auth2/views/relato_detail_view.dart';
import 'package:provider/provider.dart';
import 'package:o_auth2/controllers/latest_relatos_controller.dart';

class LatestRelatosView extends StatefulWidget {
  const LatestRelatosView({super.key});

  @override
  State<LatestRelatosView> createState() => _LatestRelatosViewState();
}

class _LatestRelatosViewState extends State<LatestRelatosView> {
  final ScrollController _scrollController = ScrollController();

  String _getCategoryName(BuildContext context, int? catId) {
    if (catId == null) return "Categoria Desconhecida";
    // O CategoryController já deve estar carregado pelo main.dart
    final categories = context.read<CategoryController>().categorias;
    try {
      return categories.firstWhere((c) => c.id == catId).nome;
    } catch (_) {
      return "Categoria #$catId";
    }
  }

  @override
  void initState() {
    super.initState();

    // Carrega os dados iniciais
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LatestRelatosController>().refresh();
    });

    // Listener para Scroll Infinito
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Se estiver perto do fim (200px), carrega mais
        context.read<LatestRelatosController>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<LatestRelatosController>().currentTitle),
        backgroundColor: Colors.teal.shade400,
        actions: [
          // --- BOTÃO DE REFRESH (ATUALIZAR) ---
          Consumer<LatestRelatosController>(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar lista',
                // Desabilita o botão se já estiver carregando (feedback visual)
                onPressed: controller.isLoading
                    ? null
                    : () => controller.refresh(),
              );
            },
          ),
        ],
      ),
      body: Consumer<LatestRelatosController>(
        builder: (context, controller, child) {
          // Exibe erro se houver, mas permite tentar de novo com Refresh
          if (controller.errorMessage != null && controller.relatos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Erro: ${controller.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: controller.refresh,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          // Loading inicial (apenas se a lista estiver vazia)
          if (controller.isLoading && controller.relatos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.relatos.isEmpty) {
            return const Center(child: Text('Nenhum relato encontrado.'));
          }

          // Lista com RefreshIndicator e Paginação
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView.builder(
              controller: _scrollController,
              // +1 para o indicador de loading no final
              itemCount: controller.relatos.length + 1,
              itemBuilder: (context, index) {
                // Se for o último item da lista
                if (index == controller.relatos.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: controller.hasMore
                          ? const CircularProgressIndicator() // Mostra loading se tem mais
                          : const Text(
                              "Você chegou ao fim.",
                            ), // Mensagem de fim
                    ),
                  );
                }

                // Renderização normal do Card
                final relato = controller.relatos[index];
                final objRoubado = relato['obj_roubado']?.toString() ?? '';
                final local = relato['local']?.toString() ?? 'Local Indefinido';

                final catId = relato['categoria_id'] as int?; // Pega o ID
                final catName = _getCategoryName(
                  context,
                  catId,
                ); // Traduz para Nome

                final dataRegistro = relato['data_registro'] != null
                    ? DateTime.parse(
                        relato['data_registro'].toString(),
                      ).toLocal().toString().substring(0, 16)
                    : 'Data Indefinida';
                final numConfirmacoes =
                    (relato['numero_confirmacoes'] as num?)?.toInt() ?? 0;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.public, color: Colors.teal),
                    title: Text(
                      catName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (objRoubado.isNotEmpty)
                          Text(
                            "Item: $objRoubado",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),

                        Text('Local: $local'),
                        Text('Data: $dataRegistro'),

                        // --- NOVO: Contador de Confirmações ---
                        const SizedBox(height: 6), // Espaçamento
                        Row(
                          children: [
                            Icon(
                              Icons.thumb_up_alt_outlined,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$numConfirmacoes confirmações",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        // --------------------------------------
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RelatoDetailView(
                            relatoId: relato['id'],
                            placeholderData: relato,
                          ),
                        ),
                      ).then((_) {
                        // Opcional: Recarregar a lista ao voltar, para atualizar o contador
                        // context.read<LatestRelatosController>().refresh();
                      });
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
