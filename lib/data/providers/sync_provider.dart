import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;
  int _pendingCount = 0;
  String? _syncError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  String? get syncError => _syncError;

  SyncProvider() {
    _updatePendingCount();
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncNow();
      }
    });
  }

  Future<void> _updatePendingCount() async {
    final actions = await _syncService.localDb.getPendingActions();
    _pendingCount = actions.length;
    notifyListeners();
  }

  Future<bool> performCollection({
    required String tarefaId,
    required String itemId,
    required int quantidade,
    String? enderecoId,
  }) async {
    final success = await _syncService.performCollection(
      tarefaId: tarefaId,
      itemId: itemId,
      quantidade: quantidade,
      enderecoId: enderecoId,
    );
    await _updatePendingCount();
    return success;
  }

  Future<bool> performReplenishment({
    String? origemId,
    String? destinoId,
    required String sku,
    required int quantidade,
  }) async {
    final success = await _syncService.performReplenishment(
      origemId: origemId,
      destinoId: destinoId,
      sku: sku,
      quantidade: quantidade,
    );
    await _updatePendingCount();
    return success;
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    
    final actions = await _syncService.localDb.getPendingActions();
    if (actions.isEmpty) return;

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      await _syncService.syncPendingActions();
    } catch (e) {
      _syncError = "Falha na sincronização: $e";
      debugPrint('[SyncProvider] Erro na sincronização: $e');
    } finally {
      _isSyncing = false;
      await _updatePendingCount();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
