import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';
import '../scanner/widgets/industrial_numeric_keyboard.dart';

class ReplenishmentScreen extends StatefulWidget {
  const ReplenishmentScreen({super.key});

  @override
  State<ReplenishmentScreen> createState() => _ReplenishmentScreenState();
}

class _ReplenishmentScreenState extends State<ReplenishmentScreen> {
  final MobileScannerController _controller = MobileScannerController();
  
  int _etapaAtual = 1; // 1: Origem, 2: Produto, 3: Qtd, 4: Destino
  bool _isLoading = false;

  // Dados da Operação
  String? _origem;
  String? _sku;
  String _quantidade = "0";
  String? _destino;

  // Mock de Saldo (Regra de Ouro: Simulação de API)
  final Map<String, int> _mockSaldos = {
    "VEPEL-BPI-174FX": 45,
    "VPER-PAL-INO-1000": 12,
    "VPER-ESS-NY-27MM": 1200,
  };

  void _processarLeitura(String code) {
    if (_isLoading) return;

    setState(() {
      if (_etapaAtual == 1) {
        _origem = code;
        _etapaAtual = 2;
      } else if (_etapaAtual == 2) {
        _sku = code;
        _etapaAtual = 3;
      } else if (_etapaAtual == 4) {
        _destino = code;
        _finalizarRemanejamento();
      }
    });
  }

  Future<void> _validarQuantidade() async {
    int qtdDigitada = int.tryParse(_quantidade) ?? 0;
    if (qtdDigitada <= 0) return;

    setState(() => _isLoading = true);

    // Simulação de Validação de Saldo na Origem (REST)
    await Future.delayed(const Duration(milliseconds: 600));

    int saldoDisponivel = _mockSaldos[_sku] ?? 0;

    if (mounted) {
      if (qtdDigitada > saldoDisponivel) {
        _showError("SALDO INSUFICIENTE! DISPONÍVEL: $saldoDisponivel UN");
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _etapaAtual = 4;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _finalizarRemanejamento() async {
    setState(() => _isLoading = true);

    // Simulação de POST Final de Efetivação
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      _showSuccess("REMANEJAMENTO CONCLUÍDO COM SUCESSO!");
      
      // Limpa para novo remanejamento ou volta ao menu
      setState(() {
        _etapaAtual = 1;
        _origem = null;
        _sku = null;
        _quantidade = "0";
        _destino = null;
        _isLoading = false;
      });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('REMANEJAMENTO DE ESTOQUE'),
        backgroundColor: AppTheme.darkBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _etapaAtual = 1),
          )
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: _etapaAtual == 3 ? _buildQuantityPanel() : _buildScannerPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 5.w),
      color: AppTheme.surfaceDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          int step = index + 1;
          bool isPath = step < _etapaAtual;
          bool isCurrent = step == _etapaAtual;

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
                      color: step < _etapaAtual ? AppTheme.successGreen : AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScannerPanel() {
    String instrucao = "";
    switch (_etapaAtual) {
      case 1: instrucao = "BIPE O ENDEREÇO DE ORIGEM"; break;
      case 2: instrucao = "BIPE O SKU DO PRODUTO"; break;
      case 4: instrucao = "BIPE O ENDEREÇO DE DESTINO"; break;
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              _processarLeitura(barcodes.first.rawValue ?? "");
            }
          },
        ),
        ScannerOverlayWidget(borderColor: _isLoading ? AppTheme.textMuted : AppTheme.goldPrimary),
        
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

        if (_etapaAtual > 1)
          Positioned(
            bottom: 2.h,
            left: 5.w,
            right: 5.w,
            child: _buildSummaryMiniCard(),
          ),

        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
          ),
      ],
    );
  }

  Widget _buildQuantityPanel() {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        children: [
          _buildSummaryMiniCard(),
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
            child: Center(child: Text(_quantidade, style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.bold))),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: IndustrialNumericKeyboard(
              onKeyPressed: (val) => setState(() => _quantidade = _quantidade == "0" ? val : _quantidade + val),
              onBackspace: () => setState(() => _quantidade = _quantidade.length > 1 ? _quantidade.substring(0, _quantidade.length - 1) : "0"),
              onClear: () => setState(() => _quantidade = "0"),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 9.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _validarQuantidade,
              child: _isLoading 
                ? const CircularProgressIndicator(color: AppTheme.darkBackground) 
                : const Text('AVANÇAR PARA DESTINO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMiniCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (_origem != null) _miniRow("ORIGEM:", _origem!),
          if (_sku != null) _miniRow("PRODUTO:", _sku!),
          if (_etapaAtual > 3) _miniRow("QTD:", "$_quantidade UN"),
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
