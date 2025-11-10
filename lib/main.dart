import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:o_auth2/auth/auth_provider.dart';
import 'package:o_auth2/services/dio_interceptor.dart';
import 'package:o_auth2/views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // --- Provedor de Serviço de Autenticação ---
        ChangeNotifierProvider(create: (context) => MyAuthProvider()),

        // --- Provedor do Cliente HTTP (Dio) ---
        // Configura o Dio para ser acessível em todo o app via context.read<Dio>()
        Provider<Dio>(
          create: (context) {
            // URL base da API
            final dio = Dio(
              BaseOptions(
                baseUrl: 'https://aricrimes-api.gabiruka.duckdns.org/',
              ),
            );

            // Pega o AuthProvider (que já foi criado acima)
            // context.read() é usado aqui pois só precisamos do valor,
            // não de "ouvir" mudanças.
            final authProvider = context.read<MyAuthProvider>();

            // Adiciona o Interceptor, que injetará o token Bearer
            // e tratará erros 401 (token expirado) automaticamente.
            final interceptor = DioAuthInterceptor(authProvider);
            dio.interceptors.add(interceptor);

            return dio;
          },
          // Garante que a conexão do Dio seja fechada quando o provider for removido
          dispose: (_, dio) => dio.close(),
        ),
      ],
      // O 'child' do MultiProvider é o app
      child: const MyApp(),
    ),
  );
}

/// O Widget Raiz do aplicativo.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // 3. PONTO DE ENTRADA DAS VIEWS
      // O app agora aponta para a 'HomeView' (antiga HomePage).
      home: HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
