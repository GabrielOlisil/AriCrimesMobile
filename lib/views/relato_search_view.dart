// lib/views/relato_search_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/relato_search_controller.dart';
import '../services/relato_service.dart';
import '../controllers/category_controller.dart'; // Para o nome da categoria
import 'relato_detail_view.dart'; // Para navegação

class RelatoSearchView extends StatelessWidget {
  const RelatoSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    // Injetando o controller localmente nesta rota
    return ChangeNotifierProvider(
      create: (context) => RelatoSearchController(context.read<RelatoService>()),
      child: const _RelatoSearchContent(),
    );
  }
}

class _RelatoSearchContent extends StatefulWidget {
  const _RelatoSearchContent();

  @override
  State<_RelatoSearchContent> createState() => _RelatoSearchContentState();
}

class _RelatoSearchContentState extends State<_RelatoSearchContent> {
  final TextEditingController _searchController = TextEditingController();

  // Helper para nome da categoria (mesma lógica das outras telas)
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RelatoSearchController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade400,
        title: TextField(
          controller: _searchController,
          autofocus: true, // Abre o teclado automaticamente
          style: const TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Buscar (ex: celular, assalto...)',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => controller.search(_searchController.text),
            ),
          ),
          onSubmitted: (value) => controller.search(value),
        ),
      ),
      body: Column(
        children: [
          if (controller.isLoading)
            const LinearProgressIndicator(),

          if (controller.errorMessage != null && !controller.isLoading)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: controller.results.length,
              itemBuilder: (context, index) {
                final relato = controller.results[index];

                // Dados para exibição
                final catId = relato['categoria_id'] as int?;
                final catName = _getCategoryName(context, catId);
                final objRoubado = relato['obj_roubado']?.toString() ?? '';
                final local = relato['local']?.toString() ?? 'Local Indefinido';
                final numConfirmacoes = (relato['numero_confirmacoes'] as num?)?.toInt() ?? 0;

                String dataRegistro = 'Data Indefinida';
                if (relato['data_registro'] != null) {
                  try {
                    dataRegistro = DateTime.parse(relato['data_registro'].toString())
                        .toLocal()
                        .toString()
                        .substring(0, 16);
                  } catch (_) {}
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.search, color: Colors.teal), // Ícone de lupa para diferenciar

                    title: Text(
                      catName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (objRoubado.isNotEmpty)
                          Text("Item: $objRoubado", style: const TextStyle(fontWeight: FontWeight.w500)),

                        Text('Local: $local'),
                        Text('Data: $dataRegistro'),

                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.blue.shade700),
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
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}