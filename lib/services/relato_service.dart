// lib/services/relato_service.dart
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer';
import 'package:http_parser/http_parser.dart';
import 'package:o_auth2/models/categoria.dart';

class RelatoService {
  final Dio _dio;
  final String token; // TOKEN vindo do MyAuthProvider (pode estar vazio)

  static const String _relatoEndpoint = '/relato';

  RelatoService({required Dio dio, required this.token}) : _dio = dio;

  // =========================================================
  // 1.1 — GET /relato (lista pública)
  // =========================================================
  Future<List<Map<String, dynamic>>> getAllRelatos() async {
    // NOME MUDADO
    try {
      final response = await _dio.get(
        _relatoEndpoint, // /relato
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Erro ao buscar todos os relatos: ${response.statusCode} - ${response.data}",
        );
      }

      return List<Map<String, dynamic>>.from(response.data as List);
    } on DioException catch (e) {
      log('DioException getAllRelatos: ${e.response?.data}', error: e);
      if (e.response != null) {
        throw Exception(
          "Erro API ${e.response!.statusCode}: ${e.response!.data}",
        );
      }
      throw Exception("Falha de rede: ${e.message}");
    } catch (e) {
      throw Exception("Falha ao obter todos os relatos: $e");
    }
  }

  // =========================================================
  // 1.2 — GET /relato/my (lista do usuário logado)
  // =========================================================
  Future<List<Map<String, dynamic>>> getMyRelatos() async {
    // NOVO MÉTODO
    try {
      final response = await _dio.get(
        '$_relatoEndpoint/my', // /relato/my
        options: Options(
          // O TOKEN É OBRIGATÓRIO AQUI PARA IDENTIFICAR O USUÁRIO
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Erro ao buscar meus relatos: ${response.statusCode} - ${response.data}",
        );
      }

      return List<Map<String, dynamic>>.from(response.data as List);
    } on DioException catch (e) {
      log('DioException getMyRelatos: ${e.response?.data}', error: e);
      if (e.response != null) {
        throw Exception(
          "Erro API ${e.response!.statusCode}: ${e.response!.data}",
        );
      }
      throw Exception("Falha de rede: ${e.message}");
    } catch (e) {
      throw Exception("Falha ao obter meus relatos: $e");
    }
  }

  // =========================================================
  // 1.3 — GET /relato/latest (lista dos últimos relatos de todos)
  // =========================================================
  /// Pega os últimos relatos de todos os usuários usando o endpoint /relato/latest.
  Future<List<Map<String, dynamic>>> fetchLatestRelatos({
    int offset = 0,
    int limit = 100,
  }) async {
    if (token.isEmpty) {
      log(
        'AVISO: Token JWT ausente para fetchLatestRelatos, a API pode negar acesso.',
        level: 800,
      );
    }

    try {
      final response = await _dio.get(
        '$_relatoEndpoint/latest', // /relato/latest
        queryParameters: {'offset': offset, 'limit': limit},
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Erro ao buscar últimos relatos: ${response.statusCode} - ${response.data}",
        );
      }

      // O endpoint retorna uma lista de objetos RelatoRead
      return (response.data as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      log('DioException fetchLatestRelatos: ${e.response?.data}', error: e);
      if (e.response != null) {
        throw Exception(
          "Erro API ${e.response!.statusCode}: ${e.response!.data}",
        );
      }
      throw Exception("Falha de rede: ${e.message}");
    } catch (e) {
      log('Erro inesperado ao buscar últimos relatos: $e');
      rethrow;
    }
  }

  // =========================================================
  // 2 — POST /relato
  // =========================================================
  Future<String> submitRelato({required Map<String, dynamic> data}) async {
    try {
      final response = await _dio.post(
        _relatoEndpoint,
        data: data,
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          "Erro ao criar relato: ${response.statusCode} - ${response.data}",
        );
      }

      final id = response.data['id'];
      if (id == null) {
        throw Exception("A API não retornou o ID do relato.");
      }

      return id.toString();
    } on DioException catch (e) {
      log('DioException submitRelato: ${e.response?.data}', error: e);
      if (e.response != null) {
        throw Exception(
          "Erro API ${e.response!.statusCode}: ${e.response!.data}",
        );
      }
      throw Exception("Falha de rede: ${e.message}");
    } catch (e) {
      throw Exception("Falha ao criar relato: $e");
    }
  }

  // =========================================================
  // 3 — PUT /relato/{id}
  // =========================================================
  Future<String?> updateRelato({
    required int relatoId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.put(
        '$_relatoEndpoint/$relatoId',
        data: data,
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return null;
      }

      return "Falha ao atualizar relato: ${response.statusCode} - ${response.data}";
    } on DioException catch (e) {
      log('DioException updateRelato: ${e.response?.data}', error: e);
      if (e.response != null) {
        return "Erro API ${e.response!.statusCode}: ${e.response!.data}";
      }
      return "Falha de rede: ${e.message}";
    } catch (e) {
      return "Erro ao atualizar: $e";
    }
  }

  // =========================================================
  // 4 — POST /relato/{id}/foto/
  // =========================================================
  Future<String?> uploadFotoParaRelato({
    required int relatoId,
    required XFile image,
  }) async {
    try {
      // determina mime
      final subtype = image.name.toLowerCase().endsWith(".png")
          ? "png"
          : "jpeg";

      final bytes = await image.readAsBytes();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: image.name.isNotEmpty
              ? image.name
              : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', subtype),
        ),
      });

      final response = await _dio.post(
        '$_relatoEndpoint/$relatoId/foto/',
        data: formData,
        options: Options(
          headers: token.isNotEmpty
              ? {
                  'Authorization': 'Bearer $token',
                  // NÃO é estritamente necessário forçar Content-Type aqui;
                  // Dio definirá multipart/form-data automaticamente.
                }
              : null,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }

      return "Falha ao enviar foto: ${response.statusCode} - ${response.data}";
    } on DioException catch (e) {
      log('DioException uploadFoto: ${e.response?.data}', error: e);
      if (e.response != null) {
        return "Erro API ${e.response!.statusCode}: ${e.response!.data}";
      }
      return "Falha de rede ao enviar foto: ${e.message}";
    } catch (e) {
      return "Erro ao enviar foto: $e";
    }
  }

  // =========================================================
  // 5 — DELETE /relato/{id}/foto/
  // =========================================================
  Future<String?> deleteFotoParaRelato(int relatoId) async {
    try {
      final response = await _dio.delete(
        '$_relatoEndpoint/$relatoId/foto/',
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return null;
      }

      return "Falha ao deletar foto: ${response.statusCode} - ${response.data}";
    } on DioException catch (e) {
      log('DioException deleteFotoParaRelato: ${e.response?.data}', error: e);
      if (e.response != null) {
        return "Erro API ${e.response!.statusCode}: ${e.response!.data}";
      }
      return "Falha de rede ao deletar foto: ${e.message}";
    } catch (e) {
      return "Erro ao deletar foto: $e";
    }
  }

  // =========================================================
  // 6 — DELETE /relato/{id}
  // =========================================================
  Future<String?> deleteRelato(int relatoId) async {
    // Log de Debug Adicionado AQUI
    log('DELETAR RELATO - ID: $relatoId.');
    log('TOKEN PRESENTE: ${token.isNotEmpty}.');
    if (token.isNotEmpty) {
      // Loga o início do token (os primeiros 15 caracteres)
      log(
        'TOKEN INÍCIO: ${token.length > 15 ? token.substring(0, 15) : token}...',
      );
    } else {
      log('TOKEN: VAZIO OU NULO.');
    }
    // Fim do Log de Debug

    try {
      final response = await _dio.delete(
        '$_relatoEndpoint/$relatoId',
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return null;
      }

      return "Falha ao deletar relato: ${response.statusCode} - ${response.data}";
    } on DioException catch (e) {
      log('DioException deleteRelato: ${e.response?.data}', error: e);
      if (e.response != null) {
        return "Erro API ${e.response!.statusCode}: ${e.response!.data}";
      }
      return "Falha de rede ao deletar relato: ${e.message}";
    } catch (e) {
      return "Erro ao deletar relato: $e";
    }
  }

  // =========================================================
  // 7 — GET /categorias (Listar categorias)
  // =========================================================
  Future<List<Categoria>> getCategorias() async {
    try {
      final response = await _dio.get(
        '/categorias',
        // Não precisa de auth obrigatória segundo seu swagger, mas se precisar:
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception("Erro ao buscar categorias: ${response.statusCode}");
      }

      return (response.data as List)
          .map((item) => Categoria.fromJson(item))
          .toList();
    } catch (e) {
      log('Erro ao buscar categorias: $e');
      throw Exception("Falha ao carregar categorias.");
    }
  }

  // =========================================================
  // 8 — GET /relato/categoria/{id} (Relatos por Categoria)
  // =========================================================
  Future<List<Map<String, dynamic>>> getRelatosPorCategoria(
      int categoryId, {
        int offset = 0,
        int limit = 10,
      }) async {
    try {
      final response = await _dio.get(
        '/relato/categoria/$categoryId',
        queryParameters: {
          'offset': offset,
          'limit': limit,
        },
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception("Erro ao buscar relatos da categoria $categoryId");
      }

      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e) {
      log('Erro ao buscar relatos por categoria: $e');
      throw Exception("Falha ao carregar relatos da categoria.");
    }
  }
}
