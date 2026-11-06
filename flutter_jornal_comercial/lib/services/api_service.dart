import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final preferencias = await SharedPreferences.getInstance();
    final token = preferencias.getString('token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _montarUri(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('${ApiConstants.baseUrl}$path');
  }

  Future<dynamic> uploadArquivo(
    String endpoint,
    List<int> bytes,
    String nomeArquivo,
  ) async {
    final request = http.MultipartRequest('POST', _montarUri(endpoint));

    final headers = await _getHeaders();
    headers.remove('Content-Type');

    request.headers.addAll(headers);

    request.files.add(
      http.MultipartFile.fromBytes('arquivo', bytes, filename: nomeArquivo),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
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
