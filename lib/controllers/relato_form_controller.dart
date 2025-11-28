// lib/controllers/relato_form_controller.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../services/relato_service.dart';
import '../services/location_service.dart';
import '../views/map_selection_view.dart';
import '../views/relato_edit_view.dart';

class RelatoFormController extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // DEPENDÊNCIAS
  // ---------------------------------------------------------------------------
  final RelatoService _relatoService;
  final LocationService _locationService;

  // ---------------------------------------------------------------------------
  // CONTROLLERS DE FORMULÁRIO
  // ---------------------------------------------------------------------------
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController objRoubadoController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController localController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  // ---------------------------------------------------------------------------
  // ESTADOS INTERNOS
  // ---------------------------------------------------------------------------
  XFile? _selectedImage;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  String? _feedbackMessage;

  XFile? get selectedImage => _selectedImage;
  LatLng? get selectedLocation => _selectedLocation;
  bool get isLoading => _isLoading;
  String? get feedbackMessage => _feedbackMessage;

  final ImagePicker _picker = ImagePicker();

  RelatoFormController({
    required RelatoService relatoService,
    required LocationService locationService,
  })  : _relatoService = relatoService,
        _locationService = locationService;

  @override
  void dispose() {
    objRoubadoController.dispose();
    descricaoController.dispose();
    localController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SELEÇÃO DE LOCAL NO MAPA
  // ---------------------------------------------------------------------------
  Future<void> selectLocation(BuildContext context) async {
    final LatLng? result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MapSelectionView()),
    );

    if (result != null) {
      _selectedLocation = result;

      latitudeController.text = result.latitude.toStringAsFixed(6);
      longitudeController.text = result.longitude.toStringAsFixed(6);

      // >>> GEOCODIFICAÇÃO REVERSA (CORRETA)
      final address = await _locationService.getAddressFromLatLng(
        result.latitude,
        result.longitude,
      );

      localController.text = address ?? "Endereço não encontrado";

      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGEM
  // ---------------------------------------------------------------------------
  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      _selectedImage = pickedFile;
      notifyListeners();
    } catch (e) {
      _feedbackMessage = 'Erro ao selecionar imagem: $e';
      notifyListeners();
    }
  }

  void removeImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ENVIO DO RELATO (ETAPA 1)
  // ---------------------------------------------------------------------------
  Future<void> submitRelato(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      _feedbackMessage = "Por favor, selecione a Localização no Mapa.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _feedbackMessage = null;
    notifyListeners();

    final dataMap = {
      "obj_roubado": objRoubadoController.text,
      "descricao": descricaoController.text,
      "local": localController.text.isEmpty
          ? 'Local não especificado'
          : localController.text,
      "latitude": _selectedLocation!.latitude,
      "longitude": _selectedLocation!.longitude,
      "data_furto": DateTime.now().toIso8601String(),
      "data_registro": DateTime.now().toIso8601String(),
      "categoria_id": 1,
    };

    final initialDataForEdit = Map<String, dynamic>.from(dataMap);

    try {
      final String reportId = await _relatoService.submitRelato(data: dataMap);

      // --------------------------------------------------------------
      // 🚨 CORREÇÃO DO WARNING use_build_context_synchronously
      // --------------------------------------------------------------
      if (!context.mounted) return;

      _feedbackMessage =
          "Relato criado com sucesso (ID: $reportId). Redirecionando...";

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
      _feedbackMessage =
          "Falha ao criar relato: ${e.toString().split('Exception:').last.trim()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // RESET
  // ---------------------------------------------------------------------------
  void _resetForm() {
    formKey.currentState?.reset();
    objRoubadoController.clear();
    descricaoController.clear();
    localController.clear();
    latitudeController.clear();
    longitudeController.clear();
    _selectedImage = null;
    _selectedLocation = null;
  }
}
