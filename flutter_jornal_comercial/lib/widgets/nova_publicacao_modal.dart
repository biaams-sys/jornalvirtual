import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/publicacao_service.dart';

class NovaPublicacaoModal extends StatefulWidget {
  final VoidCallback? atualizar;

  const NovaPublicacaoModal({
    super.key,
    this.atualizar,
  });

  @override
  State<NovaPublicacaoModal> createState() =>
      _NovaPublicacaoModalState();
}

class _NovaPublicacaoModalState
    extends State<NovaPublicacaoModal> {
  final TextEditingController _textoController =
      TextEditingController();

  final PublicacaoService _service =
      PublicacaoService();

  final ImagePicker _picker = ImagePicker();

  bool _carregando = false;

  XFile? _midiaSelecionada;

  Future<void> _selecionarMidia() async {
    try {
      final arquivo = await _picker.pickMedia();

      if (arquivo == null) return;

      setState(() {
        _midiaSelecionada = arquivo;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível selecionar a mídia: $e',
          ),
        ),
      );
    }
  }

  Future<void> _publicar() async {
    final texto = _textoController.text.trim();

    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Digite algo antes de publicar.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final publicacaoId =
          await _service.criarPublicacao(
        texto: texto,
      );

      print('ID DA PUBLICAÇÃO: $publicacaoId');

      if (_midiaSelecionada != null) {
        print(
          'CAMINHO DA MÍDIA: ${_midiaSelecionada!.path}',
        );

        print(
          'NOME DA MÍDIA: ${_midiaSelecionada!.name}',
        );

     await _service.adicionarMidia(
  publicacaoId,
  _midiaSelecionada!,
);
      }

      if (!mounted) return;

      Navigator.pop(context);

      widget.atualizar?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Publicação criada com sucesso!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      print('ERRO AO PUBLICAR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nova publicação',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _carregando
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _textoController,
                maxLines: 7,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText:
                      'O que está acontecendo?',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFC92768),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Use #hashtags no texto. Elas serão '
                'identificadas automaticamente.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _carregando
                        ? null
                        : _selecionarMidia,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                    ),
                    label: const Text(
                      'Adicionar foto/vídeo',
                    ),
                  ),
                ],
              ),

              if (_midiaSelecionada != null) ...[
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6F8),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEDE4E7),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        color: Color(0xFFC92768),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          _midiaSelecionada!.name,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),

                      IconButton(
                        onPressed: _carregando
                            ? null
                            : () {
                                setState(() {
                                  _midiaSelecionada =
                                      null;
                                });
                              },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _carregando ? null : _publicar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFC92768),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: _carregando
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Publicar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}