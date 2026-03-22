import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/supabase_service.dart';
import '../scanner/widgets/scanner_overlay_widget.dart';

/// QuickRegistry — Escritório de Bolso do Operador
/// Hub com 3 módulos de cadastro rápido:
///   MOTORISTA  → foto + nome + CPF         → motoristas + fila_aprovação
///   VEÍCULO    → placa + tipo              → veiculos   + fila_aprovação
///   PRODUTO    → bipar SKU → se inexistente → nome + foto → produtos + fila_aprovação
class QuickRegistryScreen extends StatefulWidget {
  const QuickRegistryScreen({super.key});
  @override
  State<QuickRegistryScreen> createState() => _QuickRegistryScreenState();
}

// Hub modules
enum _Module { hub, motorista, veiculo, produto }

class _QuickRegistryScreenState extends State<QuickRegistryScreen> {
  _Module _module = _Module.hub;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          _moduleTitle,
          style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.goldPrimary),
          onPressed: _module == _Module.hub ? () => Navigator.pop(context) : _backToHub,
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  String get _moduleTitle => switch (_module) {
    _Module.hub       => 'CADASTRO RÁPIDO',
    _Module.motorista => 'CADASTRAR MOTORISTA',
    _Module.veiculo   => 'CADASTRAR VEÍCULO',
    _Module.produto   => 'PRODUTO NOVO',
  };

  void _backToHub() => setState(() => _module = _Module.hub);

  Widget _buildBody() => switch (_module) {
    _Module.hub       => _HubView(onSelect: (m) => setState(() => _module = m)),
    _Module.motorista => _MotoristaFlow(onDone: _backToHub),
    _Module.veiculo   => _VeiculoFlow(onDone: _backToHub),
    _Module.produto   => _ProdutoFlow(onDone: _backToHub),
  };
}

// ══════════════════════════════════════════════════════
// HUB — 3 tiles gigantes preto/amarelo
// ══════════════════════════════════════════════════════
class _HubView extends StatelessWidget {
  final void Function(_Module) onSelect;
  const _HubView({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1.h),
          Text(
            'O QUE DESEJA CADASTRAR AGORA?',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 9.sp, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 3.h),
          Expanded(
            child: Column(
              children: [
                _HubTile(
                  icon: Icons.person_rounded,
                  title: 'MOTORISTA',
                  subtitle: 'Foto · Nome · CPF — 30 seg',
                  color: AppTheme.goldPrimary,
                  onTap: () => onSelect(_Module.motorista),
                ),
                SizedBox(height: 3.h),
                _HubTile(
                  icon: Icons.local_shipping_rounded,
                  title: 'VEÍCULO',
                  subtitle: 'Placa · Tipo · Modelo',
                  color: AppTheme.goldPrimary,
                  onTap: () => onSelect(_Module.veiculo),
                ),
                SizedBox(height: 3.h),
                _HubTile(
                  icon: Icons.add_box_rounded,
                  title: 'PRODUTO NOVO',
                  subtitle: 'Bipar SKU → Cadastrar se não existir',
                  color: AppTheme.goldPrimary,
                  onTap: () => onSelect(_Module.produto),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Text(
              'TODOS OS CADASTROS FICAM PENDENTES ATÉ APROVAÇÃO DO GESTOR',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 8.sp, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _HubTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.15),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4), width: 2),
            ),
            child: Row(children: [
              Container(
                width: 22.w,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
                ),
                child: Icon(icon, color: AppTheme.darkBackground, size: 36.sp),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(color: color, fontSize: 15.sp, fontWeight: FontWeight.black, letterSpacing: 1)),
                  SizedBox(height: 0.5.h),
                  Text(subtitle, style: TextStyle(color: AppTheme.textMuted, fontSize: 9.sp)),
                ]),
              ),
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16.sp),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// FLOW BASE — câmera, snack, submit helpers
// ══════════════════════════════════════════════════════
abstract class _BaseFlowState<T extends StatefulWidget> extends State<T> {
  final ImagePicker _picker = ImagePicker();
  File? fotoFile;
  bool enviando = false;

  String get operadorNome =>
      Provider.of<AuthProvider>(context, listen: false).user?.nome ?? 'Operador';
  String? get operadorId =>
      Provider.of<AuthProvider>(context, listen: false).user?.id;

