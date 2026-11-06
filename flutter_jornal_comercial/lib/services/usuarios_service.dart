import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<Usuario> buscarUsuarioLogado() async {
    final usuarioId = await _obterUsuarioId();

    return buscarUsuarioPorId(usuarioId);
  }

  Future<Usuario> buscarUsuarioPorId(int usuarioId) async {
    final response = await _apiService.get('/usuarios/buscar/$usuarioId');

    if (response is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao buscar usuário.');
    }

    return Usuario.fromJson(response);
  }

  Future<Usuario> atualizarUsuario({
    required int usuarioId,
    String? bio,
  }) async {
    final body = <String, dynamic>{};

    if (bio != null) {
      body['bio'] = bio;
    }

    final response = await _apiService.put(
      '/usuarios/atualizar/$usuarioId',
      body: body,
    );

    if (response is Map && response['usuario'] is Map) {
      return Usuario.fromJson(Map<String, dynamic>.from(response['usuario']));
    }

    return buscarUsuarioPorId(usuarioId);
  }

  Future<void> atualizarFoto(XFile arquivo) async {
    await _apiService.uploadArquivo(
      '/usuarios/foto-perfil',
      await arquivo.readAsBytes(),
      arquivo.name,
    );
  }

  Future<void> atualizarTemplate(int usuarioId, XFile arquivo) async {
    await _apiService.uploadArquivo(
      '/usuarios/template/$usuarioId',
      await arquivo.readAsBytes(),
      arquivo.name,
    );
  }
}
