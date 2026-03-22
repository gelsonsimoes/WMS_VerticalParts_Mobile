import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:verticalpartswms/theme/app_theme.dart';
import 'package:verticalpartswms/routes/app_routes.dart';
import 'package:verticalpartswms/data/providers/auth_provider.dart';
import 'package:verticalpartswms/data/services/supabase_service.dart';
import 'package:verticalpartswms/presentation/scanner/widgets/scanner_overlay_widget.dart';
import 'package:verticalpartswms/presentation/scanner/widgets/industrial_numeric_keyboard.dart';

// ─── MODELOS INTERNOS ─────────────────────────────────────────────────────────

class _ItemPicking {
  final String id;
  final String sku;
  final String descricao;
  final int quantidade;
  final String enderecoReservado;
  int quantidadeSeparada;
  String status; // pendente | separado | falta

  _ItemPicking({
    required this.id,
    required this.sku,
    required this.descricao,
    required this.quantidade,
    required this.enderecoReservado,
    this.quantidadeSeparada = 0,
    this.status = 'pendente',
  });

  factory _ItemPicking.fromJson(Map<String, dynamic> j) => _ItemPicking(
        id: j['id'] ?? '',
        sku: j['sku'] ?? '',
        descricao: j['descricao'] ?? '',
        quantidade: j['quantidade'] ?? 1,
        enderecoReservado: j['endereco_reservado'] ?? '',
        quantidadeSeparada: j['quantidade_separada'] ?? 0,
        status: j['status'] ?? 'pendente',
      );
}

class _Pedido {
  final String id;
  final String numeroPedido;
  final String clienteNome;
  final String dataPrevisao;
  final String status;
  final double valorTotal;
  final int totalItens;

  _Pedido({
    required this.id,
    required this.numeroPedido,
    required this.clienteNome,
    required this.dataPrevisao,
    required this.status,
    required this.valorTotal,
    required this.totalItens,
  });

  factory _Pedido.fromJson(Map<String, dynamic> j) {
    final itens = j['itens_pedido_omie'] as List? ?? [];
    return _Pedido(
      id: j['id'] ?? '',
      numeroPedido: j['numero_pedido'] ?? '',
      clienteNome: j['cliente_nome'] ?? 'Cliente',
      dataPrevisao: j['data_previsao'] ?? '',
      status: j['status'] ?? 'pendente',
      valorTotal: double.tryParse(j['valor_total']?.toString() ?? '0') ?? 0,
      totalItens: itens.length,
    );
  }
}

// ─── ESTADOS DO FLUXO DE PICKING ─────────────────────────────────────────────
enum _PickStep { lista, scanEndereco, scanSku, quantidade, concluido }

// ─── TELA PRINCIPAL ───────────────────────────────────────────────────────────
class OutboundPickingScreen extends StatefulWidget {
  const OutboundPickingScreen({super.key});

  @override
  State<OutboundPickingScreen> createState() => _OutboundPickingScreenState();
}

class _OutboundPickingScreenState extends State<OutboundPickingScreen> {
  // Estado da lista
  List<_Pedido> _pedidos = [];
  bool _loadingPedidos = true;

  // Estado do picking ativo
  _Pedido? _pedidoAtivo;
  List<_ItemPicking> _itens = [];
  int _itemIndex = 0;
  _PickStep _step = _PickStep.lista;
  String _qtyInput = '0';
  bool _processing = false;
  String? _erroMsg;
  bool _enderecoConfirmado = false;

  // Scanner
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _scannerAtivo = false;

