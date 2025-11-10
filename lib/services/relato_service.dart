import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:developer';
import 'package:path/path.dart' as path;

/// [SERVICE]
/// Responsável por todas as chamadas de rede relacionadas ao envio
/// de novos relatos.
class RelatoService {
  final Dio _dio;

  RelatoService({required Dio dio}) : _dio = dio;

  /// Envia o novo relato para a API.
  ///
  /// Gerencia a lógica de envio de dados + imagem (Multipart).
  /// Retorna [null] em caso de sucesso, ou uma [String] de erro em caso de falha.
  Future<String?> submitRelato({
    required Map<String, dynamic> data,
    XFile? image,
  }) async {
    try {
      final FormData formData;

      // 1. LÓGICA DE ENVIO DE IMAGEM (ATIVADA)
      // Se uma imagem foi selecionada, preparamos o MultipartFile.
      if (image != null) {
        final fileName = path.basename(image.path);
        final MultipartFile imageFile;

        if (kIsWeb) {
          // Na Web: Lê os bytes da imagem
          final bytes = await image.readAsBytes();
          imageFile = MultipartFile.fromBytes(bytes, filename: fileName);
        } else {
          // Mobile: Usa o caminho do arquivo
          imageFile = await MultipartFile.fromFile(image.path, filename: fileName);
        }
        
        // Adiciona a imagem ao FormData
        formData = FormData.fromMap({
          ...data,

          //Caso dê erro ou não adicione uma imagem, o problema pode estar no nome. 
          "imagem": imageFile, 
        });

      } else {
        // 2. ENVIO SEM IMAGEM
        // Se não houver imagem, envie FormData apenas com os dados
        formData = FormData.fromMap(data);
      }

      // 3. CHAMADA DE API
      // Enviando os dados. O Interceptor (dio_interceptor.dart)
      // já adiciona o Token e o 'Accept: application/json'.
      final response = await _dio.post(
        '/relato/',
        data: formData,
      );

      // 4. SUCESSO
      if (response.statusCode == 201 || response.statusCode == 200) {
        return null; // Sucesso
      } else {
        return "Erro ao enviar: ${response.statusCode} - ${response.data}";
      }

    } on DioException catch (e) {
      log('Erro de Dio/API em submitRelato: ${e.response?.data}', error: e);
      if (e.response != null) {
        return "Erro API: ${e.response!.statusCode} - ${e.response!.data}";
      } else {
        return "Falha de Rede/Conexão: ${e.message}";
      }
    } catch (e) {
      log('Erro desconhecido em submitRelato', error: e);
      return "Falha desconhecida: $e";
    }
  }
}