import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/relato_manager_controller.dart';
import 'relato_edit_view.dart'; // Importa a tela de edição

/// Tela que exibe a lista de relatos e permite a interação (edição/deleção).
class RelatoListView extends StatefulWidget {
  const RelatoListView({super.key});

  @override
  State<RelatoListView> createState() => _RelatoListViewState();
}

class _RelatoListViewState extends State<RelatoListView> {
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RelatoEditView(
          relatoId: relatoData['id'] as int, // Argumento 'relatoId' requerido
          initialData: relatoData, // Argumento 'initialData' requerido
        ),
      ),
    ).then((_) {
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
            backgroundColor: message.contains('sucesso') ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        context.read<RelatoManagerController>().clearErrorMessage(); // Limpa a mensagem do Controller
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
                onPressed: controller.isLoading ? null : controller.fetchRelatos,
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
                            Icon(Icons.warning_amber_rounded, size: 60, color: Colors.amber.shade700),
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
                        final objRoubado = relato['obj_roubado']?.toString() ?? 'Objeto Desconhecido';
                        final dataFurto = relato['data_furto'] != null 
                            ? relato['data_furto'].toString().substring(0, 10) 
                            : 'Data Indefinida';

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: Icon(Icons.security_update_warning, color: Colors.red.shade700),
                            title: Text(objRoubado, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('ID: $id | Data do Furto: $dataFurto'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Botão de Edição
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue.shade700),
                                  onPressed: controller.isLoading ? null : () => _editRelato(context, relato),
                                ),
                                // Botão de Deleção
                                IconButton(
                                  icon: Icon(Icons.delete_forever, color: Colors.red.shade500),
                                  onPressed: controller.isLoading ? null : () => _deleteRelato(context, id),
                                ),
                              ],
                            ),
                            onTap: controller.isLoading ? null : () => _editRelato(context, relato),
                          ),
                        );
                      },
                    ),
          // Botão flutuante para adicionar novo relato (se necessário)
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () { /* Navegar para tela de Adição */ },
          //   child: const Icon(Icons.add),
          // ),
        );
      },
    );
  }
}