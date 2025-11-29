import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:o_auth2/auth/auth_provider.dart';
import 'package:o_auth2/models/user.dart';
import 'package:o_auth2/services/map_service.dart';
import 'package:o_auth2/controllers/map_controller.dart';

/// Tela principal (Mapa) exibida quando o usuário está autenticado.
///
/// Esta View é um [StatefulWidget] apenas para poder inicializar
/// o [MapController] no [initState].
/// Ela usa um [ListenableBuilder] para ouvir as mudanças do Controller
/// e reconstruir a UI quando o estado (heatmaps, isLoading) mudar.
class MapView extends StatefulWidget {
  final AuthUser user;
  const MapView({super.key, required this.user});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // 2. REFERÊNCIA AO CONTROLLER
  // O Controller agora é quem guarda o estado.
  late final MapController _controller;

  @override
  void initState() {
    super.initState();

    // 3. INJEÇÃO DE DEPENDÊNCIA MANUAL
    // No initState, pegamos as dependências (Dio, AuthProvider)
    // que foram injetadas no main.dart...
    final dio = context.read<Dio>();
    final authProvider = context.read<MyAuthProvider>();

    // ...criamos o Service...
    final mapService = MapService(dio: dio);

    // ...e finalmente criamos o Controller, passando suas dependências.
    _controller = MapController(
      mapService: mapService,
      authProvider: authProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    const LatLng initialPosition = LatLng(-9.91375, -63.044);

    // 4. OUVINTE DE ESTADO
    // O ListenableBuilder "ouve" o _controller (que é um ChangeNotifier)
    // e reconstrói seu 'builder' toda vez que _controller.notifyListeners() é chamado.
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        // 5. A UI REAGE AO ESTADO DO CONTROLLER
        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: initialPosition,
                zoom: 14,
              ),
              // Os heatmaps vêm direto do Controller
              heatmaps: _controller.heatmaps,
              zoomControlsEnabled: false,
            ),

            // O card de usuário (passando o 'widget.user' original)
            _buildUserCard(context, widget.user),

            // 6. FEEDBACK DE LOADING
            // Mostra um indicador de progresso enquanto o Controller carrega
            if (_controller.isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        );
      },
    );
  }

  /// Widget privado para construir o Card de Usuário.
  /// (Movido para um método separado para organizar o 'build').
  Widget _buildUserCard(BuildContext context, AuthUser user) {
    return Positioned(
      top: 50.0,
      left: 15.0,
      right: 15.0,
      child: Card(
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: CachedNetworkImageProvider(
                      user.picture ?? '',
                      cacheKey: user.email,
                      headers: const {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                        'Referer': 'https://www.google.com/',
                      },
                    ),
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? 'Nome não disponível',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 7. AÇÕES DELEGADAS AO CONTROLLER
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: _controller.signOut, // Chama o Controller
                  ),
                  IconButton(
                    onPressed: () => _controller.copyTokenToClipboard(context),
                    icon: const Icon(Icons.copy_all),
                  ),
                ],
              ),
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // 7. AÇÕES DELEGADAS AO CONTROLLER
                  onPressed: () => _controller.navigateToRelatoForm(context),
                  child: const Text('Registrar novo furto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}