import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:o_auth2/auth/auth_provider.dart';

class RelatoForm extends StatefulWidget {
  const RelatoForm({super.key});

  @override
  State<RelatoForm> createState() => _RelatoFormState();
}

class _RelatoFormState extends State<RelatoForm> {
  final _formKey = GlobalKey<FormState>();

  String objRoubado = '';
  String descricao = '';
  String local = '';
  double latitude = 0;
  double longitude = 0;
  int categoriaId = 1;

  bool isLoading = false;
  String? feedbackMessage;

  Future<void> _enviarRelato(BuildContext context) async {
    setState(() {
      isLoading = true;
      feedbackMessage = null;
    });

    final dio = context.read<Dio>();

    try {
      final response = await dio.post(
        '/relato',
        data: {
          "obj_roubado": objRoubado,
          "descricao": descricao,
          "local": local,
          "latitude": latitude,
          "longitude": longitude,
          "data_furto": DateTime.now().toIso8601String(),
          "data_registro": DateTime.now().toIso8601String(),
          "categoria_id": categoriaId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() => feedbackMessage = "Relato enviado com sucesso!");
        _formKey.currentState?.reset();
      } else {
        setState(
          () => feedbackMessage =
              "Erro ao enviar: ${response.statusCode} - ${response.data}",
        );
      }
    } catch (e) {
      setState(() => feedbackMessage = "Falha na conexão: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<MyAuthProvider>(
      context,
      listen: false,
    ).accessToken;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Furto'),
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Objeto Roubado'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o objeto' : null,
                onSaved: (v) => objRoubado = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a descrição' : null,
                onSaved: (v) => descricao = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Local'),
                onSaved: (v) => local = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                onSaved: (v) => latitude = double.tryParse(v ?? '0') ?? 0,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                onSaved: (v) => longitude = double.tryParse(v ?? '0') ?? 0,
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar Relato'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _enviarRelato(context);
                        }
                      },
                    ),
              const SizedBox(height: 20),
              if (feedbackMessage != null)
                Text(
                  feedbackMessage!,
                  style: TextStyle(
                    color: feedbackMessage!.contains("sucesso")
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
