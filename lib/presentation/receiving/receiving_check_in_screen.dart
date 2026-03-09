import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';
import '../scanner/widgets/industrial_numeric_keyboard.dart';
import '../../data/providers/receiving_provider.dart';

class ReceivingCheckInScreen extends StatefulWidget {
  const ReceivingCheckInScreen({super.key});

  @override
  State<ReceivingCheckInScreen> createState() => _ReceivingCheckInScreenState();
}

class _ReceivingCheckInScreenState extends State<ReceivingCheckInScreen> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _processarLeitura(ReceivingProvider provider, String code) {
    if (provider.isLoading) return;
    if (provider.step == 1) {
      provider.startNF(code);
    } else if (provider.step == 2) {
      provider.setProduct(code);
    }
  }

  void _registrarAVARIA(ReceivingProvider provider) {
    Navigator.pushNamed(
      context, 
      AppRoutes.damageReport,
      arguments: {
        'taskId': provider.nfe ?? 'RECEBIMENTO',
        'itemId': provider.sku,
        'sku': provider.sku,
      },
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppTheme.successGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceivingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CONFERÊNCIA DE ENTRADA'),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: Column(
        children: [
          _buildNFProgressHeader(provider),
          Expanded(
            child: _buildDynamicBody(provider),
          ),
          _buildFooterActions(provider),
        ],
      ),
    );
  }

  Widget _buildNFProgressHeader(ReceivingProvider provider) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.surfaceDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(provider.nfe == null ? 'AGUARDANDO NF-e' : 'NF-e: ${provider.nfe}', 
                style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 12.sp)),
              Text('PROGRESSO: ${provider.checkedItems}/${provider.totalItems}', 
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: provider.progress,
            backgroundColor: AppTheme.darkBackground,
            color: AppTheme.successGreen,
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicBody(ReceivingProvider provider) {
    if (provider.step <= 2) {
      return Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) _processarLeitura(provider, barcodes.first.rawValue ?? "");
            },
          ),
          const ScannerOverlayWidget(),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.only(top: 2.h),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              color: AppTheme.goldPrimary,
              child: Text(
                provider.step == 1 ? 'BIPE A CHAVE DA NF-e / O.R.' : 'BIPE O SKU DO PRODUTO',
                style: const TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else if (provider.step == 3) {
      return _buildQuantityPanel(provider);
    } else {
      return _buildExtraDataPanel(provider);
    }
  }

  Widget _buildQuantityPanel(ReceivingProvider provider) {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        children: [
          Text('CONFERÊNCIA: ${provider.sku}', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
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
              onKeyPressed: (v) => provider.updateQuantity(v),
              onBackspace: () => provider.backspaceQuantity(),
              onClear: () => provider.clearQuantity(),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 9.h,
            child: ElevatedButton(
              onPressed: () => provider.nextToExtra(),
              child: const Text('PRÓXIMO: LOTE/VALIDADE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraDataPanel(ReceivingProvider provider) {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DADOS ADICIONAIS', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          Text('Preencha Peso e Cor para finalizar o item.', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
          SizedBox(height: 2.h),
          _buildField("LOTE", "Ex: L2024-X1", (v) => provider.setBatch(v)),
          SizedBox(height: 2.h),
          _buildField("VALIDADE", "DD/MM/AAAA", (v) => provider.setExpiry(v)),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(child: _buildField("PESO (kg)", "0.00", (v) => provider.setWeight(v))),
              SizedBox(width: 4.w),
              Expanded(child: _buildField("COR / OBS", "Ex: Azul", (v) => provider.setColor(v))),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 10.h,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () async {
                final ok = await provider.finalizeItem();
                if (ok) _showSuccess("ITEM CONFERIDO E SALVO!");
              },
              child: provider.isLoading ? const CircularProgressIndicator() : const Text('FINALIZAR ITEM'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String hint, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
        SizedBox(height: 1.h),
        TextField(
          onChanged: onChanged,
          style: TextStyle(fontSize: 14.sp, color: Colors.white),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _buildFooterActions(ReceivingProvider provider) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.darkBackground,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _registrarAVARIA(provider),
              icon: const Icon(Icons.report_problem, color: AppTheme.errorRed),
              label: const Text('REGISTRAR AVARIA', style: TextStyle(color: AppTheme.errorRed)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorRed)),
            ),
          ),
        ],
      ),
    );
  }
}
