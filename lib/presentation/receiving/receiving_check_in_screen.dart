import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';
import '../scanner/widgets/industrial_numeric_keyboard.dart';

class ReceivingCheckInScreen extends StatefulWidget {
  const ReceivingCheckInScreen({super.key});

  @override
  State<ReceivingCheckInScreen> createState() => _ReceivingCheckInScreenState();
}

class _ReceivingCheckInScreenState extends State<ReceivingCheckInScreen> {
  final MobileScannerController _controller = MobileScannerController();
  
  int _etapaAtual = 1; // 1: NF-e/O.R, 2: Produto, 3: Qtd, 4: Lote/Validade
  bool _isLoading = false;

  // Dados da Sessão de Recebimento
  String? _nfe;
  String? _sku;
  String _quantidade = "0";
  String _lote = "";
  String _validade = "";

  // Mock de Progresso da NF
  final int _totalItensNF = 10;
  int _itensConferidos = 4;

  void _processarLeitura(String code) {
    if (_isLoading) return;

    setState(() {
      if (_etapaAtual == 1) {
        _nfe = code;
        _etapaAtual = 2;
      } else if (_etapaAtual == 2) {
        _sku = code;
        _etapaAtual = 3;
      }
    });
  }

  Future<void> _salvarConferencia() async {
    setState(() => _isLoading = true);

    // Regra de Ouro: Simulação de POST Inbound para o WMS_VerticalParts
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      _itensConferidos++;
      _showSuccess("ITEM CONFERIDO E SALVO NO WMS!");
      
      // Reseta para o próximo produto da mesma NF
      setState(() {
        _etapaAtual = 2;
        _sku = null;
        _quantidade = "0";
        _lote = "";
        _validade = "";
        _isLoading = false;
      });
    }
  }

  void _registrarAVARIA() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('REGISTRAR AVARIA', style: TextStyle(color: AppTheme.errorRed, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 3.h),
            _avariaOption("EMBALAGEM DANIFICADA"),
            _avariaOption("PRODUTO QUEBRADO/RISCADO"),
            _avariaOption("PRODUTO MOLHADO/UMIDADE"),
            _avariaOption("QUANTIDADE DIVERGENTE DA NF"),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _avariaOption(String titulo) {
    return ListTile(
      title: Text(titulo, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.goldPrimary),
      onTap: () {
        Navigator.pop(context);
        _showSuccess("AVARIA REGISTRADA: $titulo");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONFERÊNCIA DE ENTRADA'),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: Column(
        children: [
          _buildNFProgressHeader(),
          Expanded(
            child: _buildDynamicBody(),
          ),
          _buildFooterActions(),
        ],
      ),
    );
  }

  Widget _buildNFProgressHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.surfaceDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_nfe == null ? 'AGUARDANDO NF-e' : 'NF-e: $_nfe', 
                style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 12.sp)),
              Text('PROGRESSO: $_itensConferidos/$_totalItensNF', 
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: _itensConferidos / _totalItensNF,
            backgroundColor: AppTheme.darkBackground,
            color: AppTheme.successGreen,
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicBody() {
    if (_etapaAtual <= 2) {
      return Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) _processarLeitura(barcodes.first.rawValue ?? "");
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
                _etapaAtual == 1 ? 'BIPE A CHAVE DA NF-e / O.R.' : 'BIPE O SKU DO PRODUTO',
                style: const TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else if (_etapaAtual == 3) {
      return _buildQuantityPanel();
    } else {
      return _buildExtraDataPanel();
    }
  }

  Widget _buildQuantityPanel() {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        children: [
          Text('CONFERÊNCIA: $_sku', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.goldPrimary), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_quantidade, style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.bold))),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: IndustrialNumericKeyboard(
              onKeyPressed: (v) => setState(() => _quantidade = _quantidade == "0" ? v : _quantidade + v),
              onBackspace: () => setState(() => _quantidade = _quantidade.length > 1 ? _quantidade.substring(0, _quantidade.length - 1) : "0"),
              onClear: () => setState(() => _quantidade = "0"),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 9.h,
            child: ElevatedButton(
              onPressed: () => setState(() => _etapaAtual = 4),
              child: const Text('PRÓXIMO: LOTE/VALIDADE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraDataPanel() {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DADOS ADICIONAIS', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 3.h),
          _buildField("LOTE", "Ex: L2024-X1", (v) => _lote = v),
          SizedBox(height: 3.h),
          _buildField("VALIDADE", "DD/MM/AAAA", (v) => _validateDate(v)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 10.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _salvarConferencia,
              child: _isLoading ? const CircularProgressIndicator() : const Text('FINALIZAR ITEM'),
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

  void _validateDate(String v) {
    _validade = v;
  }

  Widget _buildFooterActions() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.darkBackground,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _registrarAVARIA,
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
