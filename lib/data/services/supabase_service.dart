import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<AuthResponse> login(String loginInput, String senha) async {
    // Se o usuário digitou um e-mail completo, usa ele. Caso contrário, gera o padrão interno.
    final email = loginInput.contains('@') 
        ? loginInput.trim().toLowerCase()
        : '${loginInput.trim().toLowerCase()}@vp.internal';
    
    return await client.auth.signInWithPassword(email: email, password: senha);
  }

  static Future<void> logout() async => await client.auth.signOut();
  static Session? get sessaoAtual  => client.auth.currentSession;
  static User?    get usuarioAtual => client.auth.currentUser;

  static Future<Map<String, dynamic>?> getPerfil(String uid) async {
    return await client.from('operadores').select().eq('id', uid).maybeSingle();
  }

  static Future<List<Task>> getTarefas() async {
    final uid = usuarioAtual?.id;
    if (uid == null) return [];
    try {
      final res = await client.from('tarefas').select('''
        id, tipo, status, prioridade, pedido_id, created_at,
        itens:itens_tarefa (
          id, sequencia, sku, descricao, endereco_id,
          quantidade_esperada, quantidade_coletada,
          codigo_barras_produto, codigo_barras_endereco, status
        )
      ''').or('operador_id.eq.$uid,operador_id.is.null')
         .inFilter('status', ['pendente', 'em_andamento'])
         .order('created_at', ascending: true);
      
      return (res as List).map((t) => Task.fromJson(t)).toList();
    } catch (e) {
      print('[SupabaseService] Erro ao buscar tarefas: $e');
      return [];
    }
  }

  static Future<bool> registrarColeta({
    required String tarefaId,
    required String itemId,
    required int quantidade,
    String? enderecoId,
  }) async {
    final uid = usuarioAtual?.id;
    if (uid == null) return false;
    try {
      await client.from('coletas').insert({
        'tarefa_id': tarefaId, 'item_id': itemId,
        'operador_id': uid, 'quantidade_coletada': quantidade,
        'endereco_id': enderecoId,
        'timestamp_coleta': DateTime.now().toIso8601String(),
      });
      await client.from('itens_tarefa').update({
        'quantidade_coletada': quantidade, 'status': 'coletado',
      }).eq('id', itemId);
      return true;
    } catch (e) {
      print('[Supabase] Erro coleta: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> validarCodigo({
    required String codigo, required String tipo,
  }) async {
    try {
      if (tipo == 'produto') {
        final upCode = codigo.trim().toUpperCase();
        return await client.from('produtos').select()
            .or('sku.eq.$upCode').maybeSingle();
      } else {
        return await client.from('enderecos').select()
            .eq('id', codigo.toUpperCase()).maybeSingle();
      }
    } catch (e) { return null; }
  }

  static Future<Map<String, dynamic>> alocarProduto({
    required String enderecoId, required String produtoId,
    required int quantidade, String? lote, String? validade, String? tarefaId,
  }) async {
    final uid = usuarioAtual?.id;
    if (uid == null) return {'ok': false, 'erro': 'Sem sessao ativa'};
    try {
      final res = await client.rpc('alocar_produto', params: {
        'p_endereco_id': enderecoId, 'p_produto_id': produtoId,
        'p_lote': lote ?? '', 'p_validade': validade,
        'p_quantidade': quantidade, 'p_operador_id': uid, 'p_tarefa_id': tarefaId,
      });
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      return {'ok': false, 'erro': e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> consultarEstoque(String sku) async {
    final res = await client.from('estoques').select('''
      quantidade, lote, validade, peso, cor,
      produtos!inner(sku, descricao),
      enderecos!inner(id, porta_palete, nivel, coluna, rua, status)
    ''').eq('produtos.sku', sku).gt('quantidade', 0);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> consultarConteudoEndereco(String enderecoId) async {
    final res = await client.from('estoques').select('''
      quantidade, lote, validade, peso, cor,
      produtos!inner(sku, descricao)
    ''').eq('endereco_id', enderecoId).gt('quantidade', 0);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static RealtimeChannel subscribeEnderecos(
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return client.channel('enderecos_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public', table: 'enderecos',
          callback: (p) => onUpdate(p.newRecord),
        ).subscribe();
  }

  static Future<String?> uploadArquivo(String bucket, String path, File arquivo) async {
    try {
      final name = '$path/${DateTime.now().millisecondsSinceEpoch}_${arquivo.path.split('/').last}';
      await client.storage.from(bucket).upload(name, arquivo);
      return client.storage.from(bucket).getPublicUrl(name);
    } catch (e) {
      print('[Supabase Storage] Erro upload: $e');
      return null;
    }
  }

  static Future<bool> registrarAvaria({
    required String tarefaId,
    String? itemId,
    required String descricao,
    List<String>? fotos,
  }) async {
    final uid = usuarioAtual?.id;
    if (uid == null) return false;
    try {
      await client.from('avarias').insert({
        'tarefa_id': tarefaId,
        'item_id': itemId,
        'operador_id': uid,
        'descricao': descricao,
        'fotos': fotos ?? [],
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> registrarRemanejamento({
    required String? origemId,
    required String? destinoId,
    required String sku,
    required int quantidade,
  }) async {
    final uid = usuarioAtual?.id;
    if (uid == null) return false;
    try {
      await client.from('remanejamentos').insert({
        'origem_id': origemId,
        'destino_id': destinoId,
        'sku': sku,
        'quantidade': quantidade,
        'operador_id': uid,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('[Supabase] Erro remanejamento: $e');
      return false;
    }
  }

  static Future<bool> registrarRecebimento({
    required String nfe,
    required String sku,
    required int quantidade,
    String? referencia,
    double? peso,
    String? cor,
  }) async {
    final uid = usuarioAtual?.id;
    if (uid == null) return false;
    try {
      await client.from('recebimentos').insert({
        'nfe': nfe,
        'sku': sku,
        'quantidade': quantidade,
        'referencia': referencia,
        'peso': peso,
        'cor': cor,
        'operador_id': uid,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('[Supabase] Erro recebimento: $e');
      return false;
    }
  }

  // ── Inventário Ativo ────────────────────────────────────────────────────

  /// Busca produto por SKU ou código de barras (campo sku ou codigo_barras).
  static Future<Map<String, dynamic>?> buscarProdutoPorCodigo(String codigo) async {
    try {
      final upCode = codigo.trim().toUpperCase();
      // Tenta por SKU exato primeiro
      var res = await client.from('produtos').select(
        'id, sku, descricao, peso, quantidade_total:estoques(quantidade)'
      ).eq('sku', upCode).maybeSingle();
      if (res != null) return _normalizarProduto(res);

      // Fallback: busca por codigo_barras
      res = await client.from('produtos').select(
        'id, sku, descricao, peso'
      ).eq('codigo_barras', upCode).maybeSingle();
      return res != null ? _normalizarProduto(res) : null;
    } catch (e) {
      print('[SupabaseService] buscarProdutoPorCodigo: $e');
      return null;
    }
  }

  static Map<String, dynamic> _normalizarProduto(Map<String, dynamic> p) {
    // Soma quantidade total de todos os estoques
    final estoques = p['quantidade_total'];
    int qtdTotal = 0;
    if (estoques is List) {
      for (final e in estoques) {
        qtdTotal += (e['quantidade'] as num?)?.toInt() ?? 0;
      }
    }
    return {...p, 'quantidade_total': qtdTotal};
  }

  /// Insere uma linha em auditoria_inventario (tabela ponte Mobile→Web).
  static Future<bool> registrarContagemInventario({
    required String sessaoId,
    required String? operadorId,
    required String? operadorNome,
    required String sku,
    String? descricao,
    String? enderecoId,
    String? enderecoLabel,
    required int quantidadeContada,
    int? quantidadeEsperada,
    double? peso,
  }) async {
    try {
      final divergente = quantidadeEsperada != null && quantidadeContada != quantidadeEsperada;
      await client.from('auditoria_inventario').insert({
        'operador_id':          operadorId,
        'operador_nome':        operadorNome ?? 'Operador',
        'sku':                  sku,
        'descricao':            descricao,
        'endereco_id':          enderecoId,
        'endereco_label':       enderecoLabel,
        'quantidade_contada':   quantidadeContada,
        'quantidade_esperada':  quantidadeEsperada,
        'peso':                 peso,
        'sessao_id':            sessaoId,
        'dispositivo':          'mobile',
        'status':               divergente ? 'divergente' : 'registrado',
      });
      return true;
    } catch (e) {
      print('[Supabase] Erro contagem inventario: $e');
      return false;
    }
  }

  // ── OMIE: Módulo de Saída Dirigida ─────────────────────────────────────────

  /// Retorna pedidos prontos para separar (status: reservado | reservado_parcial | em_separacao)
  static Future<List<Map<String, dynamic>>> getPedidosParaSeparar() async {
    try {
      final res = await client
          .from('pedidos_venda_omie')
          .select('*, itens_pedido_omie(id)')
          .inFilter('status', ['reservado', 'reservado_parcial', 'em_separacao'])
          .order('criado_em', ascending: true);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      print('[Supabase] Erro getPedidosParaSeparar: $e');
      return [];
    }
  }

  /// Retorna os itens de um pedido ordenados por endereço (rota ótima)
  static Future<List<Map<String, dynamic>>> getItensPedido(String pedidoId) async {
    try {
      final res = await client
          .from('itens_pedido_omie')
          .select('*')
          .eq('pedido_id', pedidoId)
          .order('endereco_reservado', ascending: true);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      print('[Supabase] Erro getItensPedido: $e');
      return [];
    }
  }

  /// Registra a coleta de um item no picking Omie
  static Future<void> registrarItemSeparado({
    required String itemId,
    required int quantidade,
    required String operadorId,
  }) async {
    await client.from('itens_pedido_omie').update({
      'quantidade_separada': quantidade,
      'status': quantidade > 0 ? 'separado' : 'falta',
    }).eq('id', itemId);
  }

  /// Finaliza o pedido: muda status para 'separado', calcula e salva peso_total_separado.
  ///
  /// Estratégia de peso:
  ///  1. Busca itens do pedido com JOIN em produtos para obter peso_bruto.
  ///  2. Soma (peso_bruto * quantidade_separada) para cada item.
  ///  3. Atualiza pedidos_venda_omie com status='separado' + peso calculado.
  static Future<void> finalizarPedidoOmie({
    required String pedidoId,
    required String operadorNome,
  }) async {
    double pesoTotal = 0.0;
    try {
      // Busca itens com peso do produto (peso_bruto em kg)
      final itens = await client
          .from('itens_pedido_omie')
          .select('quantidade_separada, sku')
          .eq('pedido_id', pedidoId);

      if (itens is List && itens.isNotEmpty) {
        // Para cada item, busca o peso_bruto do produto
        for (final item in itens) {
          final qtd = (item['quantidade_separada'] as num?)?.toDouble() ?? 0.0;
          if (qtd <= 0) continue;
          final sku = item['sku'] as String?;
          if (sku == null || sku.isEmpty) continue;

          final produto = await client
              .from('produtos')
              .select('peso_bruto, peso')
              .eq('sku', sku)
              .maybeSingle();

          if (produto != null) {
            // Aceita campo peso_bruto ou peso (fallback)
            final pesoProd = (produto['peso_bruto'] as num?)?.toDouble()
                ?? (produto['peso'] as num?)?.toDouble()
                ?? 0.0;
            pesoTotal += pesoProd * qtd;
          }
        }
      }
    } catch (e) {
      print('[SupabaseService] Erro ao calcular peso_total_separado: $e');
      // Continua mesmo sem o peso — não bloqueia a finalização
    }

    await client.from('pedidos_venda_omie').update({
      'status':              'separado',
      'atualizado_em':       DateTime.now().toIso8601String(),
      'observacoes':         'Separado por $operadorNome em ${DateTime.now().toIso8601String()}',
      'peso_total_separado': pesoTotal > 0 ? pesoTotal : null,
    }).eq('id', pedidoId);
  }
}
