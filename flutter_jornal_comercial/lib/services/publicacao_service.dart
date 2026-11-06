import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/publicacao.dart';
import 'api_service.dart';

class PublicacaoService {
  final ApiService _apiService = ApiService();

  Future<List<Publicacao>> listarPublicacoes() async {
    final response = await _apiService.get('publicacoes/listar');

    if (response is! List) {
      throw Exception('Formato de publicações inválido.');
    }

    return response
        .map((item) => Publicacao.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Publicacao> buscarPublicacao(int id) async {
    final response = await _apiService.get('publicacoes/buscar/$id');

    if (response is! Map) {
      throw Exception('Formato da publicação inválido.');
    }

    return Publicacao.fromJson(Map<String, dynamic>.from(response));
  }

  // 3. CADASTRAR: Insere direto na tabela adicionando o usuário logado e a empresa 1
  Future<int> criarPublicacao({required String texto}) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId') ?? 1;

    final response = await _apiService.post(
      ApiConstants.publicacoes,
      body: {
        'texto': texto,
        'usuarioId': usuarioId,
        'empresaId': 1, // Empresa padrão de teste criada no banco
      },
    );

    if (response is! List || response.isEmpty) {
      throw Exception('Não foi possível obter o ID da publicação.');
    }

    return int.parse(response.first['id'].toString());
  }

  Future<void> adicionarMidia(int publicacaoId, XFile arquivo) async {
    final bytes = await arquivo.readAsBytes();

    final nomeArquivo =
        '${DateTime.now().millisecondsSinceEpoch}_${arquivo.name}';

    final caminhoArquivo = '$publicacaoId/$nomeArquivo';

    const storageUrl =
        'https://hepwnbumziimvfugvjbe.supabase.co/storage/v1/object';

    final respostaUpload = await http.post(
      Uri.parse('$storageUrl/midias/$caminhoArquivo'),
      headers: {
        'apikey': ApiConstants.apiKey,
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
        'Content-Type': arquivo.mimeType ?? 'application/octet-stream',
      },
      body: bytes,
    );

    if (respostaUpload.statusCode != 200 && respostaUpload.statusCode != 201) {
      throw Exception(
        'Erro no upload da mídia: ${respostaUpload.statusCode} - ${respostaUpload.body}',
      );
    }

    final pathPublico = 'midias/$caminhoArquivo';

    await _apiService.post(
      'MidiasPublicacoes',
      body: {
        'publicacaoId': publicacaoId,
        'nomeOriginal': arquivo.name,
        'nomeArquivo': nomeArquivo,
        'mimeType': arquivo.mimeType ?? 'application/octet-stream',
        'path': pathPublico,
      },
    );
  }

  Future<List<dynamic>> listarMidias(int publicacaoId) async {
    final response = await _apiService.get(
      'MidiasPublicacoes?select=*&publicacaoId=eq.$publicacaoId',
    );

    if (response is! List) {
      throw Exception('Formato de mídias inválido.');
    }

    return response;
  }

  // 5. CURTIR: Cria um registro associativo na tabela Curtidas
  Future<void> curtir(int publicacaoId) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId') ?? 1;

    await _apiService.post(
      ApiConstants.curtidas,
      body: {'usuarioId': usuarioId, 'publicacaoId': publicacaoId},
    );
  }

  // 6. DESCURTIR: Deleta filtrando pelo ID da publicação e do usuário conectado
  Future<void> descurtir(int publicacaoId) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId') ?? 1;

    await _apiService.delete(
      '${ApiConstants.curtidas}?publicacaoId=eq.$publicacaoId&usuarioId=eq.$usuarioId',
    );
  }

  // 7. LISTAR COMENTÁRIOS: Filtra a tabela Comentarios pela ID da publicação original
  Future<List<dynamic>> listarComentarios(int publicacaoId) async {
    final response = await _apiService.get(
      '${ApiConstants.comentarios}?publicacaoId=eq.$publicacaoId',
    );

    if (response is! List) {
      throw Exception('Formato de comentários inválido.');
    }

    return response;
  }

  // 8. CRIAR COMENTÁRIO: Cria a linha na tabela vinculando o autor logado
  Future<void> criarComentario({
    required int publicacaoId,
    required String texto,
    int? comentarioPaiId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId') ?? 1;

    final body = <String, dynamic>{
      'publicacaoId': publicacaoId,
      'texto': texto,
      'usuarioId': usuarioId,
    };

    if (comentarioPaiId != null) {
      body['comentarioPaiId'] = comentarioPaiId;
    }

    await _apiService.post(ApiConstants.comentarios, body: body);
  }

  // 9. HASHTAGS: Lista as tags armazenadas na tabela Hashtags
  Future<List<dynamic>> listarRankingHashtags() async {
    // Forçamos a chamada para a tabela limpa 'Hashtags' tirando qualquer sufixo manual
    final response = await _apiService.get('Hashtags');

    if (response is! List) {
      throw Exception('Formato do ranking de hashtags inválido.');
    }

    return response;
  }

  // 10. EXCLUIR PUBLICAÇÃO: Executa o DELETE baseado na ID da linha
  Future<void> excluirPublicacao(int publicacaoId) async {
    await _apiService.delete('${ApiConstants.publicacoes}?id=eq.$publicacaoId');
  }

  // 11. EXCLUIR COMENTÁRIO: Executa o DELETE baseado na ID da linha do comentário
  Future<void> excluirComentario(int comentarioId) async {
    await _apiService.delete('${ApiConstants.comentarios}?id=eq.$comentarioId');
  }
}
