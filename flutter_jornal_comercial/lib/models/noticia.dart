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
      id: int.parse(json['id'].toString()),
      titulo: json['titulo']?.toString() ?? '',
      subtitulo: json['subtitulo']?.toString(),
      texto: json['texto']?.toString() ?? '',
      dataPublicacao: DateTime.parse(json['dataPublicacao'].toString()),
      dataAtualizacao: DateTime.parse(json['dataAtualizacao'].toString()),
      autor: json['autor'] is Map
          ? Map<String, dynamic>.from(json['autor'])
          : null,
      midias: json['midias'] is List ? json['midias'] : [],
    );
  }
}
