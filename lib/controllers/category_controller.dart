// lib/controllers/category_controller.dart
import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../services/relato_service.dart';

class CategoryController extends ChangeNotifier {
  final RelatoService _service;

  // Cache das categorias
  List<Categoria> _categorias = [];
  bool _isLoading = false;
  String? _error;

  CategoryController(this._service);

  List<Categoria> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carrega as categorias apenas uma vez e salva em memória.
  Future<void> loadCategorias() async {
    // Se já tiver carregado, não busca de novo (Cache simples)
    if (_categorias.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categorias = await _service.getCategorias();
    } catch (e) {
      _error = "Erro ao carregar categorias";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}