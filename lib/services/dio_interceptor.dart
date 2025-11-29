import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:o_auth2/auth/auth_provider.dart';

// Mude de Interceptor para QueuedInterceptor
// O QueuedInterceptor garante que as requisições sejam processadas em série,
// evitando que múltiplos refreshes ocorram ao mesmo tempo.
class DioAuthInterceptor extends QueuedInterceptor {
  final MyAuthProvider authProvider;
  final Dio dio;

  DioAuthInterceptor(this.authProvider, this.dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) {
    if (authProvider.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${authProvider.accessToken}';
    }
    options.headers['Accept'] = "application/json";
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Verifica se é 401
    if (err.response?.statusCode == 401) {

      // PROTEÇÃO CONTRA LOOP INFINITO:
      // Verifica se essa requisição já foi retentada anteriormente.
      // Usamos 'extra' para marcar a requisição.
      if (err.requestOptions.extra['retried'] == true) {
        log('Loop detectado: Requisição já foi retentada e falhou novamente.');
        return handler.next(err);
      }

      log('Recebido 401. Tentando atualizar o token...');

      try {
        // Como estamos num QueuedInterceptor, outras requisições ficarão
        // paradas na fila "atrás" desta até que o handler.resolve ou handler.next seja chamado.
        final bool refreshSuccess = await authProvider.refreshToken();

        if (refreshSuccess) {
          log('Token atualizado. Re-enviando request original...');

          // Atualiza o header com o NOVO token
          err.requestOptions.headers['Authorization'] =
          'Bearer ${authProvider.accessToken}';

          // Marca que estamos retentando para evitar loops
          err.requestOptions.extra['retried'] = true;

          try {
            // Refaz a requisição
            final response = await dio.fetch(err.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            // Se falhar na nova tentativa, repassa o erro (pode ser um DioException novo)
            return handler.next(e is DioException ? e : err);
          }
        } else {
          log('Falha no refresh. Encaminhando erro original.');
          return handler.next(err);
        }
      } catch (e) {
        log('Erro inesperado no interceptor: $e');
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}