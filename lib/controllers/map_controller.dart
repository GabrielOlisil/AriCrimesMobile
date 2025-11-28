import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:o_auth2/views/relato_form_view.dart';
import 'package:o_auth2/services/map_service.dart';
import 'package:o_auth2/auth/auth_provider.dart';

/// [CONTROLLER]
/// Gerencia o estado e a lógica de negócios da [MapView].
class MapController extends ChangeNotifier {
  // --- Dependências ---
  final MapService _mapService;
  final MyAuthProvider _authProvider;

  // --- Estado ---
  Set<Heatmap> _heatmaps = {};
  bool _isLoading = true;

  // --- Getters Públicos (para a View) ---
  Set<Heatmap> get heatmaps => _heatmaps;
  bool get isLoading => _isLoading;

  // --- Construtor ---
  MapController({
    required MapService mapService,
    required MyAuthProvider authProvider,
  })  : _mapService = mapService,
        _authProvider = authProvider {
    // Ao ser criado, já inicia a busca pelos dados
    loadHeatmap();
  }

  // =========================================================================
  // Lógica de Negócios
  // =========================================================================

  /// Busca os dados do heatmap usando o serviço e notifica a View.
  Future<void> loadHeatmap() async {
    _isLoading = true;
    notifyListeners(); // Notifica a View que estamos carregando

    _heatmaps = await _mapService.fetchHeatmapData();

    _isLoading = false;
    notifyListeners(); // Notifica a View com os novos dados (ou vazio)
  }

  /// Desloga o usuário.
  Future<void> signOut() async {
    await _authProvider.signOut();
  }

  /// Navega para a tela de registro de relato.
  void navigateToRelatoForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RelatoFormView(),
      ),
    );
  }

  /// Copia o token de acesso para a área de transferência.
  Future<void> copyTokenToClipboard(BuildContext context) async {
    final token = _authProvider.accessToken;
    if (token == null) return;

    await Clipboard.setData(ClipboardData(text: token));

    // Garante que o context ainda é válido antes de mostrar o SnackBar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("O token foi copiado para a área de transferência"),
        ),
      );
    }
  }
}