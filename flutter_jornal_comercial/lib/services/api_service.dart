import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  // Ajusta e injeta as chaves de API obrigatórias que o Supabase exige para liberar o acesso
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'apikey': ApiConstants.apiKey,
      'Authorization': 'Bearer ${ApiConstants.apiKey}',
      'Prefer': 'return=representation',
    };
  }

  // Função auxiliar para garantir que a URL seja montada com uma única barra separadora
  Uri _montarUri(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('${ApiConstants.baseUrl}$path');
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      _montarUri(endpoint),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      _montarUri(endpoint),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      _montarUri(endpoint),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.delete(
      _montarUri(endpoint),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> uploadArquivo(
    String endpoint,
    List<int> bytes,
    String nomeArquivo,
  ) async {
    final request = http.MultipartRequest('POST', _montarUri(endpoint));

    // Repassa os cabeçalhos de autenticação da nuvem para o upload de multipartes
    final headersAutenticacao = await _getHeaders();
    request.headers.addAll(headersAutenticacao);

    final extensao = nomeArquivo.split('.').last.toLowerCase();
    MediaType? tipoArquivo;

    switch (extensao) {
      case 'jpg':
      case 'jpeg':
        tipoArquivo = MediaType('image', 'jpeg');
        break;
      case 'png':
        tipoArquivo = MediaType('image', 'png');
        break;
      case 'webp':
        tipoArquivo = MediaType('image', 'webp');
        break;
      case 'mp4':
        tipoArquivo = MediaType('video', 'mp4');
        break;
      case 'webm':
        tipoArquivo = MediaType('video', 'webm');
        break;
      case 'mkv':
        tipoArquivo = MediaType('video', 'x-matroska');
        break;
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'arquivo',
        bytes,
        filename: nomeArquivo,
        contentType: tipoArquivo,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (data is Map && data['mensagem'] != null) {
      throw Exception(data['mensagem']);
    }

    if (data is Map && data['erro'] != null) {
      throw Exception(data['erro']);
    }

    throw Exception(
      'Erro ${response.statusCode}: ${response.reasonPhrase} - ${response.body}',
    );
  }
}
