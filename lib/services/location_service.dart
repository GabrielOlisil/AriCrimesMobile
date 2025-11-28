// lib/services/location_service.dart
import 'dart:io';
import 'package:dio/dio.dart';

class LocationService {
  final Dio dio;
  final String? googleApiKey;

  LocationService({
    required this.dio,
    this.googleApiKey,
  });

  /// Tenta primeiro usar o endpoint do seu backend: GET /location/reverse?lat=...&lng=...
  /// Se o backend não tiver esse endpoint (404) ou ocorrer erro, faz fallback
  /// para a Geocoding API do Google (se googleApiKey for fornecida).
  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    // 1) Primeiro: tenta o backend (assim usa o token via interceptor)
    try {
      final backendResp = await dio.get(
        '/location/reverse',
        queryParameters: {'lat': lat, 'lng': lng},
      );

      if (backendResp.statusCode == 200) {
        final data = backendResp.data;
        if (data != null) {
          // tenta campos comuns
          if (data is Map && data.containsKey('address')) {
            return data['address']?.toString();
          }
          // fallback: se o backend retornar 'formatted' ou 'formatted_address'
          if (data is Map && data.containsKey('formatted')) {
            return data['formatted']?.toString();
          }
          if (data is Map && data.containsKey('formatted_address')) {
            return data['formatted_address']?.toString();
          }
          // Se o backend retornou algo diferente, tenta stringificar
          return data.toString();
        }
        return null;
      }
      // Se 404/403/etc, cai no catch abaixo para tentar Google
    } on DioException catch (e) {
      // Se for 404 do backend, ignoramos e vamos tentar Google.
      if (e.response?.statusCode == 404) {
        // backend não expõe reverse geocoding — proceder para fallback.
      } else {
        // Log para ajudar debug; não rethrowamos para permitir fallback
        // ignore: avoid_print
        print('LocationService.backend error (ignored, fallback to Google): ${e.response?.statusCode} ${e.message}');
      }
    } catch (e) {
      // ignore and fallback
      // ignore: avoid_print
      print('LocationService backend unknown error (ignored): $e');
    }

    // 2) Fallback: Google Geocoding API (se tivermos chave)
    if (googleApiKey == null || googleApiKey!.isEmpty) {
      // Sem chave e sem backend -> não conseguimos geocodificar
      return null;
    }

    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json';
      final resp = await Dio().get(
        url,
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': googleApiKey,
        },
      );

      if (resp.statusCode == 200) {
        final results = resp.data['results'];
        if (results != null && results is List && results.isNotEmpty) {
          return results[0]['formatted_address']?.toString();
        }
        return null;
      } else {
        // ignore: avoid_print
        print('Google Geocoding returned ${resp.statusCode}: ${resp.data}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro no Google Geocoding: $e');
      return null;
    }
  }
}
