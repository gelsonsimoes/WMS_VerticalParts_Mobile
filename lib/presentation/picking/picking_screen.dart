import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';
import '../scanner/widgets/industrial_numeric_keyboard.dart';

class PickingItem {
  final String sku;
  final String descricao;
  final String endereco;
  final int esperado;
  int coletado;
  bool skip;

  PickingItem({
    required this.sku,
    required this.descricao,
    required this.endereco,
    required this.esperado,
    this.coletado = 0,
    this.skip = false,
  });
}

class PickingScreen extends StatefulWidget {
  const PickingScreen({super.key});

  @override
  State<PickingScreen> createState() => _PickingScreenState();
}

class _PickingScreenState extends State<PickingScreen> {
  final MobileScannerController _controller = MobileScannerController();
  
  // Massa de Dados Mock (Onda de Separação)
  final List<PickingItem> _ondaItens = [
    PickingItem(sku: "VEPEL-BPI-174FX", descricao: "BUCHA PLÁSTICA IND. 174FX", endereco: "RUA-A-01-N4", esperado: 5),
    PickingItem(sku: "VPER-ESS-NY-27MM", descricao: "ESPAÇADOR NYLON 27MM", endereco: "RUA-B-12-N1", esperado: 20),
    PickingItem(sku: "VPER-PAL-INO-1000", descricao: "PALETE INOX 1000", endereco: "RUA-C-05-N0", esperado: 2),
  ];

  int _itemIndice = 0;
  int _etapaAtual = 1; // 1: Endereço, 2: Produto, 3: Quantidade
  String _quantidadeDigitada = "0";
  bool _isLoading = false;

  PickingItem get _currentItem => _ondaItens[_itemIndice];

  void _processarLeitura(String code) {
    if (_isLoading) return;

    setState(() {
      if (_etapaAtual == 1) {
        if (code == _currentItem.endereco) {
          _etapaAtual = 2;
        } else {
          _showError("ENDEREÇO INCORRETO! VÁ PARA: ${_currentItem.endereco}");
        }
      } else if (_etapaAtual == 2) {
        if (code == _currentItem.sku) {
          _etapaAtual = 3;
        } else {
          _showError("PRODUTO INCORRETO! SKU ESPERADO: ${_currentItem.sku}");
        }
      }
    });
  }

  Future<void> _confirmarColeta(int qtd) async {
    setState(() => _isLoading = true);

    // Regra de Ouro: POST em tempo real para o WMS
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      _currentItem.coletado = qtd;
      _showSuccess(qtd < _currentItem.esperado ? "COLETA PARCIAL REGISTRADA!" : "ITEM COLETADO COM SUCESSO!");
      _avancarParaProximo();
    }
  }

  void _avancarParaProximo() {
    setState(() {
      if (_itemIndice < _ondaItens.length - 1) {
        _itemIndice++;
        _etapaAtual = 1;
        _quantidadeDigitada = "0";
      } else {
        // Onda Finalizada
        _finalizarOnda();
      }
      _isLoading = false;
    });
  }

  Future<void> _finalizarOnda() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ONDA DE SEPARAÇÃO FINALIZADA!", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppTheme.successGreen),
    );
    Navigator.pushReplacementNamed(context, AppRoutes.mainMenu);
  }

  void _registrarFALTA() {
    _showConfirmacaoExcecao("FALTA TOTAL", "Confirmar que o item não está no endereço?", () => _confirmarColeta(0));
  }

  void _showConfirmacaoExcecao(String titulo, String msg, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(titulo, style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(onPressed: () { Navigator.pop(context); onConfirm(); }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed), child: const Text('CONFIRMAR')),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.errorRed));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.successGreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('PICKING POR ONDAS', style: TextStyle(fontSize: 12.sp, color: AppTheme.textMuted)),
            Text('ONDA: #2026-A1 / PED: 4490', style: TextStyle(fontSize: 14.sp, color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.darkBackground,
      ),
      body: Column(
        children: [
          _buildTaskHeader(),
          Expanded(
            child: _etapaAtual == 3 ? _buildQuantityPanel() : _buildScannerPanel(),
          ),
          _buildExceptionButtons(),
        ],
      ),
    );
  }

  Widget _buildTaskHeader() {
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
                color: _etapaAtual == 1 ? AppTheme.goldPrimary : AppTheme.successGreen,
                child: Text(_currentItem.endereco, style: const TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(_currentItem.sku, style: TextStyle(color: AppTheme.goldPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          Text(_currentItem.descricao, style: TextStyle(color: AppTheme.textLight, fontSize: 11.sp)),
          SizedBox(height: 1.h),
          Text('RESTANTE NA ONDA: ${_itemIndice + 1} de ${_ondaItens.length}', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.sp)),
        ],
      ),
    );
  }

  Widget _buildScannerPanel() {
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
        ScannerOverlayWidget(borderColor: _etapaAtual == 2 ? AppTheme.goldPrimary : AppTheme.successGreen),
        Align(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
            child: Text(
              _etapaAtual == 1 ? 'BIPE O ENDEREÇO' : 'BIPE O PRODUTO',
              style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityPanel() {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        children: [
          Text('QUANTIDADE COLETADA', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 1.h),
          Text('ESPERADO: ${_currentItem.esperado} UN', style: TextStyle(color: AppTheme.textMuted, fontSize: 12.sp)),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.goldPrimary), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_quantidadeDigitada, style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold))),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: IndustrialNumericKeyboard(
              onKeyPressed: (v) => setState(() => _quantidadeDigitada = _quantidadeDigitada == "0" ? v : _quantidadeDigitada + v),
              onBackspace: () => setState(() => _quantidadeDigitada = _quantidadeDigitada.length > 1 ? _quantidadeDigitada.substring(0, _quantidadeDigitada.length - 1) : "0"),
              onClear: () => setState(() => _quantidadeDigitada = "0"),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 9.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _confirmarColeta(int.parse(_quantidadeDigitada)),
              child: _isLoading ? const CircularProgressIndicator(color: AppTheme.darkBackground) : const Text('CONFIRMAR COLETA'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExceptionButtons() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.darkBackground,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _registrarFALTA,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorRed), foregroundColor: AppTheme.errorRed),
              child: const Text('FALTA TOTAL'),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (_etapaAtual == 3) {
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
    );
  }
}
