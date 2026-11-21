
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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

  Future<int> criarPublicacao({required String texto}) async {
    final response = await _apiService.post(
      '/publicacoes/cadastrar',
      body: {'texto': texto},
    );

    if (response is! Map || response['publicacao'] is! Map) {
      throw Exception('Não foi possível obter a publicação criada.');
    }

    final publicacao = Map<String, dynamic>.from(response['publicacao']);

    if (publicacao['id'] == null) {
      throw Exception('ID da publicação não encontrado.');
    }

    return int.parse(publicacao['id'].toString());
  }

  // Identifica somente formatos aceitos pelo backend.
  String? _identificarMimeType(XFile arquivo) {
    const formatosPermitidos = {
      'image/jpeg',
      'image/png',
      'image/webp',
      'video/mp4',
      'video/webm',
      'video/x-matroska',
    };

    final mimeType = arquivo.mimeType?.toLowerCase().trim();

    if (mimeType != null && formatosPermitidos.contains(mimeType)) {
      return mimeType;
    }

    final nome = arquivo.name.toLowerCase();

    if (nome.endsWith('.jpg') || nome.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (nome.endsWith('.png')) {
      return 'image/png';
    }

    if (nome.endsWith('.webp')) {
      return 'image/webp';
    }

    if (nome.endsWith('.mp4')) {
      return 'video/mp4';
    }

    if (nome.endsWith('.webm')) {
      return 'video/webm';
    }

    if (nome.endsWith('.mkv')) {
      return 'video/x-matroska';
    }

    return null;
  }

  Future<void> adicionarMidia(int publicacaoId, XFile arquivo) async {
    final mimeType = _identificarMimeType(arquivo);

    if (mimeType == null) {
      throw Exception(
        'Formato de arquivo não identificado ou não permitido. '
        'Utilize JPG, PNG, WEBP, MP4, WEBM ou MKV.',
      );
    }

    // Solicita autorização para enviar o arquivo ao Supabase.
    final autorizacao = await _apiService.post(
      '/midias-publicacoes/autorizar-upload/$publicacaoId',
      body: {
        'nomeOriginal': arquivo.name,
        'mimeType': mimeType,
      },
    );

    if (autorizacao is! Map) {
      throw Exception('Resposta inválida ao autorizar upload.');
    }

    final signedUrl = autorizacao['signedUrl'];
    final token = autorizacao['token'];
    final path = autorizacao['path'];

    if (signedUrl == null || token == null || path == null) {
      throw Exception('Dados de autorização incompletos.');
    }

    final bytes = await arquivo.readAsBytes();

    // Envia o arquivo diretamente para o Supabase Storage.
    final respostaUpload = await http.put(
      Uri.parse(signedUrl.toString()),
      headers: {
        'Authorization': 'Bearer ${token.toString()}',
        'Content-Type': mimeType,
        'x-upsert': 'false',
      },
      body: bytes,
    );

    if (respostaUpload.statusCode != 200 &&
        respostaUpload.statusCode != 201 &&
        respostaUpload.statusCode != 204) {
      throw Exception(
        'Erro ao enviar mídia: ${respostaUpload.statusCode} - '
        '${respostaUpload.body}',
      );
    }

    // Confirma o envio e registra a mídia no banco.
    final confirmacao = await _apiService.post(
      '/midias-publicacoes/confirmar-upload/$publicacaoId',
      body: {
        'path': path,
        'nomeOriginal': autorizacao['nomeOriginal'],
        'nomeArquivo': autorizacao['nomeArquivo'],
        'mimeType': autorizacao['mimeType'],
      },
    );

    if (confirmacao is! Map) {
      throw Exception('Não foi possível confirmar o cadastro da mídia.');
    }
  }

  Future<List<dynamic>> listarMidias(int publicacaoId) async {
    final response = await _apiService.get('/midias-publicacoes/listar');

    if (response is! List) {
      throw Exception('Formato de mídias inválido.');
    }

    return response.where((midia) {
      if (midia is! Map || midia['publicacaoId'] == null) {
        return false;
      }

      return midia['publicacaoId'].toString() == publicacaoId.toString();
    }).toList();
  }

  Future<void> curtir(int publicacaoId) async {
    await _apiService.post(
      '/curtidas/curtir',
      body: {'publicacaoId': publicacaoId},
    );
  }

  Future<void> descurtir(int publicacaoId) async {
    await _apiService.delete(
      '/curtidas/descurtir',
      body: {'publicacaoId': publicacaoId},
    );
  }

  Future<List<dynamic>> listarComentarios(int publicacaoId) async {
    final response = await _apiService.get(
      '/comentarios/publicacao/$publicacaoId',
    );

    if (response is! List) {
      throw Exception('Formato de comentários inválido.');
    }

    return response;
  }

  Future<void> criarComentario({
    required int publicacaoId,
    required String texto,
    int? comentarioPaiId,
  }) async {
    final body = <String, dynamic>{
      'publicacaoId': publicacaoId,
      'texto': texto,
    };

    if (comentarioPaiId != null) {
      body['comentarioPaiId'] = comentarioPaiId;
    }

    await _apiService.post('/comentarios/cadastrar', body: body);
  }

  Future<List<dynamic>> listarRankingHashtags() async {
    final response = await _apiService.get('/hashtags/ranking');

    print('RANKING DE HASHTAGS: $response');

    if (response is! List) {
      throw Exception('Formato do ranking de hashtags inválido.');
    }

    return response;
  }

  Future<void> excluirPublicacao(int publicacaoId) async {
    await _apiService.delete('/publicacoes/excluir/$publicacaoId');
  }

  Future<void> excluirComentario(int comentarioId) async {
    await _apiService.delete('/comentarios/$comentarioId');
  }
}
