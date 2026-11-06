import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class AuthService {
  Future<void> login({required String email, required String senha}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/usuarios/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email.trim().toLowerCase(), 'senha': senha}),
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        dados is Map && dados['mensagem'] != null
            ? dados['mensagem']
            : 'Não foi possível realizar o login.',
      );
    }

    if (dados is! Map || dados['token'] == null) {
      throw Exception('O servidor não retornou um token válido.');
    }

    final token = dados['token'] as String;
    final partes = token.split('.');

    if (partes.length != 3) {
      throw Exception('Token recebido em formato inválido.');
    }

    final payload = partes[1];
    final payloadCorrigido = base64Url.normalize(payload);
    final usuario = jsonDecode(utf8.decode(base64Url.decode(payloadCorrigido)));

    final preferencias = await SharedPreferences.getInstance();

    await preferencias.setString('token', token);
    await preferencias.setInt('usuarioId', usuario['id']);
    await preferencias.setString('usuarioEmail', email.trim().toLowerCase());
    await preferencias.setString('usuarioNome', usuario['nome'] ?? '');
    await preferencias.setString('usuarioTipo', usuario['tipo'] ?? '');
    await preferencias.setInt('empresaId', usuario['empresaId']);
  }

  Future<String> getEmail() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString('usuarioEmail') ?? 'Usuário';
  }

  Future<void> logout() async {
    final preferencias = await SharedPreferences.getInstance();

    await preferencias.remove('token');
    await preferencias.remove('usuarioId');
    await preferencias.remove('usuarioEmail');
    await preferencias.remove('usuarioNome');
    await preferencias.remove('usuarioTipo');
    await preferencias.remove('empresaId');
  }
}
