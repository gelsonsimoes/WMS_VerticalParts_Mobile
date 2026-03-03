import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';

class PrintLabelScreen extends StatefulWidget {
  final String? initialSku;

  const PrintLabelScreen({super.key, this.initialSku});

  @override
  State<PrintLabelScreen> createState() => _PrintLabelScreenState();
}

class _PrintLabelScreenState extends State<PrintLabelScreen> {
  bool _isSearching = false;
  bool _isPrinting = false;
  String? _selectedPrinter;
  String? _sku;

  // Lista Mock de Impressoras Bluetooth Pareadas
  final List<Map<String, String>> _printers = [
    {"name": "ZEBRA QLN320 - EXPEDIÇÃO", "id": "BT:00:11:22:33"},
    {"name": "DATAMAX O'NEIL MP3", "id": "BT:44:55:66:77"},
    {"name": "ZEBRA ZD420 - RECEBIMENTO", "id": "BT:88:99:AA:BB"},
  ];

  @override
  void initState() {
    super.initState();
    _sku = widget.initialSku ?? "VPER-ESS-NY-27MM";
  }

  Future<void> _buscarImpressoras() async {
    setState(() => _isSearching = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isSearching = false);
  }

  Future<void> _imprimirZPL() async {
    if (_selectedPrinter == null) {
      _showFeedback("POR FAVOR, SELECIONE UMA IMPRESSORA", AppTheme.errorRed);
      return;
    }

    setState(() => _isPrinting = true);

    // Regra de Ouro: Solicita o layout ZPL ao servidor WMS (Simulado)
    await Future.delayed(const Duration(seconds: 1));
    String mockZPL = "^XA^FO50,50^A0N,50,50^FD$_sku^FS^XZ"; // Código ZPL Real-ish

    // Simula envio Bluetooth
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      _showFeedback("ETIQUETA ENVIADA COM SUCESSO! (ZPL)", AppTheme.successGreen);
      setState(() => _isPrinting = false);
    }
  }

  void _showFeedback(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMPRESSÃO DE ETIQUETA'),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card do Item
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: AppTheme.goldPrimary, width: 6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ITEM PARA IMPRESSÃO', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 11.sp)),
                  SizedBox(height: 1.h),
                  Text(_sku!, style: TextStyle(color: AppTheme.textLight, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            SizedBox(height: 4.h),

            // Seleção de Impressora
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('IMPRESSORAS PROXIMAS', style: TextStyle(color: AppTheme.textMuted, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _isSearching ? null : _buscarImpressoras,
                  icon: const Icon(Icons.refresh, color: AppTheme.goldPrimary),
                  label: const Text('BUSCAR', style: TextStyle(color: AppTheme.goldPrimary)),
                ),
              ],
            ),

            if (_isSearching)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.goldPrimary))),

            Expanded(
              child: ListView.builder(
                itemCount: _printers.length,
                itemBuilder: (context, index) {
                  final printer = _printers[index];
                  bool isSelected = _selectedPrinter == printer["id"];
                  return _buildPrinterTile(printer, isSelected);
                },
              ),
            ),

            // Botão Gigante de Impressão
            SizedBox(
              width: double.infinity,
              height: 10.h,
              child: ElevatedButton.icon(
                onPressed: _isPrinting ? null : _imprimirZPL,
                icon: const Icon(Icons.print_rounded),
                label: _isPrinting 
                  ? const CircularProgressIndicator(color: AppTheme.darkBackground) 
                  : Text('IMPRIMIR ETIQUETA AGORA', style: TextStyle(fontSize: 16.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterTile(Map<String, String> printer, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        onTap: () => setState(() => _selectedPrinter = printer["id"]),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? AppTheme.goldPrimary : Colors.transparent, width: 2),
        ),
        tileColor: AppTheme.surfaceDark,
        leading: Icon(Icons.bluetooth, color: isSelected ? AppTheme.goldPrimary : AppTheme.textMuted),
        title: Text(printer["name"]!, style: TextStyle(color: AppTheme.textLight, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(printer["id"]!, style: TextStyle(color: AppTheme.textMuted, fontSize: 9.sp)),
        trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.goldPrimary) : null,
      ),
    );
  }
}
