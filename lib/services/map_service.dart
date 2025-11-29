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
    // 1. Lógica de cálculo de data (movida do widget)
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    const duracaoParaSubtrair = Duration(days: 14);
    final lastTwoWeeks = today.subtract(duracaoParaSubtrair);

    // 2. Parâmetros da query
    final queryParams = {
      'start_date': lastTwoWeeks.toIso8601String(),
      'end_date': today.toIso8601String(),
      'eps_km': 0.5,
      'min_samples': 3,
    };

    try {
      // 3. Chamada de API usando Dio (em vez de http)
      // O 'baseUrl' (https://aricrimes-api...) já está no Dio (via main.dart)
      final response = await _dio.get(
        '/heatmap', // Apenas o endpoint
        queryParameters: queryParams,
        // O header 'Accept: application/json' já é adicionado
        // pelo nosso DioAuthInterceptor.
      );

      if (response.statusCode == 200) {
        final resData = response.data as Map<String, dynamic>;
        final List<WeightedLatLng> heatmapPoints = [];

        if (resData.containsKey("points")) {
          for (var i in resData["points"]!) {
            heatmapPoints.add(
              WeightedLatLng(
                LatLng(i['lat'], i['long']),
                weight: 1.0,
              ),
            );
          }
        }

        if (heatmapPoints.isEmpty) {
          return {}; // Retorna um set vazio
        }

        // 4. Cria e retorna o objeto Heatmap
        final heatmap = Heatmap(
          heatmapId: const HeatmapId('crime_heatmap'),
          data: heatmapPoints,
          radius: HeatmapRadius.fromPixels(50),
          opacity: 0.8,
          gradient: const HeatmapGradient(
            <HeatmapGradientColor>[
              HeatmapGradientColor(Colors.green, 0.2),
              HeatmapGradientColor(Colors.yellow, 0.4),
              HeatmapGradientColor(Colors.red, 0.8),
            ],
          ),
        );
        return {heatmap};
      } else {
        log('Erro ao buscar heatmap: ${response.statusCode}');
        return {};
      }
    } on DioException catch (e) {
      log('Falha de Dio/rede ao buscar heatmap: $e');
      return {};
    } catch (e) {
      log('Erro desconhecido ao processar heatmap: $e');
      return {};
    }
  }
}