import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:o_auth2/controllers/category_controller.dart';
import 'package:provider/provider.dart';

// Auth
import 'package:o_auth2/auth/auth_provider.dart';
import 'package:o_auth2/services/dio_interceptor.dart';

// Services
import 'package:o_auth2/services/relato_service.dart';
import 'package:o_auth2/services/location_service.dart';

// Controllers
import 'package:o_auth2/controllers/relato_manager_controller.dart';
// ⭐️ ADICIONAR O NOVO CONTROLLER
import 'package:o_auth2/controllers/latest_relatos_controller.dart'; 

// Views
import 'package:o_auth2/views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // 1. Auth Provider
        ChangeNotifierProvider<MyAuthProvider>(create: (_) => MyAuthProvider()),

        // 2. Dio + interceptor (usa auth provider para adicionar o interceptor)
        Provider<Dio>(
          create: (context) {
            final dio = Dio(
              BaseOptions(
                baseUrl: 'https://aricrimes-api.gabiruka.duckdns.org/',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

            final auth = context.read<MyAuthProvider>();
            dio.interceptors.add(DioAuthInterceptor(auth, dio));

            return dio;
          },
          // Garante que a conexão do Dio seja fechada quando o provider for removido
          dispose: (_, dio) => dio.close(),
        ),

        // 3. RelatoService — criado via ProxyProvider para receber token atualizado
        ProxyProvider<MyAuthProvider, RelatoService>(
          update: (context, auth, previous) {
            return RelatoService(
              dio: context.read<Dio>(),
              token: auth.accessToken ?? '',
            );
          },
        ),

        // 4. LocationService — criado via ProxyProvider (pode receber googleApiKey se quiser)
        ProxyProvider<MyAuthProvider, LocationService>(
          update: (context, auth, previous) {
            return LocationService(
              dio: context.read<Dio>(),
              // Mantenha a chave por enquanto se quiser fallback para Google
              // Substitua por environnement var / dart-define quando pronto
              googleApiKey: '', // ex: 'SUA_GOOGLE_API_KEY_AQUI' ou ''
            );
          },
        ),

        // 5. RelatoManagerController — atualiza automaticamente quando RelatoService muda
        ChangeNotifierProxyProvider<RelatoService, RelatoManagerController>(
          create: (context) => RelatoManagerController(
            relatoService: context.read<RelatoService>(),
          ),
          update: (context, relatoService, controller) {
            controller ??= RelatoManagerController(
              relatoService: relatoService,
            );
            return controller;
          },
        ),

        // 6. ⭐️ NOVO: LatestRelatosController (Depende do RelatoService)
        ChangeNotifierProvider<LatestRelatosController>(
          create: (context) {
            // Usa context.read para pegar a instância do RelatoService que já foi criada
            final relatoService = context.read<RelatoService>(); 
            return LatestRelatosController(relatoService);
          },
        ),


        ChangeNotifierProvider<CategoryController>(
          create: (context) {
            final service = context.read<RelatoService>();
            final controller = CategoryController(service);

            // 🔥 O Pulo do Gato: Chama a API assim que o app nasce
            controller.loadCategorias();

            return controller;
          },
        ),
      ],
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
      home: HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}