import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import './widgets/scanner_overlay_widget.dart';
import './widgets/task_context_widget.dart';
import './widgets/manual_input_widget.dart';
import './quantity_confirmation_screen.dart';

class BarcodeScanningScreen extends StatefulWidget {
  const BarcodeScanningScreen({super.key});

  @override
  State<BarcodeScanningScreen> createState() => _BarcodeScanningScreenState();
}

class _BarcodeScanningScreenState extends State<BarcodeScanningScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _showManualInput = false;
  bool _isProcessing = false;
  Color _feedbackColor = AppTheme.goldPrimary;

  // Mock de contexto de tarefa
  final String _itemEsperado = "VEPEL-BPI-174FX";
  final int _qtdEsperada = 5;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
      _isCheckingPermission = false;
    });
  }

  Future<void> _processarCodigo(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _feedbackColor = AppTheme.goldPrimary;
    });

    // Simulação de Requisição REST (Passthrough para validar o que foi lido)
    await Future.delayed(const Duration(milliseconds: 600));

    // Lógica Versátil: Aceita o SKU esperado ou qualquer código de produto mock
    bool isSucesso = code == _itemEsperado || code.length >= 5;

    if (isSucesso) {
      setState(() {
        _feedbackColor = AppTheme.successGreen;
      });
      
      if (mounted) {
        // Navega para a confirmação de quantidade
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuantityConfirmationScreen(
              sku: code,
              expectedQuantity: _qtdEsperada,
            ),
          ),
        );

        // Se confirmou com sucesso, reseta para próxima leitura
        if (result == true) {
          setState(() {
            _isProcessing = false;
            _feedbackColor = AppTheme.goldPrimary;
          });
          return;
        }
      }
    } else {
      setState(() {
        _feedbackColor = AppTheme.errorRed;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ITEM NÃO RECONHECIDO OU FORA DA TAREFA", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _feedbackColor = AppTheme.goldPrimary;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_photography, color: AppTheme.errorRed, size: 80),
              SizedBox(height: 4.h),
              Text(
                'ACESSO À CÂMERA NEGADO',
                style: TextStyle(color: AppTheme.errorRed, fontSize: 18.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('TENTAR NOVAMENTE'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESCANEAMENTO'),
        backgroundColor: AppTheme.darkBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: AppTheme.goldPrimary),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.taskSummary),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                _processarCodigo(barcodes.first.rawValue ?? "");
              }
            },
          ),

          ScannerOverlayWidget(borderColor: _feedbackColor),

          Positioned(
            top: 2.h,
            left: 5.w,
            right: 5.w,
            child: TaskContextWidget(
              operacao: "CONTROLE DE SAÍDA",
              itemEsperado: _itemEsperado,
              quantidade: _qtdEsperada,
            ),
          ),

          Positioned(
            bottom: 5.h,
            left: 10.w,
            right: 10.w,
            child: SizedBox(
              height: 9.h,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showManualInput = true),
                icon: const Icon(Icons.keyboard),
                label: const Text('ENTRADA MANUAL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceDark,
                  foregroundColor: AppTheme.goldPrimary,
                ),
              ),
            ),
          ),

          if (_showManualInput)
            ManualInputWidget(
              onCancel: () => setState(() => _showManualInput = false),
              onSubmitted: (code) {
                setState(() => _showManualInput = false);
                _processarCodigo(code);
              },
            ),
            
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
