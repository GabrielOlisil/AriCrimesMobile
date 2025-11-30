// lib/views/relato_form_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/relato_form_controller.dart';
import '../controllers/category_controller.dart'; // Importe o CategoryController
import '../services/relato_service.dart';
import '../services/location_service.dart';

class RelatoFormView extends StatefulWidget {
  const RelatoFormView({super.key});

  @override
  State<RelatoFormView> createState() => _RelatoFormViewState();
}

class _RelatoFormViewState extends State<RelatoFormView> {
  late final RelatoFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RelatoFormController(
      relatoService: context.read<RelatoService>(),
      locationService: context.read<LocationService>(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper para formatar data na UI
  String _formatDateTime(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  // Lógica para abrir DatePicker e depois TimePicker
  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _controller.dataFurto,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_controller.dataFurto),
      );

      if (pickedTime != null) {
        final finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _controller.setDataFurto(finalDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Garante que as categorias estejam carregadas
    final categoryController = context.watch<CategoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Ocorrência'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Preencha os detalhes do ocorrido.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  // 1. SELEÇÃO DE CATEGORIA (Dropdown)
                  DropdownButtonFormField<int>(
                    value: _controller.selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoria da Ocorrência *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    items: categoryController.categorias.map((cat) {
                      return DropdownMenuItem<int>(
                        value: cat.id,
                        child: Text(cat.nome),
                      );
                    }).toList(),
                    onChanged: (val) => _controller.setCategoria(val),
                    validator: (v) =>
                        v == null ? 'Selecione uma categoria' : null,
                  ),

                  const SizedBox(height: 16),

                  // 2. DATA DO FURTO (Campo clicável)
                  InkWell(
                    onTap: () => _pickDateTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data e Hora do Ocorrido *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _formatDateTime(_controller.dataFurto),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. DESCRIÇÃO (Obrigatório)
                  TextFormField(
                    controller: _controller.descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição Detalhada *',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe a descrição' : null,
                  ),

                  const SizedBox(height: 16),

                  // 4. OBJETO ROUBADO (Opcional)
                  TextFormField(
                    controller: _controller.objRoubadoController,
                    decoration: const InputDecoration(
                      labelText: 'Houveram objetos roubados?', // Label alterado
                      border: OutlineInputBorder(),
                      helperText:
                          'Ex: Celular Samsung S20, Carteira de couro... (Deixe em branco se não houve)',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. LOCALIZAÇÃO (Botão)
                  ElevatedButton.icon(
                    icon: Icon(
                      _controller.selectedLocation == null
                          ? Icons.map
                          : Icons.check,
                    ),
                    label: Text(
                      _controller.selectedLocation == null
                          ? 'Selecionar Local no Mapa (Obrigatório)'
                          : 'Local Selecionado (Toque para alterar)',
                    ),
                    onPressed: () => _controller.selectLocation(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _controller.selectedLocation == null
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  if (_controller.selectedLocation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _controller.localController.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // 6. ENVIAR
                  _controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () => _controller.submitRelato(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                          child: const Text('REGISTRAR OCORRÊNCIA'),
                        ),

                  // FEEDBACK
                  if (_controller.feedbackMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _controller.feedbackMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _controller.feedbackMessage!
                                  .toLowerCase()
                                  .contains("sucesso")
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
