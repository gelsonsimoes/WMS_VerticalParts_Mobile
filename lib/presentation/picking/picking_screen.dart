import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:verticalpartswms/theme/app_theme.dart';
import 'package:verticalpartswms/routes/app_routes.dart';
import 'package:verticalpartswms/presentation/scanner/widgets/scanner_overlay_widget.dart';
import 'package:verticalpartswms/presentation/scanner/widgets/industrial_numeric_keyboard.dart';
import 'package:verticalpartswms/data/models/task_model.dart' as model;
import 'package:verticalpartswms/data/providers/picking_provider.dart';

class PickingScreen extends StatefulWidget {
  const PickingScreen({super.key});

  @override
  State<PickingScreen> createState() => _PickingScreenState();
}

class _PickingScreenState extends State<PickingScreen> {
  final MobileScannerController _controller = MobileScannerController();
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is model.Task) {
      context.read<PickingProvider>().setActiveTask(args);
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // CRÍTICO: Evita Memory Leak da câmera
    super.dispose();
  }

  void _processarLeitura(String code) {
    final provider = context.read<PickingProvider>();
    if (provider.isLoading || provider.currentItem == null) return;
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    if (provider.currentStep == 1) {
      if (cleanCode == provider.currentItem!.endereco.toUpperCase()) {
        provider.nextStep();
      } else {
        _showError("ENDEREÇO INCORRETO! VÁ PARA: ${provider.currentItem!.endereco}");
      }
    } else if (provider.currentStep == 2) {
      // Comparar com SKU ou Código de Barras
      final currentSKU = provider.currentItem!.sku.trim().toUpperCase();
      if (cleanCode == currentSKU) {
        provider.nextStep();
      } else {
        _showError("PRODUTO INCORRETO! SKU ESPERADO: ${provider.currentItem!.sku}");
      }
    }
  }

  void _showConfirmacaoExcecao(String titulo, String msg, Future<void> Function() onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(titulo, style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(onPressed: () async { 
            Navigator.pop(context); 
            await onConfirm(); 
          }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed), child: const Text('CONFIRMAR')),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.errorRed));
    }
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.successGreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PickingProvider>();
    final task = provider.activeTask;
    final currentItem = provider.currentItem;

    if (task == null || currentItem == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(title: const Text('TAREFA'), backgroundColor: AppTheme.darkBackground),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 64),
              SizedBox(height: 2.h),
              const Text('TAREFA FINALIZADA OU VAZIA', style: TextStyle(color: Colors.white)),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.mainMenu),
                child: const Text('VOLTAR AO MENU'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('SEPARAÇÃO DE ITENS', style: TextStyle(fontSize: 12.sp, color: AppTheme.textMuted)),
            Text('TAREFA: #${task.id.toString().substring(0, 8)}', style: TextStyle(fontSize: 14.sp, color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.darkBackground,
      ),
      body: Column(
        children: [
          _buildTaskHeader(provider),
          Expanded(
            child: provider.currentStep == 3 ? _buildQuantityPanel(provider) : _buildScannerPanel(provider),
          ),
          _buildExceptionButtons(provider),
        ],
      ),
    );
  }

  Widget _buildTaskHeader(PickingProvider provider) {
    final item = provider.currentItem!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      color: AppTheme.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ENDEREÇO DE COLETA:', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                color: provider.currentStep == 1 ? AppTheme.goldPrimary : AppTheme.successGreen,
                child: Text(item.endereco, style: const TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(item.sku, style: TextStyle(color: AppTheme.goldPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          Text(item.descricao, style: TextStyle(color: AppTheme.textLight, fontSize: 11.sp)),
          SizedBox(height: 1.h),
          Text('RESTANTE NA ONDA: ${provider.currentItemIndex + 1} de ${provider.activeTask!.itens.length}', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.sp)),
        ],
      ),
    );
  }

  Widget _buildScannerPanel(PickingProvider provider) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              _processarLeitura(barcodes.first.rawValue ?? "");
            }
          },
        ),
        ScannerOverlayWidget(borderColor: provider.currentStep == 2 ? AppTheme.goldPrimary : AppTheme.successGreen),
        Align(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
            child: Text(
              provider.currentStep == 1 ? 'BIPE O ENDEREÇO' : 'BIPE O PRODUTO',
              style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityPanel(PickingProvider provider) {
    final item = provider.currentItem!;
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        children: [
          Text('QUANTIDADE COLETADA', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 1.h),
          Text('ESPERADO: ${item.quantidadeEsperada} UN', style: TextStyle(color: AppTheme.textMuted, fontSize: 12.sp)),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.goldPrimary), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(provider.typedQuantity, style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold))),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: IndustrialNumericKeyboard(
              onKeyPressed: (v) => provider.updateTypedQuantity(v),
              onBackspace: () => provider.backspaceQuantity(),
              onClear: () => provider.clearQuantity(),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 9.h,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () async {
                final success = await provider.confirmCollection(int.parse(provider.typedQuantity));
                if (success) {
                  _showSuccess("COLETA REGISTRADA COM SUCESSO!");
                } else {
                  _showError("ERRO AO REGISTRAR COLETA");
                }
              },
              child: provider.isLoading ? const CircularProgressIndicator(color: AppTheme.darkBackground) : const Text('CONFIRMAR COLETA'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExceptionButtons(PickingProvider provider) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.darkBackground,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context, 
                  AppRoutes.damageReport,
                  arguments: {
                    'taskId': provider.activeTask!.id,
                    'itemId': provider.currentItem!.id,
                    'sku': provider.currentItem!.sku,
                  },
                );
              },
              icon: const Icon(Icons.report_problem, color: AppTheme.errorRed),
              label: const Text('RELATAR AVARIA DO PRODUTO', style: TextStyle(color: AppTheme.errorRed)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorRed)),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showConfirmacaoExcecao("FALTA TOTAL", "Confirmar falta?", () => provider.confirmCollection(0)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorRed), foregroundColor: AppTheme.errorRed),
                  child: const Text('FALTA TOTAL'),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (provider.currentStep == 3) {
                       _showSuccess("INFORME A QTD PARCIAL NO TECLADO");
                    } else {
                      _showError("BIPE ENDEREÇO E PRODUTO PRIMEIRO");
                    }
                  },
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.goldPrimary), foregroundColor: AppTheme.goldPrimary),
                  child: const Text('QUEBRA/PARCIAL'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
