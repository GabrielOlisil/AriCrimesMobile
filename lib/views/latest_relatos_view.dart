import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/latest_relatos_controller.dart';

class LatestRelatosView extends StatefulWidget {
  const LatestRelatosView({super.key});

  @override
  State<LatestRelatosView> createState() => _LatestRelatosViewState();
}

class _LatestRelatosViewState extends State<LatestRelatosView> {
  final ScrollController _scrollController = ScrollController();

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
        title: const Text('Últimos Relatos'),
        backgroundColor: Colors.teal.shade400,
      ),
      body: Consumer<LatestRelatosController>(
        builder: (context, controller, child) {
          // Exibe erro se houver, mas permite tentar de novo com Refresh
          if (controller.errorMessage != null && controller.relatos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro: ${controller.errorMessage}', textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: controller.refresh,
                    child: const Text('Tentar Novamente'),
                  )
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
                          : const Text("Você chegou ao fim."), // Mensagem de fim
                    ),
                  );
                }

                // Renderização normal do Card
                final relato = controller.relatos[index];
                final objRoubado = relato['obj_roubado']?.toString() ?? 'Objeto Desconhecido';
                final local = relato['local']?.toString() ?? 'Local Indefinido';

                final dataRegistro = relato['data_registro'] != null
                    ? DateTime.parse(relato['data_registro'].toString())
                    .toLocal()
                    .toString()
                    .substring(0, 16)
                    : 'Data Indefinida';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.public, color: Colors.teal),
                    title: Text(objRoubado, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Local: $local'),
                        Text('Data: $dataRegistro'),
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