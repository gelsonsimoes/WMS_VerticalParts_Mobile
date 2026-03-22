import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'supabase_service.dart';
import 'local_database.dart';

class SyncService {
  final LocalDatabase localDb = LocalDatabase();

  SyncService();

  // Executa uma coleta com fallback offline
  Future<bool> performCollection({
    required String tarefaId,
    required String itemId,
    required int quantidade,
    String? enderecoId,
  }) async {
    final dados = {
      'tarefa_id': tarefaId,
      'item_id': itemId,
      'quantidade_coletada': quantidade,
      'endereco_id': enderecoId,
    };

    // Tenta enviar online
    final success = await SupabaseService.registrarColeta(
      tarefaId: tarefaId,
      itemId: itemId,
      quantidade: quantidade,
      enderecoId: enderecoId,
    );

    if (!success) {
      // Se falhar, salva no banco local
      await localDb.saveAction('coleta', dados);
      print('Ação salva offline para sincronização posterior.');
      return true; // Retorna true para a UI pois o trabalho foi "salvo" (localmente)
    }

    return true;
  }

  // Executa um remanejamento com fallback offline
  Future<bool> performReplenishment({
    required String? origemId,
    required String? destinoId,
    required String sku,
    required int quantidade,
  }) async {
    final dados = {
      'origem_id': origemId,
      'destino_id': destinoId,
      'sku': sku,
      'quantidade': quantidade,
    };

    // Tenta enviar online via Supabase
    final success = await SupabaseService.registrarRemanejamento(
      origemId: origemId,
      destinoId: destinoId,
      sku: sku,
      quantidade: quantidade,
    );

    if (!success) {
      await localDb.saveAction('remanejo', dados);
      return true;
    }

    return true;
  }

  // Executa contagem de inventário com fallback offline
  Future<bool> performInventoryCount({
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
    final dados = {
      'sessao_id': sessaoId,
      'operador_id': operadorId,
      'operador_nome': operadorNome ?? 'Operador',
      'sku': sku,
      'descricao': descricao,
      'endereco_id': enderecoId,
      'endereco_label': enderecoLabel,
      'quantidade_contada': quantidadeContada,
      'quantidade_esperada': quantidadeEsperada,
      'peso': peso,
    };

    final success = await SupabaseService.registrarContagemInventario(
      sessaoId: sessaoId,
      operadorId: operadorId,
      operadorNome: operadorNome,
      sku: sku,
      descricao: descricao,
      enderecoId: enderecoId,
      enderecoLabel: enderecoLabel,
      quantidadeContada: quantidadeContada,
      quantidadeEsperada: quantidadeEsperada,
      peso: peso,
    );

    if (!success) {
      await localDb.saveAction('inventario', dados);
      print('[SyncService] Contagem inventário salva offline para sincronização posterior.');
    }
    return true; // operador continua — dado nunca se perde
  }

  // Sincroniza tudo que está pendente
  Future<void> syncPendingActions() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) return;

    final actions = await localDb.getPendingActions();
    if (actions.isEmpty) return;

    print('Iniciando sincronização de ${actions.length} ações...');

    for (var action in actions) {
      final id = action['id'];
      final tipo = action['tipo'];
      final dados = json.decode(action['dados']);

      bool success = false;
      if (tipo == 'coleta') {
        success = await SupabaseService.registrarColeta(
          tarefaId: dados['tarefa_id'],
          itemId: dados['item_id'],
          quantidade: dados['quantidade_coletada'],
          enderecoId: dados['endereco_id'],
        );
      } else if (tipo == 'remanejo') {
        success = await SupabaseService.registrarRemanejamento(
          origemId: dados['origem_id'],
          destinoId: dados['destino_id'],
          sku: dados['sku'],
          quantidade: dados['quantidade'],
        );
      } else if (tipo == 'inventario') {
        success = await SupabaseService.registrarContagemInventario(
          sessaoId: dados['sessao_id'] ?? '',
          operadorId: dados['operador_id'],
          operadorNome: dados['operador_nome'],
          sku: dados['sku'],
          descricao: dados['descricao'],
          enderecoId: dados['endereco_id'],
          enderecoLabel: dados['endereco_label'],
          quantidadeContada: dados['quantidade_contada'] ?? 0,
          quantidadeEsperada: dados['quantidade_esperada'],
          peso: dados['peso'] != null ? (dados['peso'] as num).toDouble() : null,
        );
      }

      if (success) {
        await localDb.deleteAction(id);
      }
    }
  }
}
