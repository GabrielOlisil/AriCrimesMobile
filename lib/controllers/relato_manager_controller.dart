// lib/controllers/relato_manager_controller.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/relato_service.dart';

/// [CONTROLLER]
/// Responsável por gerenciar a lista de "Meus Relatos" (com paginação)
/// e a lógica completa de formulário para Edição/Criação (CRUD + Imagens).
class RelatoManagerController extends ChangeNotifier {
 final RelatoService _relatoService;

 // =========================================================================
 // ESTADOS DE UI E FEEDBACK
 // =========================================================================
 bool _isLoading = false;      // Loading de tela cheia ou inicial
 bool _isLoadingMore = false;  // Loading de rodapé (paginação)
 String? _errorMessage;

 bool get isLoading => _isLoading;
 bool get isLoadingMore => _isLoadingMore;
 String? get errorMessage => _errorMessage;

 // =========================================================================
 // ESTADOS DA LISTA (PAGINAÇÃO)
 // =========================================================================
 List<Map<String, dynamic>> _relatos = [];
 int _offset = 0;
 final int _limit = 10;
 bool _hasMore = true;

 List<Map<String, dynamic>> get relatos => _relatos;
 bool get hasMore => _hasMore;

 // =========================================================================
 // ESTADOS DO FORMULÁRIO (EDIÇÃO)
 // =========================================================================
 final GlobalKey<FormState> formKey = GlobalKey<FormState>();
 final TextEditingController objRoubadoController = TextEditingController();
 final TextEditingController descricaoController = TextEditingController();
 final TextEditingController localController = TextEditingController();
 final TextEditingController latitudeController = TextEditingController();
 final TextEditingController longitudeController = TextEditingController();

 // Controle de Mídia e Contexto de Edição
 int? _editingRelatoId;
 Map<String, dynamic>? _requiredInitialData;
 XFile? _selectedImage;
 bool _shouldDeleteImage = false;
 String? _existingPhotoUrl; // URL da foto vinda da API

 final ImagePicker _picker = ImagePicker();

 XFile? get selectedImage => _selectedImage;
 String? get existingPhotoUrl => _existingPhotoUrl;
 bool get shouldDeleteImage => _shouldDeleteImage;

 RelatoManagerController({required RelatoService relatoService})
     : _relatoService = relatoService;

 // =========================================================================
 // 1. UTILITÁRIOS
 // =========================================================================

 void clearErrorMessage() {
  _errorMessage = null;
  notifyListeners();
 }

 // =========================================================================
 // 2. PAGINAÇÃO E LEITURA (READ)
 // =========================================================================

 /// Reinicia a lista e busca a primeira página (Refresh/Init)
 Future<void> fetchRelatos() async {
  _offset = 0;
  _hasMore = true;
  _errorMessage = null;
  // Opcional: _relatos.clear(); // Se quiser limpar visualmente antes

  await _fetchData(isRefresh: true);
 }

 /// Busca a próxima página de relatos (Scroll Infinito)
 Future<void> loadMore() async {
  if (_isLoadingMore || !_hasMore || _isLoading) return;
  await _fetchData(isRefresh: false);
 }

 Future<void> _fetchData({required bool isRefresh}) async {
  if (isRefresh) {
   _isLoading = true;
  } else {
   _isLoadingMore = true;
  }
  notifyListeners();

  try {
   final newRelatos = await _relatoService.getMyRelatos(
    offset: _offset,
    limit: _limit,
   );

   if (newRelatos.length < _limit) {
    _hasMore = false;
   }

   if (isRefresh) {
    _relatos = newRelatos;
   } else {
    _relatos.addAll(newRelatos);
   }

   _offset += newRelatos.length;

  } catch (e) {
   _errorMessage = 'Falha ao buscar relatos: ${e.toString().split("Exception:").last.trim()}';
  } finally {
   _isLoading = false;
   _isLoadingMore = false;
   notifyListeners();
  }
 }

 // =========================================================================
 // 3. DELEÇÃO (DELETE)
 // =========================================================================

 Future<void> deleteRelato(int id) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
   final String? error = await _relatoService.deleteRelato(id);

