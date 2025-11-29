// lib/controllers/relato_manager_controller.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Importação corrigida para ser relativa
import '../services/relato_service.dart';

/// [CONTROLLER]
/// Controller responsável por gerenciar a lista de relatos (leitura/deleção)
/// e a edição/criação de um relato específico (CRUD completo).
class RelatoManagerController extends ChangeNotifier {
 final RelatoService _relatoService;

 // =========================================================================
 // ESTADOS GLOBAIS DE FEEDBACK E CARREGAMENTO
 // =========================================================================
 bool _isLoading = false; 
 String? _errorMessage; 
 bool get isLoading => _isLoading;
 String? get errorMessage => _errorMessage; 
 final ImagePicker _picker = ImagePicker();

 // =========================================================================
 // ESTADO DA LISTA
 // =========================================================================
 List<Map<String, dynamic>> _relatos = [];
 List<Map<String, dynamic>> get relatos => _relatos;

 // =========================================================================
 // ESTADO DO FORMULÁRIO DE EDIÇÃO/CRIAÇÃO
 // =========================================================================
 final GlobalKey<FormState> formKey = GlobalKey<FormState>();
 final TextEditingController objRoubadoController = TextEditingController();
 final TextEditingController descricaoController = TextEditingController();
 final TextEditingController localController = TextEditingController();
 final TextEditingController latitudeController = TextEditingController();
 final TextEditingController longitudeController = TextEditingController();
 
 // Estado de Mídia
 int? _editingRelatoId; 
 Map<String, dynamic>? _requiredInitialData; 
 XFile? _selectedImage; 
 bool _shouldDeleteImage = false;
 String? _existingPhotoUrl; // URL da foto existente
 
 XFile? get selectedImage => _selectedImage;
 String? get existingPhotoUrl => _existingPhotoUrl; 
 bool get shouldDeleteImage => _shouldDeleteImage;

 RelatoManagerController({required RelatoService relatoService})
  : _relatoService = relatoService;
 
 // =========================================================================
 // 1. MÉTODOS DE UTILIDADE E FEEDBACK
 // =========================================================================

 /// Limpa a mensagem de erro/status manualmente.
 void clearErrorMessage() {
  _errorMessage = null;
  notifyListeners();
 }
 
 // =========================================================================
 // 2. OPERAÇÕES DE LISTA (READ & DELETE)
 // =========================================================================

 /// Busca e atualiza a lista de relatos.
 Future<void> fetchRelatos() async {
  _isLoading = true;
  _errorMessage = null; 
  notifyListeners();

  try {
   // CORREÇÃO APLICADA AQUI: Chama o novo método getMyRelatos()
   final List<Map<String, dynamic>> fetchedRelatos = await _relatoService.getMyRelatos();
   _relatos = fetchedRelatos;
   // Não exibe mensagem de sucesso na busca para não poluir a UX
  } catch (e) {
   _errorMessage = 'Falha ao buscar relatos: ${e.toString().split("Exception:").last.trim()}';
  } finally {
   _isLoading = false;
   notifyListeners();
  }
 }

 /// Deleta um relato e atualiza a lista.
 Future<void> deleteRelato(int id) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
   final String? error = await _relatoService.deleteRelato(id);
   
