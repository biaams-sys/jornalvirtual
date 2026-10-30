
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/publicacao.dart';
import '../services/publicacao_service.dart';

class ComentariosModal extends StatefulWidget {
  final Publicacao publicacao;

  const ComentariosModal({
    super.key,
    required this.publicacao,
  });

  @override
  State<ComentariosModal> createState() => _ComentariosModalState();
}

class _ComentariosModalState extends State<ComentariosModal> {
  final PublicacaoService _service = PublicacaoService();
  final TextEditingController _controller = TextEditingController();

  List<dynamic> _comentarios = [];

  bool _carregando = true;
  bool _enviando = false;
  int? _usuarioId;
  int? _comentarioRespondendo;
  int? _excluindoComentarioId;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    _carregarComentarios();
  }

  Future<void> _carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _usuarioId = prefs.getInt('usuarioId');
    });
  }

  Future<void> _carregarComentarios() async {
    try {
      final comentarios = await _service.listarComentarios(
        widget.publicacao.id,
      );

      if (!mounted) return;

      setState(() {
        _comentarios = comentarios;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _controller.text.trim();

    if (texto.isEmpty) return;

    setState(() {
      _enviando = true;
    });

    try {
      await _service.criarComentario(
        publicacaoId: widget.publicacao.id,
        texto: texto,
        comentarioPaiId: _comentarioRespondendo,
      );

      _controller.clear();

      if (!mounted) return;

      setState(() {
        _comentarioRespondendo = null;
      });

      await _carregarComentarios();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  String _nome(dynamic comentario) {
    if (comentario is! Map) return 'Usuário';

    final autor = comentario['autor'];

    if (autor is Map && autor['nome'] != null) {
      return autor['nome'].toString();
    }

    return 'Usuário';
  }

  String _nomeResposta(dynamic resposta) {
    return _nome(resposta);
  }

  String _texto(dynamic item) {
    if (item is! Map) return '';

    return item['texto']?.toString() ?? '';
  }

  int? _obterId(dynamic item) {
    if (item is! Map) return null;

    final id = item['id'];

    if (id == null) return null;

    return int.tryParse(id.toString());
  }

  int? _obterAutorId(dynamic item) {
    if (item is! Map) return null;

    // Algumas respostas da API podem trazer usuarioId diretamente.
    final usuarioId = item['usuarioId'];

    if (usuarioId != null) {
      return int.tryParse(usuarioId.toString());
    }

    // Outras podem trazer o ID dentro do objeto autor.
    final autor = item['autor'];

    if (autor is Map && autor['id'] != null) {
      return int.tryParse(autor['id'].toString());
    }

    return null;
  }

  bool _ehDono(dynamic item) {
    if (_usuarioId == null) return false;

    return _obterAutorId(item) == _usuarioId;
  }

  Future<void> _excluirComentario(dynamic item) async {
    final comentarioId = _obterId(item);

    if (comentarioId == null ||
        !_ehDono(item) ||
        _excluindoComentarioId != null) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir comentário'),
        content: const Text(
          'Tem certeza de que deseja excluir este comentário?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _excluindoComentarioId = comentarioId;
    });

    try {
      await _service.excluirComentario(comentarioId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comentário excluído com sucesso.'),
        ),
      );

      if (_comentarioRespondendo == comentarioId) {
        setState(() {
          _comentarioRespondendo = null;
        });
      }

      await _carregarComentarios();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _excluindoComentarioId = null;
        });
      }
    }
  }

  Widget _menuExcluir(dynamic item) {
    if (!_ehDono(item)) {
      return const SizedBox.shrink();
    }

    final id = _obterId(item);
    final excluindo = id != null && id == _excluindoComentarioId;

    if (excluindo) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Opções do comentário',
      enabled: _excluindoComentarioId == null,
      onSelected: (opcao) {
        if (opcao == 'excluir') {
          _excluirComentario(item);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'excluir',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                'Excluir comentário',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(
          Icons.more_vert,
          size: 20,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _comentarioWidget(dynamic comentario) {
    if (comentario is! Map) {
      return const SizedBox.shrink();
    }

    final respostas = comentario['respostas'] is List
        ? comentario['respostas'] as List<dynamic>
        : <dynamic>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFF4D5E2),
                child: Icon(
                  Icons.person,
                  size: 19,
                  color: Color(0xFFC92768),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F5F7),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nome(comentario),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _texto(comentario),
                        style: const TextStyle(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              _menuExcluir(comentario),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 48,
              top: 5,
            ),
            child: TextButton(
              onPressed: () {
                final id = _obterId(comentario);

                if (id != null) {
                  setState(() {
                    _comentarioRespondendo = id;
                  });
                }
              },
              child: const Text(
                'Responder',
                style: TextStyle(
                  color: Color(0xFFC92768),
                ),
              ),
            ),
          ),
          if (respostas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Column(
                children: respostas.map<Widget>((resposta) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF8F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 15,
                          backgroundColor: Color(0xFFF4D5E2),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Color(0xFFC92768),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nomeResposta(resposta),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(_texto(resposta)),
                            ],
                          ),
                        ),
                        _menuExcluir(resposta),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Comentários',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _carregando
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _comentarios.isEmpty
                        ? const Center(
                            child: Text(
                              'Ainda não há comentários.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            itemCount: _comentarios.length,
                            itemBuilder: (context, index) {
                              return _comentarioWidget(
                                _comentarios[index],
                              );
                            },
                          ),
              ),
              if (_comentarioRespondendo != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 7,
                  ),
                  color: const Color(0xFFF9F5F7),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Respondendo a um comentário',
                          style: TextStyle(
                            color: Color(0xFFC92768),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _comentarioRespondendo = null;
                          });
                        },
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Escreva um comentário...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _enviando ? null : _enviarComentario,
                        icon: _enviando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Color(0xFFC92768),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
