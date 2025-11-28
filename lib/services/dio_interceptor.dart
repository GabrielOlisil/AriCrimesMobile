import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:o_auth2/auth/auth_provider.dart';

/// Interceptor do Dio para lidar com autenticação de forma automática.
class DioAuthInterceptor extends Interceptor {
  final MyAuthProvider authProvider;
  final Dio dio; // Armazena a instância principal do Dio para repetição de requisição

  // Construtor agora aceita a instância do Dio (alinhado com main.dart)
  DioAuthInterceptor(this.authProvider, this.dio);

  // =========================================================================
  // onRequest (Antes da Requisição)
  // =========================================================================
  /// Chamado ANTES de cada requisição ser enviada.
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Adiciona o token de acesso (Bearer token) no header
    if (authProvider.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${authProvider.accessToken}';
    }

    // 2. Define o header 'Accept' (essencial para a API)
    options.headers['Accept'] = "application/json";

    // 3. Continua com a requisição
    return handler.next(options);
  }

  // =========================================================================
  // onError (Após um Erro)
  // =========================================================================
  /// Chamado QUANDO uma requisição falha.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 1. Verifica se o erro foi '401 Unauthorized'
    if (err.response?.statusCode == 401) {
      log('Recebido 401. Tentando atualizar o token...');

      try {
        // 2. Tenta atualizar o token usando o AuthProvider
        final bool refreshSuccess = await authProvider.refreshToken();

        if (refreshSuccess) {
          log('Token atualizado. Re-enviando request original...');

          // 3. Atualiza o header na requisição original que falhou
          err.requestOptions.headers['Authorization'] =
              'Bearer ${authProvider.accessToken}';

          // 4. Tenta refazer a requisição original (agora com o token novo)
          try {
            // CORREÇÃO: Usamos a instância original 'this.dio' 
            // e não uma nova 'Dio()' para garantir a configuração correta
            final response = await this.dio.fetch(err.requestOptions); 
            // Se funcionou, "resolve" o handler com a nova resposta
            return handler.resolve(response);
          } catch (e) {
            // A nova tentativa também falhou
            log('Erro na nova tentativa após refresh: $e');
            return handler.next(e is DioException ? e : err);
          }
        } else {
          // 5. O refresh token falhou (ex: estava expirado)
          log('Falha no refresh. Encaminhando erro original.');
          return handler.next(err);
        }
      } catch (e) {
        log('Erro inesperado no interceptor: $e');
        return handler.next(err);
      }
    }

    // 6. Se não foi 401, apenas encaminha o erro
    return handler.next(err);
  }
}