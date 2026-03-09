import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../data/models/task_model.dart' as model;
import '../../data/services/supabase_service.dart';

class TaskSummaryScreen extends StatefulWidget {
  const TaskSummaryScreen({super.key});

  @override
  State<TaskSummaryScreen> createState() => _TaskSummaryScreenState();
}

class _TaskSummaryScreenState extends State<TaskSummaryScreen> {
  bool _isLoading = false;
  model.Task? _task;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is model.Task) {
      _task = args;
    }
  }

  Future<void> _finalizarTarefa() async {
    if (_task == null) return;
    
    // Verifica se todos os itens foram coletados
    bool temPendencia = _task!.itens.any((item) => item.quantidadeColetada < item.quantidadeEsperada);

    if (temPendencia) {
      _showConfirmacaoCorte();
    } else {
      _executarSincronizacaoFinal();
    }
  }

  void _showConfirmacaoCorte() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 60),
              SizedBox(height: 2.h),
              Text(
                'ITENS PENDENTES!',
                style: TextStyle(color: AppTheme.errorRed, fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              const Text(
                'Ainda há itens que não foram totalmente coletados. Deseja finalizar a tarefa com CORTE/FALTA?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                height: 8.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _executarSincronizacaoFinal();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                  child: const Text('SIM, ENCERRAR COM FALTA'),
                ),
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                height: 8.h,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.goldPrimary)),
                  child: const Text('NÃO, VOLTAR À LEITURA', style: TextStyle(color: AppTheme.goldPrimary)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executarSincronizacaoFinal() async {
    if (_task == null) return;
    
    setState(() => _isLoading = true);

    try {
      // Atualiza o status da tarefa para concluída no Supabase
      await SupabaseService.client.from('tarefas').update({
        'status': 'concluida',
        'finished_at': DateTime.now().toIso8601String(),
      }).eq('id', _task!.id);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TAREFA SINCRONIZADA E ENCERRADA NO WMS!', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainMenu, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERRO AO FINALIZAR: $e', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RESUMO DA ORDEM')),
        body: const Center(child: Text('Nenhuma tarefa carregada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('RESUMO DA ORDEM'),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(4.w),
                itemCount: _task!.itens.length,
                itemBuilder: (context, index) {
                  final item = _task!.itens[index];
                  return _buildItemCard(item);
                },
              ),
            ),
            
            // Botão Fixo de Finalização
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 10.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finalizarTarefa,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppTheme.darkBackground)
                      : Text('FINALIZAR TAREFA', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(model.TaskItem item) {
    final bool isCompleto = item.quantidadeColetada >= item.quantidadeEsperada;
    Color statusColor = isCompleto ? AppTheme.successGreen : AppTheme.goldPrimary;
    if (item.quantidadeColetada == 0) statusColor = AppTheme.textMuted;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.sku, style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 0.5.h),
                Text(item.descricao, style: TextStyle(color: AppTheme.textLight, fontSize: 11.sp)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              '${item.quantidadeColetada}/${item.quantidadeEsperada}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15.sp),
            ),
          ),
        ],
      ),
    );
  }
}