   if (error == null) {
    // Remove da lista local para atualização instantânea
    _relatos.removeWhere((relato) => relato['id'] == id);
    _errorMessage = 'Relato excluído com sucesso';
   } else {
    _errorMessage = 'Falha ao excluir o relato: $error';
   }
  } catch (e) {
   _errorMessage = 'Erro crítico ao deletar: ${e.toString().split("Exception:").last.trim()}';
  } finally {
   _isLoading = false;
   notifyListeners();
   // Não precisa de fetchRelatos aqui, a remoção local resolveu.
  }
 }

 // =========================================================================
 // 3. CRIAÇÃO DE RELATO (CREATE)
 // =========================================================================

 /// Envia os dados do novo relato para o servidor e atualiza a lista.
 Future<void> addRelato(Map<String, dynamic> newRelatoData) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
   // Envia os dados textuais do relato. O serviço retorna o ID.
   final String reportId = await _relatoService.submitRelato(
    data: newRelatoData,
   );
   
   // Força um refresh para buscar o novo item e atualizar a lista.
   await fetchRelatos();
   
   _errorMessage = 'Relato ID $reportId adicionado com sucesso!';
   
  } catch (e) {
   _errorMessage = 'Erro ao adicionar relato: ${e.toString().split("Exception:").last.trim()}';
  } finally {
   _isLoading = false;
   notifyListeners();
  }
 }

 // =========================================================================
 // 4. MÉTODOS DE EDIÇÃO (UPDATE)
 // =========================================================================

 /// Prepara o controller para editar um relato específico.
 void initializeEdit(int relatoId, Map<String, dynamic> initialData) {
  _editingRelatoId = relatoId;
  _requiredInitialData = initialData;

  objRoubadoController.text = initialData['obj_roubado']?.toString() ?? '';
  descricaoController.text = initialData['descricao']?.toString() ?? '';
  localController.text = initialData['local']?.toString() ?? '';
  // Corrigido para garantir que campos nullos ou inexistentes não causem problemas
  latitudeController.text = initialData['latitude'] != null && initialData['latitude'] != 0.0 ? initialData['latitude']?.toString() ?? '' : '';
  longitudeController.text = initialData['longitude'] != null && initialData['longitude'] != 0.0 ? initialData['longitude']?.toString() ?? '' : '';
  
  // Extrai a URL da foto existente
  _existingPhotoUrl = null;
  if (initialData['fotos'] is List && (initialData['fotos'] as List).isNotEmpty) {
   // Assume que a primeira foto é a principal
   _existingPhotoUrl = initialData['fotos'][0]['url']?.toString();
  }
  
  // Reseta o estado da nova imagem e da deleção
  _selectedImage = null;
  _shouldDeleteImage = false;
  _errorMessage = null; 
 }

 /// Salva a foto (se selecionada), deleta (se marcado) E atualiza os dados de texto.
 Future<void> saveChanges() async {
  if (_editingRelatoId == null || _requiredInitialData == null) {
   _errorMessage = "Erro: Nenhum relato selecionado para edição.";
   notifyListeners();
   return;
  }
  
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  String? photoError;
  String? dataError;

  try {
   // A. DELEÇÃO DA FOTO
   if (_shouldDeleteImage) {
     final deleteError = await _relatoService.deleteFotoParaRelato(_editingRelatoId!); 
     if (deleteError != null) {
      photoError = "Falha ao deletar foto: $deleteError";
     } else {
      _shouldDeleteImage = false; 
      _existingPhotoUrl = null; // Remove URL após deleção bem-sucedida
     }
   }

   // B. UPLOAD DA FOTO
   if (photoError == null && _selectedImage != null) {
    photoError = await _relatoService.uploadFotoParaRelato(
     relatoId: _editingRelatoId!,
     image: _selectedImage!,
    );
   }

   if (photoError != null) {
    _errorMessage = "Erro na Foto: $photoError";
    return; 
   }
   
   // C. ATUALIZAÇÃO DE DADOS (PUT)
   final updatedData = {
    "obj_roubado": objRoubadoController.text,
    "descricao": descricaoController.text,
    "local": localController.text,
    // Tenta converter para double; 0.0 será enviado se falhar
    "latitude": double.tryParse(latitudeController.text) ?? 0.0,
    "longitude": double.tryParse(longitudeController.text) ?? 0.0,
    
    // Mantém dados não editáveis
    "data_furto": _requiredInitialData!['data_furto']?.toString() ?? DateTime.now().toIso8601String(),
    "data_registro": _requiredInitialData!['data_registro']?.toString() ?? DateTime.now().toIso8601String(),
    "categoria_id": _requiredInitialData!['categoria_id'] ?? 1, 
   };

   dataError = await _relatoService.updateRelato(
    relatoId: _editingRelatoId!,
    data: updatedData,
   );

   if (dataError != null) {
    _errorMessage = "Falha ao atualizar dados: $dataError";
    return; 
   }

   // D. SUCESSO
   String finalMessage = "Relato atualizado com sucesso!";
   if (_selectedImage != null) {
    finalMessage += " Foto enviada.";
    _selectedImage = null; 
   } else if (_shouldDeleteImage) { 
    finalMessage += " Foto removida.";
    _shouldDeleteImage = false;
   }
   
   _errorMessage = finalMessage; 
   
  } on Exception catch (e) {
   _errorMessage = "Erro crítico ao salvar: ${e.toString().split("Exception:").last.trim()}";
  } finally {
   _isLoading = false;
   notifyListeners();
  }
 }

 // =========================================================================
 // 5. LÓGICA DE IMAGEM
 // =========================================================================
 
 Future<void> pickImage() async {
  try {
   final XFile? pickedFile = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 80,
   );
   
   _selectedImage = pickedFile;
   if (pickedFile != null) {
    // Se selecionar uma nova imagem, desmarca a deleção da existente
    _shouldDeleteImage = false; 
    _errorMessage = 'Imagem selecionada! Clique em SALVAR ALTERAÇÕES.'; 
   } else {
    _errorMessage = 'Seleção cancelada.';
   }

  } catch (e) { 
   _errorMessage = 'Erro ao selecionar imagem: $e';
  }
  notifyListeners();
 }

 void removeImage() {
  // Se há uma imagem selecionada, apenas a remove
  if (_selectedImage != null) {
    _selectedImage = null;
    _errorMessage = 'Seleção de imagem desfeita.';
  } 
  // Se há uma URL existente, marca para deleção
  else if (_existingPhotoUrl != null && !_shouldDeleteImage) {
    _shouldDeleteImage = true;
    _errorMessage = 'Foto marcada para remoção. Clique em SALVAR ALTERAÇÕES para confirmar.';
  }
  // Se já estava marcada para deleção, desfaz
  else if (_shouldDeleteImage) {
    _shouldDeleteImage = false;
    _errorMessage = 'Remoção de foto existente desfeita.';
  }
  
  notifyListeners();
 }

 @override
 void dispose() {
  objRoubadoController.dispose();
  descricaoController.dispose();
  localController.dispose();
  latitudeController.dispose();
  longitudeController.dispose();
  super.dispose();
 }
}