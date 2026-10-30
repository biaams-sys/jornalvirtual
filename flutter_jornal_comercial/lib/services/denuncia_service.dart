import 'api_service.dart';

class DenunciaService {
  final ApiService _apiService = ApiService();

  Future<void> denunciarPublicacao({
    required int publicacaoId,
    required String motivo,
  }) async {
    await _apiService.post(
      '/denuncias-publicacao/cadastrar',
      body: {
        'publicacaoId': publicacaoId,
        'motivo': motivo,
      },
    );
  }

  Future<void> denunciarComentario({
    required int comentarioId,
    required String motivo,
  }) async {
    await _apiService.post(
      '/denuncias-comentario/cadastrar',
      body: {
        'comentarioId': comentarioId,
        'motivo': motivo,
      },
    );
  }
}