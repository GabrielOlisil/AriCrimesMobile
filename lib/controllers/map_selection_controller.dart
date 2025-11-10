import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Gerencia o estado e a lógica de negócios da [MapSelectionView].
class MapSelectionController extends ChangeNotifier {
  
  // --- Estado ---
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};

  // --- Getters Públicos (para a View) ---
  LatLng? get selectedLocation => _selectedLocation;
  Set<Marker> get markers => _markers;

  // =Ações (chamadas pela View) ==============================================

  /// Chamado quando o usuário toca no mapa.
  /// Atualiza a localização e o marcador.
  void onMapTap(LatLng position) {
    _selectedLocation = position;
    
    // Remove o marcador anterior e adiciona um novo
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected-location'),
        position: position,
        infoWindow: const InfoWindow(title: 'Local Selecionado'),
      ),
    );
    
    // Notifica a View (ListenableBuilder) que o estado mudou
    notifyListeners();
  }

  /// Confirma a seleção e retorna para a tela anterior.
  void confirmSelection(BuildContext context) {
    if (_selectedLocation != null) {
      // Retorna o LatLng selecionado para a tela anterior
      Navigator.pop(context, _selectedLocation);
    } else {
      // Exibe uma mensagem de erro se nada foi selecionado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, toque no mapa para selecionar um local.'),
        ),
      );
    }
  }
}