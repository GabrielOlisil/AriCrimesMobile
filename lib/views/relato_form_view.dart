import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:o_auth2/controllers/relato_form_controller.dart';
import 'package:o_auth2/services/relato_service.dart';

/// Tela de formulário para registro de novo furto.
///
/// Esta View usa um [RelatoFormController] para gerenciar seu estado,
/// tornando o widget da View "burro" (apenas exibe o estado).
class RelatoFormView extends StatefulWidget {
  const RelatoFormView({super.key});

  @override
  State<RelatoFormView> createState() => _RelatoFormViewState();
}

class _RelatoFormViewState extends State<RelatoFormView> {
  // 2. REFERÊNCIA AO CONTROLLER
  late final RelatoFormController _controller;

  @override
  void initState() {
    super.initState();

    // 3. INJEÇÃO DE DEPENDÊNCIA
    // Pega o Dio (provido no main.dart)
    final dio = context.read<Dio>();
    // Cria o Service
    final relatoService = RelatoService(dio: dio);
    // Cria o Controller
    _controller = RelatoFormController(relatoService: relatoService);
  }

  // 4. DISPOSE
  // Dá dispose no Controller quando o widget for removido
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Furto'),
        backgroundColor: const Color.fromARGB(255, 83, 214, 247),
      ),
      // 5. OUVINTE DE ESTADO
      // O ListenableBuilder ouve o Controller e reconstrói
      // a UI quando notifyListeners() é chamado.
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              // 6. USA A KEY DO CONTROLLER
              key: _controller.formKey,
              child: Column(
                children: [
                  // 7. USA OS TEXT CONTROLLERS
                  TextFormField(
                    controller: _controller.objRoubadoController,
                    decoration:
                        const InputDecoration(labelText: 'Objeto Roubado'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe o objeto' : null,
                  ),
                  TextFormField(
                    controller: _controller.descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe a descrição' : null,
                  ),

                  // --- Seção de Imagem (controlada) ---
                  _buildImageSection(_controller),

                  // --- Botão de Mapa (controlado) ---
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: Text(
                      // 8. REAGE AO ESTADO DO CONTROLLER
                      _controller.selectedLocation == null
                          ? 'Selecionar Localização no Mapa (Obrigatório)'
                          : 'Localização Selecionada (Lat: ${_controller.selectedLocation!.latitude.toStringAsFixed(3)})',
                    ),
                    // 9. CHAMA O MÉTODO DO CONTROLLER
                    onPressed: () => _controller.selectLocation(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: _controller.selectedLocation == null
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),

                  // --- Campos de Local (controlados) ---
                  TextFormField(
                    // 7. USA OS TEXT CONTROLLERS
                    controller: _controller.localController,
                    decoration: const InputDecoration(
                      labelText: 'Local',
                      enabled: false,
                    ),
                  ),
                  TextFormField(
                    controller: _controller.latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      enabled: false,
                    ),
                  ),
                  TextFormField(
                    controller: _controller.longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      enabled: false,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Botão de Envio (controlado) ---
                  _controller.isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Enviar Relato'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          // 9. CHAMA O MÉTODO DO CONTROLLER
                          onPressed: _controller.submitRelato,
                        ),
                  const SizedBox(height: 20),

                  // --- Mensagem de Feedback (controlada) ---
                  if (_controller.feedbackMessage != null)
                    Text(
                      _controller.feedbackMessage!,
                      style: TextStyle(
                        color: _controller.feedbackMessage!.contains("sucesso")
                            ? Colors.green
                            : Colors.red,
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

  /// Widget privado para construir a seção de imagem
  /// (Movido para organizar o 'build').
  Widget _buildImageSection(RelatoFormController controller) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text('Imagem do Relato:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // 8. REAGE AO ESTADO DO CONTROLLER
        if (controller.selectedImage != null) ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: kIsWeb
                  ? Image.network(
                      controller.selectedImage!.path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error),
                    )
                  : Image.file(
                      File(controller.selectedImage!.path),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Trocar Imagem'),
                // 9. CHAMA O MÉTODO DO CONTROLLER
                onPressed: controller.pickImage,
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Remover'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                // 9. CHAMA O MÉTODO DO CONTROLLER
                onPressed: controller.removeImage,
              ),
            ],
          ),
        ] else ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, size: 50, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Selecionar Imagem da Galeria'),
            // 9. CHAMA O MÉTODO DO CONTROLLER
            onPressed: controller.pickImage,
          ),
        ],
      ],
    );
  }
}