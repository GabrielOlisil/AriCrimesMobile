import 'package:flutter/material.dart';
import 'package:o_auth2/controllers/category_controller.dart';
import 'package:o_auth2/views/relato_detail_view.dart';
import 'package:provider/provider.dart';
import 'package:o_auth2/controllers/relato_manager_controller.dart';
import 'relato_edit_view.dart'; // Importa a tela de edição

/// Tela que exibe a lista de relatos e permite a interação (edição/deleção).
class RelatoListView extends StatefulWidget {
  const RelatoListView({super.key});

  @override
  State<RelatoListView> createState() => _RelatoListViewState();
}

class _RelatoListViewState extends State<RelatoListView> {

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
    // Busca os dados assim que a tela for construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RelatoManagerController>().fetchRelatos();
    });
  }

  // Abre a tela de edição com os dados do relato selecionado
  void _editRelato(BuildContext context, Map<String, dynamic> relatoData) {
    // CORREÇÃO CRÍTICA AQUI: A RelatoEditView espera 'relatoId' e 'initialData'
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => RelatoEditView(
              relatoId:
                  relatoData['id'] as int, // Argumento 'relatoId' requerido
              initialData: relatoData, // Argumento 'initialData' requerido
            ),
          ),
        )
        .then((_) {
          // Quando voltar da tela de edição, atualiza a lista
          context.read<RelatoManagerController>().fetchRelatos();
        });
  }

  // Lógica de deleção com confirmação visual
  Future<void> _deleteRelato(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza de que deseja excluir este relato permanentemente?',
        ),
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

    if (confirmed == true) {
      // Chama a função de deleção do Controller
      await context.read<RelatoManagerController>().deleteRelato(id);

      // Exibe feedback (SnackBar)
      final message = context.read<RelatoManagerController>().errorMessage;
      if (mounted && message != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: message.contains('sucesso')
                ? Colors.green
                : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        context
            .read<RelatoManagerController>()
            .clearErrorMessage(); // Limpa a mensagem do Controller
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa o Consumer para ouvir as mudanças no Controller (loading, relatos)
    return Consumer<RelatoManagerController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Meus Relatos de Crimes'),
            backgroundColor: Colors.blue.shade700,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.isLoading
                    ? null
                    : controller.fetchRelatos,
              ),
            ],
          ),
          body: controller.isLoading && controller.relatos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : controller.relatos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 60,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum relato encontrado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Por favor, adicione um novo relato ou verifique sua conexão.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: controller.relatos.length,
                  itemBuilder: (context, index) {
                    final relato = controller.relatos[index];
                    final id = relato['id'] as int;
                    final catId = relato['categoria_id'] as int?; // Pega o ID
                    final catName = _getCategoryName(context, catId);


                    final objRoubado = relato['obj_roubado']?.toString() ?? '';

                    final dataFurto = relato['data_furto'] != null
                        ? relato['data_furto'].toString().substring(0, 10)
                        : 'Data Indefinida';
                    final numConfirmacoes = (relato['numero_confirmacoes'] as num?)?.toInt() ?? 0;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.public, color: Colors.teal),
                        title: Text(
                          catName.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column( // Alterado de Text para Column para caber mais info
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Data do Ocorrencia: $dataFurto'),

                            // --- NOVO: Contador ---
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (objRoubado.isNotEmpty)
                                  Text("Item: $objRoubado", style: const TextStyle(fontWeight: FontWeight.w500)),


                                Icon(Icons.thumb_up, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  "$numConfirmacoes",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // ----------------------
                          ],
                        ),
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
                            // Atualiza a lista ao voltar (caso tenha editado ou confirmado)
                            context.read<RelatoManagerController>().fetchRelatos();
                          });
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ... (seus botões de editar/excluir mantidos aqui)
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue.shade700),
                              onPressed: controller.isLoading ? null : () => _editRelato(context, relato),
                            ),
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
    );
  }
}
