import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';
import '../scanner/widgets/industrial_numeric_keyboard.dart';

class BlindCountScreen extends StatefulWidget {
  const BlindCountScreen({super.key});

  @override
  State<BlindCountScreen> createState() => _BlindCountScreenState();
}

class _BlindCountScreenState extends State<BlindCountScreen> {
  final MobileScannerController _controller = MobileScannerController();
  
  String? _enderecoLido;
  String? _produtoLido;
  String _quantidadeDigitada = "0";
  
  int _etapaAtual = 1; // 1: Endereço, 2: Produto, 3: Quantidade
  bool _isLoading = false;

  void _processarLeitura(String code) {
    setState(() {
      if (_etapaAtual == 1) {
        _enderecoLido = code;
        _etapaAtual = 2;
      } else if (_etapaAtual == 2) {
        _produtoLido = code;
        _etapaAtual = 3;
      }
    });
  }

  Future<void> _enviarContagem() async {
    int qtd = int.tryParse(_quantidadeDigitada) ?? 0;
    if (qtd <= 0) return;

    setState(() => _isLoading = true);
    
    // Simulação Regra de Ouro (Validação no Servidor)
    await Future.delayed(const Duration(seconds: 1));

    // Lógica Mock de Divergência
    bool temDivergencia = _produtoLido == "VPER-ESS-NY-27MM" && qtd != 1200;

    if (mounted) {
      _showResultado(
        temDivergencia ? 'DIVERGÊNCIA ENCONTRADA - RECONTAGEM SOLICITADA' : 'CONTAGEM VALIDADA - ESTOQUE CORRETO',
        temDivergencia ? AppTheme.errorRed : AppTheme.successGreen,
      );
      
      if (!temDivergencia) {
        setState(() {
          _enderecoLido = null;
          _produtoLido = null;
          _quantidadeDigitada = "0";
          _etapaAtual = 1;
        });
      }
      setState(() => _isLoading = false);
    }
  }

  void _showResultado(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONFERÊNCIA CEGA'),
        backgroundColor: AppTheme.darkBackground,
        actions: [
          if (_etapaAtual > 1) 
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() { _etapaAtual = 1; _enderecoLido = null; _produtoLido = null; }),
            )
        ],
      ),
      body: Column(
        children: [
          // Header de Progresso
          _buildStepHeader(),

          // Área Dinâmica (Scanner ou Teclado)
          Expanded(
            child: _etapaAtual < 3 
              ? Stack(
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
                    const ScannerOverlayWidget(),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: EdgeInsets.only(top: 2.h),
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        color: AppTheme.goldPrimary,
                        child: Text(
                          _etapaAtual == 1 ? 'BIPE O ENDEREÇO' : 'BIPE O PRODUTO',
                          style: const TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                )
              : _buildQuantityInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.surfaceDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stepIcon(1, Icons.location_on, _enderecoLido != null),
          const Icon(Icons.arrow_forward_ios, size: 15, color: AppTheme.textMuted),
          _stepIcon(2, Icons.inventory, _produtoLido != null),
          const Icon(Icons.arrow_forward_ios, size: 15, color: AppTheme.textMuted),
          _stepIcon(3, Icons.calculate, _etapaAtual == 3),
        ],
      ),
    );
  }

  Widget _stepIcon(int step, IconData icon, bool active) {
    return Column(
      children: [
        Icon(icon, color: active ? AppTheme.goldPrimary : AppTheme.textMuted, size: 28.sp),
        SizedBox(height: 0.5.h),
        Text(
          step == 1 ? 'LOCAL' : step == 2 ? 'SKU' : 'QTD',
          style: TextStyle(color: active ? AppTheme.goldPrimary : AppTheme.textMuted, fontSize: 10.sp),
        ),
      ],
    );
  }

  Widget _buildQuantityInput() {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        children: [
          Text('QUANTIDADE FÍSICA NO LOCAL', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 1.h),
          Text(_enderecoLido!, style: const TextStyle(color: AppTheme.textMuted)),
          Text(_produtoLido!, style: TextStyle(color: AppTheme.textLight, fontSize: 15.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 3.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.goldPrimary), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_quantidadeDigitada, style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.bold))),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: IndustrialNumericKeyboard(
              onKeyPressed: (val) => setState(() => _quantidadeDigitada = _quantidadeDigitada == "0" ? val : _quantidadeDigitada + val),
              onBackspace: () => setState(() => _quantidadeDigitada = _quantidadeDigitada.length > 1 ? _quantidadeDigitada.substring(0, _quantidadeDigitada.length - 1) : "0"),
              onClear: () => setState(() => _quantidadeDigitada = "0"),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 9.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _enviarContagem,
              child: _isLoading 
                ? const CircularProgressIndicator(color: AppTheme.darkBackground) 
                : const Text('ENVIAR CONTAGEM'),
            ),
          ),
        ],
      ),
    );
  }
}
