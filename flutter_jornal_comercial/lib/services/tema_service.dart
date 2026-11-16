
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';

class TemaService {
  TemaService._();

  static final ValueNotifier<ThemeData> temaAtual =
      ValueNotifier<ThemeData>(AppTheme.light);

  static Future<void> carregarTema() async {
    try {
      final preferencias = await SharedPreferences.getInstance();

      final token = preferencias.getString('token');
      final empresaId = preferencias.getInt('empresaId');

      if (token == null || empresaId == null) {
        restaurarPadrao();
        return;
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/tema/buscar/$empresaId',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        restaurarPadrao();
        return;
      }

      final dados = jsonDecode(response.body);

      if (dados is! Map) {
        restaurarPadrao();
        return;
      }

      final tema = dados['tema'] is Map ? dados['tema'] : dados;

      temaAtual.value = AppTheme.criar(
        primary: _lerCor(
          tema['primary'],
          const Color(0xFF315C63),
        ),
        primaryDark: _lerCor(
          tema['primaryDark'],
          const Color(0xFF264A50),
        ),
        secondary: _lerCor(
          tema['secondary'],
          const Color(0xFF687276),
        ),
        background: _lerCor(
          tema['background'],
          const Color(0xFFF3F5F4),
        ),
        surface: _lerCor(
          tema['surface'],
          const Color(0xFFFFFFFF),
        ),
        text: _lerCor(
          tema['text'],
          const Color(0xFF273033),
        ),
        textLight: _lerCor(
          tema['textLight'],
          const Color(0xFF687276),
        ),
        border: _lerCor(
          tema['border'],
          const Color(0xFFD6DCDD),
        ),
        danger: _lerCor(
          tema['danger'],
          const Color(0xFFB42318),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao carregar tema da empresa: $e');
      restaurarPadrao();
    }
  }

  static Color _lerCor(dynamic valor, Color padrao) {
    if (valor == null) return padrao;

    String hexadecimal = valor.toString().trim();

    if (hexadecimal.isEmpty) return padrao;

    hexadecimal = hexadecimal.replaceAll('#', '');

    if (hexadecimal.toLowerCase().startsWith('0x')) {
      hexadecimal = hexadecimal.substring(2);
    }

    if (hexadecimal.length == 6) {
      hexadecimal = 'FF$hexadecimal';
    }

    if (hexadecimal.length != 8) {
      return padrao;
    }

    final numero = int.tryParse(hexadecimal, radix: 16);

    if (numero == null) return padrao;

    return Color(numero);
  }

  static void restaurarPadrao() {
    temaAtual.value = AppTheme.light;
  }
}