  Future<void> tirarFoto({bool docMode = false}) async {
    try {
      final xf = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: docMode ? 85 : 72, // maior qualidade para documentos
        maxWidth: docMode ? 1600 : 1024, // resolução extra para leitura de CPF
        preferredCameraDevice: CameraDevice.rear,
      );
      if (xf != null && mounted) setState(() => fotoFile = File(xf.path));
    } catch (e) {
      snack('Erro ao abrir câmera: $e', AppTheme.errorRed);
    }
  }

  Future<String?> uploadFoto(String subPath) async {
    if (fotoFile == null) return null;
    final path = subPath + const Uuid().v4();
    return await SupabaseService.uploadArquivo('registros_campo', path, fotoFile!);
  }

  void snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      backgroundColor: color,
      duration: const Duration(seconds: 4),
    ));
  }

  // Botão de câmera grande preto/amarelo
  Widget buildCameraButton() => GestureDetector(
    onTap: tirarFoto,
    child: Container(
      height: 22.h,
      decoration: BoxDecoration(
        color: fotoFile != null ? AppTheme.surfaceDark : AppTheme.goldPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary, width: 3),
      ),
      child: fotoFile != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(fit: StackFit.expand, children: [
                Image.file(fotoFile!, fit: BoxFit.cover),
                Positioned(
                  bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppTheme.goldPrimary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: AppTheme.darkBackground, size: 20),
                  ),
                ),
              ]),
            )
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.camera_alt_rounded, color: AppTheme.darkBackground, size: 40.sp),
              SizedBox(height: 1.h),
              Text('TIRAR FOTO', style: TextStyle(color: AppTheme.darkBackground, fontSize: 14.sp, fontWeight: FontWeight.black, letterSpacing: 1.5)),
              Text('Toque aqui', style: TextStyle(color: AppTheme.darkBackground.withOpacity(0.6), fontSize: 9.sp)),
            ]),
    ),
  );

  // Campo de texto alto contraste
  Widget buildField(String label, TextEditingController ctrl, {TextInputType? type, String? hint, int? maxLength, bool uppercase = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: AppTheme.goldPrimary, fontSize: 9.5.sp, fontWeight: FontWeight.black, letterSpacing: 1)),
      SizedBox(height: 0.8.h),
      TextField(
        controller: ctrl,
        keyboardType: type,
        maxLength: maxLength,
        textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.words,
        style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11.sp),
          counterStyle: TextStyle(color: AppTheme.textMuted, fontSize: 8.sp),
          filled: true,
          fillColor: AppTheme.surfaceDark,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF444444))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 2)),
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        ),
      ),
    ]);
  }

  // Botão de envio gigante
  Widget buildSubmitButton(String label, VoidCallback? onPress) => SizedBox(
    width: double.infinity,
    height: 8.h,
    child: ElevatedButton(
      onPressed: enviando ? null : onPress,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.goldPrimary,
        foregroundColor: AppTheme.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.black, letterSpacing: 1.5),
      ),
      child: enviando
          ? const CircularProgressIndicator(color: AppTheme.darkBackground, strokeWidth: 3)
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.send_rounded, size: 24),
              const SizedBox(width: 12),
              Text(label),
            ]),
    ),
  );
}

// ══════════════════════════════════════════════════════
// MOTORISTA FLOW
// ══════════════════════════════════════════════════════
class _MotoristaFlow extends StatefulWidget {
  final VoidCallback onDone;
  const _MotoristaFlow({required this.onDone});
  @override
  State<_MotoristaFlow> createState() => _MotoristaFlowState();
}

class _MotoristaFlowState extends _BaseFlowState<_MotoristaFlow> {
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl  = TextEditingController();

