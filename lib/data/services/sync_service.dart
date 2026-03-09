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
      }

      if (success) {
        await localDb.deleteAction(id);
      }
    }
  }
}
