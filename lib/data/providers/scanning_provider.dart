import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/task_model.dart';
import '../services/supabase_service.dart';

class ScanningProvider with ChangeNotifier {
  Task? _activeTask;
  bool _isProcessing = false;
  Color _feedbackColor = AppTheme.goldPrimary;
  String? _errorMessage;

  Task? get activeTask => _activeTask;
  bool get isProcessing => _isProcessing;
  Color get feedbackColor => _feedbackColor;
  String? get errorMessage => _errorMessage;

  String? get expectedSKU => (_activeTask?.itens.isNotEmpty ?? false) 
      ? _activeTask!.itens.first.sku 
      : null;

  int get expectedQuantity => (_activeTask?.itens.isNotEmpty ?? false)
      ? _activeTask!.itens.first.quantidadeEsperada
      : 0;

  void setActiveTask(Task task) {
    _activeTask = task;
    _feedbackColor = AppTheme.goldPrimary;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> validateBarcode(String code) async {
    if (_isProcessing || _activeTask == null) return false;

    _isProcessing = true;
    _feedbackColor = AppTheme.goldPrimary;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanCode = code.trim().toUpperCase();
      final product = await SupabaseService.validarCodigo(codigo: cleanCode, tipo: 'produto');
      
      final currentExpectedSKU = expectedSKU;
      
      bool isMatch = product != null && product['sku'] == currentExpectedSKU;

      if (isMatch) {
        _feedbackColor = AppTheme.successGreen;
        _isProcessing = false;
        notifyListeners();
        return true;
      } else {
        _feedbackColor = AppTheme.errorRed;
        _errorMessage = "ITEM NÃO RECONHECIDO OU FORA DA TAREFA";
        _isProcessing = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _feedbackColor = AppTheme.errorRed;
      _errorMessage = "ERRO AO VALIDAR PRODUTO";
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void resetFeedback() {
    _feedbackColor = AppTheme.goldPrimary;
    _errorMessage = null;
    notifyListeners();
  }
}
