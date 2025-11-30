// lib/views/relato_detail_view.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/relato_service.dart';
import '../controllers/category_controller.dart';

class RelatoDetailView extends StatefulWidget {
  final int relatoId;
  final Map<String, dynamic>? placeholderData;

  const RelatoDetailView({
    super.key,
    required this.relatoId,
    this.placeholderData
  });

  @override
  State<RelatoDetailView> createState() => _RelatoDetailViewState();
}

class _RelatoDetailViewState extends State<RelatoDetailView> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _relato;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    if (widget.placeholderData != null) {
      _relato = widget.placeholderData;
    }
    _fetchRelatoCompleto();
  }

  Future<void> _handleConfirmacao() async {
    if (_isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      await context.read<RelatoService>().confirmarRelato(widget.relatoId);
      await _fetchRelatoCompleto();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Confirmação atualizada com sucesso!"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erro ao confirmar: ${e.toString()}"),
              backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  Future<void> _fetchRelatoCompleto() async {
    try {
      final service = context.read<RelatoService>();
      final dadosAtualizados = await service.getRelatoById(widget.relatoId);

      if (mounted) {
        setState(() {
          _relato = dadosAtualizados;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erro ao carregar relato: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  String _getNomeCategoria(int? catId) {
    if (catId == null) return 'Sem Categoria';
    final categorias = context.read<CategoryController>().categorias;
    try {
      final cat = categorias.firstWhere((c) => c.id == catId);
      return cat.nome;
    } catch (_) {
      return 'Categoria #$catId';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _relato == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Erro")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchRelatoCompleto();
                },
                child: const Text("Tentar Novamente"),
              )
            ],
          ),
        ),
      );
    }

    final relato = _relato!;

    final objRoubado = relato['obj_roubado']?.toString() ?? 'Objeto não identificado';
    final descricao = relato['descricao']?.toString() ?? 'Sem descrição.';
    final local = relato['local']?.toString() ?? 'Local não informado';
    final latitude = relato['latitude'];
    final longitude = relato['longitude'];
    final categoriaId = relato['categoria_id'] as int?;

    String dataFurto = 'Data desconhecida';
    if (relato['data_furto'] != null) {
      try {
        final dt = DateTime.parse(relato['data_furto'].toString()).toLocal();
        dataFurto = "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} às ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}";
      } catch (_) {}
    }

    String? photoUrl;
    final fotos = relato['fotos'];
    if (fotos is List && fotos.isNotEmpty) {
      photoUrl = fotos[0]['url']?.toString();
    }

    final numConfirmacoes = (relato['numero_confirmacoes'] as num?)?.toInt() ?? 0;

    return Scaffold(
      extendBodyBehindAppBar: photoUrl != null,
      appBar: AppBar(
        backgroundColor: photoUrl != null ? Colors.transparent : Colors.blue.shade800,
        elevation: 0,
        iconTheme: IconThemeData(
          color: photoUrl != null ? Colors.white : Colors.white,
          shadows: photoUrl != null ? [const Shadow(color: Colors.black, blurRadius: 10)] : null,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FOTO DE CAPA ---
            if (photoUrl != null)
              Hero(
                tag: 'relato_img_${relato['id']}',
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(photoUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: Colors.blue.shade800,
                padding: const EdgeInsets.only(top: 60),
                child: const Center(
                  child: Icon(Icons.security, size: 50, color: Colors.white24),
                ),
              ),

            // --- CONTEÚDO ---
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TÍTULO E CATEGORIA
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            objRoubado.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getNomeCategoria(categoriaId),
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // BOTÃO DE LIKE
                    InkWell(
                      onTap: _isConfirming ? null : _handleConfirmacao,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isConfirming
                                ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2)
                            )
                                : Icon(Icons.thumb_up, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Text(
                              "$numConfirmacoes confirmações",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "(Toque para confirmar)",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // DATA
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          dataFurto,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),

                    const Divider(height: 30),

                    // --- [CORREÇÃO] DESCRIÇÃO REINSERIDA AQUI ---
                    const Text(
                      "Descrição do Ocorrido",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      descricao,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    ),

                    const SizedBox(height: 24),

                    // --- [CORREÇÃO] LOCALIZAÇÃO REINSERIDA AQUI ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red.shade400, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Localização",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  local,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                if (latitude != null && longitude != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "GPS: $latitude, $longitude",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}