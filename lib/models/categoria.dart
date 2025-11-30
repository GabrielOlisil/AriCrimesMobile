class Categoria {
  final int id;
  final String nome;
  final String descricao;

  Categoria({
    required this.id,
    required this.nome,
    required this.descricao,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] ?? 0,
      nome: json['nome'] ?? 'Sem Nome',
      descricao: json['descricao'] ?? '',
    );
  }
}