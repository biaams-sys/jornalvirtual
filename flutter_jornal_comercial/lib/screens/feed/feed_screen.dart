
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/publicacao.dart';
import '../../services/publicacao_service.dart';
import '../../widgets/hashtags_em_alta.dart';
import '../../widgets/nova_publicacao_modal.dart';
import '../../widgets/publicacao_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PublicacaoService _service = PublicacaoService();

  final TextEditingController _pesquisaController =
      TextEditingController();

  late Future<List<Publicacao>> _publicacoesFuture;

  int? _usuarioId;
  String _termoPesquisa = '';
  String? _hashtagSelecionada;

  @override
  void initState() {
    super.initState();
    _publicacoesFuture = _carregarPublicacoes();
    _carregarUsuario();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _usuarioId = prefs.getInt('usuarioId');
    });
  }

  Future<List<Publicacao>> _carregarPublicacoes() {
    return _service.listarPublicacoes();
  }

  Future<void> _atualizarFeed() async {
    final consulta = _carregarPublicacoes();

    setState(() {
      _publicacoesFuture = consulta;
    });

    try {
      await consulta;
    } catch (_) {
      // O FutureBuilder apresenta o erro na tela.
    }
  }

  Future<void> _abrirNovaPublicacao() async {
    await showDialog(
      context: context,
      builder: (_) {
        return NovaPublicacaoModal(
          atualizar: _atualizarFeed,
        );
      },
    );
  }

  String _normalizar(String texto) {
    var resultado = texto.toLowerCase().trim();

    const acentos = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    acentos.forEach((acento, substituto) {
      resultado = resultado.replaceAll(acento, substituto);
    });

    return resultado;
  }

  String _nomeHashtag(dynamic hashtag) {
    if (hashtag is String || hashtag is num) {
      return hashtag
          .toString()
          .trim()
          .replaceFirst(RegExp(r'^#+'), '');
    }

    if (hashtag is Map) {
      for (final chave in [
        'nome',
        'hashtag',
        'texto',
        'tag',
        'name',
      ]) {
        final valor = hashtag[chave];

        if (valor != null && valor.toString().trim().isNotEmpty) {
          return valor
              .toString()
              .trim()
              .replaceFirst(RegExp(r'^#+'), '');
        }
      }
    }

    return '';
  }

  String _textoCampo(dynamic valor) {
    if (valor == null) return '';

    if (valor is String || valor is num) {
      return valor.toString();
    }

    if (valor is Map) {
      // Procura os campos de nome mais comuns sem incluir IDs.
      final partes = <String>[];

      for (final chave in [
        'nome',
        'nomeUsuario',
        'usuario',
        'username',
        'titulo',
        'texto',
      ]) {
        final item = valor[chave];

        if (item != null && item is! Map && item is! List) {
          partes.add(item.toString());
        } else if (item is Map) {
          partes.add(_textoCampo(item));
        }
      }

      return partes.join(' ');
    }

    if (valor is Iterable) {
      return valor.map(_textoCampo).join(' ');
    }

    return '';
  }

  bool _correspondePesquisa(Publicacao publicacao) {
    final termo = _normalizar(_termoPesquisa);

    if (termo.isEmpty) return true;

    final textoPublicacao = _normalizar(
      publicacao.texto ?? '',
    );

    final textoAutor = _normalizar(
      _textoCampo(publicacao.autor),
    );

    final textoEmpresa = _normalizar(
      _textoCampo(publicacao.empresa),
    );

    final textoHashtags = _normalizar(
      publicacao.hashtags
          .map(_nomeHashtag)
          .where((nome) => nome.isNotEmpty)
          .join(' '),
    );

    return textoPublicacao.contains(termo) ||
        textoAutor.contains(termo) ||
        textoEmpresa.contains(termo) ||
        textoHashtags.contains(termo);
  }

  bool _correspondeHashtag(Publicacao publicacao) {
    if (_hashtagSelecionada == null) return true;

    final selecionada = _normalizar(
      _hashtagSelecionada!.replaceFirst(RegExp(r'^#+'), ''),
    );

    return publicacao.hashtags.any((hashtag) {
      final nome = _normalizar(_nomeHashtag(hashtag));
      return nome.isNotEmpty && nome == selecionada;
    });
  }

  List<Publicacao> _filtrarPublicacoes(
    List<Publicacao> publicacoes,
  ) {
    return publicacoes.where((publicacao) {
      return _correspondePesquisa(publicacao) &&
          _correspondeHashtag(publicacao);
    }).toList();
  }

  void _selecionarHashtag(String hashtag) {
    setState(() {
      _hashtagSelecionada = hashtag
          .trim()
          .replaceFirst(RegExp(r'^#+'), '');

      _termoPesquisa = '';
      _pesquisaController.clear();
    });
  }

  void _limparFiltros() {
    setState(() {
      _termoPesquisa = '';
      _hashtagSelecionada = null;
      _pesquisaController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD52B6D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _atualizarFeed,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar feed',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovaPublicacao,
        backgroundColor: const Color(0xFFC92768),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Publicar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _campoPesquisa(),
                const SizedBox(height: 16),
                HashtagsEmAlta(
                  onHashtagSelecionada: _selecionarHashtag,
                ),
                if (_hashtagSelecionada != null) ...[
                  const SizedBox(height: 12),
                  _filtroAtivo(),
                ],
                const SizedBox(height: 20),
                Expanded(child: _feed()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoPesquisa() {
    return TextField(
      controller: _pesquisaController,
      onChanged: (valor) {
        setState(() {
          _termoPesquisa = valor;
          _hashtagSelecionada = null;
        });
      },
      decoration: InputDecoration(
        hintText: 'Pesquisar publicações, hashtags ou pessoas...',
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFFD52B6D),
        ),
        suffixIcon: _termoPesquisa.isNotEmpty
            ? IconButton(
                onPressed: _limparFiltros,
                icon: const Icon(Icons.close),
                tooltip: 'Limpar pesquisa',
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE9E1E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE9E1E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFD52B6D),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _filtroAtivo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE7EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tag,
            size: 19,
            color: Color(0xFFD52B6D),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtrando por #$_hashtagSelecionada',
              style: const TextStyle(
                color: Color(0xFFC92768),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _limparFiltros,
            child: const Text(
              'Limpar filtros',
              style: TextStyle(color: Color(0xFFC92768)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feed() {
    return FutureBuilder<List<Publicacao>>(
      future: _publicacoesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(
                color: Color(0xFFD52B6D),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 45,
                  color: Colors.grey,
                ),
                const SizedBox(height: 10),
                const Text('Não foi possível carregar o feed.'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _atualizarFeed,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final todasPublicacoes = snapshot.data ?? [];
        final publicacoes = _filtrarPublicacoes(todasPublicacoes);

        if (todasPublicacoes.isEmpty &&
            _termoPesquisa.trim().isEmpty &&
            _hashtagSelecionada == null) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 50,
                    color: Color(0xFFC92768),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ainda não há publicações.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Seja a primeira pessoa a publicar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (publicacoes.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 45),
              const Icon(
                Icons.search_off,
                size: 50,
                color: Color(0xFFD52B6D),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nenhuma publicação encontrada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tente outra palavra ou limpe os filtros.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _limparFiltros,
                  child: const Text(
                    'Limpar filtros',
                    style: TextStyle(color: Color(0xFFC92768)),
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: _atualizarFeed,
          color: const Color(0xFFD52B6D),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: publicacoes.length,
            itemBuilder: (context, index) {
              final publicacao = publicacoes[index];

              return PublicacaoCard(
                key: ValueKey(publicacao.id),
                publicacao: publicacao,
                usuarioId: _usuarioId,
                atualizar: _atualizarFeed,
              );
            },
          ),
        );
      },
    );
  }
}