  @override
  void dispose() { _nomeCtrl.dispose(); _cpfCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) { snack('Nome é obrigatório.', AppTheme.errorRed); return; }
    setState(() => enviando = true);
    try {
      final fotoUrl = await uploadFoto('motoristas/');
      final id = const Uuid().v4();
      await SupabaseService.client.from('motoristas').insert({
        'id': id, 'nome': nome, 'cpf': _cpfCtrl.text.trim(),
        'foto_url': fotoUrl, 'status': 'pendente',
        'criado_via_mobile': true,
        'operador_id': operadorId, 'operador_nome': operadorNome,
      });
      await SupabaseService.client.from('registros_campo_pendentes').insert({
        'tipo': 'motorista', 'referencia_id': id,
        'dados': {'nome': nome, 'cpf': _cpfCtrl.text.trim()},
        'foto_url': fotoUrl,
        'operador_id': operadorId, 'operador_nome': operadorNome,
        'status': 'pendente',
      });
      snack('✓ MOTORISTA CADASTRADO — Aguarda aprovação do gestor', AppTheme.successGreen);
      widget.onDone();
    } catch (e) {
      snack('Erro: $e', AppTheme.errorRed);
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  // Motorista usa modo documento: maior resolução + dica de flash
  @override
  Future<void> tirarFoto({bool docMode = false}) =>
      super.tirarFoto(docMode: true);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.all(4.w),
    child: Column(children: [
      // Banner de lanterna
      Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1600),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.flashlight_on_rounded, color: AppTheme.goldPrimary, size: 16),
          SizedBox(width: 2.w),
          Expanded(child: Text(
            'ATIVE O FLASH DO CELULAR antes de tirar a foto para garantir leitura do documento.',
            style: TextStyle(color: AppTheme.goldPrimary, fontSize: 8.5.sp, fontWeight: FontWeight.bold),
          )),
        ]),
      ),
      SizedBox(height: 1.5.h),
      buildCameraButton(),
      SizedBox(height: 2.h),
      buildField('NOME COMPLETO *', _nomeCtrl, hint: 'Ex: João Silva', uppercase: false),
      SizedBox(height: 1.5.h),
      buildField('CPF', _cpfCtrl, type: TextInputType.number, hint: '000.000.000-00', maxLength: 14),
      SizedBox(height: 3.h),
      buildSubmitButton('CADASTRAR MOTORISTA', _submit),
    ]),
  );
}

// ══════════════════════════════════════════════════════
// VEÍCULO FLOW
// ══════════════════════════════════════════════════════
class _VeiculoFlow extends StatefulWidget {
  final VoidCallback onDone;
  const _VeiculoFlow({required this.onDone});
  @override
  State<_VeiculoFlow> createState() => _VeiculoFlowState();
}

class _VeiculoFlowState extends _BaseFlowState<_VeiculoFlow> {
  final _placaCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  String _tipo = 'Caminhão';

  static const _tipos = ['Caminhão', 'VUC', 'Truck', 'Carreta', 'Fiorino', 'Moto', 'Van', 'Outro'];

