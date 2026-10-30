import '../models/hashtag.dart';
import 'api_service.dart';

class HashtagService {
  final ApiService _apiService = ApiService();

  Future<List<Hashtag>> listarRanking() async {
    final response = await _apiService.get(
      '/hashtags/ranking',
    );

    if (response is! List) {
      throw Exception(
        'Formato de hashtags inválido.',
      );
    }

    return response
        .map(
          (item) => Hashtag.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<List<Hashtag>> listar() async {
    final response = await _apiService.get(
      '/hashtags/listar',
    );

    if (response is! List) {
      throw Exception(
        'Formato de hashtags inválido.',
      );
    }

    return response
        .map(
          (item) => Hashtag.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<List<dynamic>> listarPublicacoes(
    String nome,
  ) async {
    final nomeFormatado = nome.startsWith('#')
        ? nome.substring(1)
        : nome;

    final response = await _apiService.get(
      '/hashtags/publicacoes/$nomeFormatado',
    );

    if (response is! List) {
      throw Exception(
        'Formato de publicações da hashtag inválido.',
      );
    }

    return response;
  }
}