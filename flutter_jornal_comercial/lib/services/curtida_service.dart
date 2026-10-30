import 'api_service.dart';

class CurtidaService {
  final ApiService _apiService = ApiService();

  Future<void> curtir(int publicacaoId) async {
    await _apiService.post(
      '/curtidas/curtir',
      body: {
        'publicacaoId': publicacaoId,
      },
    );
  }

  Future<void> descurtir(int publicacaoId) async {
    await _apiService.delete(
      '/curtidas/descurtir',
      body: {
        'publicacaoId': publicacaoId,
      },
    );
  }

  Future<int> contarCurtidas(int publicacaoId) async {
    final response = await _apiService.get(
      '/curtidas/contar/$publicacaoId',
    );

    return response['curtidas'] ?? 0;
  }
}