import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../data/providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFICAÇÕES'),
        backgroundColor: AppTheme.darkBackground,
        actions: [
          if (provider.naoLidas > 0)
            TextButton(
              onPressed: provider.marcarTodasLidas,
              child: const Text('LER TODAS', style: TextStyle(color: AppTheme.goldPrimary)),
            ),
        ],
      ),
      body: provider.notificacoes.isEmpty
          ? _buildVazio()
          : ListView.separated(
              padding: EdgeInsets.all(4.w),
              itemCount: provider.notificacoes.length,
              separatorBuilder: (_, __) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final n = provider.notificacoes[index];
                return _NotificationCard(
                  notificacao: n,
                  onTap: () => provider.marcarLida(n.id),
                );
              },
            ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 20.w, color: AppTheme.textMuted),
          SizedBox(height: 2.h),
          Text('NENHUMA NOTIFICAÇÃO',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14.sp, letterSpacing: 2)),
          SizedBox(height: 1.h),
          Text('Ações do sistema aparecerão aqui em tempo real',
              style: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 10.sp)),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final WMSNotification notificacao;
  final VoidCallback onTap;

  const _NotificationCard({required this.notificacao, required this.onTap});

  Color get _cor {
    switch (notificacao.tipo) {
      case 'tarefa': return AppTheme.goldPrimary;
      case 'alerta': return AppTheme.errorRed;
      default: return AppTheme.successGreen;
    }
  }

  IconData get _icone {
    switch (notificacao.tipo) {
      case 'tarefa': return Icons.assignment_rounded;
      case 'alerta': return Icons.warning_amber_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  String _formatarTempo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: notificacao.lida ? AppTheme.surfaceDark : _cor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notificacao.lida ? AppTheme.surfaceDark : _cor.withOpacity(0.5),
            width: notificacao.lida ? 1 : 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_icone, color: _cor, size: 20),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(notificacao.titulo,
                            style: TextStyle(
                              color: notificacao.lida ? AppTheme.textMuted : AppTheme.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                            )),
                      ),
                      Text(_formatarTempo(notificacao.criadoEm),
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 9.sp)),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(notificacao.mensagem,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
                ],
              ),
            ),
            if (!notificacao.lida)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 8, top: 4),
                decoration: BoxDecoration(color: _cor, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
