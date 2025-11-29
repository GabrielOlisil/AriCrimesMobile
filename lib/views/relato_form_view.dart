// lib/views/relato_form_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../controllers/relato_form_controller.dart';
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

    // Pega as instâncias fornecidas pelo Provider (RelatoService e LocationService)
    final relatoService = context.read<RelatoService>();
    final locationService = context.read<LocationService>();

    // Cria o controller com as dependências injetadas
    _controller = RelatoFormController(
      relatoService: relatoService,
      locationService: locationService,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Furto (Passo 1 de 2)'),
        backgroundColor: const Color.fromARGB(255, 83, 214, 247),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _controller.formKey,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Preencha apenas os dados textuais. Após a confirmação, você será redirecionado para adicionar fotos.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),

                  // --- CAMPOS DE TEXTO ---
                  TextFormField(
                    controller: _controller.objRoubadoController,
                    decoration: const InputDecoration(
                      labelText: 'Objeto Roubado',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe o objeto' : null,
                  ),
                  TextFormField(
                    controller: _controller.descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe a descrição' : null,
                  ),

                  // --- Botão de MAPA ---
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: Text(
                      _controller.selectedLocation == null
                          ? 'Selecionar Localização no Mapa (Obrigatório)'
                          : 'Localização Selecionada',
                    ),
                    onPressed: () => _controller.selectLocation(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: _controller.selectedLocation == null
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),

                  // --- CAMPOS DE LOCALIZAÇÃO ---
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _controller.localController,
                    decoration: const InputDecoration(
                      labelText: 'Local',
                      enabled: false,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- BOTÃO DE ENVIO ---
                  _controller.isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('ENVIAR RELATO (1ª Fase)'),
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
                          onPressed: () => _controller.submitRelato(context),
                        ),

                  const SizedBox(height: 20),

                  // --- FEEDBACK ---
                  if (_controller.feedbackMessage != null)
                    Text(
                      _controller.feedbackMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _controller.feedbackMessage!.toLowerCase().contains(
                              "sucesso",
                            )
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
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
