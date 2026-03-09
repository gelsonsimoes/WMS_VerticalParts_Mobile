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
    String? lote,
    String? validade,
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
        'lote': lote,
        'validade': validade,
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
}
