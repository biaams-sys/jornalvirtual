class Usuario {
  final int id;
  final String nome;
  final String email;
  final String? fotoPerfil;
  final String? template;
  final String? bio;
  final String tipo;
  final int empresaId;
  final Map<String, dynamic>? empresa;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.fotoPerfil,
    this.template,
    this.bio,
    required this.tipo,
    required this.empresaId,
    this.empresa,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      fotoPerfil: json['fotoPerfil'],
      template: json['template'],
      bio: json['bio'],
      tipo: json['tipo'] ?? '',
      empresaId: json['empresaId'],
      empresa: json['empresa'] is Map
          ? Map<String, dynamic>.from(json['empresa'])
          : null,
    );
  }

  Usuario copyWith({
    int? id,
    String? nome,
    String? email,
    String? fotoPerfil,
    String? template,
    String? bio,
    String? tipo,
    int? empresaId,
    Map<String, dynamic>? empresa,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      template: template ?? this.template,
      bio: bio ?? this.bio,
      tipo: tipo ?? this.tipo,
      empresaId: empresaId ?? this.empresaId,
      empresa: empresa ?? this.empresa,
    );
  }
}