  @override
  void initState() {
    super.initState();
    _carregarPedidos();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  // ── Carrega pedidos do Supabase ───────────────────────────────────────────
  Future<void> _carregarPedidos() async {
    setState(() => _loadingPedidos = true);
    try {
      final data = await SupabaseService.getPedidosParaSeparar();
      setState(() {
        _pedidos = data.map((j) => _Pedido.fromJson(j)).toList();
        _loadingPedidos = false;
      });
    } catch (_) {
      setState(() => _loadingPedidos = false);
    }
  }

  // ── Inicia picking de um pedido ───────────────────────────────────────────
  Future<void> _iniciarPedido(_Pedido pedido) async {
    setState(() => _processing = true);
    try {
      final itensRaw = await SupabaseService.getItensPedido(pedido.id);
      // Ordena por rua: menor rua primeiro = caminho mais curto
      final itens = itensRaw
          .map((j) => _ItemPicking.fromJson(j))
          .where((i) => i.status == 'reservado')
          .toList()
        ..sort((a, b) => a.enderecoReservado.compareTo(b.enderecoReservado));

      if (itens.isEmpty) {
        _snack('Nenhum item reservado para separar neste pedido', error: true);
        setState(() => _processing = false);
        return;
      }

      setState(() {
        _pedidoAtivo = pedido;
        _itens = itens;
        _itemIndex = 0;
        _step = _PickStep.scanEndereco;
        _enderecoConfirmado = false;
        _qtyInput = '0';
        _processing = false;
        _erroMsg = null;
      });
      _ativarScanner();
    } catch (e) {
      _snack('Erro ao carregar itens: $e', error: true);
      setState(() => _processing = false);
    }
  }

  // ── Processa leitura de barcode ───────────────────────────────────────────
  void _processarLeitura(String code) {
    if (_processing) return;
    final limpo = code.trim().toUpperCase();
    if (limpo.isEmpty) return;

    final item = _itens[_itemIndex];

    if (_step == _PickStep.scanEndereco) {
      // Aceita o código do endereço ou o código formatado (ex: R1-PP1-A01)
      final endEsperado = item.enderecoReservado.toUpperCase();
      if (limpo == endEsperado || limpo.replaceAll(RegExp(r'[-_]'), '') == endEsperado.replaceAll(RegExp(r'[-_]'), '')) {
        HapticFeedback.mediumImpact();
        setState(() {
          _enderecoConfirmado = true;
          _step = _PickStep.scanSku;
          _erroMsg = null;
        });
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _erroMsg = '❌ ENDEREÇO ERRADO!\nVÁ PARA: ${item.enderecoReservado}');
      }
    } else if (_step == _PickStep.scanSku) {
      final skuEsperado = item.sku.trim().toUpperCase();
      if (limpo == skuEsperado) {
        HapticFeedback.mediumImpact();
        _desativarScanner();
        setState(() {
          _step = _PickStep.quantidade;
          _qtyInput = item.quantidade.toString();
          _erroMsg = null;
        });
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _erroMsg = '❌ PRODUTO INCORRETO!\nSKU ESPERADO: ${item.sku}');
      }
    }
  }

  // ── Confirma quantidade e avança item ─────────────────────────────────────
  Future<void> _confirmarColeta() async {
    final qtd = int.tryParse(_qtyInput) ?? 0;
    final item = _itens[_itemIndex];
    setState(() => _processing = true);

    try {
      await SupabaseService.registrarItemSeparado(
        itemId: item.id,
        quantidade: qtd,
        operadorId: context.read<AuthProvider>().user?.id ?? '',
      );

      _itens[_itemIndex].quantidadeSeparada = qtd;
      _itens[_itemIndex].status = qtd > 0 ? 'separado' : 'falta';

      if (_itemIndex < _itens.length - 1) {
        // Próximo item
        setState(() {
          _itemIndex++;
          _step = _PickStep.scanEndereco;
          _enderecoConfirmado = false;
          _qtyInput = '0';
          _erroMsg = null;
          _processing = false;
        });
        _ativarScanner();
      } else {
        // ÚLTIMO ITEM: finaliza o pedido
        await _finalizarPedido();
      }
    } catch (e) {
      _snack('Erro ao registrar coleta: $e', error: true);
      setState(() => _processing = false);
    }
  }

  // ── Finaliza o pedido ─────────────────────────────────────────────────────
  Future<void> _finalizarPedido() async {
    try {
      await SupabaseService.finalizarPedidoOmie(
        pedidoId: _pedidoAtivo!.id,
        operadorNome: context.read<AuthProvider>().user?.nome ?? 'Operador',
      );
      setState(() {
        _step = _PickStep.concluido;
        _processing = false;
      });
    } catch (e) {
      _snack('Pedido coletado mas erro ao finalizar: $e', error: true);
      setState(() => _processing = false);
    }
  }

  // ── Confirmar falta ───────────────────────────────────────────────────────
  Future<void> _confirmarFalta() async {
    setState(() => _qtyInput = '0');
    await _confirmarColeta();
  }

  // ── Scanner helpers ───────────────────────────────────────────────────────
  void _ativarScanner() {
    if (!_scannerAtivo) { _scanner.start(); _scannerAtivo = true; }
  }

  void _desativarScanner() {
    if (_scannerAtivo) { _scanner.stop(); _scannerAtivo = false; }
  }

  // ── Voltar para lista ─────────────────────────────────────────────────────
  void _voltarLista() {
    _desativarScanner();
    setState(() {
      _pedidoAtivo = null;
      _itens = [];
      _itemIndex = 0;
      _step = _PickStep.lista;
      _erroMsg = null;
    });
    _carregarPedidos();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: error ? AppTheme.errorRed : AppTheme.successGreen,
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_step != _PickStep.lista) { _voltarLista(); return false; }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.darkBackground,
      leading: _step != _PickStep.lista
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.goldPrimary),
              onPressed: _voltarLista,
            )
          : null,
      automaticallyImplyLeading: _step == _PickStep.lista,
      title: Column(
        children: [
          Text(
            'SAÍDA DIRIGIDA',
            style: TextStyle(color: AppTheme.goldPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          if (_pedidoAtivo != null)
            Text(
              _pedidoAtivo!.numeroPedido,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (_step == _PickStep.lista)
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.goldPrimary),
            onPressed: _carregarPedidos,
          ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _PickStep.lista:
        return _buildListaPedidos();
      case _PickStep.scanEndereco:
        return _buildScannerEndereco();
      case _PickStep.scanSku:
        return _buildScannerSku();
      case _PickStep.quantidade:
        return _buildQuantidade();
      case _PickStep.concluido:
        return _buildConcluido();
    }
  }

  // ─── LISTA DE PEDIDOS ─────────────────────────────────────────────────────
  Widget _buildListaPedidos() {
    if (_loadingPedidos) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary));
    }
    if (_pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 56),
            SizedBox(height: 2.h),
            Text('NENHUM PEDIDO PARA SEPARAR',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            Text('Aguardando reservas do Omie',
                style: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 9.sp)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _pedidos.length,
      itemBuilder: (ctx, i) => _buildPedidoCard(_pedidos[i]),
    );
  }

  Widget _buildPedidoCard(_Pedido p) {
    final corStatus = _statusColor(p.status);
    return GestureDetector(
      onTap: _processing ? null : () => _iniciarPedido(p),
      child: Container(
        margin: EdgeInsets.only(bottom: 3.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: corStatus.withOpacity(0.4), width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              // Ícone de status
              Container(
                width: 10.w, height: 10.w,
                decoration: BoxDecoration(
                  color: corStatus.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_statusIcon(p.status), color: corStatus, size: 16.sp),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.numeroPedido,
                        style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 0.5.h),
                    Text(p.clienteNome,
                        style: TextStyle(color: AppTheme.textLight, fontSize: 10.sp)),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        _chip('${p.totalItens} itens', AppTheme.goldPrimary),
                        SizedBox(width: 2.w),
                        _chip(
                          'R\$ ${p.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                          AppTheme.textMuted,
                        ),
                        SizedBox(width: 2.w),
                        _chip(_statusLabel(p.status), corStatus),
                      ],
                    ),
                  ],
                ),
              ),
              if (_processing)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: AppTheme.goldPrimary, strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right, color: AppTheme.goldPrimary, size: 14.sp),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SCANNER: CONFIRMAR ENDEREÇO ─────────────────────────────────────────
  Widget _buildScannerEndereco() {
    final item = _itens[_itemIndex];
    final progresso = '${_itemIndex + 1} / ${_itens.length}';

    return Column(
      children: [
        // ── HEADER ENDEREÇO (gigante, legível de longe) ────────────────────
        Container(
          width: double.infinity,
          color: AppTheme.goldPrimary,
          padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 6.w),
          child: Column(
            children: [
              Text('VÁ PARA O ENDEREÇO',
                  style: TextStyle(
                      color: AppTheme.darkBackground,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
              SizedBox(height: 1.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.enderecoReservado.isEmpty ? '—' : item.enderecoReservado,
                  style: TextStyle(
                    color: AppTheme.darkBackground,
                    fontSize: 48.sp, // ← 48sp conforme requisito
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
              SizedBox(height: 0.5.h),
              Text('Item $progresso · ${item.sku}',
                  style: TextStyle(color: AppTheme.darkBackground.withOpacity(0.7), fontSize: 9.sp)),
            ],
          ),
        ),

        // ── Info do produto ────────────────────────────────────────────────
        Container(
          color: AppTheme.surfaceDark,
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.descricao,
                        style: TextStyle(color: AppTheme.textLight, fontSize: 10.sp),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('QTDE: ${item.quantidade} UN',
                        style: TextStyle(color: AppTheme.goldPrimary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Erro (se houver) ───────────────────────────────────────────────
        if (_erroMsg != null)
          Container(
            width: double.infinity,
            color: AppTheme.errorRed.withOpacity(0.15),
            padding: EdgeInsets.all(3.w),
            child: Text(_erroMsg!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.errorRed, fontSize: 11.sp, fontWeight: FontWeight.bold)),
          ),

        // ── Scanner ────────────────────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scanner,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    _processarLeitura(barcodes.first.rawValue ?? '');
                  }
                },
              ),
              ScannerOverlayWidget(borderColor: AppTheme.goldPrimary),
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 30.h),
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('BIPE A ETIQUETA DO ENDEREÇO',
                      style: TextStyle(
                          color: AppTheme.goldPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        // ── Botão falta ────────────────────────────────────────────────────
        _buildBotoesExcecao(),
      ],
    );
  }

  // ─── SCANNER: CONFIRMAR SKU ───────────────────────────────────────────────
  Widget _buildScannerSku() {
    final item = _itens[_itemIndex];

    return Column(
      children: [
        // Endereço confirmado (verde) + produto esperado
        Container(
          width: double.infinity,
          color: AppTheme.successGreen,
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 6.w),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 2.w),
                  Text('ENDEREÇO CONFIRMADO: ${item.enderecoReservado}',
                      style: TextStyle(
                          color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),

        Container(
          width: double.infinity,
          color: AppTheme.surfaceDark,
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AGORA BIPE O PRODUTO:',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 9.sp, letterSpacing: 1.5)),
              SizedBox(height: 1.h),
              Text(item.sku,
                  style: TextStyle(
                      color: AppTheme.goldPrimary, fontSize: 18.sp, fontWeight: FontWeight.w900)),
              Text(item.descricao,
                  style: TextStyle(color: AppTheme.textLight, fontSize: 10.sp)),
              SizedBox(height: 0.5.h),
              Text('QTDE ESPERADA: ${item.quantidade} UN',
                  style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        if (_erroMsg != null)
          Container(
            width: double.infinity,
            color: AppTheme.errorRed.withOpacity(0.15),
            padding: EdgeInsets.all(3.w),
            child: Text(_erroMsg!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.errorRed, fontSize: 11.sp, fontWeight: FontWeight.bold)),
          ),

        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scanner,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    _processarLeitura(barcodes.first.rawValue ?? '');
                  }
                },
              ),
              ScannerOverlayWidget(borderColor: AppTheme.goldPrimary),
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 30.h),
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text('BIPE O CÓDIGO DO PRODUTO',
                      style: TextStyle(
                          color: AppTheme.goldPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        _buildBotoesExcecao(),
      ],
    );
  }

  // ─── QUANTIDADE ───────────────────────────────────────────────────────────
  Widget _buildQuantidade() {
    final item = _itens[_itemIndex];
    final progresso = '${_itemIndex + 1} / ${_itens.length}';

    return Column(
      children: [
        // Header produto
        Container(
          width: double.infinity,
          color: AppTheme.surfaceDark,
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Text('PRODUTO CONFIRMADO ✓',
                  style: TextStyle(color: AppTheme.successGreen, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 1.h),
              Text(item.sku,
                  style: TextStyle(
                      color: AppTheme.goldPrimary, fontSize: 16.sp, fontWeight: FontWeight.w900)),
              Text(item.descricao,
                  style: TextStyle(color: AppTheme.textLight, fontSize: 10.sp),
                  textAlign: TextAlign.center),
              SizedBox(height: 1.h),
              Text('Item $progresso · Esperado: ${item.quantidade} UN',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 9.sp)),
            ],
          ),
        ),

        SizedBox(height: 2.h),
        Text('QUANTIDADE COLETADA',
            style: TextStyle(
                color: AppTheme.goldPrimary, fontSize: 12.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        SizedBox(height: 2.h),

        // Display da quantidade
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.goldPrimary, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.surfaceDark,
            ),
            child: Center(
              child: Text(
                _qtyInput,
                style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // Teclado numérico
        Expanded(
          child: IndustrialNumericKeyboard(
            onKeyPressed: (v) => setState(() {
              _qtyInput = _qtyInput == '0' ? v : _qtyInput + v;
            }),
            onBackspace: () => setState(() {
              _qtyInput = _qtyInput.length > 1
                  ? _qtyInput.substring(0, _qtyInput.length - 1)
                  : '0';
            }),
            onClear: () => setState(() => _qtyInput = '0'),
          ),
        ),
        SizedBox(height: 1.h),

        // Botão confirmar
        Padding(
          padding: EdgeInsets.all(4.w),
          child: SizedBox(
            width: double.infinity,
            height: 8.h,
            child: ElevatedButton(
              onPressed: _processing ? null : _confirmarColeta,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: AppTheme.darkBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _processing
                  ? const CircularProgressIndicator(color: AppTheme.darkBackground)
                  : Text('CONFIRMAR COLETA',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── CONCLUÍDO ────────────────────────────────────────────────────────────
  Widget _buildConcluido() {
    final separados = _itens.where((i) => i.status == 'separado').length;
    final faltas    = _itens.where((i) => i.status == 'falta').length;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              faltas > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: faltas > 0 ? AppTheme.goldPrimary : AppTheme.successGreen,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text('PEDIDO SEPARADO!',
                style: TextStyle(
                    color: AppTheme.goldPrimary, fontSize: 18.sp, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
            SizedBox(height: 1.h),
            Text(_pedidoAtivo?.numeroPedido ?? '',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12.sp)),
            SizedBox(height: 3.h),

            // Resumo
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _resumoItem('Itens Coletados', '$separados / ${_itens.length}', AppTheme.successGreen),
                  if (faltas > 0) ...[
                    SizedBox(height: 1.h),
                    _resumoItem('Itens com Falta', '$faltas', AppTheme.errorRed),
                  ],
                  SizedBox(height: 1.h),
                  _resumoItem(
                    'Status',
                    faltas == 0 ? 'AGUARDANDO CONFERÊNCIA' : 'SEPARAÇÃO PARCIAL',
                    faltas == 0 ? AppTheme.successGreen : AppTheme.goldPrimary,
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),

            SizedBox(
              width: double.infinity,
              height: 7.h,
              child: ElevatedButton.icon(
                onPressed: _voltarLista,
                icon: const Icon(Icons.list_alt),
                label: Text('PRÓXIMO PEDIDO',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: AppTheme.darkBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.mainMenu),
              child: Text('IR AO MENU PRINCIPAL',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTÕES DE EXCEÇÃO ────────────────────────────────────────────────────
  Widget _buildBotoesExcecao() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      color: AppTheme.darkBackground,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _processing ? null : () => _mostrarDialogFalta(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorRed),
                foregroundColor: AppTheme.errorRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('FALTA TOTAL', style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogFalta() {
    final item = _itens[_itemIndex];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('FALTA TOTAL', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
        content: Text(
          'Confirmar que o item "${item.sku}" não foi encontrado no endereço ${item.enderecoReservado}?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _confirmarFalta(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('CONFIRMAR FALTA'),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS VISUAIS ─────────────────────────────────────────────────────
  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 8.sp, fontWeight: FontWeight.bold)),
      );

  Widget _resumoItem(String label, String value, Color color) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp)),
          Text(value, style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold)),
        ],
      );

  Color _statusColor(String status) {
    switch (status) {
      case 'reservado': return AppTheme.goldPrimary;
      case 'reservado_parcial': return Colors.amber;
      case 'separado': return AppTheme.successGreen;
      case 'em_separacao': return Colors.blue;
      default: return AppTheme.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'reservado': return Icons.inventory_2_rounded;
      case 'reservado_parcial': return Icons.warning_amber_rounded;
      case 'separado': return Icons.check_circle_outline;
      case 'em_separacao': return Icons.shopping_basket_rounded;
      default: return Icons.pending_outlined;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'reservado': return 'RESERVADO';
      case 'reservado_parcial': return 'PARCIAL';
      case 'separado': return 'SEPARADO';
      case 'em_separacao': return 'SEPARANDO';
      default: return status.toUpperCase();
    }
  }
}
