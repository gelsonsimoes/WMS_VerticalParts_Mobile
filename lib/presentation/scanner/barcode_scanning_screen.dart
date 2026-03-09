import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:verticalpartswms/theme/app_theme.dart';
import 'package:verticalpartswms/routes/app_routes.dart';
import 'package:verticalpartswms/presentation/scanner/widgets/scanner_overlay_widget.dart';
import 'package:verticalpartswms/presentation/scanner/widgets/task_context_widget.dart';
import 'package:verticalpartswms/presentation/scanner/widgets/manual_input_widget.dart';
import 'package:verticalpartswms/presentation/scanner/quantity_confirmation_screen.dart';
import 'package:verticalpartswms/data/models/task_model.dart';
import 'package:verticalpartswms/data/providers/scanning_provider.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Task) {
      context.read<ScanningProvider>().setActiveTask(args);
    }
  }

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

  Future<void> _processarCodigo(ScanningProvider provider, String code) async {
    if (provider.isProcessing) return;

    final success = await provider.validateBarcode(code);
    
    if (success && mounted) {
      final currentItem = provider.activeTask!.itens.first; // Simplificado para o item esperado da tarefa

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuantityConfirmationScreen(
            sku: code,
            expectedQuantity: currentItem.quantidadeEsperada,
            taskId: provider.activeTask!.id,
            itemId: currentItem.id,
          ),
        ),
      );

      if (result == true) {
        provider.resetFeedback();
      }
    } else if (provider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.errorRed,
        ),
      );
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

    final provider = context.watch<ScanningProvider>();
    final task = provider.activeTask;

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
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _processarCodigo(provider, barcodes.first.rawValue ?? "");
              }
            },
          ),

          ScannerOverlayWidget(borderColor: provider.feedbackColor),

          Positioned(
            top: 2.h,
            left: 5.w,
            right: 5.w,
            child: task == null 
              ? const Center(child: CircularProgressIndicator())
              : TaskContextWidget.fromItem(
                operacao: task.tipo.name == 'alocacao' ? "ALOCAÇÃO (GUARDA)" : "SEPARAÇÃO (PICKING)",
                item: task.itens.first,
              ),
          ),

          Positioned(
            bottom: 5.h,
            left: 5.w,
            right: 5.w,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 9.h,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showManualInput = true),
                      icon: const Icon(Icons.keyboard),
                      label: const Text('MANUAL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceDark,
                        foregroundColor: AppTheme.goldPrimary,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 9.h,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (task == null) return;
                        Navigator.pushNamed(
                          context, 
                          AppRoutes.damageReport,
                          arguments: {
                            'taskId': task.id,
                            'itemId': task.itens.first.id,
                            'sku': provider.expectedSKU,
                          },
                        );
                      },
                      icon: const Icon(Icons.report_problem),
                      label: const Text('RELATAR AVARIA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_showManualInput)
            ManualInputWidget(
              onCancel: () => setState(() => _showManualInput = false),
              onSubmitted: (code) {
                setState(() => _showManualInput = false);
                _processarCodigo(provider, code);
              },
            ),
            
          if (provider.isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
