import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:o_auth2/controllers/map_selection_controller.dart';

/// Tela para seleção de uma coordenada [LatLng] no mapa.
class MapSelectionView extends StatefulWidget {
  const MapSelectionView({super.key});

  @override
  State<MapSelectionView> createState() => _MapSelectionViewState();
}

class _MapSelectionViewState extends State<MapSelectionView> {
  // 2. REFERÊNCIA AO CONTROLLER
  late final MapSelectionController _controller;

  // Posição inicial da câmera (constante, não é estado)
  static const LatLng _initialCameraPosition =
      LatLng(-9.9087, -63.0378); // Ariquemes, RO

  @override
  void initState() {
    super.initState();
    // 3. INICIALIZAÇÃO DO CONTROLLER
    // Como este controller não tem dependências de Service,
    // podemos simplesmente instanciá-lo.
    _controller = MapSelectionController();
  }

  @override
  void dispose() {
    // 4. DISPOSE
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Localização'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            // 5. AÇÃO DELEGADA AO CONTROLLER
            onPressed: () => _controller.confirmSelection(context),
          ),
        ],
      ),
      // 6. OUVINTE DE ESTADO
      // Ouve o controller e reconstrói a UI quando o estado muda
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _initialCameraPosition,
                  zoom: 12,
                ),
                mapType: MapType.normal,
                // 5. AÇÃO DELEGADA AO CONTROLLER
                onTap: _controller.onMapTap,
                // 7. DADOS VINDOS DO CONTROLLER
                markers: _controller.markers,
                myLocationEnabled: true,
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.location_on),
                  label: Text(
                    // 7. DADOS VINDOS DO CONTROLLER
                    _controller.selectedLocation == null
                        ? 'Toque no mapa para selecionar um local'
                        : 'Confirmar Local Selecionado (${_controller.selectedLocation!.latitude.toStringAsFixed(4)}, ${_controller.selectedLocation!.longitude.toStringAsFixed(4)})',
                    textAlign: TextAlign.center,
                  ),
                  // 5. AÇÃO DELEGADA AO CONTROLLER
                  onPressed: () => _controller.confirmSelection(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}