import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/noticia.dart';

class NotificacaoService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _chaveNotificacoesAtivas = 'notificacoes_ativas';

  static const String _chaveNoticiasConhecidas = 'noticias_conhecidas';

  static Future<void> inicializar() async {
    const configuracoes = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings: configuracoes);
  }

  static Future<bool> solicitarPermissao() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) {
      return false;
    }

    final permissao = await android.requestNotificationsPermission();
    final notificacoesPermitidas = await android.areNotificationsEnabled();

    return notificacoesPermitidas ?? permissao ?? false;
  }

  static Future<void> definirNotificacoesAtivas(bool ativo) async {
    final preferencias = await SharedPreferences.getInstance();

    await preferencias.setBool(_chaveNotificacoesAtivas, ativo);
  }

  static Future<bool> notificacoesEstaoAtivas() async {
    final preferencias = await SharedPreferences.getInstance();

    return preferencias.getBool(_chaveNotificacoesAtivas) ?? false;
  }

  static Future<void> verificarNovasNoticias(List<Noticia> noticias) async {
    if (noticias.isEmpty) return;

    final preferencias = await SharedPreferences.getInstance();

    final idsAtuais = noticias.map((noticia) => noticia.id.toString()).toSet();

    final idsSalvos = preferencias.getStringList(_chaveNoticiasConhecidas);

    if (idsSalvos == null) {
      await preferencias.setStringList(
        _chaveNoticiasConhecidas,
        idsAtuais.toList(),
      );
      return;
    }

    final idsConhecidos = idsSalvos.toSet();

    final noticiasNovas = noticias.where((noticia) {
      return !idsConhecidos.contains(noticia.id.toString());
    }).toList();

    final ativo = await notificacoesEstaoAtivas();

    if (!ativo) {
      idsConhecidos.addAll(idsAtuais);

      await preferencias.setStringList(
        _chaveNoticiasConhecidas,
        idsConhecidos.toList(),
      );

      return;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final permitido = await android?.areNotificationsEnabled() ?? false;

    if (!permitido) {
      idsConhecidos.addAll(idsAtuais);

      await preferencias.setStringList(
        _chaveNoticiasConhecidas,
        idsConhecidos.toList(),
      );

      return;
    }

    for (final noticia in noticiasNovas) {
      await mostrar(
        id: noticia.id,
        titulo: 'Nova notícia no Jornal Virtual',
        mensagem: noticia.titulo,
      );

      idsConhecidos.add(noticia.id.toString());

      await preferencias.setStringList(
        _chaveNoticiasConhecidas,
        idsConhecidos.toList(),
      );
    }
  }

  static Future<void> mostrar({
    required int id,
    required String titulo,
    required String mensagem,
  }) async {
    const detalhes = NotificationDetails(
      android: AndroidNotificationDetails(
        'novas_noticias',
        'Novas notícias',
        channelDescription: 'Avisos sobre novas notícias publicadas.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      id: id,
      title: titulo,
      body: mensagem,
      notificationDetails: detalhes,
    );
  }
}
