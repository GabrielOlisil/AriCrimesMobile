import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:o_auth2/auth/auth_provider.dart';
import 'package:o_auth2/components/relato_form.dart';
import 'package:o_auth2/models/CircleData.dart';
import 'package:o_auth2/models/user.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class AuthenticatedBody extends StatefulWidget {
  final AuthUser user;

  const AuthenticatedBody({super.key, required this.user});

  @override
  State<AuthenticatedBody> createState() => _AuthenticatedBodyState();
}

class _AuthenticatedBodyState extends State<AuthenticatedBody> {
  late AuthUser _user;

  Set<Circle> _circles = {};

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
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    const duracaoParaSubtrair = Duration(days: 14);

    final lastTwoWeeks = today.subtract(duracaoParaSubtrair);

    final url = Uri.parse(
      'https://aricrimes-api.gabiruka.duckdns.org/heatmap?start_date=$lastTwoWeeks&end_date=$today&eps_km=0.5&min_samples=3',
    );
    http.get(url, headers: {"Accept": "application/json"}).then((response) {
      if (response.statusCode != 200) {
        return;
      }

      final resData = jsonDecode(response.body) as Map<String, dynamic>;

      final List<CircleData> circlesData = [];
      final List<CircleData> pointsData = [];

      if (resData.containsKey("circles")) {
        for (var i in resData["circles"]!) {
          print(i['latitude']);
          print(i['longitude']);
          print(i['radius_meters']);
          print(i['weight']);

          circlesData.add(
            CircleData(
              id: i.hashCode.toString(),
              latitude: i['latitude'],
              longitude: i['longitude'],
              radius: i['radius_meters'],
              weight: i['weight'],
            ),
          );
        }
      }

      if (resData.containsKey("points")) {
        for (var i in resData["points"]!) {
          pointsData.add(
            CircleData(
              id: i.hashCode.toString(),
              latitude: i['lat'],
              longitude: i['long'],
              radius: 30,
              weight: 1,
            ),
          );
        }
      }

      final Set<Circle> tempCircles = {};

      for (final circle in circlesData) {
        tempCircles.add(
          Circle(
            circleId: CircleId(circle.id),
            center: LatLng(circle.latitude, circle.longitude),
            radius: circle.radius,
            fillColor: Colors.red.withOpacity(0.3),
            strokeWidth: 2,
            strokeColor: Colors.red,
          ),
        );
      }

      for (final circle in pointsData) {
        tempCircles.add(
          Circle(
            circleId: CircleId(circle.id),
            center: LatLng(circle.latitude, circle.longitude),
            radius: circle.radius,
            fillColor: Color.fromARGB(255, 60, 20, 10),
            strokeWidth: 2,
            strokeColor: Colors.red,
          ),
        );
      }


      setState(() {
        _circles = tempCircles;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<MyAuthProvider>(
      context,
      listen: false,
    ).accessToken;

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
                      IconButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: token!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "O token foi copiado para a área de transferencia",
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_all),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RelatoForm(),
                          ),
                        );
                      },
                      child: const Text('Registrar novo furto'),
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
