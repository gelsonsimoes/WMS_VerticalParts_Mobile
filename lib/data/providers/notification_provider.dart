import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WMSNotification {
  final String id;
  final String titulo;
  final String mensagem;
  final String tipo; // 'tarefa', 'alerta', 'sistema'
  final DateTime criadoEm;
  bool lida;

  WMSNotification({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.criadoEm,
    this.lida = false,
  });
}

class NotificationProvider with ChangeNotifier {
  final List<WMSNotification> _notificacoes = [];
  RealtimeChannel? _channel;

  List<WMSNotification> get notificacoes => List.unmodifiable(_notificacoes);
  int get naoLidas => _notificacoes.where((n) => !n.lida).length;

  void iniciarEscuta() {
    final client = Supabase.instance.client;

    _channel = client
        .channel('wms_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tarefas',
          callback: (payload) {
            final nova = WMSNotification(
              id: payload.newRecord['id']?.toString() ?? DateTime.now().toString(),
              titulo: 'Nova Tarefa Disponível',
              mensagem: 'Tipo: ${payload.newRecord['tipo'] ?? 'Operação'} — Prioridade: ${payload.newRecord['prioridade'] ?? 'Normal'}',
              tipo: 'tarefa',
              criadoEm: DateTime.now(),
            );
            _notificacoes.insert(0, nova);
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tarefas',
          callback: (payload) {
            final status = payload.newRecord['status'] ?? '';
            if (status == 'em_andamento' || status == 'concluida') {
              final nova = WMSNotification(
                id: 'upd_${DateTime.now().millisecondsSinceEpoch}',
                titulo: 'Tarefa Atualizada',
                mensagem: 'Status alterado para: ${status.toUpperCase()}',
                tipo: 'alerta',
                criadoEm: DateTime.now(),
              );
              _notificacoes.insert(0, nova);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  void adicionarSistema(String titulo, String mensagem) {
    _notificacoes.insert(0, WMSNotification(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      titulo: titulo,
      mensagem: mensagem,
      tipo: 'sistema',
      criadoEm: DateTime.now(),
    ));
    notifyListeners();
  }

  void marcarTodasLidas() {
    for (final n in _notificacoes) { n.lida = true; }
    notifyListeners();
  }

  void marcarLida(String id) {
    final idx = _notificacoes.indexWhere((n) => n.id == id);
    if (idx != -1) { _notificacoes[idx].lida = true; notifyListeners(); }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
