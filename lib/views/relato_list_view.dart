// lib/views/relato_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/relato_manager_controller.dart';
import '../controllers/category_controller.dart'; // Para o nome da categoria
import 'relato_edit_view.dart';
import 'relato_detail_view.dart'; // Importe a view de detalhes

class RelatoListView extends StatefulWidget {
  const RelatoListView({super.key});

  @override
  State<RelatoListView> createState() => _RelatoListViewState();
}

class _RelatoListViewState extends State<RelatoListView> {
  final ScrollController _scrollController = ScrollController();

  // Helper para nome da categoria
  String _getCategoryName(BuildContext context, int? catId) {
    if (catId == null) return "Categoria Desconhecida";
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
    // Carrega dados iniciais
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RelatoManagerController>().fetchRelatos();
    });

    // Listener de Scroll Infinito
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<RelatoManagerController>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _editRelato(BuildContext context, Map<String, dynamic> relatoData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RelatoEditView(
          relatoId: relatoData['id'] as int,
          initialData: relatoData,
        ),
      ),
    ).then((_) {
      // Recarrega a lista ao voltar da edição
      context.read<RelatoManagerController>().fetchRelatos();
    });
  }

  Future<void> _deleteRelato(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza de que deseja excluir este relato permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<RelatoManagerController>().deleteRelato(id);

      if (mounted) {
        final message = context.read<RelatoManagerController>().errorMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: message.contains('sucesso') ? Colors.green : Colors.red,
            ),
          );
          context.read<RelatoManagerController>().clearErrorMessage();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Relatos'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Consumer<RelatoManagerController>(
        builder: (context, controller, child) {

          // Se estiver carregando a primeira página e a lista estiver vazia
          if (controller.isLoading && controller.relatos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.relatos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.feed_outlined, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Você ainda não registrou nenhum relato.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.fetchRelatos, // Puxar para atualizar
            child: ListView.builder(
              controller: _scrollController,
              // +1 para o indicador de loading no fim
              itemCount: controller.relatos.length + 1,
              itemBuilder: (context, index) {

                // Indicador de Carregamento da Próxima Página
                if (index == controller.relatos.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: controller.hasMore
                          ? const CircularProgressIndicator()
                          : Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Text(
                          "Fim da lista.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  );
                }

                final relato = controller.relatos[index];
                final id = relato['id'] as int;
                final objRoubado = relato['obj_roubado']?.toString() ?? '';
                final catId = relato['categoria_id'] as int?;
                final catName = _getCategoryName(context, catId);

                String dataFurto = 'Data Indefinida';
                if (relato['data_furto'] != null) {
                  try {
                    dataFurto = DateTime.parse(relato['data_furto'].toString())
                        .toLocal()
                        .toString()
                        .substring(0, 16); // dd-mm-yyyy hh:mm (aprox)
                  } catch (_) {}
                }

                final numConfirmacoes = (relato['numero_confirmacoes'] as num?)?.toInt() ?? 0;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(Icons.security_update_warning, color: Colors.red.shade700),

                    // TÍTULO: Categoria
                    title: Text(
                      catName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (objRoubado.isNotEmpty)
                          Text("Item: $objRoubado", style: const TextStyle(color: Colors.black87)),

                        Text('Data do Ocorrido: $dataFurto'),

                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.thumb_up, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              "$numConfirmacoes",
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // AÇÃO: Visualizar Detalhe
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RelatoDetailView(
                            relatoId: id,
                            placeholderData: relato,
                          ),
                        ),
                      ).then((_) {
                        // Atualiza a lista ao voltar (caso tenha editado/confirmado)
                        controller.fetchRelatos();
                      });
                    },

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Editar
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue.shade700),
                          onPressed: controller.isLoading ? null : () => _editRelato(context, relato),
                        ),
                        // Excluir
                        IconButton(
                          icon: Icon(Icons.delete_forever, color: Colors.red.shade500),
                          onPressed: controller.isLoading ? null : () => _deleteRelato(context, id),
                        ),
                      ],
                    ),
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