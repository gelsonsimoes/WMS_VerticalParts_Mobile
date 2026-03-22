import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/supabase_service.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';

/// CheckInPortariaScreen
/// Fluxo: Bipar/Digitar placa → Busca em veiculos (status=ativo) →
///        Se encontrado: confirma Check-In → insere em movimentacao_patio
///        Se não encontrado: direciona para cadastro rápido
class CheckInPortariaScreen extends StatefulWidget {
  const CheckInPortariaScreen({super.key});
  @override
  State<CheckInPortariaScreen> createState() => _CheckInPortariaScreenState();
}

enum _Step { scan, confirmacao, sucesso }

class _CheckInPortariaScreenState extends State<CheckInPortariaScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final TextEditingController _placaManual = TextEditingController();

  _Step _step = _Step.scan;
  bool _torchOn   = false;
  bool _loading   = false;
  bool _enviando  = false;
  bool _modoManual = false;

  Map<String, dynamic>? _veiculo;   // dados do veículo encontrado
  String? _placaLida;
  String? _erroMensagem;

  @override
  void dispose() { _scanner.dispose(); _placaManual.dispose(); super.dispose(); }

  // ── Scanner ────────────────────────────────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty || _loading) return;
    HapticFeedback.mediumImpact();
    await _buscarVeiculo(raw.trim().toUpperCase());
  }

  Future<void> _buscarPorDigitacao() async {
    final placa = _placaManual.text.trim().toUpperCase();
    if (placa.isEmpty) return;
    FocusScope.of(context).unfocus();
    await _buscarVeiculo(placa);
  }

  // ── Lookup ─────────────────────────────────────────────────────────
  Future<void> _buscarVeiculo(String placa) async {
    setState(() { _loading = true; _erroMensagem = null; _placaLida = placa; });
    _scanner.stop();
    try {
      // Busca veículo ativo
      final res = await SupabaseService.client
          .from('veiculos')
          .select('id, placa, tipo, marca, modelo, status, motorista_id')
          .eq('placa', placa)
          .eq('status', 'ativo')
          .maybeSingle();

      if (!mounted) return;

      if (res != null) {
        // Busca motorista vinculado
        Map<String, dynamic>? motorista;
        if (res['motorista_id'] != null) {
          motorista = await SupabaseService.client
              .from('motoristas')
              .select('nome, foto_url')
              .eq('id', res['motorista_id'])
              .maybeSingle();
        }

        // Verifica se já está no pátio (check-in sem check-out)
        final emPatio = await SupabaseService.client
            .from('movimentacao_patio')
            .select('id, entrada_em')
            .eq('placa', placa)
            .eq('status', 'no_patio')
            .maybeSingle();

        if (emPatio != null && mounted) {
          final entradaTs = DateTime.tryParse(emPatio['entrada_em'] ?? '');
          final minutos = entradaTs != null ? DateTime.now().difference(entradaTs).inMinutes : 0;
          setState(() {
            _erroMensagem = '⚠ Veículo $placa já está no pátio há ${minutos}min.\nDeseja fazer Check-OUT?';
            _veiculo = {...res, 'motorista_nome': motorista?['nome'], 'patio_id': emPatio['id']};
            _loading = false;
            _step = _Step.confirmacao;
          });
          return;
        }

        setState(() {
          _veiculo = {...res, 'motorista_nome': motorista?['nome'], 'motorista_foto': motorista?['foto_url']};
          _loading = false;
          _step = _Step.confirmacao;
        });
      } else {
        // Veículo não encontrado ou pendente
        final pendente = await SupabaseService.client
            .from('registros_campo_pendentes')
            .select('status')
            .filter('dados->>placa', 'eq', placa)
            .maybeSingle();

        setState(() {
          _loading = false;
          if (pendente != null) {
            _erroMensagem = 'Veículo $placa está em processo de cadastro (${pendente['status']}).\nAguarde aprovação do gestor.';
          } else {
            _erroMensagem = 'Placa $placa não encontrada.\nUse o Cadastro Rápido para registrar este veículo.';
          }
        });
        _scanner.start();
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _erroMensagem = 'Erro: $e'; });
      _scanner.start();
    }
  }

  // ── Check-in ───────────────────────────────────────────────────────
  Future<void> _confirmarCheckIn() async {
    if (_veiculo == null) return;
    setState(() => _enviando = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await SupabaseService.client.from('movimentacao_patio').insert({
        'id':            const Uuid().v4(),
        'veiculo_id':    _veiculo!['id'],
        'placa':         _placaLida,
        'tipo_veiculo':  _veiculo!['tipo'],
        'motorista_nome': _veiculo!['motorista_nome'],
        'operador_id':   auth.user?.id,
        'operador_nome': auth.user?.nome ?? 'Operador',
        'status':        'no_patio',
      });

      if (mounted) setState(() { _step = _Step.sucesso; _enviando = false; });
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao registrar entrada: $e', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.errorRed,
        ));
        setState(() => _enviando = false);
      }
    }
  }

  // ── Check-out ──────────────────────────────────────────────────────
  Future<void> _confirmarCheckOut() async {
    final patioId = _veiculo?['patio_id'];
    if (patioId == null) return;
    setState(() => _enviando = true);
    try {
      await SupabaseService.client.from('movimentacao_patio').update({
        'status': 'saiu',
        'saida_em': DateTime.now().toIso8601String(),
      }).eq('id', patioId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ CHECK-OUT REGISTRADO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: AppTheme.successGreen,
        ));
        _resetScanner();
      }
    } catch (e) {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _resetScanner() {
    setState(() {
      _step = _Step.scan;
      _veiculo = null;
      _placaLida = null;
      _erroMensagem = null;
      _enviando = false;
      _modoManual = false;
      _loading = false;
      _placaManual.clear();
    });
    _scanner.start();
  }

  // ── UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.darkBackground,
    appBar: AppBar(
      backgroundColor: AppTheme.darkBackground,
      title: Text('CHECK-IN PORTARIA', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.black, letterSpacing: 1.5)),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.goldPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_step == _Step.scan)
          IconButton(
            icon: Icon(_torchOn ? Icons.flashlight_on : Icons.flashlight_off, color: _torchOn ? AppTheme.goldPrimary : AppTheme.textMuted),
            onPressed: () { _scanner.toggleTorch(); setState(() => _torchOn = !_torchOn); },
          ),
      ],
    ),
    body: SafeArea(child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (_step) {
        _Step.scan        => _buildScanView(),
        _Step.confirmacao => _buildConfirmacaoView(),
        _Step.sucesso     => _buildSucessoView(),
      },
    )),
  );

  // ── Scan View ───────────────────────────────────────────────────────
  Widget _buildScanView() {
    if (_modoManual) return _buildManualInput();
    return Stack(children: [
      MobileScanner(controller: _scanner, onDetect: _onDetect),
      const ScannerOverlayWidget(),

      // Instrução
      Positioned(
        top: 2.h, left: 0, right: 0,
        child: Center(child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
          decoration: BoxDecoration(color: AppTheme.goldPrimary, borderRadius: BorderRadius.circular(8)),
          child: Text('BIPE A PLACA DO VEÍCULO', style: TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.black, fontSize: 13.sp, letterSpacing: 1)),
        )),
      ),

      // Loading overlay
      if (_loading) Container(
        color: AppTheme.darkBackground.withOpacity(0.8),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: AppTheme.goldPrimary),
          SizedBox(height: 2.h),
          Text('BUSCANDO VEÍCULO...', style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.black, fontSize: 12.sp)),
        ])),
      ),

      // Erro
      if (_erroMensagem != null && !_loading)
        Positioned(
          bottom: 14.h, left: 4.w, right: 4.w,
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(color: const Color(0xFF3A1212), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.errorRed, width: 2)),
            child: Text(_erroMensagem!, style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
        ),

      // Botão digitação manual
      Positioned(
        bottom: 3.h, left: 4.w, right: 4.w,
        child: SizedBox(
          height: 6.5.h,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _modoManual = true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark, foregroundColor: AppTheme.goldPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
            label: Text('DIGITAR PLACA', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.black)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildManualInput() => Padding(
    padding: EdgeInsets.all(5.w),
    child: Column(children: [
      SizedBox(height: 4.h),
      Text('PLACA DO VEÍCULO', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 10.sp, fontWeight: FontWeight.black, letterSpacing: 1.5)),
      SizedBox(height: 1.5.h),
      TextField(
        controller: _placaManual,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        maxLength: 8,
        style: TextStyle(color: AppTheme.goldPrimary, fontSize: 38.sp, fontWeight: FontWeight.black, letterSpacing: 5, fontFamily: 'monospace'),
        textAlign: TextAlign.center,
        onSubmitted: (_) => _buscarPorDigitacao(),
        decoration: InputDecoration(
          hintText: 'ABC-1234',
          hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 30.sp),
          filled: true, fillColor: AppTheme.surfaceDark,
          counterStyle: TextStyle(color: AppTheme.textMuted),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 3)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 3)),
          contentPadding: EdgeInsets.symmetric(vertical: 2.5.h),
        ),
      ),
      SizedBox(height: 3.h),
      SizedBox(
        width: double.infinity, height: 7.5.h,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _buscarPorDigitacao,
          icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.search_rounded, size: 26),
          label: Text('BUSCAR VEÍCULO', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.black)),
        ),
      ),
      SizedBox(height: 2.h),
      TextButton.icon(
        onPressed: () => setState(() => _modoManual = false),
        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.textMuted),
        label: Text('Usar Scanner', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
      ),
    ]),
  );

  // ── Confirmação View ────────────────────────────────────────────────
  Widget _buildConfirmacaoView() {
    final isCheckout = _veiculo?['patio_id'] != null;
    return SingleChildScrollView(
      padding: EdgeInsets.all(5.w),
      child: Column(children: [
        SizedBox(height: 2.h),

        // Veículo card
        Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isCheckout ? AppTheme.errorRed : AppTheme.goldPrimary, width: 2),
          ),
          child: Column(children: [
            Icon(Icons.local_shipping_rounded, color: isCheckout ? AppTheme.errorRed : AppTheme.goldPrimary, size: 40.sp),
            SizedBox(height: 1.5.h),
            Text(_placaLida ?? '', style: TextStyle(color: isCheckout ? AppTheme.errorRed : AppTheme.goldPrimary, fontSize: 32.sp, fontWeight: FontWeight.black, letterSpacing: 4, fontFamily: 'monospace')),
            SizedBox(height: 0.5.h),
            Text(_veiculo?['tipo'] ?? 'Veículo', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.sp, fontWeight: FontWeight.bold)),
            if (_veiculo?['marca'] != null) ...[
              SizedBox(height: 0.3.h),
              Text(_veiculo!['marca'], style: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 9.sp)),
            ],
            if (_veiculo?['motorista_nome'] != null) ...[
              Divider(color: AppTheme.textMuted.withOpacity(0.2), height: 3.h),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.person_rounded, color: AppTheme.goldPrimary, size: 18),
                SizedBox(width: 2.w),
                Text(_veiculo!['motorista_nome'], style: TextStyle(color: AppTheme.textLight, fontSize: 11.sp, fontWeight: FontWeight.bold)),
              ]),
            ],
          ]),
        ),

        SizedBox(height: 3.h),

        // Aviso de erro/duplicidade
        if (_erroMensagem != null) Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(color: const Color(0xFF3A2A00), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5))),
          child: Text(_erroMensagem!, style: TextStyle(color: AppTheme.goldPrimary, fontSize: 9.5.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),

        SizedBox(height: 2.h),

        // Botão principal
        if (!isCheckout) SizedBox(
          width: double.infinity, height: 8.h,
          child: ElevatedButton.icon(
            onPressed: _enviando ? null : _confirmarCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: AppTheme.darkBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _enviando ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.login_rounded, size: 26),
            label: Text('✓ CONFIRMAR CHECK-IN', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.black, letterSpacing: 1)),
          ),
        ) else Row(children: [
          Expanded(child: SizedBox(height: 7.h, child: ElevatedButton.icon(
            onPressed: _enviando ? null : _confirmarCheckOut,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.logout_rounded, size: 22),
            label: Text('CHECK-OUT', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.black)),
          ))),
        ]),

        SizedBox(height: 1.5.h),
        SizedBox(
          width: double.infinity, height: 5.5.h,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.textMuted), foregroundColor: AppTheme.textMuted),
            onPressed: _resetScanner,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text('ESCANEAR OUTRA PLACA', style: TextStyle(fontSize: 9.5.sp)),
          ),
        ),
      ]),
    );
  }

  // ── Sucesso View ────────────────────────────────────────────────────
  Widget _buildSucessoView() => Center(child: Padding(
    padding: EdgeInsets.all(6.w),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 90.sp, height: 90.sp,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.successGreen.withOpacity(0.15), border: Border.all(color: AppTheme.successGreen, width: 3)),
        child: Icon(Icons.check_rounded, color: AppTheme.successGreen, size: 50.sp),
      ),
      SizedBox(height: 3.h),
      Text('CHECK-IN REGISTRADO!', style: TextStyle(color: AppTheme.successGreen, fontSize: 18.sp, fontWeight: FontWeight.black)),
      SizedBox(height: 1.h),
      Text(_placaLida ?? '', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 28.sp, fontWeight: FontWeight.black, fontFamily: 'monospace', letterSpacing: 3)),
      SizedBox(height: 0.5.h),
      Text('${_veiculo?['tipo'] ?? ''} · ${_veiculo?['motorista_nome'] ?? ''}', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
      SizedBox(height: 1.h),
      Text(
        DateTime.now().toLocal().toString().substring(11, 16),
        style: TextStyle(color: AppTheme.textLight, fontSize: 26.sp, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 0.3.h),
      Text('HORÁRIO DE ENTRADA', style: TextStyle(color: AppTheme.textMuted, fontSize: 8.sp, letterSpacing: 2)),
      SizedBox(height: 5.h),
      SizedBox(
        width: double.infinity, height: 7.h,
        child: ElevatedButton.icon(
          onPressed: _resetScanner,
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
          label: Text('PRÓXIMO VEÍCULO', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.black)),
        ),
      ),
    ]),
  ));
}
