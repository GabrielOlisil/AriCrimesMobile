import 'dart:convert';


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 1. IMPORTE APENAS O PACOTE PADRÃO.
// As classes 'Heatmap' e 'WeightedLatLng' ESTÃO AQUI.
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:o_auth2/auth/auth_provider.dart';
import 'package:o_auth2/components/relato_form.dart';

// import 'package:o_auth2/models/CircleData.dart'; // Não é mais necessário
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

  // 2. MUDE O ESTADO PARA 'Set<Heatmap>'
  Set<Heatmap> _heatmaps = {};

  Future<void> _handleSignOut() async {
    await Provider.of<MyAuthProvider>(context, listen: false).signOut();
  }

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _buildHeatmap();
  }

  // 4. LÓGICA DE CONSTRUÇÃO DO HEATMAP
  void _buildHeatmap() {
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

      // A lista de pontos que o Heatmap precisa
      final List<WeightedLatLng> heatmapPoints = [];

      // Usamos apenas os 'points' do seu JSON.
      // O frontend fará o trabalho de "borrar" (blur)
      if (resData.containsKey("points")) {
        for (var i in resData["points"]!) {
          // O seu JSON tem 'lat' e 'long'
          heatmapPoints.add(
            // Use o construtor correto com o parâmetro 'point'
            WeightedLatLng(
              LatLng(i['lat'], i['long']),
              weight: 1.0, // Peso 1 para cada relato
            ),
          );
        }
      }

      if (heatmapPoints.isEmpty) {
        setState(() {
          _heatmaps = {};
        });
        return;
      }

      // Criamos o objeto Heatmap (que é nativo do google_maps_flutter)
      final heatmap = Heatmap(
        heatmapId: HeatmapId('crime_heatmap'),
        data: heatmapPoints,
        radius: HeatmapRadius.fromPixels(70),
        // Raio de influência (blur) em pixels. Ajuste este valor.
        opacity: 0.8,
        gradient: HeatmapGradient(
          // O gradiente de cores
          <HeatmapGradientColor>[
            HeatmapGradientColor(Colors.green, 0.2),
            HeatmapGradientColor(Colors.yellow, 0.2),
            HeatmapGradientColor(Colors.red, 0.2),
          ],
        ),
      );

      // Chamamos setState UMA VEZ com o resultado final
      print(_heatmaps);
      setState(() {
        _heatmaps = {heatmap};
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
        // 3. ATUALIZAR O GOOGLE MAP
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14,
          ),
          // AQUI ESTÁ A MUDANÇA: Use a propriedade 'heatmaps'
          heatmaps: _heatmaps,

          // 'circles: _circles' não é mais necessário
          zoomControlsEnabled: false,
        ),

        // O seu card de usuário (não mudei nada aqui)
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
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: CachedNetworkImageProvider(
                          _user.picture ?? '',
                        ),
                        onBackgroundImageError: (_, __) {},
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