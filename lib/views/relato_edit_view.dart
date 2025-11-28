import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../controllers/relato_manager_controller.dart'; 

/// Tela de formulário para edição de relato existente e upload de imagem.
class RelatoEditView extends StatefulWidget {
  final int relatoId;
  final Map<String, dynamic> initialData;

  const RelatoEditView({
    super.key,
    required this.relatoId,
    required this.initialData,
  });

  @override
  State<RelatoEditView> createState() => _RelatoEditViewState();
}

class _RelatoEditViewState extends State<RelatoEditView> {
  late final RelatoManagerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = context.read<RelatoManagerController>();

    _controller.initializeEdit(
      widget.relatoId,
      widget.initialData,
    );
  }

  /// Responsável por validar o formulário, chamar o salvamento e dar feedback ao usuário.
  Future<void> _handleSave() async {
    // 1. Validação do Formulário (apenas os campos Textuais que estão na tela)
    if (!_controller.formKey.currentState!.validate()) {
      _showSnackBar('Por favor, preencha todos os campos textuais obrigatórios.', Colors.orange);
      return;
    }

    // 2. Chama a lógica do Controller (sem passar o context)
    await _controller.saveChanges();

    // 3. Feedback e Navegação
    final message = _controller.errorMessage;
    if (message != null) {
      _showSnackBar(
        message,
        message.contains("sucesso") ? Colors.green.shade700 : Colors.red.shade700,
      );

      // Se for sucesso, volta para a tela anterior (Lista)
      if (message.contains("sucesso") && mounted) {
        // Aguarda um pouco para o usuário ler o SnackBar antes de voltar
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
    // Limpa a mensagem no controller após exibir o SnackBar (melhor UX)
    _controller.clearErrorMessage();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Relato #${widget.relatoId}'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          // O feedback agora é gerenciado pelo SnackBar dentro do _handleSave
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Adicione a foto e/ou altere os dados do relato. Clique em "SALVAR ALTERAÇÕES" para finalizar.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                    ),
                  ),

                  // --- SEÇÃO DE IMAGEM ---
                  _buildImageSection(_controller), 
                  const Divider(),
                  
                  // --- CAMPOS DE EDIÇÃO (Dados Textuais) ---
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
                  
                  // Campos de localização (tornados editáveis, pois a intenção é editar)
                  TextFormField(
                    controller: _controller.localController,
                    decoration: const InputDecoration(labelText: 'Local do Furto'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe o local' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _controller.latitudeController,
                          decoration: const InputDecoration(labelText: 'Latitude'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || double.tryParse(v) == null ? 'Lat inválida' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _controller.longitudeController,
                          decoration: const InputDecoration(labelText: 'Longitude'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || double.tryParse(v) == null ? 'Long inválida' : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- Botão de Salvamento ---
                  _controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('SALVAR ALTERAÇÕES'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            // MUDANÇA: Chama o método local sem passar o context para o Controller
                            onPressed: _handleSave, 
                          ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget privado para construir a seção de imagem
  Widget _buildImageSection(RelatoManagerController controller) {
    // ⚠️ NOTA: O tratamento de imagem para web/móvel está correto.
    return Column(
      children: [
        const Text('IMAGEM:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        
        // Exibição da imagem selecionada
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: controller.selectedImage != null
              ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                              controller.selectedImage!.path,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error, color: Colors.red),
                          )
                        : Image.file(
                              File(controller.selectedImage!.path),
                              fit: BoxFit.cover,
                          ),
                )
              : const Center(
                  child: Text('Nenhuma foto selecionada para upload.', style: TextStyle(color: Colors.grey)),
                ),
        ),
        const SizedBox(height: 8),
        
        // Botões de Ação
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: Text(controller.selectedImage != null ? 'Trocar Imagem' : 'Adicionar Imagem'),
              onPressed: controller.pickImage,
            ),
            if (controller.selectedImage != null || controller.shouldDeleteImage) 
              TextButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Remover Seleção'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: controller.removeImage,
              ),
          ],
        ),
      ],
    );
  }
}