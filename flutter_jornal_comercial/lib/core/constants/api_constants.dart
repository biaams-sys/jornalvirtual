class ApiConstants {
  // Mantemos a URL oficial exatamente como está no seu painel
  static const String baseUrl =
      'https://hepwnbumziimvfugvjbe.supabase.co/rest/v1';

  // Sua chave pública exata e completa
  static const String apiKey = 'sb_publishable_r6TSPspP2GR5PjiIoVSY4g_rD8Dbkmb';

  // Removemos a barra inicial de cada tabela para sumir com o erro de barra dupla (//)
  static const String empresa = 'Empresa';
  static const String tema = 'TemaEmpresa';
  static const String usuarios = 'Usuarios';
  static const String noticias = 'Noticias';
  static const String publicacoes = 'Publicacoes';
  static const String comentarios = 'Comentarios';
  static const String curtidas = 'Curtidas';
  static const String hashtags = 'Hashtags';
  static const String login = 'Usuarios';

  // Cabeçalhos que liberam o acesso na nuvem do Supabase
  static Map<String, String> get headers {
    return {
      'apikey': apiKey,
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };
  }
}
