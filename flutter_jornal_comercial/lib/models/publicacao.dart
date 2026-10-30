class Publicacao {
  final int id;
  final String? texto;
  final DateTime dataPublicacao;
  final Map<String, dynamic>? autor;
  final Map<String, dynamic>? empresa;
  final List<dynamic> hashtags;
  final List<dynamic> midias;
  final List<dynamic> curtidas;
  final List<dynamic> comentarios;

  Publicacao({
    required this.id,
    this.texto,
    required this.dataPublicacao,
    this.autor,
    this.empresa,
    required this.hashtags,
    required this.midias,
    required this.curtidas,
    required this.comentarios,
  });

  factory Publicacao.fromJson(Map<String, dynamic> json) {
    return Publicacao(
      id: json['id'],
      texto: json['texto'],
      dataPublicacao: DateTime.parse(
        json['dataPublicacao'],
      ),
      autor: json['autor'] != null
          ? Map<String, dynamic>.from(json['autor'])
          : null,
      empresa: json['empresa'] != null
          ? Map<String, dynamic>.from(json['empresa'])
          : null,
      hashtags: json['hashtags'] is List
          ? List<dynamic>.from(json['hashtags'])
          : [],
      midias: json['midias'] is List
          ? List<dynamic>.from(json['midias'])
          : [],
      curtidas: json['curtidas'] is List
          ? List<dynamic>.from(json['curtidas'])
          : [],
      comentarios: json['comentarios'] is List
          ? List<dynamic>.from(json['comentarios'])
          : [],
    );
  }

  int get quantidadeCurtidas {
    return curtidas.length;
  }

  int get quantidadeComentarios {
    return comentarios.length;
  }

  bool curtidaPorUsuario(int usuarioId) {
    return curtidas.any((curtida) {
      if (curtida is! Map) {
        return false;
      }

      if (curtida['usuarioId'] == usuarioId) {
        return true;
      }

      final usuario = curtida['usuario'];

      if (usuario is Map) {
        return usuario['id'] == usuarioId;
      }

      return false;
    });
  }
}