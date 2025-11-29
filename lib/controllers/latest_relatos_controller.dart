// lib/controllers/latest_relatos_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Necessário para ChangeNotifier
import '../services/relato_service.dart'; // Assumindo que este serviço já existe

/// Controller para gerenciar a lista de relatos mais recentes de todos os usuários.
class LatestRelatosController extends ChangeNotifier {
  final RelatoService _relatoService;
  List<Map<String, dynamic>> _relatos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get relatos => _relatos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LatestRelatosController(this._relatoService);

  /// Busca os relatos mais recentes e filtra apenas os registrados nos últimos 7 dias.
  Future<void> fetchLatestRelatos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // CORREÇÃO AQUI: Chamando o método correto 'fetchLatestRelatos' do service.
      // Buscamos um limite maior (ex: 100) para ter uma boa chance de pegar relatos recentes.
      final fetchedRelatos = await _relatoService.fetchLatestRelatos(limit: 100);

      // 1. Filtragem para os últimos 7 dias (lógica no lado do cliente)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final filteredRelatos = fetchedRelatos.where((relato) {
        try {
          // Converte a data de registro para DateTime (o campo 'data_registro' é formatado como date-time na API)
          final dataRegistro = DateTime.parse(relato['data_registro'] as String);
          // Retorna apenas se o relato foi registrado após os últimos 7 dias
          return dataRegistro.isAfter(sevenDaysAgo);
        } catch (e) {
          // Ignora relatos com data inválida
          return false;
        }
      }).toList();

      // 2. Ordena por data de registro (mais recente primeiro)
      filteredRelatos.sort((a, b) {
        final dateA = DateTime.parse(a['data_registro'] as String);
        final dateB = DateTime.parse(b['data_registro'] as String);
        return dateB.compareTo(dateA);
      });
      
      _relatos = filteredRelatos;

    } catch (e) {
      // O erro do Dio ou do serviço
      _errorMessage = 'Erro ao carregar relatos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}