class Noticia {
  final int id;
  final String titulo;
  final String? subtitulo;
  final String texto;
  final DateTime dataPublicacao;
  final DateTime dataAtualizacao;
  final Map<String, dynamic>? autor;
  final List<dynamic> midias;

  Noticia({
    required this.id,
    required this.titulo,
    this.subtitulo,
    required this.texto,
    required this.dataPublicacao,
    required this.dataAtualizacao,
    this.autor,
    required this.midias,
  });

  factory Noticia.fromJson(Map<String, dynamic> json) {
    return Noticia(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      subtitulo: json['subtitulo'],
      texto: json['texto'] ?? '',
      dataPublicacao: DateTime.parse(
        json['dataPublicacao'],
      ),
      dataAtualizacao: DateTime.parse(
        json['dataAtualizacao'],
      ),
      autor: json['autor'],
      midias: json['midias'] ?? [],
    );
  }
}