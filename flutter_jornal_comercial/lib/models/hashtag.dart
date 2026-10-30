class Hashtag {
  final int id;
  final String nome;
  final int quantidadePublicacoes;

  Hashtag({
    required this.id,
    required this.nome,
    required this.quantidadePublicacoes,
  });

  factory Hashtag.fromJson(Map<String, dynamic> json) {
    return Hashtag(
      id: json['id'],
      nome: json['nome'] ?? '',
      quantidadePublicacoes:
          json['quantidadePublicacoes'] ?? 0,
    );
  }
}