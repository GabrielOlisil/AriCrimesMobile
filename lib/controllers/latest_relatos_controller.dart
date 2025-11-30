// lib/controllers/latest_relatos_controller.dart
import 'package:flutter/material.dart';
import '../services/relato_service.dart';

class LatestRelatosController extends ChangeNotifier {
  final RelatoService _relatoService;

  // --- Estado dos Dados ---
  List<Map<String, dynamic>> _relatos = [];

  // --- Estado de Controle ---
  bool _isLoading = false;      // Loading inicial (tela branca ou spinner central)
  bool _isLoadingMore = false;  // Loading de rodapé (paginação)
  String? _errorMessage;

  // --- Paginação ---
  int _offset = 0;
  final int _limit = 10;
  bool _hasMore = true;

  // --- Filtros ---
  int? _currentCategoryId;
  String _currentTitle = "Novos Relatos";

  // --- Getters ---
  List<Map<String, dynamic>> get relatos => _relatos;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  String get currentTitle => _currentTitle;

  LatestRelatosController(this._relatoService);

  /// Método chamado pela HomeView para iniciar a tela com ou sem filtro.
  /// Resolve o erro: "The method 'loadRelatos' isn't defined".
  Future<void> loadRelatos({int? categoryId, String? categoryName}) async {
    _currentCategoryId = categoryId;

    // Define o título da tela
    if (categoryId != null) {
      _currentTitle = categoryName ?? "Categoria";
    } else {
      _currentTitle = "Novos Relatos";
    }

    // Reseta a paginação e limpa a lista para a nova busca
    _offset = 0;
    _hasMore = true;
    _relatos.clear();

    // Inicia a busca (com loading tela cheia)
    await _fetchData(isRefresh: true);
  }

  /// Chamado pelo RefreshIndicator (arrastar pra baixo)
  Future<void> refresh() async {
    _offset = 0;
    _hasMore = true;
    // Não limpamos _relatos imediatamente para não piscar a tela em branco
    await _fetchData(isRefresh: true);
  }

  /// Chamado pelo ScrollController quando chega no fim da lista
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    await _fetchData(isRefresh: false);
  }

  /// Lógica central de busca
  Future<void> _fetchData({required bool isRefresh}) async {
    if (isRefresh) {
      _isLoading = true;
      _errorMessage = null;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      List<Map<String, dynamic>> newRelatos;

      // Decide qual endpoint chamar baseado no filtro atual
      if (_currentCategoryId != null) {
        newRelatos = await _relatoService.getRelatosPorCategoria(
          _currentCategoryId!,
          offset: _offset,
          limit: _limit,
        );
      } else {
        newRelatos = await _relatoService.fetchLatestRelatos(
          offset: _offset,
          limit: _limit,
        );
      }

      // Lógica de paginação
      if (newRelatos.length < _limit) {
        _hasMore = false;
      }

      if (isRefresh) {
        _relatos = newRelatos;
      } else {
        _relatos.addAll(newRelatos);
      }

      _offset += newRelatos.length;

    } catch (e) {
      _errorMessage = 'Erro ao carregar: $e';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}