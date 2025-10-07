import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:o_auth2/auth/auth_provider.dart';
import 'package:o_auth2/models/CircleData.dart';
import 'package:o_auth2/models/user.dart';
import 'package:provider/provider.dart';

class AuthenticatedBody extends StatefulWidget {
  final AuthUser user;

  const AuthenticatedBody({super.key, required this.user});

  @override
  State<AuthenticatedBody> createState() => _AuthenticatedBodyState();
}

class _AuthenticatedBodyState extends State<AuthenticatedBody> {
  late AuthUser _user;

  final Set<Circle> _circles = {};


  Future<void> _handleSignOut() async {
    await Provider.of<MyAuthProvider>(context, listen: false).signOut();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _user = widget.user;
    _buildCircles();

  }

  void _buildCircles() {
    // Exemplo de lista de dados. Você receberá isso de uma API, banco de dados, etc.
    final List<CircleData> circlesData = [
      CircleData(id: "ponto_central", latitude: -9.91375, longitude: -63.044, radius: 500),
      CircleData(id: "ponto_vizinho_1", latitude: -9.91800, longitude: -63.050, radius: 300),
      CircleData(id: "ponto_vizinho_2", latitude: -9.91000, longitude: -63.038, radius: 250),
    ];

    // Converte cada item da sua lista para um widget Circle
    for (final circle in circlesData) {
      _circles.add(
        Circle(
          circleId: CircleId(circle.id),
          center: LatLng(circle.latitude, circle.longitude),
          radius: circle.radius, // O raio é em metros
          fillColor: Colors.red.withOpacity(0.3), // Cor de preenchimento
          strokeWidth: 2, // Largura da borda
          strokeColor: Colors.red, // Cor da borda
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    const LatLng initialPosition = LatLng(-9.91375, -63.044);

    return Stack(
      children: [
        // O mapa ocupa toda a tela
         GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14,
          ),
          circles: _circles,

          zoomControlsEnabled:
              false, // Controles de zoom desabilitados para um visual mais limpo
        ),

        // NOVO: Card de informações do usuário na parte superior
        Positioned(
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
                      // Foto de perfil do usuário
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: CachedNetworkImageProvider(
                          _user.picture ?? '',
                        ),

                        onBackgroundImageError:
                            (_, __) {}, // Lida com caso de foto nula
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user.name ?? 'Nome não disponível',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _user.email ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Ícone de logout
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        onPressed: _handleSignOut,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {}, //_takesInformation,
                      child: const Text('Verificar Token com Backend'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
