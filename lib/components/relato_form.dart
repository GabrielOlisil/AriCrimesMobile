import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Para seleção de imagem (funciona na web)
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar web
import 'dart:io'; // Para File no mobile (não usado na web)
import 'package:path/path.dart' as path; // Para nome do arquivo no MultipartFile
// 🆕 Adicionado: Import do LatLng e do MapSelectionScreen do local CORRETO
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:o_auth2/components/map_selection_screen.dart'; // Mantido, assumindo que esta é a importação correta

// ⚠️ REMOVIDO: A MapSelectionScreen temporária DEVE ser removida daqui
// para evitar conflito com o arquivo real.

class RelatoForm extends StatefulWidget {
  const RelatoForm({super.key});

  @override
  State<RelatoForm> createState() => _RelatoFormState();
}

class _RelatoFormState extends State<RelatoForm> {
  final _formKey = GlobalKey<FormState>();

  String objRoubado = '';
  String descricao = '';
  String local = '';
  // 🆕 Substituído latitude e longitude por uma única variável LatLng
  LatLng? _selectedLocation; 
  int categoriaId = 1;

  // Variável para a imagem selecionada (XFile funciona na web)
  XFile? selectedImage;

  bool isLoading = false;
  String? feedbackMessage;

  // Instância do ImagePicker (reutilizável, suporta web)
  final ImagePicker _picker = ImagePicker();

