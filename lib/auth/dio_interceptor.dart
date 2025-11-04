import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:o_auth2/auth/auth_provider.dart';

class DioAuthInterceptor extends Interceptor {
  final MyAuthProvider authProvider;


  DioAuthInterceptor(this.authProvider );

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {

    if (authProvider.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${authProvider.accessToken}';
    }

    options.headers['Accept'] = "application/json";

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      log('Recebido 401. Tentando atualizar o token...');

      try {
        final bool refreshSuccess = await authProvider.refreshToken();

        if (refreshSuccess) {
          log('Token atualizado. Re-enviando request original...');

          // 2. Atualize o header na requisição original que falhou
          err.requestOptions.headers['Authorization'] =
          'Bearer ${authProvider.accessToken}';

          // 3. Crie uma NOVA instância de Dio (limpa, sem interceptors)
          //    e re-execute a requisição original (agora com o token novo).
          try {
            // Usa a nova instância Dio()
            final response = await Dio().fetch(err.requestOptions);
            // Resolve com a resposta da nova tentativa
            return handler.resolve(response);
          } catch (e) {
            // A nova tentativa também falhou (ex: 500, ou 401 de novo)
            log('Erro na nova tentativa após refresh: $e');
            // Encaminha o NOVO erro
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