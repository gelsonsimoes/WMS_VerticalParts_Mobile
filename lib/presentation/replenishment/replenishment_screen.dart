import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';
import '../scanner/widgets/industrial_numeric_keyboard.dart';
import '../../data/providers/replenishment_provider.dart';
import '../../data/providers/sync_provider.dart';

class ReplenishmentScreen extends StatefulWidget {
  const ReplenishmentScreen({super.key});

  @override
  State<ReplenishmentScreen> createState() => _ReplenishmentScreenState();
}

class _ReplenishmentScreenState extends State<ReplenishmentScreen> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _processarLeitura(ReplenishmentProvider provider, String code) async {
    if (provider.isLoading) return;

    if (provider.currentStep <= 2) {
      provider.processScan(code);
    } else if (provider.currentStep == 4) {
      _finalizarOperacao(provider, code);
    }
  }

  Future<void> _finalizarOperacao(ReplenishmentProvider provider, String destino) async {
    provider.setLoading(true);

    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    
    final success = await syncProvider.performReplenishment(
      origemId: provider.sourceAddress,
      destinoId: destino,
      sku: provider.sku!,
      quantidade: int.parse(provider.quantity),
    );

    if (mounted) {
      if (success) {
        _showSuccess("REMANEJAMENTO CONCLUÍDO COM SUCESSO!");
        provider.reset();
      } else {
        _showError("ERRO AO FINALIZAR REMANEJO.");
        provider.setLoading(false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorRed),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReplenishmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('REMANEJAMENTO DE ESTOQUE'),
        backgroundColor: AppTheme.darkBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.reset(),
          )
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(provider),
          Expanded(
            child: provider.currentStep == 3 ? _buildQuantityPanel(provider) : _buildScannerPanel(provider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context, 
            AppRoutes.damageReport,
            arguments: {
              'taskId': 'REMANEJAMENTO',
              'itemId': provider.sku,
              'sku': provider.sku,
            },
          );
        },
        backgroundColor: AppTheme.errorRed,
        icon: const Icon(Icons.report_problem, color: Colors.white),
        label: const Text('AVARIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProgressBar(ReplenishmentProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 5.w),
      color: AppTheme.surfaceDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          int step = index + 1;
          bool isPath = step < provider.currentStep;
          bool isCurrent = step == provider.currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPath ? AppTheme.successGreen : (isCurrent ? AppTheme.goldPrimary : AppTheme.textMuted),
                  ),
                  child: Center(
                    child: isPath 
                      ? const Icon(Icons.check, size: 16, color: AppTheme.darkBackground)
                      : Text('$step', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkBackground)),
                  ),
                ),
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: step < provider.currentStep ? AppTheme.successGreen : AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScannerPanel(ReplenishmentProvider provider) {
    String instrucao = "";
    switch (provider.currentStep) {
      case 1: instrucao = "BIPE O ENDEREÇO DE ORIGEM"; break;
      case 2: instrucao = "BIPE O SKU DO PRODUTO"; break;
      case 4: instrucao = "BIPE O ENDEREÇO DE DESTINO"; break;
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              _processarLeitura(provider, barcodes.first.rawValue ?? "");
            }
          },
        ),
        ScannerOverlayWidget(borderColor: provider.isLoading ? AppTheme.textMuted : AppTheme.goldPrimary),
        
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: EdgeInsets.only(top: 2.h),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              instrucao,
              style: const TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        if (provider.currentStep > 1)
          Positioned(
            bottom: 2.h,
            left: 5.w,
            right: 5.w,
            child: _buildSummaryMiniCard(provider),
          ),

        if (provider.isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
          ),
      ],
    );
  }

  Widget _buildQuantityPanel(ReplenishmentProvider provider) {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        children: [
          _buildSummaryMiniCard(provider),
          SizedBox(height: 3.h),
          Text(
            'INFORME A QUANTIDADE',
            style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.goldPrimary), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(provider.quantity, style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.bold))),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: IndustrialNumericKeyboard(
              onKeyPressed: (val) => provider.updateQuantity(val),
              onBackspace: () => provider.backspaceQuantity(),
              onClear: () => provider.clearQuantity(),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 9.h,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () => provider.nextToDestination(),
              child: provider.isLoading 
                ? const CircularProgressIndicator(color: AppTheme.darkBackground) 
                : const Text('AVANÇAR PARA DESTINO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMiniCard(ReplenishmentProvider provider) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (provider.sourceAddress != null) _miniRow("ORIGEM:", provider.sourceAddress!),
          if (provider.sku != null) _miniRow("PRODUTO:", provider.sku!),
          if (provider.currentStep > 3) _miniRow("QTD:", "${provider.quantity} UN"),
        ],
      ),
    );
  }

  Widget _miniRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
          Text(value, style: TextStyle(color: AppTheme.textLight, fontSize: 11.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
