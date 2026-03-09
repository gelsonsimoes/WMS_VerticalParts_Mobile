import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/supabase_service.dart';

class PickingProvider with ChangeNotifier {
  Task? _activeTask;
  int _currentItemIndex = 0;
  int _currentStep = 1; // 1: Address, 2: Product, 3: Quantity
  bool _isLoading = false;
  String _typedQuantity = "0";

  Task? get activeTask => _activeTask;
  int get currentItemIndex => _currentItemIndex;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String get typedQuantity => _typedQuantity;

  TaskItem? get currentItem => (_activeTask != null && _activeTask!.itens.isNotEmpty)
      ? _activeTask!.itens[_currentItemIndex]
      : null;

  void setActiveTask(Task task) {
    _activeTask = task;
    _currentItemIndex = 0;
    _currentStep = 1;
    _typedQuantity = "0";
    notifyListeners();
  }

  void updateTypedQuantity(String value) {
    if (_typedQuantity == "0") {
      _typedQuantity = value;
    } else {
      _typedQuantity += value;
    }
    notifyListeners();
  }

  void backspaceQuantity() {
    if (_typedQuantity.length > 1) {
      _typedQuantity = _typedQuantity.substring(0, _typedQuantity.length - 1);
    } else {
      _typedQuantity = "0";
    }
    notifyListeners();
  }

  void clearQuantity() {
    _typedQuantity = "0";
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 3) {
      _currentStep++;
      notifyListeners();
    }
  }

  Future<bool> confirmCollection(int quantity) async {
    if (currentItem == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await SupabaseService.registrarColeta(
        tarefaId: _activeTask!.id,
        itemId: currentItem!.id,
        quantidade: quantity,
        enderecoId: currentItem!.endereco, // O endereço onde o item foi coletado
      );
      
      if (success) {
        currentItem!.quantidadeColetada = quantity;
        _isLoading = false;
        _advanceToNextItem();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _advanceToNextItem() {
    if (_activeTask != null && _currentItemIndex < _activeTask!.itens.length - 1) {
      _currentItemIndex++;
      _currentStep = 1;
      _typedQuantity = "0";
    } else {
      // All items picked
      _activeTask = null; // Or mark as completed
    }
    notifyListeners();
  }

  void resetSteps() {
    _currentStep = 1;
    _typedQuantity = "0";
    notifyListeners();
  }
}
