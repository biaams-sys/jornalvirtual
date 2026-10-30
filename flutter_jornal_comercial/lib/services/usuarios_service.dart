import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../models/usuario.dart';
import 'api_service.dart';

class UsuarioService {
  final ApiService _apiService = ApiService();

  Future<int> _obterUsuarioId() async {
    final preferencias = await SharedPreferences.getInstance();

    final usuarioIdSalvo = preferencias.getInt('usuarioId');

    if (usuarioIdSalvo != null) {
      return usuarioIdSalvo;
    }

    final token = preferencias.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      final partes = token.split('.');

      if (partes.length != 3) {
        throw Exception('Token inválido.');
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(partes[1])),
      );

      final dados = jsonDecode(payload) as Map<String, dynamic>;

      final id =
          dados['id'] ?? dados['usuarioId'] ?? dados['userId'] ?? dados['sub'];

      final usuarioId = int.tryParse(id.toString());

      if (usuarioId == null) {
        throw Exception('Não foi possível identificar o usuário.');
      }

      return usuarioId;
    } catch (_) {
      throw Exception('Não foi possível identificar o usuário autenticado.');
    }
  }

  // Busca os dados do usuário que está conectado.
  Future<Usuario> buscarUsuarioLogado() async {
    final usuarioId = await _obterUsuarioId();

    return buscarUsuarioPorId(usuarioId);
  }

  // Busca os dados de qualquer usuário pelo ID.
  Future<Usuario> buscarUsuarioPorId(int usuarioId) async {
    // Filtra na tabela Usuarios onde o id é igual ao ID passado
    final url = '${ApiConstants.usuarios}?id=eq.$usuarioId';
    final response = await _apiService.get(url);

    if (response is! List || response.isEmpty) {
      throw Exception('Usuário não encontrado.');
    }

    return Usuario.fromJson(Map<String, dynamic>.from(response.first));
  }

  // Atualiza os dados do usuário.
  Future<Usuario> atualizarUsuario({
    required int usuarioId,
    String? bio,
  }) async {
    final body = <String, dynamic>{};

    if (bio != null) {
      body['bio'] = bio;
    }

    // No Supabase, atualizações usam PATCH com o filtro do ID na URL
    final url = '${ApiConstants.usuarios}?id=eq.$usuarioId';

    // Certifique-se de que a sua classe ApiService execute o método PATCH ou PUT enviando os headers do ApiConstants
    final response = await _apiService.put(url, body: body);

    return buscarUsuarioPorId(usuarioId);
  }

  // Atualiza a foto de perfil do usuário conectado.
  Future<void> atualizarFoto(XFile arquivo) async {
    final bytes = await arquivo.readAsBytes();

    await _apiService.uploadArquivo(
      '${ApiConstants.usuarios}/foto-perfil',
      bytes,
      arquivo.name,
    );
  }

  // Atualiza o template do perfil.
  Future<void> atualizarTemplate(int usuarioId, XFile arquivo) async {
    final bytes = await arquivo.readAsBytes();

    await _apiService.uploadArquivo(
      '${ApiConstants.usuarios}/template/$usuarioId',
      bytes,
      arquivo.name,
    );
  }
}
