class ApiConstants {
  // URL do backend
  static const String baseUrl = 'SUA_URL_DO_BACKEND';

  // URL do Supabase
  static const String supabaseUrl =
      'https://hepwnbumziimvfugvjbe.supabase.co/rest/v1';

  // Sua chave pública exata e completa
  static const String apiKey = 'sb_publishable_r6TSPspP2GR5PjiIoVSY4g_rD8Dbkmb';

  static const String empresa = 'Empresa';
  static const String tema = 'TemaEmpresa';
  static const String usuarios = 'Usuarios';
  static const String noticias = 'Noticias';
  static const String publicacoes = 'Publicacoes';
  static const String comentarios = 'Comentarios';
  static const String curtidas = 'Curtidas';
  static const String hashtags = 'Hashtags';
  static const String login = 'Usuarios';

  static Map<String, String> get headers {
    return {'Content-Type': 'application/json'};
  }
}
