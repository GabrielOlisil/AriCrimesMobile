import 'dart:developer';
import 'package:dio/dio.dart';

/// [SERVICE]
/// Responsável pelas operações CRUD (Read, Update, Delete)
/// específicas para os relatos do usuário logado.
class RelatoManagerService {
  final Dio _dio;

  RelatoManagerService({required Dio dio}) : _dio = dio;

  /// [READ] Busca todos os relatos criados pelo usuário logado (GET /relato/my).
  /// Retorna uma lista de mapas ou lança uma exceção.
  Future<List<Map<String, dynamic>>> fetchMyRelatos() async {
    try {
      // O endpoint /relato/my deve ser protegido e usar o token JWT para identificar o usuário.
      final response = await _dio.get('/relato/my');

      if (response.statusCode == 200) {
        // A API deve retornar uma lista de relatos (List<Map<String, dynamic>>)
        return List<Map<String, dynamic>>.from(response.data);
      }
      
      throw Exception("Falha ao buscar relatos: ${response.statusCode} - ${response.data}");

    } on DioException catch (e) {
      log('Erro de Dio/API em fetchMyRelatos: ${e.response?.data}', error: e);
      throw Exception("Falha de Rede ao listar relatos: ${e.response?.statusCode ?? 'Desconhecido'}");
    } catch (e) {
      log('Erro desconhecido em fetchMyRelatos', error: e);
      throw Exception("Erro desconhecido: $e");
    }
  }


  /// [UPDATE] Atualiza os dados textuais de um relato existente (PUT /relato/{id}).
  /// Retorna [null] em caso de sucesso, ou uma [String] com a mensagem de erro.
  /// 
  /// @param relatoId O ID do relato a ser atualizado.
  /// @param data O Map contendo todos os campos do DTO de Edição (incluindo os não alterados).
  Future<String?> updateRelato({
    required int relatoId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.put(
        '/relato/$relatoId',
        data: data,
      );

      if (response.statusCode == 200) {
        return null; // Sucesso
      }
      
      return "Erro ${response.statusCode}: ${response.data}";

    } on DioException catch (e) {
      log('Erro de Dio/API em updateRelato: ${e.response?.data}', error: e);
      return "Falha de Rede/API: ${e.message}";
    } catch (e) {
      return "Erro desconhecido: $e";
    }
  }


  /// [DELETE] Deleta um relato pelo ID (DELETE /relato/{id}).
  /// Retorna [null] em caso de sucesso, ou uma [String] com a mensagem de erro.
  Future<String?> deleteRelato(int relatoId) async {
    try {
      final response = await _dio.delete('/relato/$relatoId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return null; // Sucesso
      }
      
      return "Erro ${response.statusCode}: ${response.data}";

    } on DioException catch (e) {
      log('Erro de Dio/API em deleteRelato: ${e.response?.data}', error: e);
      return "Falha de Rede/API: ${e.message}";
    } catch (e) {
      return "Erro desconhecido: $e";
    }
  }
}