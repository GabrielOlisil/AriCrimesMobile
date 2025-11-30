// lib/controllers/relato_search_controller.dart
import 'package:flutter/material.dart';
import '../services/relato_service.dart';

class RelatoSearchController extends ChangeNotifier {
  final RelatoService _relatoService;

  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Controle do termo de busca para evitar repetições
  String _lastQuery = '';

  List<Map<String, dynamic>> get results => _results;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RelatoSearchController(this._relatoService);

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    // Evita buscar a mesma coisa duas vezes seguidas
    if (query == _lastQuery && _results.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    _lastQuery = query;
    notifyListeners();

    try {
      // Busca com limite de 50 itens para simplificar (sem paginação infinita por enquanto)
      final data = await _relatoService.searchRelatos(query, limit: 50);
      _results = data;

      if (_results.isEmpty) {
        _errorMessage = "Nenhum relato encontrado para '$query'";
      }
    } catch (e) {
      _errorMessage = "Erro ao buscar: ${e.toString().split('Exception:').last.trim()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _results = [];
    _lastQuery = '';
    _errorMessage = null;
    notifyListeners();
  }
}