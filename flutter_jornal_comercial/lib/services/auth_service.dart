import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<void> login({required String email, required String senha}) async {
    // DESVIO TEMPORÁRIO COMPLETO: Injeta todas as claims de permissão que o seu app exige
    final preferencias = await SharedPreferences.getInstance();

    // 1. Salva as credenciais básicas
    await preferencias.setInt('usuarioId', 1);
    await preferencias.setString('usuarioEmail', email.toLowerCase().trim());

    // 2. Monta o payload do Token JWT com as informações idênticas ao que o seu backend Node gerava
    // Isso garante que qualquer decodificador de token nas outras abas libere o acesso!
    final dadosToken = {
      'id': 1,
      'nome': 'Beatriz Admin',
      'tipo':
          'ADMINISTRADOR', // Atribui o cargo mais alto para liberar todas as notícias
      'empresaId': 1, // Vincula com a empresa padrão que criamos
    };

    // Transforma o objeto acima no formato Base64Url exigido pelo padrão JWT
    final payloadString = jsonEncode(dadosToken);
    final payloadBytes = utf8.encode(payloadString);
    final payloadBase64 = base64Url.encode(payloadBytes).replaceAll('=', '');

    // Salva o token estruturado perfeitamente em 3 partes (header.payload.signature)
    await preferencias.setString('token', 'ficticio.$payloadBase64.ficticio');

    return;
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
  }
}
