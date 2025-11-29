// lib/services/map_service.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Responsável por todas as chamadas de rede relacionadas ao mapa.
class MapService {
  final Dio _dio;

  MapService({required Dio dio}) : _dio = dio;

  /// Busca os dados do heatmap na API.
  /// Converte a resposta JSON em um [Set<Heatmap>] pronto para ser
  /// usado pelo [GoogleMap].
  Future<Set<Heatmap>> fetchHeatmapData() async {
    // 1. CORREÇÃO: Usar DateTime.now() para incluir dados até o momento atual
    final now = DateTime.now().toUtc();
    const duracaoParaSubtrair = Duration(days: 14);
    final lastTwoWeeks = now.subtract(duracaoParaSubtrair);

    // 2. Parâmetros da query
    final queryParams = {
      'start_date': lastTwoWeeks.toIso8601String(),
      'end_date': now.toIso8601String(), // Agora inclui crimes até o momento atual
      'eps_km': 0.5,
      'min_samples': 3,
    };

    try {
      // 3. Chamada de API usando Dio
      final response = await _dio.get(
        '/heatmap', // Apenas o endpoint
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // CORREÇÃO: Verificação de nulidade e tipo seguro
        final resData = response.data;
        if (resData == null || resData is! Map<String, dynamic>) {
          log('A API retornou 200, mas o corpo da resposta é inválido ou nulo.');
          return {};
        }

        final List<dynamic>? pointsData = resData["points"];

        if (pointsData == null || pointsData.isEmpty) {
          return {}; // Retorna um set vazio se não houver pontos
        }

        final List<WeightedLatLng> heatmapPoints = [];

        for (var i in pointsData) {
          // CORREÇÃO 2: Cast seguro com 'num' para evitar erro int/double e null safety
          if (i is Map<String, dynamic> && i['lat'] is num && i['long'] is num) {
            final double lat = (i['lat'] as num).toDouble();
            final double lng = (i['long'] as num).toDouble();

            heatmapPoints.add(
              WeightedLatLng(
                LatLng(lat, lng),
                weight: 1.0,
              ),
            );
          } else {
            // Loga pontos com formato incorreto
            log('Ponto de heatmap inválido encontrado no JSON: $i');
          }
        }

        if (heatmapPoints.isEmpty) {
          return {}; // Retorna vazio se todos os pontos forem inválidos
        }

        // 4. Cria e retorna o objeto Heatmap
        final heatmap = Heatmap(
          heatmapId: const HeatmapId('crime_heatmap'),
          data: heatmapPoints,
          radius: HeatmapRadius.fromPixels(70),
          opacity: 0.8,
          gradient: const HeatmapGradient(
            <HeatmapGradientColor>[
              HeatmapGradientColor(Colors.green, 0.2),
              HeatmapGradientColor(Colors.yellow, 0.5), // Ajustei opacidade visual
              HeatmapGradientColor(Colors.red, 1.0),
            ],
          ),
        );
        return {heatmap};
      } else {
        log('Erro ao buscar heatmap: Status Code ${response.statusCode}');
        return {};
      }
    } on DioException catch (e) {
      // Tratamento de DioException (rede ou API com erro HTTP)
      log('Falha de Dio/rede ao buscar heatmap: ${e.response?.statusCode}', error: e); 
      return {};
    } catch (e) {
      // Erros genéricos de processamento
      log('Erro desconhecido ao processar heatmap', error: e);
      return {};
    }
  }
}