  @override
  void dispose() { _placaCtrl.dispose(); _marcaCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final placa = _placaCtrl.text.trim().toUpperCase();
    if (placa.isEmpty) { snack('Placa é obrigatória.', AppTheme.errorRed); return; }
    setState(() => enviando = true);
    try {
      // ── Trava de placa duplicada ─────────────────────────────────────
      final existeAtivo = await SupabaseService.client
          .from('veiculos').select('id, status').eq('placa', placa).maybeSingle();
      if (existeAtivo != null) {
        final st = existeAtivo['status'] ?? '?';
        snack('⚠ Placa $placa já está cadastrada (status: $st).', AppTheme.goldPrimary);
        setState(() => enviando = false);
        return;
      }
      final existePendente = await SupabaseService.client
          .from('registros_campo_pendentes')
          .select('id')
          .filter('dados->>placa', 'eq', placa)
          .eq('status', 'pendente')
          .maybeSingle();
      if (existePendente != null) {
        snack('⚠ Placa $placa já está em processo de aprovação.', AppTheme.goldPrimary);
        setState(() => enviando = false);
        return;
      }
      // ─────────────────────────────────────────────────────────────────
      final id = const Uuid().v4();
      await SupabaseService.client.from('veiculos').insert({
        'id': id, 'placa': placa, 'tipo': _tipo,
        'marca': _marcaCtrl.text.trim(),
        'status': 'pendente', 'criado_via_mobile': true,
        'operador_id': operadorId, 'operador_nome': operadorNome,
      });
      await SupabaseService.client.from('registros_campo_pendentes').insert({
        'tipo': 'veiculo', 'referencia_id': id,
        'dados': {'placa': placa, 'tipo': _tipo, 'marca': _marcaCtrl.text.trim()},
        'operador_id': operadorId, 'operador_nome': operadorNome,
        'status': 'pendente',
      });
      HapticFeedback.heavyImpact();
      snack('✓ VEÍCULO $placa CADASTRADO — Aguarda aprovação', AppTheme.successGreen);
      widget.onDone();
    } catch (e) {
      snack('Erro: $e', AppTheme.errorRed);
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.all(4.w),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Placa em destaque — campo gigante
      Text('PLACA DO VEÍCULO *', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 9.5.sp, fontWeight: FontWeight.black, letterSpacing: 1)),
      SizedBox(height: 0.8.h),
      TextField(
        controller: _placaCtrl,
        textCapitalization: TextCapitalization.characters,
        maxLength: 8,
        style: TextStyle(color: AppTheme.goldPrimary, fontSize: 36.sp, fontWeight: FontWeight.black, letterSpacing: 4),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: 'ABC-1234',
          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 28.sp),
          filled: true, fillColor: AppTheme.surfaceDark,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 3)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 3)),
          counterStyle: const TextStyle(color: AppTheme.textMuted),
          contentPadding: EdgeInsets.symmetric(vertical: 2.5.h),
        ),
      ),
      SizedBox(height: 2.h),

      // Tipo — botões rápidos em grid
      Text('TIPO DO VEÍCULO *', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 9.5.sp, fontWeight: FontWeight.black, letterSpacing: 1)),
      SizedBox(height: 1.h),
      Wrap(spacing: 2.w, runSpacing: 1.5.h, children: _tipos.map((t) {
        final sel = _tipo == t;
        return GestureDetector(
          onTap: () => setState(() => _tipo = t),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
            decoration: BoxDecoration(
              color: sel ? AppTheme.goldPrimary : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? AppTheme.goldPrimary : const Color(0xFF444444), width: 2),
            ),
            child: Text(t, style: TextStyle(
              color: sel ? AppTheme.darkBackground : AppTheme.textLight,
              fontWeight: FontWeight.black, fontSize: 10.sp,
            )),
          ),
        );
      }).toList()),
      SizedBox(height: 2.h),

      buildField('MARCA / MODELO', _marcaCtrl, hint: 'Ex: Scania R450'),
      SizedBox(height: 3.h),
      buildSubmitButton('CADASTRAR VEÍCULO', _submit),
    ]),
  );
}

// ══════════════════════════════════════════════════════
// PRODUTO FLOW — Bipar SKU → Cadastrar se não existir
// ══════════════════════════════════════════════════════
class _ProdutoFlow extends StatefulWidget {
  final VoidCallback onDone;
  const _ProdutoFlow({required this.onDone});
  @override
  State<_ProdutoFlow> createState() => _ProdutoFlowState();
}

class _ProdutoFlowState extends _BaseFlowState<_ProdutoFlow> {
  final MobileScannerController _scanner = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  final _descCtrl = TextEditingController();
  final _skuCtrl  = TextEditingController();

  bool _scanned   = false;
  bool _loading   = false;
  bool _existe    = false;
  bool _torchOn   = false;
  Map<String, dynamic>? _produtoExistente;

