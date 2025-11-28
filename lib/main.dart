// lib/main.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:o_auth2/auth/auth_provider.dart';
import 'package:o_auth2/auth/dio_interceptor.dart';
import 'package:o_auth2/components/authenticated_body.dart';
import 'package:o_auth2/components/unauthenticated_body.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyAuthProvider()),
        Provider<Dio>(
          create: (context) {
            // Cria a instância base do Dio
            final dio = Dio(BaseOptions(baseUrl: 'https://aricrimes-api.gabiruka.duckdns.org/', ));

            // Lê o MyAuthProvider (que já foi criado, pois está acima na lista)
            // context.read() não faz o widget ouvir mudanças, é o ideal aqui.
            final authProvider = context.read<MyAuthProvider>();

            // Cria e adiciona o interceptor (agora sem passar 'dio')
            final interceptor = DioAuthInterceptor(authProvider);
            dio.interceptors.add(interceptor);

            // Retorna o Dio pronto e configurado
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
            controller ??= RelatoManagerController(relatoService: relatoService);
            // Se desejar, poderia expor um método para atualizar a instância interna do service.
            // Aqui recriamos o controller se for nulo, caso contrário você pode atualizar campos se necessário.
            return controller;
          },
        ),
      ],
      child: MyApp(),
    ),
  );
}

/// O Widget Raiz do aplicativo.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<MyAuthProvider>(context, listen: true).user;

    if (user == null) {
      return Scaffold(body: UnauthenticatedBody());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AuthenticatedBody(user: user),
    );
  }
}
