import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:o_auth2/services/relato_service.dart';
import 'package:o_auth2/views/map_selection_view.dart'; // Import da futura view

/// [CONTROLLER]
/// Gerencia o estado e a lógica de negócios da [RelatoFormView].
class RelatoFormController extends ChangeNotifier {
  
  // --- Dependências ---
  final RelatoService _relatoService;

  // --- Estado do Formulário ---
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // 1. CONTROLADORES DE TEXTO
  // Substituímos as variáveis de String por TextControllers.
  // A View vai usá-los, e o Controller lerá os valores.
  final TextEditingController objRoubadoController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController localController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  
  // --- Estado da UI ---
  XFile? _selectedImage;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  String? _feedbackMessage;

  // --- Getters Públicos (para a View) ---
  XFile? get selectedImage => _selectedImage;
  LatLng? get selectedLocation => _selectedLocation;
  bool get isLoading => _isLoading;
  String? get feedbackMessage => _feedbackMessage;

  // Instância do ImagePicker (privada)
  final ImagePicker _picker = ImagePicker();

  // --- Construtor ---
  RelatoFormController({required RelatoService relatoService})
      : _relatoService = relatoService;

  // 2. LIMPEZA DE MEMÓRIA
  // É crucial dar dispose() nos Controllers para evitar memory leaks.
  @override
  void dispose() {
    objRoubadoController.dispose();
    descricaoController.dispose();
    localController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  // =========================================================================
  // Lógica de Negócios (Métodos chamados pela View)
  // =========================================================================

  /// Navega para a tela de seleção de mapa.
  Future<void> selectLocation(BuildContext context) async {
    final LatLng? result = await Navigator.of(context).push(
      MaterialPageRoute(
        // TODO: Mudar 'MapSelectionScreen' para 'MapSelectionView'
        builder: (context) => const MapSelectionView(),
      ),
    );

    if (result != null) {
      _selectedLocation = result;
      // 3. ATUALIZA OS CONTROLLERS
      // Atualiza os TextControllers que a View está ouvindo.
      localController.text =
          'Local Selecionado (${result.latitude.toStringAsFixed(3)}, ${result.longitude.toStringAsFixed(3)})';
      latitudeController.text = result.latitude.toStringAsFixed(6);
      longitudeController.text = result.longitude.toStringAsFixed(6);

      // Notifica a View que o estado mudou
      notifyListeners();

      // Feedback para o usuário
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Localização selecionada: Lat ${result.latitude.toStringAsFixed(4)}, Lon ${result.longitude.toStringAsFixed(4)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Seleciona uma imagem da galeria.
  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      _selectedImage = pickedFile;
      _feedbackMessage =
          pickedFile != null ? 'Imagem selecionada!' : 'Seleção cancelada.';
    } catch (e) {
      _feedbackMessage = 'Erro ao selecionar imagem: $e';
    }
    notifyListeners();
  }

  /// Remove a imagem selecionada.
  void removeImage() {
    _selectedImage = null;
    _feedbackMessage = 'Imagem removida.';
    notifyListeners();
  }

  /// Valida o formulário e envia o relato.
  Future<void> submitRelato() async {
    // 1. Validação do Form (campos de texto)
    if (!formKey.currentState!.validate()) {
      return;
    }

    // 2. Validação da Localização (lógica do Controller)
    if (_selectedLocation == null) {
      _feedbackMessage = "Por favor, selecione a Localização no Mapa.";
      notifyListeners();
      return;
    }

    // 3. Inicia o Loading
    _isLoading = true;
    _feedbackMessage = null;
    notifyListeners();

    // 4. Prepara os dados para o Serviço
    // (O 'formKey.currentState!.save()' não é mais necessário
    // pois estamos usando TextControllers)
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
      "categoria_id": 1, // 'categoriaId' estava fixo em 1 no original
    };

    // 5. Chama o Serviço
    final String? errorMessage = await _relatoService.submitRelato(
      data: dataMap,
      image: _selectedImage, // Passa a imagem para o serviço
    );

    // 6. Finaliza o Loading
    _isLoading = false;

    // 7. Trata a Resposta
    if (errorMessage == null) {
      // Sucesso
      _feedbackMessage = "Relato enviado com sucesso!";
      _resetForm();
    } else {
      // Falha
      _feedbackMessage = errorMessage;
    }
    notifyListeners();
  }

  /// Limpa o formulário após o envio.
  void _resetForm() {
    formKey.currentState?.reset();
    objRoubadoController.clear();
    descricaoController.clear();
    localController.clear();
    latitudeController.clear();
    longitudeController.clear();
    _selectedImage = null;
    _selectedLocation = null;
    // (o feedbackMessage já foi setado, não limpar)
  }
}