// map_selection_controller.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSelectionController extends ChangeNotifier {
  LatLng? selectedLocation;
  Set<Marker> markers = {};

  /// Chamado quando o usuário toca no mapa.
  void onMapTap(LatLng position) {
    selectedLocation = position;

    markers = {
      Marker(
        markerId: const MarkerId('selected-location'),
        position: position,
      ),
    };

    notifyListeners();
  }

  /// Confirma a seleção e retorna o LatLng para a tela anterior.
  void confirmSelection(BuildContext context) {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um local no mapa.')),
      );
      return;
    }

    // 🔥 ESSA LINHA É QUE FALTAVA E QUE FAZ TUDO FUNCIONAR!
    Navigator.pop(context, selectedLocation);
  }
}
