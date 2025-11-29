// lib/views/latest_relatos_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/latest_relatos_controller.dart'; 

class LatestRelatosView extends StatefulWidget {
  const LatestRelatosView({super.key});

  @override
  State<LatestRelatosView> createState() => _LatestRelatosViewState();
}

class _LatestRelatosViewState extends State<LatestRelatosView> {
  @override
  void initState() {
    super.initState();
    // Inicia a busca dos relatos logo após a construção da tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LatestRelatosController>().fetchLatestRelatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novos Relatos (Últimos 7 dias)'),
        backgroundColor: Colors.teal.shade400,
        actions: [
          // Botão de atualização
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LatestRelatosController>().fetchLatestRelatos(),
          ),
        ],
      ),
      body: Consumer<LatestRelatosController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erro: ${controller.errorMessage}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (controller.relatos.isEmpty) {
            return const Center(
              child: Text('Nenhum relato novo encontrado nos últimos 7 dias.'),
            );
          }

          // Lista de Relatos
          return ListView.builder(
            itemCount: controller.relatos.length,
            itemBuilder: (context, index) {
              final relato = controller.relatos[index];
              final objRoubado = relato['obj_roubado']?.toString() ?? 'Objeto Desconhecido';
              final local = relato['local']?.toString() ?? 'Local Indefinido';
              
              // Formata a data de registro para exibição
              final dataRegistro = relato['data_registro'] != null 
                  ? DateTime.parse(relato['data_registro'].toString()).toLocal().toString().substring(0, 16)
                  : 'Data Indefinida';
              
              final categoriaId = relato['categoria_id']?.toString() ?? 'N/A';
              
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
                      Text('Registrado em: $dataRegistro'),
                      Text('Categoria ID: $categoriaId'),
                    ],
                  ),
                  // Importante: Não há onTap, nem botões de edição/deleção.
                  // O relato é apenas para visualização.
                ),
              );
            },
          );
        },
      ),
    );
  }
}