  @override
  void dispose() { _scanner.dispose(); _descCtrl.dispose(); _skuCtrl.dispose(); super.dispose(); }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty || _scanned) return;
    HapticFeedback.mediumImpact();
    setState(() { _scanned = true; _loading = true; _skuCtrl.text = raw.trim().toUpperCase(); });
    _scanner.stop();

    final produto = await SupabaseService.buscarProdutoPorCodigo(raw.trim());
    if (!mounted) return;
    if (produto != null) {
      setState(() { _produtoExistente = produto; _existe = true; _loading = false; });
    } else {
      setState(() { _existe = false; _loading = false; });
    }
  }

  Future<void> _submit() async {
    final descricao = _descCtrl.text.trim();
    final sku = _skuCtrl.text.trim().toUpperCase();
    if (sku.isEmpty)     { snack('SKU é obrigatório.', AppTheme.errorRed); return; }
    if (descricao.isEmpty) { snack('Descrição é obrigatória.', AppTheme.errorRed); return; }
    setState(() => enviando = true);
    try {
      final fotoUrl = await uploadFoto('produtos/');
      final id = const Uuid().v4();
      await SupabaseService.client.from('produtos').insert({
        'id': id, 'sku': sku, 'descricao': descricao,
        'foto_url': fotoUrl, 'criado_via_mobile': true,
        'unidade': 'UN', 'status': 'ativo',
      });
      await SupabaseService.client.from('registros_campo_pendentes').insert({
        'tipo': 'produto', 'referencia_id': id,
        'dados': {'sku': sku, 'descricao': descricao},
        'foto_url': fotoUrl,
        'operador_id': operadorId, 'operador_nome': operadorNome,
        'status': 'pendente',
      });
      snack('✓ PRODUTO $sku CADASTRADO — Aguarda aprovação do gestor', AppTheme.successGreen);
      widget.onDone();
    } catch (e) {
      snack('Erro: $e', AppTheme.errorRed);
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  void _resetScanner() {
    setState(() { _scanned = false; _existe = false; _produtoExistente = null; fotoFile = null; _descCtrl.clear(); _skuCtrl.clear(); });
    _scanner.start();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: AppTheme.goldPrimary),
      SizedBox(height: 16),
      Text('BUSCANDO PRODUTO...', style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
    ]));

    // Produto já existe — mostra info
    if (_existe && _produtoExistente != null) return _buildProdutoExistente();

    // Produto novo — formulário
    if (_scanned) return _buildFormNovoProduto();

    // Scanner
    return _buildScanner();
  }

  Widget _buildScanner() => Stack(children: [
    MobileScanner(controller: _scanner, onDetect: _onDetect),
    const ScannerOverlayWidget(),
    Positioned(
      top: 2.h, left: 0, right: 0,
      child: Center(child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
        decoration: BoxDecoration(color: AppTheme.goldPrimary, borderRadius: BorderRadius.circular(8)),
        child: Text('BIPE O SKU OU CÓDIGO DE BARRAS', style: TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.black, fontSize: 12.sp)),
      )),
    ),
    Positioned(
      bottom: 3.h, right: 4.w,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: AppTheme.surfaceDark,
        onPressed: () { _scanner.toggleTorch(); setState(() => _torchOn = !_torchOn); },
        child: Icon(_torchOn ? Icons.flashlight_on : Icons.flashlight_off, color: AppTheme.goldPrimary),
      ),
    ),
  ]);

  Widget _buildProdutoExistente() => Center(child: Padding(
    padding: EdgeInsets.all(6.w),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.successGreen, width: 2)),
        child: Column(children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 56),
          SizedBox(height: 2.h),
          Text('PRODUTO JÁ CADASTRADO', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.black, fontSize: 13.sp)),
          SizedBox(height: 1.h),
          Text(_produtoExistente!['sku'] ?? '', style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.black, fontSize: 16.sp, fontFamily: 'monospace')),
          SizedBox(height: 0.5.h),
          Text(_produtoExistente!['descricao'] ?? '', style: TextStyle(color: AppTheme.textLight, fontSize: 11.sp), textAlign: TextAlign.center),
          SizedBox(height: 0.5.h),
          Text('Qtd em estoque: ${_produtoExistente!['quantidade_total'] ?? 0} un', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
        ]),
      ),
      SizedBox(height: 4.h),
      SizedBox(
        width: double.infinity, height: 7.h,
        child: ElevatedButton.icon(
          onPressed: _resetScanner,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: Text('BIPAR OUTRO PRODUTO', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.black)),
        ),
      ),
    ]),
  ));

  Widget _buildFormNovoProduto() => SingleChildScrollView(
    padding: EdgeInsets.all(4.w),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5))),
        child: Row(children: [
          const Icon(Icons.new_label_rounded, color: AppTheme.goldPrimary),
          SizedBox(width: 2.w),
          Text('SKU NÃO ENCONTRADO — CADASTRAR NOVO', style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.black, fontSize: 9.sp)),
        ]),
      ),
      SizedBox(height: 2.h),
      buildCameraButton(),
      SizedBox(height: 2.h),
      buildField('SKU / CÓDIGO *', _skuCtrl, uppercase: true, hint: 'Ex: VPER-ESS-NY-27MM'),
      SizedBox(height: 1.5.h),
      buildField('DESCRIÇÃO DO PRODUTO *', _descCtrl, hint: 'Ex: Correia dentada 27mm'),
      SizedBox(height: 3.h),
      buildSubmitButton('CADASTRAR PRODUTO', _submit),
      SizedBox(height: 1.h),
      SizedBox(
        width: double.infinity, height: 5.h,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.textMuted), foregroundColor: AppTheme.textMuted),
          onPressed: _resetScanner,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: Text('BIPAR NOVAMENTE', style: TextStyle(fontSize: 9.5.sp)),
        ),
      ),
    ]),
  );
}
