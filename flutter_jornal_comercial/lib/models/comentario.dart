class Comentario {
  final int id;
  final String texto;
  final DateTime dataPublicacao;
  final int usuarioId;
  final int publicacaoId;
  final int? comentarioPaiId;
  final Map<String, dynamic>? autor;
  final List<dynamic> respostas;

  Comentario({
    required this.id,
    required this.texto,
    required this.dataPublicacao,
    required this.usuarioId,
    required this.publicacaoId,
    this.comentarioPaiId,
    this.autor,
    required this.respostas,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      texto: json['texto'] ?? '',
      dataPublicacao: DateTime.parse(
        json['dataPublicacao'],
      ),
      usuarioId: json['usuarioId'],
      publicacaoId: json['publicacaoId'],
      comentarioPaiId: json['comentarioPaiId'],
      autor: json['autor'],
      respostas: json['respostas'] ?? [],
    );
  }
}