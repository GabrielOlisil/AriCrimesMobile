import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:o_auth2/Auth/auth_provider.dart';
import 'package:provider/provider.dart';

class AuthenticatedBody extends StatefulWidget {
  final User user;

  const AuthenticatedBody({super.key, required this.user});

  @override
  State<AuthenticatedBody> createState() => _AuthenticatedBodyState();
}

class _AuthenticatedBodyState extends State<AuthenticatedBody> {
  late User _user;

  Future<void> _handleSignOut() async {
    await Provider.of<MyAuthProvider>(context, listen: false).signOut();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    const LatLng initialPosition = LatLng(-9.91375, -63.044);

    return Stack(
      children: [
        // O mapa ocupa toda a tela
        const GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14,
          ),
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
                        backgroundImage: NetworkImage(_user.photoURL ?? ''),
                        onBackgroundImageError:
                            (_, __) {}, // Lida com caso de foto nula
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user.displayName ?? 'Nome não disponível',
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
