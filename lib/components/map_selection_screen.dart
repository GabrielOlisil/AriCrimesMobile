// lib/map_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Para obter a localização inicial
import 'package:geocoding/geocoding.dart'; // Opcional: para buscar o endereço

class MapSelectionScreen extends StatefulWidget {
  // O construtor não precisa de nada por enquanto, mas se você quiser
  // passar uma localização inicial, pode adicionar aqui.
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  // Posição inicial da câmera do mapa.
  // Vamos usar uma coordenada de exemplo para Ariquemes, RO.
  static const LatLng _initialCameraPosition = LatLng(-9.9087, -63.0378); // Ariquemes, RO

  // Variável para armazenar a localização selecionada pelo usuário
  LatLng? _selectedLocation;

  // Conjunto de marcadores no mapa (vamos ter apenas um: o local selecionado)
  final Set<Marker> _markers = {};

  // Método chamado quando o usuário toca no mapa
  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      // Remove o marcador anterior e adiciona um novo no local tocado
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected-location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Local Selecionado'),
        ),
      );
    });
  }

  // Método para retornar a localização selecionada para a tela anterior
  void _selectLocation() {
    if (_selectedLocation != null) {
      // Usa Navigator.pop para retornar para a tela anterior,
      // passando o valor da localização selecionada.
      Navigator.pop(context, _selectedLocation);
    } else {
      // Exibe uma mensagem se nenhum local foi selecionado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, toque no mapa para selecionar um local.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Localização'),
        actions: [
          // Botão para confirmar a seleção
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Widget principal do Google Maps
          GoogleMap(
            // **IMPORTANTE**: Certifique-se de que sua chave de API
            // está configurada corretamente nos arquivos nativos.
            initialCameraPosition: const CameraPosition(
              target: _initialCameraPosition,
              zoom: 12,
            ),
            mapType: MapType.normal,
            onTap: _onMapTap, // Chama a função de seleção ao tocar no mapa
            markers: _markers, // Exibe o marcador do local selecionado
            myLocationEnabled: true, // Habilita o ponto azul de localização
          ),
          // Um botão flutuante também pode ser usado para confirmar a seleção
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.location_on),
              label: Text(
                _selectedLocation == null
                    ? 'Toque no mapa para selecionar um local'
                    : 'Confirmar Local Selecionado (${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)})',
                textAlign: TextAlign.center,
              ),
              onPressed: _selectLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}