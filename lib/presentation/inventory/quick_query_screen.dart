import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';
import '../../data/services/supabase_service.dart';

class QuickQueryScreen extends StatefulWidget {
  const QuickQueryScreen({super.key});

  @override
  State<QuickQueryScreen> createState() => _QuickQueryScreenState();
}

class _QuickQueryScreenState extends State<QuickQueryScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  Map<String, dynamic>? _queryResult;

  Future<void> _consultar(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _queryResult = null;
    });

    try {
      final upCode = code.trim().toUpperCase();
      
      // Tenta validar como produto primeiro
      final produto = await SupabaseService.validarCodigo(codigo: upCode, tipo: 'produto');
      
        if (produto != null) {
          final estoques = await SupabaseService.consultarEstoque(upCode);
          
          int total = 0;
          List<Map<String, dynamic>> detalhes = [];
          for (var e in estoques) {
            total += (e['quantidade'] as num).toInt();
            final end = e['enderecos'];
            detalhes.add({
              "local": "${end['rua']}-${end['coluna']}-${end['nivel']}",
              "peso": e['peso'],
              "cor": e['cor'],
              "qtd": e['quantidade'],
            });
          }

          setState(() {
            _queryResult = {
              "tipo": "PRODUTO",
              "descricao": produto['descricao'] ?? "SEM DESCRIÇÃO",
              "total": total,
              "detalhes": detalhes,
            };
          });
        } else {
          final endereco = await SupabaseService.validarCodigo(codigo: upCode, tipo: 'endereco');
          
          if (endereco != null) {
            final itens = await SupabaseService.consultarConteudoEndereco(upCode);
            
            setState(() {
              _queryResult = {
                "tipo": "ENDEREÇO",
                "descricao": "ENDEREÇO: ${endereco['id']}",
                "itens": itens.map((i) => {
                  "sku": i['produtos']['sku'],
                  "qtd": i['quantidade'],
                  "peso": i['peso'],
                  "cor": i['cor'],
                }).toList(),
              };
            });
          } else {
          setState(() {
            _queryResult = {"erro": "CÓDIGO NÃO ENCONTRADO NO WMS"};
          });
        }
      }
    } catch (e) {
      setState(() {
        _queryResult = {"erro": "ERRO NA CONSULTA: $e"};
      });
    } finally {
      setState(() => _isProcessing = false);
    }
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
            Text("DETALHES POR ENDEREÇO:", style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ...(data["detalhes"] as List).map((det) => Container(
                  margin: EdgeInsets.only(top: 1.5.h),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    border: Border(left: BorderSide(color: AppTheme.successGreen, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(det["local"], style: TextStyle(color: AppTheme.textLight, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                          Text("${det["qtd"]} UN", style: TextStyle(color: AppTheme.successGreen, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (det["peso"] != null || det["cor"] != null) Divider(color: AppTheme.textMuted.withOpacity(0.3)),
                      Row(
                        children: [
                          if (det["peso"] != null) ...[
                            Icon(Icons.scale, color: AppTheme.textMuted, size: 12.sp),
                            SizedBox(width: 1.w),
                            Text("${det["peso"]} kg", style: TextStyle(color: AppTheme.textMuted, fontSize: 11.sp)),
                            SizedBox(width: 4.w),
                          ],
                          if (det["cor"] != null && det["cor"] != "") ...[
                            Icon(Icons.palette, color: AppTheme.textMuted, size: 12.sp),
                            SizedBox(width: 1.w),
                            Text("${det["cor"]}", style: TextStyle(color: AppTheme.textMuted, fontSize: 11.sp)),
                          ],
                        ],
                      ),
                    ],
                  ),
                )),
          ] else ...[
            Text("CONTEÚDO DO ENDEREÇO:", style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            ...(data["itens"] as List).map((item) => Container(
                  margin: EdgeInsets.only(bottom: 1.h),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(4)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item["sku"], style: TextStyle(color: AppTheme.textLight, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                          Text("${item["qtd"]} UN", style: TextStyle(color: AppTheme.successGreen, fontSize: 13.sp)),
                        ],
                      ),
                      if (item["peso"] != null || (item["cor"] != null && item["cor"] != "")) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          "Extra: ${item["peso"] ?? '-'} kg / ${item["cor"] ?? '-'}",
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp),
                        ),
                      ],
                    ],
                  ),
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