  // Função para navegar para a tela de seleção de mapa
  Future<void> _goToMapSelection() async {
    // A tela MapSelectionScreen retorna um LatLng (o tipo correto)
    final LatLng? result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MapSelectionScreen()),
    );

    // 🆕 Se o resultado for um LatLng válido, atualize o estado
    if (result != null) {
      setState(() {
        _selectedLocation = result;
        // Opcional: tentar fazer um GeoCoding reverso para preencher o 'local'
        local = 'Local Selecionado no Mapa (${result.latitude.toStringAsFixed(3)}, ${result.longitude.toStringAsFixed(3)})';
      });
      // Adicionar feedback para o usuário
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Localização selecionada: Lat ${result.latitude.toStringAsFixed(4)}, Lon ${result.longitude.toStringAsFixed(4)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Função implementada: Seleciona imagem da galeria (troque para ImageSource.camera se quiser câmera)
  // Na web, abre o seletor de arquivos do browser
  void _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, // Galeria; na web, usa input file HTML
        maxWidth: 1024, // Opcional: Reduz tamanho para envio mais leve
        maxHeight: 1024,
        imageQuality: 80, // Qualidade para otimizar (ajuda na web)
      );

      if (pickedFile != null) {
        setState(() {
          selectedImage = pickedFile;
          feedbackMessage = 'Imagem selecionada com sucesso!'; // Feedback imediato
        });
      } else {
        setState(() {
          feedbackMessage = 'Seleção cancelada.';
        });
      }
    } catch (e) {
      setState(() {
        feedbackMessage = 'Erro ao selecionar imagem: $e';
      });
      print('Erro no pickImage: $e');
    }
  }

  // Nova função: Remove a imagem selecionada
  void _removeImage() {
    setState(() {
      selectedImage = null;
      feedbackMessage = 'Imagem removida.';
    });
  }

  Future<void> _enviarRelato(BuildContext context) async {
    // ⚠️ Validação adicional para Localização
    if (_selectedLocation == null) {
       setState(() {
        feedbackMessage = "Por favor, selecione a Localização no Mapa.";
        isLoading = false;
      });
      return;
    }
    
    setState(() {
      isLoading = true;
      feedbackMessage = null;
    });
    
    // 🆕 Obtém a latitude e longitude da variável _selectedLocation
    final double latitude = _selectedLocation!.latitude;
    final double longitude = _selectedLocation!.longitude;

    final dio = context.read<Dio>();

    try {
      // Preparando a requisição para lidar com imagens (FormData/Multipart)
      final dataMap = {
        "obj_roubado": objRoubado,
        "descricao": descricao,
        "local": local.isEmpty ? 'Local não especificado' : local, // 🆕 Garantir que 'local' não é vazio se não houver geocoding reverso
        "latitude": latitude, // Usando a nova variável
        "longitude": longitude, // Usando a nova variável
        "data_furto": DateTime.now().toIso8601String(),
        "data_registro": DateTime.now().toIso8601String(),
        "categoria_id": categoriaId,
      };

      // FormData formData;

      // if (selectedImage != null) {
      //   final fileName = path.basename(selectedImage!.path);
      //   MultipartFile imageFile;

      //   if (kIsWeb) {
      //     // Na web: Lê como bytes e usa fromBytes (essencial!)
      //     final bytes = await selectedImage!.readAsBytes();
      //     imageFile = MultipartFile.fromBytes(bytes, filename: fileName);
      //   } else {
      //     // Mobile: Usa fromFile normal
      //     imageFile = await MultipartFile.fromFile(selectedImage!.path, filename: fileName);
      //   }

      //   formData = FormData.fromMap({
      //     ...dataMap,
      //     "imagem": imageFile, // Nome do campo: ajuste se a API esperar outro (ex: "foto")
      //   });
      // } else {
      //   // Se não houver imagem, envie FormData com apenas os dados
      //   formData = FormData.fromMap(dataMap);
      // }

      final response = await dio.post(
        '/relato/',
        data: dataMap,
        options: Options(
          headers: {'Content-Type': 'application/json', }
      )
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          feedbackMessage = "Relato enviado com sucesso!";
          // Limpar a imagem e localização após o envio
          selectedImage = null;
          _selectedLocation = null;
          local = '';
        });
        _formKey.currentState?.reset();
      } else {
        setState(
          () => feedbackMessage =
              "Erro ao enviar: ${response.statusCode} - ${response.data}",
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        setState(() => feedbackMessage = "Erro API: ${e.response!.statusCode} - ${e.response!.data}");
      } else {
        setState(() => feedbackMessage = "Falha de Rede/Conexão: ${e.message}");
      }
    } catch (e) {
      setState(() => feedbackMessage = "Falha desconhecida: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Furto'),
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Objeto Roubado'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o objeto' : null,
                onSaved: (v) => objRoubado = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a descrição' : null,
                onSaved: (v) => descricao = v!,
              ),
              // --- Seção de Imagem Atualizada ---
              const SizedBox(height: 10),
              const Text('Imagem do Relato:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Preview da Imagem: Condicional para web/mobile
              if (selectedImage != null) ...[
                Container(
                  height: 200, // Altura fixa para preview
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network( // Na web: Usa URL do XFile (blob/data URL)
                            selectedImage!.path,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                          )
                        : Image.file( // Mobile: Usa File normal
                            File(selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon( // Botão para trocar imagem
                      icon: const Icon(Icons.edit),
                      label: const Text('Trocar Imagem'),
                      onPressed: _pickImage,
                    ),
                    TextButton.icon( // Botão para remover
                      icon: const Icon(Icons.delete),
                      label: const Text('Remover'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: _removeImage,
                    ),
                  ],
                ),
              ] else ...[
                // Estado sem imagem: Texto e botão
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
                  onPressed: _pickImage, // Chama a seleção real
                ),
              ],
              // --- Botão de Mapa ---
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                // 🆕 Atualização do texto do botão
                label: Text(
                  _selectedLocation == null
                      ? 'Selecionar Localização no Mapa (Obrigatório)'
                      : 'Localização Selecionada (Lat: ${_selectedLocation!.latitude.toStringAsFixed(3)})',
                ),
                onPressed: _goToMapSelection, // Chamar a navegação
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40), // Largura total
                  backgroundColor: _selectedLocation == null ? Colors.orange : Colors.green, // Destaque se não selecionado
                ),
              ),
              // --- Campos de Local, Lat/Long ---
              // Removendo o TextFormField do 'Local' pois o mapa preencherá, 
              // mas mantendo Lat/Long para visualização.
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Local',
                  // Exibe o valor de 'local' atual
                  hintText: local.isEmpty ? 'Local do Furto' : local, 
                  enabled: false, // Desabilita a edição manual
                ),
                // 🆕 Usando o valor de 'local'
                initialValue: local, 
                onSaved: (v) => local = v ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  enabled: false, // Desabilita a edição manual
                ),
                // 🆕 Exibe a latitude da variável _selectedLocation
                initialValue: _selectedLocation?.latitude.toStringAsFixed(6) ?? '0.0', 
                keyboardType: TextInputType.number,
                // onSaved: Já está sendo usada no _selectedLocation
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  enabled: false, // Desabilita a edição manual
                ),
                // 🆕 Exibe a longitude da variável _selectedLocation
                initialValue: _selectedLocation?.longitude.toStringAsFixed(6) ?? '0.0', 
                keyboardType: TextInputType.number,
                // onSaved: Já está sendo usada no _selectedLocation
              ),
              const SizedBox(height: 24),
              // --- Botão de Envio ---
              isLoading
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          // ⚠️ Validação de localização antes de enviar
                          if (_selectedLocation != null) { 
                            _enviarRelato(context);
                          } else {
                            setState(() => feedbackMessage = "Por favor, selecione a Localização no Mapa.");
                          }
                        }
                      },
                    ),
              const SizedBox(height: 20),
              if (feedbackMessage != null)
                Text(
                  feedbackMessage!,
                  style: TextStyle(
                    color: feedbackMessage!.contains("sucesso")
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}