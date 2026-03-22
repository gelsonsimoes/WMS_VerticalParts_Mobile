import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/sync_service.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';
import '../scanner/widgets/industrial_numeric_keyboard.dart';

/// InventoryCountScreen — Módulo de Inventário Ativo (Mobile Field Tool)
/// Fluxo: Bipar Endereço → Bipar SKU (auto-lookup) → Qty + Peso → Enviar
/// Offline-safe: falha na rede → SQLite local → SyncProvider sincroniza depois.
class InventoryCountScreen extends StatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen>
    with SingleTickerProviderStateMixin {
  // ── scanner controller ──────────────────────────────────────────────────
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // ── state ───────────────────────────────────────────────────────────────
  static const int _stepEndereco = 1;
  static const int _stepSku     = 2;
  static const int _stepQtd     = 3;

  int    _step            = _stepEndereco;
  bool   _scannerPaused   = false;
  bool   _loadingProduto  = false;
  bool   _enviando        = false;
  bool   _torchOn         = false;

  String? _enderecoId;
  String? _enderecoLabel;
  String? _sku;
  String? _descricao;
  int?    _qtdEsperada;
  double? _pesoUnitario;

  String  _qtdDigitada    = '0';
  String  _pesoDigitado   = '';

  // Sessão única por abertura da tela (agrupa coletas do mesmo turno)
  final String _sessaoId = const Uuid().v4();

  late final TabController _inputTab; // Qty / Peso

  @override
  void initState() {
    super.initState();
    _inputTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _scanner.dispose();
    _inputTab.dispose();
    super.dispose();
  }

  // ── scanner ─────────────────────────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) {
    if (_scannerPaused) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    HapticFeedback.mediumImpact();
    _pauseScanner();

    if (_step == _stepEndereco) {
      setState(() {
        _enderecoId    = raw;
        _enderecoLabel = raw;
        _step          = _stepSku;
      });
      _resumeScanner(after: 800);
    } else if (_step == _stepSku) {
      _buscarProduto(raw);
    }
  }

  void _pauseScanner()                        => setState(() => _scannerPaused = true);
  void _resumeScanner({int after = 500})      => Future.delayed(
    Duration(milliseconds: after), () { if (mounted) setState(() => _scannerPaused = false); });

  // ── product lookup ───────────────────────────────────────────────────────
  Future<void> _buscarProduto(String codigo) async {
    setState(() => _loadingProduto = true);
    try {
      final produto = await SupabaseService.buscarProdutoPorCodigo(codigo);
      if (!mounted) return;
      if (produto == null) {
        _showSnack('SKU não encontrado: $codigo', AppTheme.errorRed);
        setState(() { _loadingProduto = false; });
        _resumeScanner(after: 1500);
        return;
      }
      setState(() {
        _sku          = produto['sku'] ?? codigo;
        _descricao    = produto['descricao'] ?? '—';
        _qtdEsperada  = (produto['quantidade_total'] as num?)?.toInt();
        _pesoUnitario = (produto['peso'] as num?)?.toDouble();
        _loadingProduto = false;
        _step         = _stepQtd;
      });
    } catch (e) {
      if (mounted) {
        _showSnack('Erro ao buscar produto: $e', AppTheme.errorRed);
        setState(() => _loadingProduto = false);
        _resumeScanner(after: 1500);
      }
    }
  }

  // ── enviar contagem ──────────────────────────────────────────────────────
  Future<void> _enviarContagem() async {
    final qty = int.tryParse(_qtdDigitada) ?? 0;
    if (qty < 0) { _showSnack('Quantidade inválida.', AppTheme.errorRed); return; }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final operadorId   = authProvider.user?.id;
    final operadorNome = authProvider.user?.nome ?? 'Operador';

    setState(() => _enviando = true);
    try {
      final syncService = SyncService();
      final ok = await syncService.performInventoryCount(
        sessaoId:          _sessaoId,
        operadorId:        operadorId,
        operadorNome:      operadorNome,
        sku:               _sku!,
        descricao:         _descricao,
        enderecoId:        _enderecoId,
        enderecoLabel:     _enderecoLabel,
        quantidadeContada: qty,
        quantidadeEsperada: _qtdEsperada,
        peso:              _pesoDigitado.isNotEmpty ? double.tryParse(_pesoDigitado.replaceAll(',', '.')) : null,
      );

      if (!mounted) return;
      final divergente = _qtdEsperada != null && qty != _qtdEsperada;
      _showSnack(
        ok
          ? divergente
              ? '⚠ DIVERGÊNCIA: Contado $qty | Esperado $_qtdEsperada'
              : '✓ CONTAGEM ENVIADA — SKU: $_sku'
          : '📶 Sem sinal — salvo offline',
        ok && !divergente ? AppTheme.successGreen : AppTheme.goldPrimary,
      );
      _resetToNextItem();
    } catch (e) {
      if (mounted) _showSnack('Erro: $e', AppTheme.errorRed);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _resetToNextItem() {
    // Mantém endereço, reseta produto + quantidade para próximo item no mesmo local
    setState(() {
      _sku          = null;
      _descricao    = null;
      _qtdEsperada  = null;
      _pesoUnitario = null;
      _qtdDigitada  = '0';
      _pesoDigitado = '';
      _step         = _stepSku;
    });
    _resumeScanner();
  }

  void _resetTotal() {
    setState(() {
      _enderecoId    = null;
      _enderecoLabel = null;
      _sku           = null;
      _descricao     = null;
      _qtdEsperada   = null;
      _pesoUnitario  = null;
      _qtdDigitada   = '0';
      _pesoDigitado  = '';
      _step          = _stepEndereco;
    });
    _resumeScanner();
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      backgroundColor: color,
      duration: const Duration(seconds: 4),
    ));
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'INVENTÁRIO ATIVO',
          style: TextStyle(color: AppTheme.goldPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.goldPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_step >= _stepSku)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppTheme.textMuted, size: 20.sp),
              tooltip: 'Recomeçar',
              onPressed: _resetTotal,
            ),
          if (_step < _stepQtd)
            IconButton(
              icon: Icon(
                _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                color: _torchOn ? AppTheme.goldPrimary : AppTheme.textMuted,
                size: 20.sp,
              ),
              onPressed: () {
                _scanner.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
            ),
        ],
      ),
      body: SafeArea(child: Column(
        children: [
          _buildProgressBar(),
          Expanded(child: _buildBody()),
        ],
      )),
    );
  }

  // ── progress indicator ───────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Container(
      color: AppTheme.surfaceDark,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          _stepDot(1, Icons.location_on_rounded,  'LOCAL',   _step >= _stepSku),
          _progressLine(_step >= _stepSku),
          _stepDot(2, Icons.qr_code_scanner_rounded, 'SKU', _step >= _stepQtd),
          _progressLine(_step >= _stepQtd),
          _stepDot(3, Icons.calculate_rounded,   'QTD',    _step == _stepQtd),
        ],
      ),
    );
  }

  Widget _stepDot(int step, IconData icon, String label, bool active) {
    return Expanded(
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppTheme.goldPrimary : AppTheme.surfaceDark,
            border: Border.all(color: active ? AppTheme.goldPrimary : AppTheme.textMuted, width: 2),
          ),
          child: Icon(icon, size: 18, color: active ? AppTheme.darkBackground : AppTheme.textMuted),
        ),
        SizedBox(height: 0.5.h),
        Text(label, style: TextStyle(fontSize: 8.sp, color: active ? AppTheme.goldPrimary : AppTheme.textMuted, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _progressLine(bool active) => Expanded(
    child: Container(height: 2, color: active ? AppTheme.goldPrimary : AppTheme.textMuted.withOpacity(0.3)),
  );

  // ── body switcher ────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_step == _stepEndereco || _step == _stepSku) return _buildScannerView();
    return _buildInputView();
  }

  // ── scanner view ─────────────────────────────────────────────────────────
  Widget _buildScannerView() {
    return Stack(children: [
      MobileScanner(controller: _scanner, onDetect: _onDetect),
      const ScannerOverlayWidget(),

      // Instrução no topo
      Positioned(
        top: 2.h, left: 0, right: 0,
        child: Center(child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
          decoration: BoxDecoration(color: AppTheme.goldPrimary, borderRadius: BorderRadius.circular(8)),
          child: Text(
            _step == _stepEndereco ? 'BIPE O ENDEREÇO' : 'BIPE O SKU DO PRODUTO',
            style: TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold, fontSize: 13.sp, letterSpacing: 1),
          ),
        )),
      ),

      // Contexto atual (endereço já lido)
      if (_enderecoLabel != null)
        Positioned(
          bottom: 2.h, left: 4.w, right: 4.w,
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withOpacity(0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.goldPrimary, size: 20),
              SizedBox(width: 2.w),
              Expanded(child: Text(
                'ENDEREÇO: $_enderecoLabel',
                style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold, fontSize: 11.sp),
              )),
            ]),
          ),
        ),

      // Loading overlay
      if (_loadingProduto)
        Container(
          color: AppTheme.darkBackground.withOpacity(0.75),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: AppTheme.goldPrimary),
            SizedBox(height: 2.h),
            Text('BUSCANDO PRODUTO...', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ])),
        ),
    ]);
  }

  // ── input view ───────────────────────────────────────────────────────────
  Widget _buildInputView() {
    final divergente = _qtdEsperada != null && int.tryParse(_qtdDigitada) != _qtdEsperada;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Produto info card
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.inventory_2_rounded, color: AppTheme.goldPrimary, size: 20),
              SizedBox(width: 2.w),
              Expanded(child: Text(_sku ?? '', style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp))),
            ]),
            SizedBox(height: 0.8.h),
            Text(_descricao ?? '', style: TextStyle(color: AppTheme.textLight, fontSize: 11.sp)),
            SizedBox(height: 0.8.h),
            Row(children: [
              _chip(Icons.location_on_rounded, _enderecoLabel ?? '—', AppTheme.textMuted),
              SizedBox(width: 2.w),
              if (_qtdEsperada != null)
                _chip(Icons.inventory_rounded, 'Esperado: $_qtdEsperada', AppTheme.textMuted),
              if (_pesoUnitario != null)
                _chip(Icons.scale_rounded, '${_pesoUnitario!.toStringAsFixed(2)} kg/un', AppTheme.textMuted),
            ]),
          ]),
        ),

        SizedBox(height: 2.h),

        // Tabs: Quantidade | Peso
        Container(
          decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(8)),
          child: TabBar(
            controller: _inputTab,
            indicatorColor: AppTheme.goldPrimary,
            labelColor: AppTheme.goldPrimary,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.sp),
            tabs: const [Tab(text: 'QUANTIDADE'), Tab(text: 'PESO (kg)')],
          ),
        ),

        SizedBox(height: 1.5.h),

        // Quantidade display
        SizedBox(
          height: 8.h,
          child: TabBarView(controller: _inputTab, physics: const NeverScrollableScrollPhysics(), children: [
            _displayField(
              value: _qtdDigitada,
              suffix: 'un',
              highlight: divergente ? AppTheme.errorRed : AppTheme.goldPrimary,
              note: divergente ? '⚠ Diverge do esperado ($_qtdEsperada)' : (_qtdEsperada != null ? 'Esperado: $_qtdEsperada un' : null),
            ),
            _displayField(
              value: _pesoDigitado.isEmpty ? '—' : _pesoDigitado,
              suffix: 'kg',
              highlight: AppTheme.goldPrimary,
            ),
          ]),
        ),

        SizedBox(height: 1.5.h),

        // Teclado industrial
        SizedBox(
          height: 34.h,
          child: IndustrialNumericKeyboard(
            onKeyPressed: (v) => setState(() {
              if (_inputTab.index == 0) {
                _qtdDigitada = _qtdDigitada == '0' ? v : _qtdDigitada + v;
              } else {
                _pesoDigitado = _pesoDigitado + v;
              }
            }),
            onBackspace: () => setState(() {
              if (_inputTab.index == 0) {
                _qtdDigitada = _qtdDigitada.length > 1 ? _qtdDigitada.substring(0, _qtdDigitada.length - 1) : '0';
              } else {
                _pesoDigitado = _pesoDigitado.isNotEmpty ? _pesoDigitado.substring(0, _pesoDigitado.length - 1) : '';
              }
            }),
            onClear: () => setState(() {
              if (_inputTab.index == 0) _qtdDigitada = '0';
              else _pesoDigitado = '';
            }),
          ),
        ),

        SizedBox(height: 2.h),

        // Botão enviar
        SizedBox(
          width: double.infinity,
          height: 7.h,
          child: ElevatedButton.icon(
            onPressed: _enviando ? null : _enviarContagem,
            icon: _enviando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.darkBackground, strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 22),
            label: Text(_enviando ? 'ENVIANDO...' : 'CONFIRMAR CONTAGEM', style: TextStyle(fontSize: 13.sp, letterSpacing: 1)),
          ),
        ),

        SizedBox(height: 1.h),

        // Botão próximo produto (mesmo endereço)
        SizedBox(
          width: double.infinity,
          height: 5.h,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.textMuted),
              foregroundColor: AppTheme.textMuted,
            ),
            onPressed: _enviando ? null : _resetToNextItem,
            icon: const Icon(Icons.skip_next_rounded, size: 18),
            label: Text('PRÓXIMO PRODUTO (MESMO LOCAL)', style: TextStyle(fontSize: 9.5.sp)),
          ),
        ),
      ]),
    );
  }

  Widget _displayField({required String value, String? suffix, Color? highlight, String? note}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          border: Border.all(color: highlight ?? AppTheme.goldPrimary, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Expanded(child: Text(value, style: TextStyle(color: highlight ?? AppTheme.goldPrimary, fontSize: 28.sp, fontWeight: FontWeight.bold))),
          if (suffix != null) Text(suffix, style: TextStyle(color: AppTheme.textMuted, fontSize: 12.sp)),
        ]),
      ),
      if (note != null) Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(note, style: TextStyle(color: highlight, fontSize: 9.sp, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  Widget _chip(IconData icon, String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: color, fontSize: 9.sp)),
    const SizedBox(width: 8),
  ]);
}