   if (error == null) {
    // Remove localmente para atualização instantânea
    _relatos.removeWhere((relato) => relato['id'] == id);
    _offset--; // Ajusta offset
    _errorMessage = 'Relato excluído com sucesso';
   } else {
    _errorMessage = 'Falha ao excluir o relato: $error';
   }
  } catch (e) {
   _errorMessage = 'Erro crítico ao deletar: ${e.toString().split("Exception:").last.trim()}';
  } finally {
   _isLoading = false;
   notifyListeners();
  }
 }

 // =========================================================================
 // 4. CRIAÇÃO (CREATE - Via formulário externo)
 // =========================================================================

 /// Adiciona um relato criado externamente (pelo RelatoFormController) e recarrega a lista.
 Future<void> addRelato(Map<String, dynamic> newRelatoData) async {
  // Nota: O RelatoFormController já faz o submitRelato.
  // Esse método aqui serve caso você queira centralizar a criação neste controller também.
  // Se usado, ele chama o service e depois atualiza a lista.
  _isLoading = true;
  notifyListeners();

  try {
   await _relatoService.submitRelato(data: newRelatoData);
   await fetchRelatos(); // Recarrega tudo para garantir ordem e consistência
   _errorMessage = 'Relato adicionado com sucesso!';
  } catch (e) {
   _errorMessage = 'Erro ao adicionar: $e';
  } finally {
   _isLoading = false;
   notifyListeners();
  }
 }

 // =========================================================================
 // 5. EDIÇÃO (UPDATE) - Lógica Completa
 // =========================================================================

 /// Prepara os controllers com os dados existentes.
 void initializeEdit(int relatoId, Map<String, dynamic> initialData) {
  _editingRelatoId = relatoId;
  _requiredInitialData = initialData;

  objRoubadoController.text = initialData['obj_roubado']?.toString() ?? '';
  descricaoController.text = initialData['descricao']?.toString() ?? '';
  localController.text = initialData['local']?.toString() ?? '';

  // Tratamento seguro para Lat/Lng
  latitudeController.text = (initialData['latitude'] != null && initialData['latitude'] != 0.0)
      ? initialData['latitude'].toString()
      : '';
  longitudeController.text = (initialData['longitude'] != null && initialData['longitude'] != 0.0)
      ? initialData['longitude'].toString()
      : '';

  // Extrai a foto existente (se houver)
  _existingPhotoUrl = null;
  if (initialData['fotos'] is List && (initialData['fotos'] as List).isNotEmpty) {
   _existingPhotoUrl = initialData['fotos'][0]['url']?.toString();
  }

  // Reseta estados temporários
  _selectedImage = null;
  _shouldDeleteImage = false;
  _errorMessage = null;
 }

 /// Salva alterações (Texto + Foto + Deleção de Foto).
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
   // A. DELEÇÃO DA FOTO (Se solicitado)
   if (_shouldDeleteImage) {
    final deleteError = await _relatoService.deleteFotoParaRelato(_editingRelatoId!);
    if (deleteError != null) {
     photoError = "Falha ao deletar foto: $deleteError";
    } else {
     _shouldDeleteImage = false;
     _existingPhotoUrl = null;
    }
   }

   // B. UPLOAD DA FOTO (Se nova imagem selecionada)
   if (photoError == null && _selectedImage != null) {
    photoError = await _relatoService.uploadFotoParaRelato(
     relatoId: _editingRelatoId!,
     image: _selectedImage!,
    );
   }

   if (photoError != null) {
    _errorMessage = "Erro na Foto: $photoError";
    // Não retornamos imediatamente; tentamos salvar o texto mesmo assim.
   }

   // C. ATUALIZAÇÃO DE DADOS TEXTUAIS (PUT)
   final updatedData = {
    // Permite vazio no objeto roubado
    "obj_roubado": objRoubadoController.text.isEmpty ? "" : objRoubadoController.text,
    "descricao": descricaoController.text,
    "local": localController.text,
    "latitude": double.tryParse(latitudeController.text) ?? 0.0,
    "longitude": double.tryParse(longitudeController.text) ?? 0.0,

    // Mantém dados originais imutáveis
    "data_furto": _requiredInitialData!['data_furto'],
    "data_registro": _requiredInitialData!['data_registro'],
    "categoria_id": _requiredInitialData!['categoria_id'],
   };

   dataError = await _relatoService.updateRelato(
    relatoId: _editingRelatoId!,
    data: updatedData,
   );

   if (dataError != null) {
    _errorMessage = "Falha ao atualizar dados: $dataError";
    return;
   }

   // D. FEEDBACK FINAL
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
 // 6. GERENCIAMENTO DE IMAGEM LOCAL
 // =========================================================================

 Future<void> pickImage() async {
  try {
   final XFile? pickedFile = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 80,
   );

   if (pickedFile != null) {
    _selectedImage = pickedFile;
    // Se selecionar nova imagem, cancela a deleção da antiga (pois será substituída ou adicionada)
    _shouldDeleteImage = false;
    _errorMessage = 'Imagem selecionada! Clique em SALVAR para enviar.';
   }
  } catch (e) {
   _errorMessage = 'Erro ao selecionar imagem: $e';
  }
  notifyListeners();
 }

 void removeImage() {
  // 1. Se tem uma imagem LOCAL selecionada -> Remove a seleção
  if (_selectedImage != null) {
   _selectedImage = null;
   _errorMessage = 'Seleção de imagem desfeita.';
  }
  // 2. Se tem uma imagem NO SERVIDOR -> Marca para deletar
  else if (_existingPhotoUrl != null && !_shouldDeleteImage) {
   _shouldDeleteImage = true;
   _errorMessage = 'Foto marcada para remoção. Clique em SALVAR para confirmar.';
  }
  // 3. Se já estava marcada para deletar -> Desmarca (Undo)
  else if (_shouldDeleteImage) {
   _shouldDeleteImage = false;
   _errorMessage = 'Remoção de foto cancelada.';
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