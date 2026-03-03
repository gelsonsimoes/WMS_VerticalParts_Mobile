import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';

class TaskItem {
  final String sku;
  final String descricao;
  final int esperado;
  int coletado;

  TaskItem({
    required this.sku,
    required this.descricao,
    required this.esperado,
    this.coletado = 0,
  });

  bool get isCompleto => coletado == esperado;
}

class TaskSummaryScreen extends StatefulWidget {
  const TaskSummaryScreen({super.key});

  @override
  State<TaskSummaryScreen> createState() => _TaskSummaryScreenState();
}

class _TaskSummaryScreenState extends State<TaskSummaryScreen> {
  bool _isLoading = false;

  // Mock de dados da Tarefa Atual (Espelho da API REST)
  final List<TaskItem> _itensTarefa = [
    TaskItem(sku: "VEPEL-BPI-174FX", descricao: "BUCHA PLÁSTICA IND. 174FX", esperado: 5, coletado: 5),
    TaskItem(sku: "VPER-ESS-NY-27MM", descricao: "ESPAÇADOR NYLON 27MM", esperado: 10, coletado: 7),
    TaskItem(sku: "VP-MTR-88-AL", descricao: "MONTANTE DE ALUMÍNIO 88", esperado: 2, coletado: 0),
  ];

  Future<void> _finalizarTarefa() async {
    bool temPendencia = _itensTarefa.any((item) => !item.isCompleto);

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
    setState(() => _isLoading = true);

    // Simulação Regra de Ouro: POST final para o WMS_VerticalParts
    await Future.delayed(const Duration(seconds: 1));

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
  }

  @override
  Widget build(BuildContext context) {
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
                itemCount: _itensTarefa.length,
                itemBuilder: (context, index) {
                  final item = _itensTarefa[index];
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

  Widget _buildItemCard(TaskItem item) {
    Color statusColor = item.isCompleto ? AppTheme.successGreen : AppTheme.goldPrimary;
    if (item.coletado == 0) statusColor = AppTheme.textMuted;

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
              '${item.coletado}/${item.esperado}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15.sp),
            ),
          ),
        ],
      ),
    );
  }
}
