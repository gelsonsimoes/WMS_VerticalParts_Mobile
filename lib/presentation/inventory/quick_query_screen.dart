import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';

class QuickQueryScreen extends StatefulWidget {
  const QuickQueryScreen({super.key});

  @override
  State<QuickQueryScreen> createState() => _QuickQueryScreenState();
}

class _QuickQueryScreenState extends State<QuickQueryScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  Map<String, dynamic>? _queryResult;

  // Massa de dados Mock (Real-time API Simulation)
  final Map<String, Map<String, dynamic>> _mockDatabase = {
    "VEPEL-BPI-174FX": {
      "tipo": "PRODUTO",
      "descricao": "BARREIRA DE PROTEÇÃO INFRAVERMELHA 174FX",
      "total": 45,
      "locais": ["RUA-A-01-N1", "RUA-B-05-N2"],
    },
    "VPER-ESS-NY-27MM": {
      "tipo": "PRODUTO",
      "descricao": "ESPAÇADOR NYLON 27MM - ALTO DESEMPENHO",
      "total": 1200,
      "locais": ["RUA-C-10-N4"],
    },
    "RUA-A-01-N4": {
      "tipo": "ENDEREÇO",
      "descricao": "ENDEREÇO LOGÍSTICO: RUA A, COLUNA 01, NÍVEL 4",
      "itens": [
        {"sku": "VPER-PAL-INO-1000", "qtd": 2},
        {"sku": "VP-MTR-88-AL", "qtd": 15},
      ],
    },
  };

  Future<void> _consultar(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _queryResult = null;
    });

    // Simulação GET REST
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _queryResult = _mockDatabase[code] ?? {"erro": "CÓDIGO NÃO ENCONTRADO NO WMS"};
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONSULTA RÁPIDA'),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: Column(
        children: [
          // Área do Scanner (Metade Superior)
          SizedBox(
            height: 40.h,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && !_isProcessing) {
                      _consultar(barcodes.first.rawValue ?? "");
                    }
                  },
                ),
                const ScannerOverlayWidget(),
                if (_isProcessing)
                  Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
                  ),
              ],
            ),
          ),

          // Área de Resultado (Metade Inferior)
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(5.w),
              decoration: const BoxDecoration(
                color: AppTheme.darkBackground,
                border: Border(top: BorderSide(color: AppTheme.goldPrimary, width: 2)),
              ),
              child: _queryResult == null
                  ? _buildPlaceholder()
                  : _queryResult!.containsKey("erro")
                      ? _buildError(_queryResult!["erro"])
                      : _buildDataCard(_queryResult!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.qr_code_scanner, color: AppTheme.textMuted, size: 60),
        SizedBox(height: 2.h),
        Text(
          'AGUARDANDO LEITURA...',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 60),
        SizedBox(height: 2.h),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.errorRed, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDataCard(Map<String, dynamic> data) {
    bool isProduto = data["tipo"] == "PRODUTO";

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                color: AppTheme.goldPrimary,
                child: Text(
                  data["tipo"],
                  style: const TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            data["descricao"],
            style: TextStyle(color: AppTheme.textLight, fontSize: 15.sp, fontWeight: FontWeight.bold),
          ),
          Divider(color: AppTheme.goldPrimary, height: 4.h),
          if (isProduto) ...[
            _buildInfoRow("SALDO TOTAL", "${data["total"]} UN"),
            SizedBox(height: 2.h),
            Text("ENDEREÇOS:", style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ...(data["locais"] as List).map((loc) => Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Text("• $loc", style: TextStyle(color: AppTheme.textLight, fontSize: 13.sp)),
                )),
          ] else ...[
            Text("CONTEÚDO DO ENDEREÇO:", style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            ...(data["itens"] as List).map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Text("• ${item["sku"]} [${item["qtd"]} UN]", style: TextStyle(color: AppTheme.textLight, fontSize: 13.sp)),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12.sp)),
        Text(value, style: TextStyle(color: AppTheme.successGreen, fontSize: 16.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
