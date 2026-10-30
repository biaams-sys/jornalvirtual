import '../models/comentario.dart';
import 'api_service.dart';

class ComentarioService {
  final ApiService _apiService = ApiService();

  Future<List<Comentario>> listarPorPublicacao(
    int publicacaoId,
  ) async {
    final response = await _apiService.get(
      '/comentarios/publicacao/$publicacaoId',
    );

    if (response is! List) {
      throw Exception(
        'Formato de comentários inválido.',
      );
    }

    return response
        .map(
          (item) => Comentario.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
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

    await _apiService.post(
      '/comentarios/cadastrar',
      body: body,
    );
  }

  Future<void> excluirComentario(
    int comentarioId,
  ) async {
    await _apiService.delete(
      '/comentarios/$comentarioId',
    );
  }
}