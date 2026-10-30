import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/noticia.dart';

class HistoricoNoticiasService {
  static const String _chave = 'historico_noticias';

  Future<void> registrar(Noticia noticia) async {
    final prefs = await SharedPreferences.getInstance();

    final historicoSalvo = prefs.getStringList(_chave) ?? [];

    final noticias = historicoSalvo
        .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
        .toList();

    noticias.removeWhere(
      (item) => item['id'] == noticia.id,
    );

    noticias.insert(0, {
      'id': noticia.id,
      'titulo': noticia.titulo,
      'subtitulo': noticia.subtitulo,
      'texto': noticia.texto,
      'dataPublicacao': noticia.dataPublicacao.toIso8601String(),
      'dataAtualizacao': noticia.dataAtualizacao.toIso8601String(),
      'autor': noticia.autor,
      'midias': noticia.midias,
    });

    if (noticias.length > 3) {
      noticias.removeRange(3, noticias.length);
    }

    await prefs.setStringList(
      _chave,
      noticias.map((item) => jsonEncode(item)).toList(),
    );
  }

  Future<List<Noticia>> listar() async {
    final prefs = await SharedPreferences.getInstance();

    final historicoSalvo = prefs.getStringList(_chave) ?? [];

    return historicoSalvo.map((item) {
      final json = Map<String, dynamic>.from(jsonDecode(item));

      return Noticia.fromJson(json);
    }).toList();
  }
}