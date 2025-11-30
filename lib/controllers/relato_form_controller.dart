// lib/controllers/relato_form_controller.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../services/relato_service.dart';
import '../services/location_service.dart';
import '../views/map_selection_view.dart';
import '../views/relato_edit_view.dart';

class RelatoFormController extends ChangeNotifier {
  final RelatoService _relatoService;
  final LocationService _locationService;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController objRoubadoController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController localController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  // --- NOVOS ESTADOS ---
  XFile? _selectedImage;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  String? _feedbackMessage;

  // 1. Data do Furto (inicia com Agora, mas user pode mudar)
  DateTime _dataFurto = DateTime.now();

  // 2. Categoria Selecionada
  int? _selectedCategoryId;

  // --- GETTERS ---
  XFile? get selectedImage => _selectedImage;
  LatLng? get selectedLocation => _selectedLocation;
  bool get isLoading => _isLoading;
  String? get feedbackMessage => _feedbackMessage;
  DateTime get dataFurto => _dataFurto;
  int? get selectedCategoryId => _selectedCategoryId;

  final ImagePicker _picker = ImagePicker();

  RelatoFormController({
    required RelatoService relatoService,
    required LocationService locationService,
  })  : _relatoService = relatoService,
        _locationService = locationService;

  // --- SETTERS ---
  void setDataFurto(DateTime date) {
    _dataFurto = date;
    notifyListeners();
  }

  void setCategoria(int? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  // ... (dispose, selectLocation, pickImage, removeImage mantidos iguais) ...

  @override
  void dispose() {
    objRoubadoController.dispose();
    descricaoController.dispose();
    localController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<void> selectLocation(BuildContext context) async {
    final LatLng? result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MapSelectionView()),
    );

    if (result != null) {
      _selectedLocation = result;
      latitudeController.text = result.latitude.toStringAsFixed(6);
      longitudeController.text = result.longitude.toStringAsFixed(6);

      final address = await _locationService.getAddressFromLatLng(
        result.latitude,
        result.longitude,
      );
      localController.text = address ?? "Endereço não encontrado";
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    // ... (mantido igual ao anterior)
  }

  void removeImage() {
    // ... (mantido igual ao anterior)
  }

  // --- ENVIO DO RELATO ---
  Future<void> submitRelato(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      _feedbackMessage = "Por favor, selecione a Localização no Mapa.";
      notifyListeners();
      return;
    }

    if (_selectedCategoryId == null) {
      _feedbackMessage = "Por favor, selecione uma Categoria.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _feedbackMessage = null;
    notifyListeners();

    final dataMap = {
      // PERMITE VAZIO (envia string vazia se nulo)
      "obj_roubado": objRoubadoController.text.isEmpty ? "" : objRoubadoController.text,
      "descricao": descricaoController.text,
      "local": localController.text.isEmpty ? 'Local não especificado' : localController.text,
      "latitude": _selectedLocation!.latitude,
      "longitude": _selectedLocation!.longitude,

      // USA A DATA ESCOLHIDA PELO USUÁRIO
      "data_furto": _dataFurto.toIso8601String(),

      // DATA REGISTRO É SEMPRE AGORA
      "data_registro": DateTime.now().toIso8601String(),

      // USA A CATEGORIA SELECIONADA
      "categoria_id": _selectedCategoryId,
    };

    final initialDataForEdit = Map<String, dynamic>.from(dataMap);

    try {
      final String reportId = await _relatoService.submitRelato(data: dataMap);

      if (!context.mounted) return;

      _feedbackMessage = "Relato criado com sucesso (ID: $reportId). Redirecionando...";
      _resetForm();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RelatoEditView(
            relatoId: int.parse(reportId),
            initialData: initialDataForEdit,
          ),
        ),
      );
    } catch (e) {
      _feedbackMessage = "Falha ao criar relato: ${e.toString().split('Exception:').last.trim()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    formKey.currentState?.reset();
    objRoubadoController.clear();
    descricaoController.clear();
    localController.clear();
    latitudeController.clear();
    longitudeController.clear();
    _selectedImage = null;
    _selectedLocation = null;
    _dataFurto = DateTime.now(); // Reseta data
    _selectedCategoryId = null;  // Reseta categoria
  }
}